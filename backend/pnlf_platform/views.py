import datetime as dt

from django.db import transaction
from django.db.models import F, OuterRef, Q, Subquery
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import MethodNotAllowed, PermissionDenied, ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import Utilisateur
from accounts.audit import request_meta, write_audit
from accounts.permissions import CanExportJournal, CanUseMarketplace, CanViewDashboard, CanSyncTerrain
import uuid as uuid_lib
from pnlf_platform.models import (
    AppareilSync,
    Conversation,
    ConversationContext,
    ConversationParticipant,
    ConversationParticipantMeta,
    Message,
    MessagePiece,
    Notification,
    OffreDemande,
    SyncConflict,
)
from pnlf_platform.serializers import (
    AppareilSyncSerializer,
    ConversationSerializer,
    MessageSerializer,
    NotificationSerializer,
    OffreDemandePubliqueSerializer,
    OffreDemandeSerializer,
    SyncConflictSerializer,
    SyncPushSerializer,
)
from pnlf_platform.chat import (
    PLACEHOLDER_AUDIO,
    PLACEHOLDER_PHOTO,
    detecter_piece,
    enregistrer_piece_message,
    is_admin_superviseur,
    is_staff_chat,
    nom_utilisateur,
    photos_utilisateurs,
    profils_utilisateurs,
)
from pnlf_platform.services import (
    creer_notification,
    dashboard_stats,
    generer_qr_offre,
    journal_detail,
    journal_periodes,
)
from pnlf_platform.annonces import PHOTOS_OFFRE_MAX, enregistrer_moderation
from pnlf_platform.offre_statut import enum_supports, ids_par_statut, published_ids, read_statut, write_statut
from traceability.db_utils import column_exists
from traceability.models import Lot, Producteur

ROLES_VALIDATION_OFFRES = (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE)
STATUTS_OFFRE_FIGES = ('CLOTUREE', 'ANNULEE')
CHAMPS_CONTENU_OFFRE = (
    'type_annonce', 'produit_id', 'province_id', 'quantite', 'unite', 'prix_unitaire',
    'devise', 'titre', 'description', 'certification_requise', 'expire_at',
)
FORMATS_EXPORT = ('csv', 'xlsx', 'pdf')
MESSAGES_MAX = 500


def _param_date(request, nom: str):
    texte = (request.query_params.get(nom) or '').strip()
    if not texte:
        return None
    try:
        valeur = parse_date(texte)
    except ValueError:
        valeur = None
    if valeur is None:
        raise ValidationError({nom: 'Date invalide (format attendu : AAAA-MM-JJ).'})
    return valeur


def _param_uuid(request, nom: str):
    texte = (request.query_params.get(nom) or '').strip()
    if not texte:
        return None
    try:
        return uuid_lib.UUID(texte)
    except ValueError as exc:
        raise ValidationError({nom: 'Identifiant invalide.'}) from exc


def _param_since(request):
    """Paramètre ``since`` ISO 8601 (date ou date et heure) ; 400 s'il est illisible."""
    texte = (request.query_params.get('since') or '').strip()
    if not texte:
        return None
    valeur = None
    for candidat in (texte, texte.replace(' ', '+')):
        try:
            valeur = parse_datetime(candidat)
        except ValueError:
            valeur = None
        if valeur is not None:
            break
    if valeur is None:
        try:
            jour = parse_date(texte)
        except ValueError:
            jour = None
        if jour is not None:
            valeur = dt.datetime.combine(jour, dt.time.min)
    if valeur is None:
        raise ValidationError({'since': 'Date invalide (format ISO 8601 attendu, ex. 2026-10-02T08:00:00Z).'})
    if timezone.is_naive(valeur):
        valeur = timezone.make_aware(valeur)
    return valeur


def _format_export(request, defaut: str = 'csv') -> str:
    fmt = (request.query_params.get('export_format') or defaut).strip().lower()
    if fmt not in FORMATS_EXPORT:
        raise ValidationError({'export_format': 'Format d’export inconnu (csv, xlsx ou pdf).'})
    return fmt


class ExportFileView(APIView):
    """Évite le 406 DRF quand le navigateur envoie Accept: application/pdf."""

    permission_classes = [CanViewDashboard]

    def perform_content_negotiation(self, request, force=False):
        return super().perform_content_negotiation(request, force=True)


class DashboardView(APIView):
    permission_classes = [CanViewDashboard]

    def get(self, request):
        date_debut = _param_date(request, 'date_debut')
        date_fin = _param_date(request, 'date_fin')
        if date_debut and date_fin and date_fin < date_debut:
            raise ValidationError({'date_fin': 'La date de fin doit être postérieure ou égale à la date de début.'})
        data = dashboard_stats(
            province_id=_param_uuid(request, 'province'),
            produit_id=_param_uuid(request, 'produit'),
            date_debut=date_debut,
            date_fin=date_fin,
        )
        return Response(data)


class InboxValidationView(APIView):
    """File unique des demandes à traiter (admin / ministère / forestier)."""
    permission_classes = [CanViewDashboard]

    def get(self, request):
        from pnlf_platform.tableau_de_bord import file_a_traiter

        return Response(file_a_traiter(request.user))


class DashboardResumeView(APIView):
    """Indicateurs personnels du tableau de bord, pour tous les profils connectés."""

    def get(self, request):
        from pnlf_platform.tableau_de_bord import resume

        return Response(resume(request.user))


def _lots_filtres(request, src=None):
    """Lots exportables (périmètre du profil) filtrés par recherche, statut, période, province et produit."""
    from accounts.permissions import scope_lots_qs
    from pnlf_platform.statistiques import LIBELLES_STATUT_LOT
    from traceability.models import Produit, Province

    src = src if src is not None else request.query_params
    qs = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
    filtres: list[tuple[str, str]] = []
    q = (str(src.get('q') or '')).strip()[:100]
    if q:
        qs = qs.filter(
            Q(code_lot__icontains=q) | Q(produit__nom__icontains=q) | Q(producteur__nom__icontains=q)
            | Q(producteur__prenoms__icontains=q) | Q(producteur__province__nom__icontains=q)
        )
        filtres.append(('Recherche', q))
    statut = (str(src.get('statut') or '')).strip().upper()
    if statut:
        if statut not in LIBELLES_STATUT_LOT:
            raise ValidationError({'statut': 'Statut de lot inconnu (BROUILLON, VALIDE ou COMMERCIALISE).'})
        qs = qs.filter(statut=statut)
        filtres.append(('Statut', LIBELLES_STATUT_LOT[statut]))
    bornes = {}
    for nom in ('date_debut', 'date_fin'):
        texte = (str(src.get(nom) or '')).strip()
        if texte:
            valeur = parse_date(texte)
            if valeur is None:
                raise ValidationError({nom: 'Date invalide (format attendu : AAAA-MM-JJ).'})
            bornes[nom] = valeur
    if bornes.get('date_debut') and bornes.get('date_fin') and bornes['date_fin'] < bornes['date_debut']:
        raise ValidationError({'date_fin': 'La date de fin doit être postérieure ou égale à la date de début.'})
    if bornes.get('date_debut'):
        qs = qs.filter(date_collecte__gte=bornes['date_debut'])
    if bornes.get('date_fin'):
        qs = qs.filter(date_collecte__lte=bornes['date_fin'])
    province = _uuid_filtre(src, 'province')
    if province:
        qs = qs.filter(producteur__province_id=province)
        filtres.append(('Province', Province.objects.filter(pk=province).values_list('nom', flat=True).first() or '-'))
    produit = _uuid_filtre(src, 'produit')
    if produit:
        qs = qs.filter(produit_id=produit)
        filtres.append(('Produit', Produit.objects.filter(pk=produit).values_list('nom', flat=True).first() or '-'))
    if bornes:
        debut = bornes.get('date_debut')
        fin = bornes.get('date_fin')
        periode = (
            f'du {debut:%d/%m/%Y} au {fin:%d/%m/%Y}' if debut and fin
            else (f'depuis le {debut:%d/%m/%Y}' if debut else f'jusqu’au {fin:%d/%m/%Y}')
        )
    else:
        periode = 'Toutes les dates de collecte'
    return qs, periode, filtres


def _exporter_lots(request, fmt: str, src=None):
    from pnlf_platform.rapports_export import exporter, tableau_lots

    qs, periode, filtres = _lots_filtres(request, src)
    ip, ua = request_meta(request)
    write_audit(
        utilisateur_id=request.user.id, action='EXPORT', table_cible='lots',
        ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': fmt, 'filtres': dict(filtres)},
    )
    return exporter(tableau_lots(qs, periode=periode, filtres=filtres), fmt, request.user)


class ExportLotsView(ExportFileView):
    permission_classes = [CanExportJournal]

    def get(self, request):
        return _exporter_lots(request, _format_export(request))


class JournalPeriodesView(APIView):
    """Historique des périodes (jour / semaine / mois) pour lesquelles un journal d'audit existe.
    Mêmes droits que l'export : le journal contient adresses IP et navigateurs (SEC-15)."""
    permission_classes = [CanExportJournal]

    def get(self, request):
        granularite = (request.query_params.get('granularite') or 'jour').lower()
        if granularite not in ('jour', 'semaine', 'mois'):
            granularite = 'jour'
        return Response({
            'granularite': granularite,
            'results': journal_periodes(
                granularite,
                date_debut=request.query_params.get('date_debut') or None,
                date_fin=request.query_params.get('date_fin') or None,
                q=request.query_params.get('q') or None,
            ),
        })


def _journal_filtres(request):
    """Extrait les filtres communs aux endpoints journal (GET query ou POST body)."""
    src = request.query_params if request.method == 'GET' else request.data
    utilisateur_id = (str(src.get('utilisateur_id') or '')).strip() or None
    if utilisateur_id:
        try:
            uuid_lib.UUID(utilisateur_id)
        except ValueError as exc:
            raise ValidationError({'utilisateur_id': 'Identifiant invalide.'}) from exc
    dates = {}
    for nom in ('date_debut', 'date_fin', 'date'):
        texte = (str(src.get(nom) or '')).strip()
        if not texte:
            dates[nom] = None
            continue
        try:
            valide = parse_date(texte) is not None
        except ValueError:
            valide = False
        if not valide:
            raise ValidationError({nom: 'Date invalide (format attendu : AAAA-MM-JJ).'})
        dates[nom] = texte
    return {
        'utilisateur_id': utilisateur_id,
        'action': (src.get('action') or '').strip().upper() or None,
        'q': (src.get('q') or '').strip() or None,
        'date_debut': dates['date_debut'],
        'date_fin': dates['date_fin'],
    }


class JournalDetailView(APIView):
    permission_classes = [CanExportJournal]

    def get(self, request):
        granularite = (request.query_params.get('granularite') or 'jour').lower()
        if granularite not in ('jour', 'semaine', 'mois'):
            granularite = 'jour'
        date_ref = request.query_params.get('date')
        try:
            page = max(1, int(request.query_params.get('page') or 1))
        except (TypeError, ValueError):
            page = 1
        try:
            page_size = min(100, max(1, int(request.query_params.get('page_size') or 25)))
        except (TypeError, ValueError):
            page_size = 25
        filtres = _journal_filtres(request)
        return Response(journal_detail(
            granularite, date_ref, page=page, page_size=page_size, **filtres,
        ))


class ExportJournalView(ExportFileView):
    permission_classes = [CanExportJournal]

    def get(self, request):
        granularite = (request.query_params.get('granularite') or 'jour').lower()
        if granularite not in ('jour', 'semaine', 'mois'):
            granularite = 'jour'
        date_ref = request.query_params.get('date')
        fmt = _format_export(request)
        return _exporter_journal(request, granularite, date_ref, fmt)


def _exporter_journal(request, granularite: str, date_ref, fmt: str):
    from pnlf_platform.rapports_export import exporter, tableau_journal
    from pnlf_platform.services import _audit_rows, _resolve_journal_bornes

    filtres = _journal_filtres(request)
    debut, fin, libelle = _resolve_journal_bornes(granularite, date_ref, filtres['date_debut'], filtres['date_fin'])
    rows, total = _audit_rows(
        debut=timezone.make_aware(dt.datetime.combine(debut, dt.time.min)),
        fin=timezone.make_aware(dt.datetime.combine(fin, dt.time.min)),
        limit=5000, offset=0,
        utilisateur_id=filtres['utilisateur_id'], action=filtres['action'], q=filtres['q'],
    )
    from pnlf_platform.pdf_export import libelle_action

    contexte = [
        ('Recherche', filtres['q'] or ''),
        ('Action', libelle_action(filtres['action']) if filtres['action'] else ''),
        ('Utilisateur', next((r['utilisateur'] for r in rows), '') if filtres['utilisateur_id'] else ''),
    ]
    ip, ua = request_meta(request)
    write_audit(
        utilisateur_id=request.user.id, action='EXPORT', table_cible='audit_logs',
        ip_adresse=ip, user_agent=ua,
        nouvelles_valeurs={'format': fmt, 'granularite': granularite, 'date': date_ref, **filtres},
    )
    return exporter(tableau_journal(rows, periode=libelle, filtres=contexte, total=total), fmt, request.user)


class ExportLotsTicketView(APIView):
    """Génère le PDF des lots sous JWT et le renvoie directement (octets, pas de redirection).

    Historiquement cette vue renvoyait une URL de « ticket » à charger dans un nouvel
    onglet ouvert via window.open() ; Chrome bloque/annule silencieusement ce type de
    navigation asynchrone (ERR_ABORTED, considéré comme un téléchargement automatique
    non rattaché à un geste utilisateur direct). Le frontend récupère désormais ce PDF
    en Blob authentifié (fetch/XHR classique) puis l'affiche dans un aperçu intégré à la
    page : robuste sur tous les navigateurs, sans dépendre du blocage anti-pop-up.
    """

    permission_classes = [CanExportJournal]

    def post(self, request):
        return _pdf_ou_erreur(lambda: _exporter_lots(request, 'pdf', request.data), 'des lots')


def _pdf_ou_erreur(generer, objet: str):
    try:
        return generer()
    except (ValidationError, PermissionDenied):
        raise
    except Exception:
        import logging

        logging.getLogger(__name__).exception('Échec de génération PDF %s', objet)
        return Response(
            {'detail': f'Le PDF {objet} n’a pas pu être généré. Réessayez dans un instant ou choisissez '
                       'l’export Excel.', 'code': 'pdf_indisponible'},
            status=500,
        )


class ExportJournalTicketView(APIView):
    """Génère le PDF du journal sous JWT et le renvoie directement (voir ExportLotsTicketView)."""

    permission_classes = [CanExportJournal]

    def post(self, request):
        granularite = (request.data.get('granularite') or 'jour').lower()
        if granularite not in ('jour', 'semaine', 'mois'):
            granularite = 'jour'
        date_ref = request.data.get('date')
        return _pdf_ou_erreur(lambda: _exporter_journal(request, granularite, date_ref, 'pdf'), 'du journal')


class ExportDownloadView(APIView):
    """Ancien endpoint ticket sans JWT : désactivé (SEC-12). Utiliser /exports/*/ticket/."""

    permission_classes = [CanViewDashboard]

    def get(self, request):
        return Response(
            {'detail': 'Cet endpoint a été retiré. Utilisez l’export PDF authentifié.'},
            status=status.HTTP_410_GONE,
        )


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    # 'post' est indispensable : les actions personnalisées lire/ et lire-tout/
    # (ci-dessous) sont exposées en POST. Sans lui, DRF rejette ces requêtes en
    # 405 avant même d'atteindre l'action : bug à l'origine du bouton
    # « tout marquer comme lu » silencieusement inopérant.
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        # Les traces d'envoi EMAIL / SMS (accounts.messaging) ne sont pas des notifications à lire.
        return Notification.objects.filter(destinataire_id=self.request.user.id, type_notif='INTERNE')

    def create(self, request, *args, **kwargs):
        raise MethodNotAllowed('POST')

    @action(detail=False, methods=['get'], url_path='non-lues')
    def non_lues(self, request):
        """Compteur pour la cloche (ex. demandes d'inscription en attente non traitées)."""
        return Response({'count': self.get_queryset().filter(lue=False).count()})

    @action(detail=True, methods=['post'])
    def lire(self, request, pk=None):
        n = self.get_object()
        n.lue = True
        n.save(update_fields=['lue'])
        return Response(NotificationSerializer(n).data)

    @action(detail=False, methods=['post'], url_path='lire-tout')
    def lire_tout(self, request):
        self.get_queryset().filter(lue=False).update(lue=True)
        return Response({'detail': 'OK'})


TRIS_ANNONCES = {
    'recent': ('-created_at',),
    'ancien': ('created_at',),
    'prix_asc': (F('prix_unitaire').asc(nulls_last=True), '-created_at'),
    'prix_desc': (F('prix_unitaire').desc(nulls_last=True), '-created_at'),
    'expiration': (F('expire_at').asc(nulls_last=True), '-created_at'),
}


def _param_decimal(params, nom: str):
    from decimal import Decimal, InvalidOperation

    texte = (params.get(nom) or '').strip().replace(',', '.').replace(' ', '')
    if not texte:
        return None
    try:
        valeur = Decimal(texte)
    except InvalidOperation as exc:
        raise ValidationError({nom: 'Montant invalide : saisissez un nombre en FCFA.'}) from exc
    if valeur < 0:
        raise ValidationError({nom: 'Le montant ne peut pas être négatif.'})
    return valeur


def _uuid_filtre(params, *noms):
    for nom in noms:
        texte = (params.get(nom) or '').strip()
        if texte:
            try:
                return uuid_lib.UUID(texte)
            except ValueError as exc:
                raise ValidationError({nom: 'Identifiant invalide.'}) from exc
    return None


def filtrer_annonces(qs, params):
    """Filtres et tri communs aux listes d'annonces (espace connecté et vitrine publique)."""
    type_annonce = (params.get('type_annonce') or '').strip().upper()
    if type_annonce:
        if type_annonce not in ('OFFRE', 'DEMANDE'):
            raise ValidationError({'type_annonce': 'Type d’annonce invalide (OFFRE ou DEMANDE).'})
        qs = qs.filter(type_annonce=type_annonce)
    recherche = (params.get('q') or '').strip()
    if recherche:
        from traceability.models import Produit

        produits = Produit.objects.filter(nom__icontains=recherche).values('id')
        qs = qs.filter(
            Q(titre__icontains=recherche) | Q(description__icontains=recherche)
            | Q(produit_id__in=produits) | Q(details__localite__icontains=recherche)
        )
    produit = _uuid_filtre(params, 'produit', 'produit_id')
    if produit:
        qs = qs.filter(produit_id=produit)
    province = _uuid_filtre(params, 'province', 'province_id')
    if province:
        qs = qs.filter(province_id=province)
    categorie = _uuid_filtre(params, 'categorie')
    if categorie:
        qs = qs.filter(Q(details__categorie_id=categorie) | Q(produit_id__in=_produits_de_categorie(categorie)))
    prix_min = _param_decimal(params, 'prix_min')
    prix_max = _param_decimal(params, 'prix_max')
    if prix_min is not None and prix_max is not None and prix_max < prix_min:
        raise ValidationError({'prix_max': 'Le prix maximum doit être supérieur ou égal au prix minimum.'})
    if prix_min is not None:
        qs = qs.filter(prix_unitaire__gte=prix_min)
    if prix_max is not None:
        qs = qs.filter(prix_unitaire__lte=prix_max)
    tri = (params.get('tri') or 'recent').strip().lower()
    if tri not in TRIS_ANNONCES:
        raise ValidationError({'tri': 'Tri inconnu (recent, ancien, prix_asc, prix_desc ou expiration).'})
    return qs.order_by(*TRIS_ANNONCES[tri])


def _produits_de_categorie(categorie_id):
    from traceability.models import Produit

    return Produit.objects.filter(Q(categorie_id=categorie_id) | Q(categorie__parent_id=categorie_id)).values('id')


def _notifier_moderateurs_offre(offre, *, titre: str, corps: str, sauf=None) -> None:
    moderateurs = Utilisateur.objects.filter(
        role__in=ROLES_VALIDATION_OFFRES, statut=Utilisateur.Statut.ACTIF, deleted_at__isnull=True,
    ).exclude(id=sauf).values_list('id', flat=True)
    for moderateur_id in moderateurs:
        creer_notification(
            moderateur_id, titre, corps,
            metadata={'table_cible': 'offres_demandes', 'enregistrement_id': str(offre.id)},
        )


class OffreDemandeViewSet(viewsets.ModelViewSet):
    """Annonces : création soumise à modération, modification par l'auteur (re-modération si
    l'annonce était publiée), clôture ; pas de suppression (clôturer ou rejeter à la place)."""
    permission_classes = [CanUseMarketplace]
    serializer_class = OffreDemandeSerializer
    filterset_fields = ('produit_id', 'province_id')
    search_fields = ('titre', 'description')
    parser_classes = [FormParser, MultiPartParser, JSONParser]
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        qs = OffreDemande.objects.select_related('details', 'moderation').order_by('-created_at')
        if user.role not in ROLES_VALIDATION_OFFRES:
            non_expiree = Q(expire_at__isnull=True) | Q(expire_at__gt=timezone.now())
            if enum_supports('EN_VALIDATION'):
                qs = qs.filter((Q(statut='OUVERTE') & non_expiree) | Q(auteur_id=user.id))
            else:
                qs = qs.filter((Q(id__in=published_ids()) & non_expiree) | Q(auteur_id=user.id))
        if self.action != 'list':
            return qs
        params = self.request.query_params
        qs = filtrer_annonces(qs, params)
        if (params.get('mine') or '').strip().lower() in ('1', 'true', 'oui'):
            qs = qs.filter(auteur_id=user.id)
        statut = (params.get('statut') or '').strip().upper()
        if statut:
            if statut not in ('EN_VALIDATION', 'OUVERTE', 'REJETEE', 'CLOTUREE', 'ANNULEE'):
                raise ValidationError({'statut': 'Statut d’annonce invalide.'})
            qs = qs.filter(id__in=ids_par_statut(statut))
        return qs

    def _est_moderateur(self) -> bool:
        return self.request.user.role in ROLES_VALIDATION_OFFRES

    def _verifier_modifiable(self, obj) -> str:
        if obj.auteur_id != self.request.user.id and not self._est_moderateur():
            raise PermissionDenied('Vous ne pouvez modifier que vos propres annonces.')
        statut = read_statut(obj)
        if statut in STATUTS_OFFRE_FIGES:
            raise ValidationError({'detail': 'Une annonce clôturée ou annulée ne peut plus être modifiée.'})
        return statut

    def _remettre_en_moderation(self, obj) -> None:
        write_statut(obj, 'EN_VALIDATION')
        _notifier_moderateurs_offre(
            obj, titre='Annonce modifiée à revalider',
            corps=f'L’annonce « {obj.titre} » a été modifiée par son auteur et attend une nouvelle validation.',
            sauf=self.request.user.id,
        )

    def perform_create(self, serializer):
        now = timezone.now()
        db_statut = 'EN_VALIDATION' if enum_supports('EN_VALIDATION') else 'OUVERTE'
        obj = serializer.save(
            auteur_id=self.request.user.id, statut=db_statut, created_at=now, updated_at=now,
        )
        write_statut(obj, 'EN_VALIDATION')
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='CREATE', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
        )
        type_libelle = 'offre' if obj.type_annonce == 'OFFRE' else 'demande'
        _notifier_moderateurs_offre(
            obj, titre='Nouvelle annonce à valider',
            corps=f'Nouvelle {type_libelle} « {obj.titre} » en attente de validation.',
            sauf=self.request.user.id,
        )

    def perform_update(self, serializer):
        obj = serializer.instance
        statut = self._verifier_modifiable(obj)
        modifies = sorted([
            *(champ for champ in CHAMPS_CONTENU_OFFRE
              if champ in serializer.validated_data and serializer.validated_data[champ] != getattr(obj, champ)),
            *serializer.details_modifies(obj),
        ])
        obj = serializer.save(updated_at=timezone.now())
        # Une annonce publiée et modifiée, ou rejetée puis corrigée, repasse en validation.
        remoderation = statut in ('OUVERTE', 'REJETEE') and bool(modifies) and not self._est_moderateur()
        if remoderation:
            self._remettre_en_moderation(obj)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='UPDATE', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'champs': modifies, **({'statut': 'EN_VALIDATION'} if remoderation else {})},
        )

    @action(detail=True, methods=['post'], url_path='photos')
    def photos(self, request, pk=None):
        """Ajoute jusqu'à PHOTOS_OFFRE_MAX photos illustrant l'annonce (auteur ou modérateur)."""
        from traceability.services import enregistrer_photo, photo_url

        obj = self.get_object()
        statut = self._verifier_modifiable(obj)
        fichiers = request.FILES.getlist('photos')
        if not fichiers and 'photo' in request.FILES:
            fichiers = [request.FILES['photo']]
        if not fichiers:
            raise ValidationError({'photos': 'Aucun fichier reçu.'})

        libres = [i for i in range(1, PHOTOS_OFFRE_MAX + 1) if not photo_url('offres', obj.id, suffixe=f'_{i}')]
        if len(fichiers) > len(libres):
            deja = PHOTOS_OFFRE_MAX - len(libres)
            raise ValidationError({
                'photos': f'{PHOTOS_OFFRE_MAX} photos maximum par annonce '
                          f'({deja} déjà enregistrée{"s" if deja > 1 else ""}).',
            })
        for fichier in fichiers:
            enregistrer_photo(fichier, 'offres', obj.id, suffixe=f'_{libres.pop(0)}')
        if statut in ('OUVERTE', 'REJETEE') and not self._est_moderateur():
            self._remettre_en_moderation(obj)

        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='photos/supprimer')
    def supprimer_photo(self, request, pk=None):
        """Retire une photo de l'annonce (numéro 1 à PHOTOS_OFFRE_MAX) ; les suivantes sont renumérotées."""
        from config import media_store
        from traceability.services import chemin_photo

        obj = self.get_object()
        self._verifier_modifiable(obj)
        try:
            numero = int(request.data.get('numero'))
        except (TypeError, ValueError):
            numero = 0
        if not 1 <= numero <= PHOTOS_OFFRE_MAX or not chemin_photo('offres', obj.id, f'_{numero}').exists():
            raise ValidationError({'numero': 'Cette photo n’existe pas ou a déjà été retirée.'})
        cible = chemin_photo('offres', obj.id, f'_{numero}')
        cible.unlink()
        media_store.supprimer(cible)
        for suivant in range(numero + 1, PHOTOS_OFFRE_MAX + 1):
            source = chemin_photo('offres', obj.id, f'_{suivant}')
            if not source.exists():
                break
            destination = chemin_photo('offres', obj.id, f'_{suivant - 1}')
            source.replace(destination)
            media_store.pousser(destination)
            media_store.supprimer(source)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='DELETE_PHOTO', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'numero': numero},
        )
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='valider')
    def valider(self, request, pk=None):
        """Validation par un administrateur / agent du ministère : publication + génération du QR."""
        obj = self.get_object()
        if request.user.role not in ROLES_VALIDATION_OFFRES:
            raise PermissionDenied('Seuls les administrateurs et agents du ministère peuvent valider une annonce.')
        if read_statut(obj) != 'EN_VALIDATION':
            raise ValidationError({'detail': 'Seule une annonce en attente de validation peut être validée.'})
        if column_exists('offres_demandes', 'uuid_public'):
            from traceability.db_utils import get_optional_column, set_optional_column

            uuid_public = get_optional_column('offres_demandes', 'uuid_public', obj.id) or uuid_lib.uuid4()
            qr_payload = f'PNLF-OD:{uuid_public}'
            obj.uuid_public = uuid_public
            obj.qr_payload = qr_payload
            qr_image_path = generer_qr_offre(obj)
            set_optional_column('offres_demandes', 'uuid_public', obj.id, uuid_public)
            set_optional_column('offres_demandes', 'qr_payload', obj.id, qr_payload)
            set_optional_column('offres_demandes', 'qr_image_path', obj.id, qr_image_path)
        write_statut(obj, 'OUVERTE')
        enregistrer_moderation(obj, decision='VALIDEE', moderateur=request.user)

        creer_notification(
            obj.auteur_id, 'Annonce validée',
            f'Votre annonce « {obj.titre} » a été validée et publiée dans l\'annuaire public.',
            metadata={'table_cible': 'offres_demandes', 'enregistrement_id': str(obj.id)},
        )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='rejeter')
    def rejeter(self, request, pk=None):
        obj = self.get_object()
        if request.user.role not in ROLES_VALIDATION_OFFRES:
            raise PermissionDenied('Seuls les administrateurs et agents du ministère peuvent rejeter une annonce.')
        if read_statut(obj) != 'EN_VALIDATION':
            raise ValidationError({'detail': 'Seule une annonce en attente de validation peut être rejetée.'})
        motif = (request.data.get('motif') or '').strip()
        if not motif:
            raise ValidationError({'motif': 'Le motif du rejet est obligatoire : il est communiqué à l’auteur.'})
        motif = motif[:1000]
        write_statut(obj, 'REJETEE')
        enregistrer_moderation(obj, decision='REJETEE', moderateur=request.user, motif=motif)

        corps = f'Votre annonce « {obj.titre} » a été rejetée. Motif : {motif}'
        creer_notification(
            obj.auteur_id, 'Annonce rejetée', corps,
            metadata={'table_cible': 'offres_demandes', 'enregistrement_id': str(obj.id)},
        )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'motif': motif},
        )
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='cloturer')
    def cloturer(self, request, pk=None):
        obj = self.get_object()
        # L'auteur ou un modérateur (rôles habilités à valider / rejeter) peut clôturer.
        if obj.auteur_id != request.user.id and not self._est_moderateur():
            raise PermissionDenied('Seuls l’auteur et les modérateurs peuvent clôturer une annonce.')
        if read_statut(obj) != 'OUVERTE':
            raise ValidationError({'detail': 'Seule une annonce publiée peut être clôturée.'})
        write_statut(obj, 'CLOTUREE')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='UPDATE', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'statut': 'CLOTUREE'},
        )
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)


class PublicOffresDemandesListView(APIView):
    """Vitrine publique des offres/demandes validées par un administrateur ou agent du ministère."""
    permission_classes = [AllowAny]

    def get(self, request):
        qs = OffreDemande.objects.select_related('details')
        if enum_supports('EN_VALIDATION'):
            qs = qs.filter(statut='OUVERTE')
        else:
            qs = qs.filter(id__in=published_ids())
        qs = qs.filter(Q(expire_at__isnull=True) | Q(expire_at__gt=timezone.now()))
        qs = filtrer_annonces(qs, request.query_params)

        try:
            page = max(1, int(request.query_params.get('page') or 1))
        except (TypeError, ValueError):
            page = 1
        try:
            page_size = min(50, max(1, int(request.query_params.get('page_size') or 12)))
        except (TypeError, ValueError):
            page_size = 12
        total = qs.count()
        start = (page - 1) * page_size
        rows = list(qs[start:start + page_size])
        data = OffreDemandePubliqueSerializer(rows, many=True, context={'request': request}).data

        def url_page(numero: int) -> str:
            params = request.query_params.copy()
            params['page'] = str(numero)
            return request.build_absolute_uri(f'{request.path}?{params.urlencode()}')

        return Response({
            'count': total,
            'next': url_page(page + 1) if start + page_size < total else None,
            'previous': url_page(page - 1) if page > 1 and start - page_size < total else None,
            'results': data,
            'page': page,
            'page_size': page_size,
        })


class PublicOffreDemandeDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        try:
            obj = OffreDemande.objects.select_related('details').filter(pk=uuid_lib.UUID(str(pk))).first()
        except ValueError:
            obj = None
        if not obj or read_statut(obj) != 'OUVERTE' or (obj.expire_at and obj.expire_at <= timezone.now()):
            return Response({'detail': 'Cette annonce est introuvable, expirée ou n’est plus publiée.'}, status=404)
        return Response(OffreDemandePubliqueSerializer(obj, context={'request': request}).data)


class PublicContactOffreView(APIView):
    permission_classes = [AllowAny]

    def get_throttles(self):
        from traceability.public_views import ContactPublicThrottle
        return [ContactPublicThrottle()]

    def post(self, request, pk=None):
        from django.core.validators import validate_email
        from django.core.exceptions import ValidationError as DjangoValidationError
        from pnlf_platform.offre_statut import read_statut
        if (request.data.get('site_web') or '').strip():
            return Response({'detail': 'Requête invalide.'}, status=400)
        obj = OffreDemande.objects.filter(pk=pk).first()
        if not obj or read_statut(obj) != 'OUVERTE':
            return Response({'detail': 'Annonce introuvable ou non publiée.'}, status=404)
        nom = (request.data.get('nom') or '').strip()
        email = (request.data.get('email') or '').strip()
        telephone = (request.data.get('telephone') or '').strip()
        message = (request.data.get('message') or '').strip()
        from config.validators import normaliser_telephone
        from rest_framework.exceptions import ValidationError as DRFValidationError
        erreurs = {}
        if not nom:
            erreurs['nom'] = ['Votre nom est requis.']
        if not email:
            erreurs['email'] = ['Votre adresse e-mail est requise.']
        else:
            try:
                validate_email(email)
            except DjangoValidationError:
                erreurs['email'] = ['Adresse e-mail invalide.']
        if not message:
            erreurs['message'] = ['Votre message est requis.']
        elif len(message) < 10:
            erreurs['message'] = ['Votre message est trop court (10 caractères minimum).']
        elif len(message) > 2000:
            erreurs['message'] = ['Message trop long (2000 caractères maximum).']
        try:
            telephone = normaliser_telephone(telephone) or ''
        except DRFValidationError as exc:
            erreurs['telephone'] = exc.detail
        if erreurs:
            return Response(erreurs, status=400)
        creer_notification(
            obj.auteur_id,
            'Message sur votre annonce',
            f'{nom} ({email}{(" · " + telephone) if telephone else ""}) à propos de « {obj.titre} » : {message[:280]}',
        )
        prod = Producteur.objects.filter(utilisateur_id=obj.auteur_id, deleted_at__isnull=True).first()
        if prod:
            from traceability.db_utils import table_exists
            from traceability.models import MessagePublic
            if table_exists('messages_publics'):
                MessagePublic.objects.create(
                    producteur=prod,
                    nom_visiteur=nom,
                    email_visiteur=email,
                    telephone_visiteur=telephone or None,
                    message=f'[Annonce {obj.titre}] {message}',
                    created_at=timezone.now(),
                )
        return Response({'detail': 'Message transmis à l’auteur de l’annonce.'}, status=201)


def _uuid_or_none(value, champ: str = 'detail'):
    if value is None:
        return None
    text = str(value).strip()
    if not text or text.lower() in ('null', 'undefined', 'none'):
        return None
    try:
        return str(uuid_lib.UUID(text))
    except ValueError as exc:
        raise ValidationError({champ: 'Identifiant invalide.'}) from exc


CONTACTS_FILTRES_ROLE = {
    'PRODUCTEUR': (Utilisateur.Role.PRODUCTEUR,),
    'COOPERATIVE': (Utilisateur.Role.COOPERATIVE,),
    'ACHETEUR': (Utilisateur.Role.ACHETEUR,),
    'AGENT': (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER),
}
SUPERVISION_PDF_MESSAGES_MAX = 5000


class ContactsPagination(PageNumberPagination):
    page_size = 30
    page_size_query_param = 'page_size'
    max_page_size = 100


def _messages_recents(qs) -> list:
    """Les MESSAGES_MAX messages les plus récents, restitués dans l'ordre chronologique."""
    recents = list(qs.order_by('-created_at', '-id')[:MESSAGES_MAX])
    recents.reverse()
    return recents


def _controler_interlocuteur(user, destinataire_id, champ: str):
    """Tout compte connecté peut écrire à n'importe quel autre compte actif de la plateforme."""
    if str(destinataire_id) == str(user.id):
        raise ValidationError({champ: 'Vous ne pouvez pas discuter avec vous-même.'})
    dest = Utilisateur.objects.filter(
        pk=destinataire_id, deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
    ).first()
    if not dest:
        raise ValidationError({champ: 'Ce compte est introuvable ou n’est pas actif : la discussion ne peut pas être ouverte.'})
    return dest


def _cle_tri_nom(texte: str) -> str:
    import unicodedata

    decompose = unicodedata.normalize('NFKD', texte or '')
    return ''.join(c for c in decompose if not unicodedata.combining(c)).casefold().strip()


def _conversation_queryset(user):
    """Inbox personnelle : uniquement les fils où l'utilisateur est participant."""
    last = Message.objects.filter(conversation_id=OuterRef('pk')).order_by('-created_at')
    qs = Conversation.objects.prefetch_related('participants').annotate(
        dernier_at=Subquery(last.values('created_at')[:1]),
        dernier_contenu=Subquery(last.values('contenu')[:1]),
    )
    deleted_ids = ConversationParticipantMeta.objects.filter(
        utilisateur_id=user.id, deleted_at__isnull=False,
    ).values_list('conversation_id', flat=True)
    conv_ids = ConversationParticipant.objects.filter(
        utilisateur_id=user.id,
    ).values_list('conversation_id', flat=True)
    return qs.filter(id__in=conv_ids).exclude(id__in=deleted_ids)


def _supervision_queryset():
    """Tous les fils (supervision admin uniquement)."""
    last = Message.objects.filter(conversation_id=OuterRef('pk')).order_by('-created_at')
    return Conversation.objects.prefetch_related('participants').annotate(
        dernier_at=Subquery(last.values('created_at')[:1]),
        dernier_contenu=Subquery(last.values('contenu')[:1]),
    )


def _filtrer_conversations_par_recherche(qs, q: str):
    text = (q or '').strip()
    if not text:
        return qs
    user_ids = Utilisateur.objects.filter(
        Q(nom__icontains=text) | Q(prenoms__icontains=text) | Q(email__icontains=text),
        deleted_at__isnull=True,
    ).values_list('id', flat=True)
    conv_via_participants = ConversationParticipant.objects.filter(
        utilisateur_id__in=user_ids,
    ).values_list('conversation_id', flat=True)
    return qs.filter(
        Q(sujet__icontains=text)
        | Q(id__in=conv_via_participants)
        | Q(dernier_contenu__icontains=text)
    )


def _hydrate_conversation_users(serializer, conversations, request=None):
    ids = set()
    for conv in conversations:
        for p in conv.participants.all():
            ids.add(p.utilisateur_id)
    users = {str(u.id): u for u in Utilisateur.objects.filter(id__in=list(ids))}
    serializer.context['_users_by_id'] = users
    serializer.context['_profils_by_user'] = profils_utilisateurs(users.values())
    conv_ids = [c.id for c in conversations]
    ctx_rows = ConversationContext.objects.filter(conversation_id__in=conv_ids)
    serializer.context['_ctx_by_conv'] = {str(row.conversation_id): row for row in ctx_rows}
    req = request or serializer.context.get('request')
    serializer.context['_photos_by_user'] = photos_utilisateurs(ids, req)

    me = getattr(getattr(req, 'user', None), 'id', None)
    unread = {}
    if me and conv_ids:
        metas = {
            str(m.conversation_id): m
            for m in ConversationParticipantMeta.objects.filter(
                conversation_id__in=conv_ids, utilisateur_id=me,
            )
        }
        for conv in conversations:
            meta = metas.get(str(conv.id))
            since = meta.last_read_at if meta and meta.last_read_at else None
            qs = Message.objects.filter(conversation_id=conv.id).exclude(expediteur_id=me)
            if since:
                qs = qs.filter(created_at__gt=since)
            unread[str(conv.id)] = qs.count()
    serializer.context['_unread_by_conv'] = unread


def _hydrate_message_users(serializer, messages, conversation=None, request=None):
    ids = {m.expediteur_id for m in messages}
    users = {str(u.id): u for u in Utilisateur.objects.filter(id__in=list(ids))}
    serializer.context['_users_by_id'] = users
    msg_ids = [m.id for m in messages]
    pieces = MessagePiece.objects.filter(message_id__in=msg_ids)
    serializer.context['_pieces_by_msg'] = {str(p.message_id): p for p in pieces}
    req = request or serializer.context.get('request')
    serializer.context['_photos_by_user'] = photos_utilisateurs(ids, req)

    other_reads = {}
    if conversation is not None:
        me = getattr(getattr(req, 'user', None), 'id', None)
        others = [
            p.utilisateur_id
            for p in conversation.participants.all()
            if me is None or str(p.utilisateur_id) != str(me)
        ]
        metas = {
            str(m.utilisateur_id): m.last_read_at
            for m in ConversationParticipantMeta.objects.filter(
                conversation_id=conversation.id, utilisateur_id__in=others,
            )
        }
        other_reads[str(conversation.id)] = [metas.get(str(uid)) for uid in others]
    serializer.context['_other_reads_by_conv'] = other_reads


def _ajouter_participant(conv, utilisateur_id, now):
    ConversationParticipant.objects.get_or_create(
        conversation=conv,
        utilisateur_id=utilisateur_id,
        defaults={'joined_at': now},
    )
    ConversationParticipantMeta.objects.get_or_create(
        conversation_id=conv.id,
        utilisateur_id=utilisateur_id,
        defaults={'last_read_at': now},
    )


def _marquer_lu(conversation_id, utilisateur_id):
    now = timezone.now()
    meta, created = ConversationParticipantMeta.objects.get_or_create(
        conversation_id=conversation_id,
        utilisateur_id=utilisateur_id,
        defaults={'last_read_at': now, 'deleted_at': None},
    )
    if not created:
        meta.last_read_at = now
        if meta.deleted_at:
            meta.deleted_at = None
        meta.save(update_fields=['last_read_at', 'deleted_at'])
    Message.objects.filter(
        conversation_id=conversation_id, lu_at__isnull=True,
    ).exclude(expediteur_id=utilisateur_id).update(lu_at=now)


def _trouver_fil_existant(user_id, *, offre_id=None, producteur_id=None, cooperative_id=None, destinataire_id=None):
    deleted = ConversationParticipantMeta.objects.filter(
        utilisateur_id=user_id, deleted_at__isnull=False,
    ).values_list('conversation_id', flat=True)
    mine = ConversationParticipant.objects.filter(utilisateur_id=user_id).values_list('conversation_id', flat=True)
    qs = Conversation.objects.filter(id__in=mine).exclude(id__in=deleted)
    if offre_id:
        return qs.filter(offre_id=offre_id).first()
    if producteur_id:
        ctx_ids = ConversationContext.objects.filter(
            producteur_id=producteur_id, est_groupe=False,
        ).values_list('conversation_id', flat=True)
        return qs.filter(id__in=ctx_ids).first()
    if cooperative_id:
        ctx_ids = ConversationContext.objects.filter(
            cooperative_id=cooperative_id, est_groupe=False, producteur_id__isnull=True,
        ).values_list('conversation_id', flat=True)
        return qs.filter(id__in=ctx_ids).first()
    if destinataire_id:
        theirs = ConversationParticipant.objects.filter(
            utilisateur_id=destinataire_id,
        ).values_list('conversation_id', flat=True)
        linked = ConversationContext.objects.filter(conversation_id__in=mine).values_list('conversation_id', flat=True)
        return (
            qs.filter(id__in=theirs, offre_id__isnull=True)
            .exclude(id__in=linked)
            .first()
        )
    return None


def _trouver_groupe_identique(user_id, cooperative_id, selected_ids: set[str]):
    """Retrouve un groupe coop avec exactement le même ensemble de participants."""
    ctx_ids = ConversationContext.objects.filter(
        cooperative_id=cooperative_id, est_groupe=True,
    ).values_list('conversation_id', flat=True)
    mine = ConversationParticipant.objects.filter(
        utilisateur_id=user_id, conversation_id__in=ctx_ids,
    ).values_list('conversation_id', flat=True)
    wanted = {str(x) for x in selected_ids}
    for conv_id in mine:
        members = {
            str(uid)
            for uid in ConversationParticipant.objects.filter(
                conversation_id=conv_id,
            ).values_list('utilisateur_id', flat=True)
        }
        if members == wanted:
            return Conversation.objects.filter(pk=conv_id).first()
    return None


def _cooperatives_de_l_utilisateur(user):
    from traceability.models import Cooperative, CooperativeMembre, Producteur

    coops = list(Cooperative.objects.filter(utilisateur_id=user.id, actif=True))
    # Producteur (ou compte coop aussi producteur) : via adhésions
    fiche_ids = Producteur.objects.filter(
        utilisateur_id=user.id, deleted_at__isnull=True,
    ).values_list('id', flat=True)
    coop_ids = CooperativeMembre.objects.filter(
        producteur_id__in=fiche_ids, actif=True,
    ).values_list('cooperative_id', flat=True)
    coops.extend(list(Cooperative.objects.filter(id__in=coop_ids, actif=True)))
    seen = set()
    unique = []
    for c in coops:
        if c.id not in seen:
            seen.add(c.id)
            unique.append(c)
    return unique


def _membres_utilisateurs_coop(cooperative_id, exclude_user_id=None):
    from traceability.models import Cooperative, CooperativeMembre, Producteur

    ids = set()
    coop = Cooperative.objects.filter(pk=cooperative_id).first()
    if coop and coop.utilisateur_id:
        ids.add(coop.utilisateur_id)
    prod_ids = CooperativeMembre.objects.filter(
        cooperative_id=cooperative_id, actif=True,
    ).values_list('producteur_id', flat=True)
    for uid in Producteur.objects.filter(
        id__in=prod_ids, deleted_at__isnull=True, utilisateur_id__isnull=False,
    ).values_list('utilisateur_id', flat=True):
        ids.add(uid)
    if exclude_user_id:
        ids.discard(exclude_user_id)
    return list(Utilisateur.objects.filter(
        id__in=list(ids), deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
    ).order_by('nom', 'prenoms'))


class ConversationViewSet(viewsets.ModelViewSet):
    permission_classes = [CanUseMarketplace]
    serializer_class = ConversationSerializer
    http_method_names = ['get', 'post', 'delete', 'head', 'options']
    parser_classes = [JSONParser, FormParser, MultiPartParser]
    filterset_fields = ('offre_id',)

    def get_queryset(self):
        qs = _conversation_queryset(self.request.user)
        producteur_id = _param_uuid(self.request, 'producteur_id')
        cooperative_id = _param_uuid(self.request, 'cooperative_id')
        if producteur_id:
            qs = qs.filter(
                id__in=ConversationContext.objects.filter(producteur_id=producteur_id).values_list('conversation_id', flat=True),
            )
        if cooperative_id:
            qs = qs.filter(
                id__in=ConversationContext.objects.filter(cooperative_id=cooperative_id).values_list('conversation_id', flat=True),
            )
        qs = _filtrer_conversations_par_recherche(qs, self.request.query_params.get('q'))
        return qs.order_by(
            F('dernier_at').desc(nulls_last=True), '-created_at',
        )

    def get_serializer(self, *args, **kwargs):
        serializer = super().get_serializer(*args, **kwargs)
        instance = args[0] if args else kwargs.get('instance')
        if instance is None:
            return serializer
        target = serializer.child if hasattr(serializer, 'child') else serializer
        if kwargs.get('many'):
            convs = list(instance)
        elif isinstance(instance, Conversation):
            convs = [instance]
        else:
            return serializer
        _hydrate_conversation_users(target, convs, self.request)
        return serializer

    def destroy(self, request, *args, **kwargs):
        conv = self.get_object()
        now = timezone.now()
        meta, _ = ConversationParticipantMeta.objects.get_or_create(
            conversation_id=conv.id,
            utilisateur_id=request.user.id,
            defaults={'deleted_at': now},
        )
        if not meta.deleted_at:
            meta.deleted_at = now
            meta.save(update_fields=['deleted_at'])
        return Response(status=status.HTTP_204_NO_CONTENT)

    def create(self, request, *args, **kwargs):
        from traceability.models import Cooperative, Producteur

        est_groupe = str(request.data.get('est_groupe', '')).lower() in ('1', 'true', 'yes')
        offre_id = _uuid_or_none(request.data.get('offre_id'), 'offre_id')
        producteur_id = _uuid_or_none(request.data.get('producteur_id'), 'producteur_id')
        cooperative_id = _uuid_or_none(request.data.get('cooperative_id'), 'cooperative_id')
        destinataire_id = _uuid_or_none(request.data.get('destinataire_id'), 'destinataire_id')
        sujet = (request.data.get('sujet') or '').strip() or None
        raw_participants = request.data.get('participants') or request.data.get('participant_ids') or []
        if isinstance(raw_participants, str):
            raw_participants = [x.strip() for x in raw_participants.split(',') if x.strip()]

        if est_groupe:
            # Réservé aux membres réels d'une coopérative (pas de bypass admin)
            if request.user.role not in (
                Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE,
            ):
                raise PermissionDenied(
                    'Seuls les producteurs et comptes coopérative peuvent créer un groupe.'
                )
            if not cooperative_id:
                raise ValidationError({'cooperative_id': 'Choisissez votre coopérative.'})
            mes_coops = {str(c.id) for c in _cooperatives_de_l_utilisateur(request.user)}
            if cooperative_id not in mes_coops:
                raise PermissionDenied('Vous n’êtes pas membre de cette coopérative.')
            coop = Cooperative.objects.filter(pk=cooperative_id).first()
            if not coop:
                raise ValidationError({'cooperative_id': 'Coopérative introuvable.'})
            membres = _membres_utilisateurs_coop(cooperative_id, exclude_user_id=None)
            allowed = {str(u.id) for u in membres}
            allowed.add(str(request.user.id))
            if raw_participants:
                selected = {str(x) for x in raw_participants}
            else:
                selected = set(allowed)
            selected.add(str(request.user.id))
            if not selected <= allowed:
                raise ValidationError({
                    'participants': 'Tous les membres sélectionnés doivent appartenir à la coopérative.',
                })
            if len(selected) < 2:
                raise ValidationError({
                    'participants': 'Ajoutez au moins un autre membre de la coopérative.',
                })
            now = timezone.now()
            sujet = sujet or f'Groupe : {coop.nom}'
            # Réutiliser un groupe existant avec exactement les mêmes participants si possible
            existing_group = _trouver_groupe_identique(
                request.user.id, cooperative_id, selected,
            )
            if existing_group:
                ConversationParticipantMeta.objects.filter(
                    conversation_id=existing_group.id, utilisateur_id=request.user.id,
                ).update(deleted_at=None)
                ser = self.get_serializer(existing_group)
                return Response(ser.data)
            conv = Conversation.objects.create(
                id=uuid_lib.uuid4(), sujet=sujet, offre_id=None, created_at=now,
            )
            ConversationContext.objects.create(
                conversation=conv, cooperative_id=cooperative_id, est_groupe=True,
            )
            for uid in selected:
                _ajouter_participant(conv, uid, now)
            ser = self.get_serializer(conv)
            return Response(ser.data, status=status.HTTP_201_CREATED)

        if offre_id and not (producteur_id or cooperative_id or destinataire_id):
            if OffreDemande.objects.filter(pk=offre_id, auteur_id=request.user.id).exists():
                raise ValidationError({
                    'offre_id': 'Vous êtes l’auteur de cette annonce : répondez depuis les échanges reçus.',
                })

        moi = str(request.user.id)
        soi_meme = (
            (destinataire_id and str(destinataire_id) == moi)
            or (producteur_id and Producteur.objects.filter(pk=producteur_id, utilisateur_id=request.user.id).exists())
            or (cooperative_id and Cooperative.objects.filter(pk=cooperative_id, utilisateur_id=request.user.id).exists())
        )
        if soi_meme:
            raise ValidationError({'detail': 'Vous ne pouvez pas discuter avec vous-même.'})

        existing = _trouver_fil_existant(
            request.user.id,
            offre_id=offre_id,
            producteur_id=producteur_id,
            cooperative_id=cooperative_id,
            destinataire_id=destinataire_id,
        )
        if existing:
            # réactiver si soft-deleted
            ConversationParticipantMeta.objects.filter(
                conversation_id=existing.id, utilisateur_id=request.user.id,
            ).update(deleted_at=None)
            ser = self.get_serializer(existing)
            return Response(ser.data)

        offre = None
        if offre_id:
            offre = OffreDemande.objects.filter(pk=offre_id).first()
            if not offre:
                raise ValidationError({'offre_id': 'Annonce introuvable.'})
            if read_statut(offre) != 'OUVERTE' and not is_staff_chat(request.user):
                raise ValidationError({'offre_id': 'Cette annonce n’est pas ouverte aux échanges.'})

        other_id = None
        champ = None
        if producteur_id:
            champ = 'producteur_id'
            fiche = Producteur.objects.filter(pk=producteur_id, deleted_at__isnull=True).first()
            if not fiche or fiche.statut != 'ACTIF':
                raise ValidationError({'producteur_id': 'Producteur introuvable ou inactif.'})
            if not fiche.utilisateur_id:
                raise ValidationError({
                    'producteur_id': "Ce producteur n'a pas de compte connecté : utilisez le formulaire de contact.",
                })
            other_id = fiche.utilisateur_id
            sujet = sujet or f'Discussion avec {fiche.prenoms} {fiche.nom}'.strip()
        elif cooperative_id:
            champ = 'cooperative_id'
            coop = Cooperative.objects.filter(pk=cooperative_id).first()
            if not coop or not coop.actif or (coop.statut or 'ACTIF') != 'ACTIF':
                raise ValidationError({'cooperative_id': 'Coopérative introuvable ou inactive.'})
            if not coop.utilisateur_id:
                raise ValidationError({
                    'cooperative_id': "Cette coopérative n'a pas de compte connecté.",
                })
            other_id = coop.utilisateur_id
            sujet = sujet or f'Discussion avec {coop.nom}'
        elif offre is not None:
            champ = 'offre_id'
            other_id = offre.auteur_id
            sujet = sujet or offre.titre
        elif destinataire_id:
            champ = 'destinataire_id'
            other_id = destinataire_id
        else:
            raise ValidationError({'detail': 'Indiquez une offre, un producteur, une coopérative ou un destinataire.'})

        dest = _controler_interlocuteur(request.user, other_id, champ)
        if champ == 'destinataire_id':
            sujet = sujet or f'Discussion avec {nom_utilisateur(dest)}'

        now = timezone.now()
        conv = Conversation.objects.create(
            id=uuid_lib.uuid4(),
            sujet=sujet,
            offre_id=offre_id,
            created_at=now,
        )
        if producteur_id or cooperative_id:
            ConversationContext.objects.create(
                conversation=conv,
                producteur_id=producteur_id,
                cooperative_id=cooperative_id,
                est_groupe=False,
            )
        _ajouter_participant(conv, request.user.id, now)
        _ajouter_participant(conv, dest.id, now)
        ser = self.get_serializer(conv)
        return Response(ser.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def contacts(self, request):
        """Comptes actifs joignables, triés alphabétiquement : recherche serveur, filtre par rôle, pagination."""
        from traceability.models import Cooperative, Producteur

        qs = Utilisateur.objects.filter(
            deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
        ).exclude(id=request.user.id)
        filtre = (request.query_params.get('role') or '').strip().upper()
        if filtre:
            if filtre not in CONTACTS_FILTRES_ROLE:
                raise ValidationError({'role': 'Filtre inconnu (PRODUCTEUR, COOPERATIVE, ACHETEUR ou AGENT).'})
            qs = qs.filter(role__in=CONTACTS_FILTRES_ROLE[filtre])
        for mot in (request.query_params.get('q') or '').split()[:6]:
            via_coop = Cooperative.objects.filter(
                nom__icontains=mot, utilisateur_id__isnull=False,
            ).values('utilisateur_id')
            via_fiche = Producteur.objects.filter(
                cooperative__nom__icontains=mot, deleted_at__isnull=True, utilisateur_id__isnull=False,
            ).values('utilisateur_id')
            qs = qs.filter(
                Q(nom__icontains=mot) | Q(prenoms__icontains=mot)
                | Q(id__in=via_coop) | Q(id__in=via_fiche)
            )
        lignes = sorted(
            qs.values_list('id', 'prenoms', 'nom'),
            key=lambda r: (_cle_tri_nom(f'{r[1]} {r[2]}'), str(r[0])),
        )
        paginator = ContactsPagination()
        page = paginator.paginate_queryset(lignes, request, view=self)
        ids = [r[0] for r in page]
        par_id = {u.id: u for u in Utilisateur.objects.filter(id__in=ids)}
        users = [par_id[i] for i in ids if i in par_id]
        photos = photos_utilisateurs(ids, request)
        profils = profils_utilisateurs(users)
        data = [
            {
                'id': str(u.id),
                'nom': u.nom,
                'prenoms': u.prenoms,
                'role': u.role,
                'role_libelle': profils[str(u.id)]['role_libelle'],
                'organisation': profils[str(u.id)]['organisation'],
                'libelle': nom_utilisateur(u),
                'photo_url': photos.get(str(u.id)),
            }
            for u in users
        ]
        return paginator.get_paginated_response(data)

    @action(detail=False, methods=['get'], url_path='non-lus')
    def non_lus(self, request):
        total = 0
        for conv in _conversation_queryset(request.user):
            meta = ConversationParticipantMeta.objects.filter(
                conversation_id=conv.id, utilisateur_id=request.user.id,
            ).first()
            since = meta.last_read_at if meta and meta.last_read_at else None
            qs = Message.objects.filter(conversation_id=conv.id).exclude(expediteur_id=request.user.id)
            if since:
                qs = qs.filter(created_at__gt=since)
            total += qs.count()
        return Response({'count': total})

    @action(detail=False, methods=['get'], url_path='membres-coop')
    def membres_coop(self, request):
        """Coopératives de l'utilisateur + membres joignables (création de groupe)."""
        if request.user.role not in (
            Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE,
        ):
            return Response([])
        coops = _cooperatives_de_l_utilisateur(request.user)
        payload = []
        for coop in coops:
            membres = _membres_utilisateurs_coop(coop.id, exclude_user_id=request.user.id)
            photos = photos_utilisateurs([u.id for u in membres], request)
            payload.append({
                'id': str(coop.id),
                'nom': coop.nom,
                'membres': [
                    {
                        'id': str(u.id),
                        'nom': u.nom,
                        'prenoms': u.prenoms,
                        'role': u.role,
                        'libelle': nom_utilisateur(u),
                        'photo_url': photos.get(str(u.id)),
                    }
                    for u in membres
                ],
            })
        return Response(payload)

    @action(detail=False, methods=['get'], url_path='supervision')
    def supervision(self, request):
        """Recherche admin en lecture seule : hors inbox personnelle."""
        if not is_admin_superviseur(request.user):
            raise PermissionDenied('Réservé à l’administrateur.')
        q = (request.query_params.get('q') or '').strip()
        qs = _supervision_queryset()
        if q:
            qs = _filtrer_conversations_par_recherche(qs, q)
        qs = qs.order_by(F('dernier_at').desc(nulls_last=True), '-created_at')[:200]
        convs = list(qs)
        ser = ConversationSerializer(convs, many=True, context={'request': request})
        _hydrate_conversation_users(ser.child, convs, request)
        data = ser.data
        for row in data:
            row['lecture_seule'] = True
        return Response({'count': len(data), 'results': data, 'lecture_seule': True})

    @action(detail=True, methods=['get'], url_path='supervision-lire')
    def supervision_lire(self, request, pk=None):
        """Lecture seule d'un fil par l'administrateur (sans devenir participant)."""
        if not is_admin_superviseur(request.user):
            raise PermissionDenied('Réservé à l’administrateur.')
        try:
            conv = Conversation.objects.prefetch_related('participants').filter(pk=uuid_lib.UUID(str(pk))).first()
        except ValueError:
            conv = None
        if not conv:
            raise ValidationError({'detail': 'Conversation introuvable.'})
        msgs = _messages_recents(Message.objects.filter(conversation=conv))
        ser = MessageSerializer(msgs, many=True, context={'request': request})
        _hydrate_message_users(ser, msgs, conversation=conv, request=request)
        return Response({'conversation_id': str(conv.id), 'lecture_seule': True, 'results': ser.data})

    @action(detail=True, methods=['post'], url_path='supervision-pdf')
    def supervision_pdf(self, request, pk=None):
        """Impression PDF de la conversation entière (administrateur, journalisée)."""
        from pnlf_platform.pdf_conversation import conversation_pdf_bytes
        from pnlf_platform.pdf_export import pdf_file_response

        if not is_admin_superviseur(request.user):
            raise PermissionDenied('L’impression des conversations est réservée à l’administrateur.')
        conv_id = _uuid_or_none(pk)
        conv = Conversation.objects.filter(pk=conv_id).first() if conv_id else None
        if not conv:
            return Response({'detail': 'Conversation introuvable.'}, status=status.HTTP_404_NOT_FOUND)
        try:
            pdf, filename = conversation_pdf_bytes(conv, imprime_par=request.user)
        except Exception:
            import logging

            logging.getLogger(__name__).exception('Échec génération PDF conversation')
            return Response({'detail': 'Impossible de générer le PDF de la conversation.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='conversations',
            enregistrement_id=conv.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf', 'supervision': True, 'sujet': conv.sujet},
        )
        return pdf_file_response(pdf, filename)

    @action(detail=True, methods=['post'])
    def intervenir(self, request, pk=None):
        # Accès global désactivé : l'admin consulte via supervision en lecture seule.
        raise PermissionDenied(
            'L’intervention directe est désactivée. Utilisez la supervision en lecture seule.'
        )

    @action(detail=True, methods=['get', 'post'], url_path='messages', parser_classes=[JSONParser, FormParser, MultiPartParser])
    def messages(self, request, pk=None):
        conv = self.get_object()
        # Seuls les participants voient / écrivent (isolation stricte)
        if not ConversationParticipant.objects.filter(
            conversation=conv, utilisateur_id=request.user.id,
        ).exists():
            raise PermissionDenied('Vous n’êtes pas participant de cette discussion.')

        if request.method == 'GET':
            since = _param_since(request)
            _marquer_lu(conv.id, request.user.id)
            msgs = Message.objects.filter(conversation=conv)
            if since:
                msgs = msgs.filter(created_at__gt=since)
            msgs = _messages_recents(msgs)
            ser = MessageSerializer(msgs, many=True, context={'request': request})
            _hydrate_message_users(ser, msgs, conversation=conv, request=request)
            return Response(ser.data)

        contenu = (request.data.get('contenu') or '').strip()
        piece = request.FILES.get('piece') or request.FILES.get('image') or request.FILES.get('audio')
        if not contenu and not piece:
            return Response({'contenu': 'Saisissez un message ou joignez une image / un vocal.'}, status=400)
        if len(contenu) > 4000:
            return Response({'contenu': 'Message trop long (4000 caractères maximum).'}, status=400)

        now = timezone.now()
        msg_id = uuid_lib.uuid4()
        piece_type = None
        piece_path = None
        if piece:
            piece_type = detecter_piece(piece)
            piece_path = enregistrer_piece_message(piece, msg_id, piece_type)
        if not contenu:
            contenu = PLACEHOLDER_PHOTO if piece_type == 'IMAGE' else PLACEHOLDER_AUDIO

        msg = Message.objects.create(
            id=msg_id,
            conversation=conv,
            expediteur_id=request.user.id,
            contenu=contenu,
            created_at=now,
        )
        if piece_type and piece_path:
            MessagePiece.objects.create(message=msg, piece_type=piece_type, piece_path=piece_path)
        apercu = contenu if contenu not in (PLACEHOLDER_PHOTO, PLACEHOLDER_AUDIO) else (
            'Photo' if piece_type == 'IMAGE' else 'Message vocal'
        )
        for p in ConversationParticipant.objects.filter(conversation=conv).exclude(utilisateur_id=request.user.id):
            ConversationParticipantMeta.objects.filter(
                conversation_id=conv.id, utilisateur_id=p.utilisateur_id,
            ).update(deleted_at=None)
            creer_notification(
                p.utilisateur_id,
                f'Message: {conv.sujet or "Conversation"}',
                apercu,
                metadata={'table_cible': 'conversations', 'enregistrement_id': str(conv.id)},
            )
        _marquer_lu(conv.id, request.user.id)
        ser = MessageSerializer(msg, context={'request': request})
        _hydrate_message_users(ser, [msg], conversation=conv, request=request)
        return Response(ser.data, status=status.HTTP_201_CREATED)


class AppareilSyncViewSet(viewsets.ModelViewSet):
    permission_classes = [CanSyncTerrain]
    serializer_class = AppareilSyncSerializer
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        return AppareilSync.objects.filter(utilisateur_id=self.request.user.id, actif=True)

    def perform_create(self, serializer):
        serializer.save(utilisateur_id=self.request.user.id, created_at=timezone.now())


class SyncPushView(APIView):
    """Push hors ligne (prise en charge partielle) : seule la mise à jour du nom d'un producteur
    existant, dans le périmètre de l'utilisateur, est appliquée. Les créations et les lots sont
    comptés comme ignorés : la réponse ne déclare synchronisé que ce qui l'a réellement été."""
    permission_classes = [CanSyncTerrain]

    def post(self, request):
        from accounts.permissions import scope_producteurs_qs

        ser = SyncPushSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        device_id = ser.validated_data['device_id']
        producteurs = ser.validated_data.get('producteurs', [])
        lots = ser.validated_data.get('lots', [])
        now = timezone.now()
        synced = {'producteurs': 0, 'lots': 0, 'conflits': 0}
        ignores = {'producteurs': 0, 'lots': len(lots)}
        with transaction.atomic():
            appareil, _ = AppareilSync.objects.update_or_create(
                utilisateur_id=request.user.id, device_id=device_id,
                defaults={'libelle': ser.validated_data.get('libelle'), 'actif': True, 'created_at': now},
            )
            perimetre = scope_producteurs_qs(Producteur.objects.filter(deleted_at__isnull=True), request.user)
            for item in producteurs:
                try:
                    client_uuid = uuid_lib.UUID(str(item.get('client_uuid') or ''))
                    version = int(item.get('sync_version') or 0)
                except (TypeError, ValueError):
                    ignores['producteurs'] += 1
                    continue
                nom = (item.get('nom') or '').strip()[:100]
                existing = perimetre.filter(client_uuid=client_uuid).first()
                if not existing or not nom:
                    ignores['producteurs'] += 1
                    continue
                if existing.sync_version > version:
                    SyncConflict.objects.create(
                        appareil_id=appareil.id, entite='producteurs', client_uuid=client_uuid,
                        payload_client={**item, 'client_uuid': str(client_uuid)},
                        payload_serveur={'id': str(existing.id)},
                        created_at=now,
                    )
                    synced['conflits'] += 1
                    continue
                Producteur.objects.filter(pk=existing.pk).update(
                    nom=nom, updated_at=now, sync_statut='SYNCED',
                )
                synced['producteurs'] += 1
            appareil.dernier_sync_at = now
            appareil.save(update_fields=['dernier_sync_at'])
        reponse = {'synced': synced, 'ignores': ignores, 'server_time': now.isoformat()}
        if ignores['producteurs'] or ignores['lots']:
            reponse['detail'] = (
                'Synchronisation partielle : seule la mise à jour du nom de producteurs existants '
                'est prise en charge. Les créations et les lots doivent être saisis en ligne.'
            )
        return Response(reponse)


class SyncPullView(APIView):
    permission_classes = [CanSyncTerrain]

    def get(self, request):
        since = _param_since(request)
        from accounts.permissions import scope_lots_qs, scope_producteurs_qs
        prods = scope_producteurs_qs(Producteur.objects.filter(deleted_at__isnull=True), request.user)
        lots = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
        if since:
            prods = prods.filter(updated_at__gt=since)
            lots = lots.filter(updated_at__gt=since)
        return Response({
            'producteurs': list(prods.values('id', 'code_producteur', 'nom', 'statut', 'client_uuid', 'updated_at')[:200]),
            'lots': list(lots.values('id', 'code_lot', 'statut', 'client_uuid', 'updated_at')[:200]),
        })


class SyncConflictViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanSyncTerrain]
    serializer_class = SyncConflictSerializer

    def get_queryset(self):
        if self.request.user.role not in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            return SyncConflict.objects.none()
        return SyncConflict.objects.filter(resolu=False).order_by('-created_at')

    @action(detail=True, methods=['post'])
    def resoudre(self, request, pk=None):
        if self.request.user.role not in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            raise PermissionDenied()
        c = self.get_object()
        c.resolu = True
        c.resolution = request.data.get('resolution', '')
        c.resolved_at = timezone.now()
        c.save(update_fields=['resolu', 'resolution', 'resolved_at'])
        return Response(SyncConflictSerializer(c).data)


ANNUAIRE_PAGE_DEFAUT = 10
ANNUAIRE_PAGE_MAX = 50


def _param_page(request, nom: str) -> int:
    texte = (request.query_params.get(nom) or '1').strip()
    try:
        valeur = int(texte)
    except ValueError as exc:
        raise ValidationError({nom: 'Numéro de page invalide.'}) from exc
    return max(valeur, 1)


def _page_annuaire(qs, page: int, taille: int):
    """Tranche de la page demandée, ramenée à la dernière page si elle n'existe plus."""
    total = qs.count()
    derniere = max((total + taille - 1) // taille, 1)
    page = min(page, derniere)
    debut = (page - 1) * taille
    return list(qs[debut:debut + taille]), total, page


class AnnuaireView(APIView):
    """Annuaire producteurs / coopératives : module 6.9, deux listes paginées côté serveur.

    Paramètres : q, province, produit, page_producteurs, page_cooperatives, page_size,
    liste (producteurs | cooperatives) pour ne recharger qu'une des deux listes."""
    permission_classes = [CanUseMarketplace]

    def get(self, request):
        from traceability.models import Cooperative
        from traceability.serializers import CooperativeSerializer, ProducteurSerializer

        produit = _param_uuid(request, 'produit')
        province = _param_uuid(request, 'province')
        recherche = (request.query_params.get('q') or '').strip()
        liste = (request.query_params.get('liste') or '').strip().lower()
        if liste and liste not in ('producteurs', 'cooperatives'):
            raise ValidationError({'liste': 'Liste inconnue (producteurs ou cooperatives).'})
        try:
            taille = int(request.query_params.get('page_size') or ANNUAIRE_PAGE_DEFAUT)
        except ValueError as exc:
            raise ValidationError({'page_size': 'Taille de page invalide.'}) from exc
        taille = min(max(taille, 1), ANNUAIRE_PAGE_MAX)
        context = {'request': request}
        payload: dict = {'page_size': taille}

        if liste != 'cooperatives':
            qs_prod = Producteur.objects.filter(
                deleted_at__isnull=True, statut='ACTIF',
            ).select_related('province', 'cooperative')
            if province:
                qs_prod = qs_prod.filter(province_id=province)
            if produit:
                qs_prod = qs_prod.filter(id__in=Lot.objects.filter(produit_id=produit).values('producteur_id'))
            if recherche:
                qs_prod = qs_prod.filter(
                    Q(nom__icontains=recherche) | Q(prenoms__icontains=recherche)
                    | Q(code_producteur__icontains=recherche) | Q(telephone__icontains=recherche)
                )
            items, total, page = _page_annuaire(
                qs_prod.order_by('nom', 'prenoms', 'id'), _param_page(request, 'page_producteurs'), taille,
            )
            payload.update({
                'producteurs': ProducteurSerializer(items, many=True, context=context).data,
                'producteurs_count': total,
                'page_producteurs': page,
            })

        if liste != 'producteurs':
            coops = Cooperative.objects.filter(
                Q(statut='ACTIF') | Q(statut__isnull=True), actif=True,
            ).select_related('province')
            if province:
                coops = coops.filter(province_id=province)
            if recherche:
                coops = coops.filter(
                    Q(nom__icontains=recherche) | Q(code__icontains=recherche)
                    | Q(telephone__icontains=recherche) | Q(email__icontains=recherche)
                )
            items, total, page = _page_annuaire(
                coops.order_by('nom', 'id'), _param_page(request, 'page_cooperatives'), taille,
            )
            payload.update({
                'cooperatives': CooperativeSerializer(items, many=True, context=context).data,
                'cooperatives_count': total,
                'page_cooperatives': page,
            })

        return Response(payload)
