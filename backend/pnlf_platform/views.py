from django.db.models import F, OuterRef, Q, Subquery
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
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
)
from pnlf_platform.services import (
    creer_notification,
    dashboard_stats,
    export_journal,
    export_lots_csv,
    export_lots_pdf,
    export_lots_xlsx,
    generer_qr_offre,
    journal_detail,
    journal_periodes,
)
from pnlf_platform.offre_statut import enum_supports, published_ids, write_statut
from traceability.db_utils import column_exists
from traceability.models import Lot, Producteur

ROLES_VALIDATION_OFFRES = (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE)


class ExportFileView(APIView):
    """Évite le 406 DRF quand le navigateur envoie Accept: application/pdf."""

    permission_classes = [CanViewDashboard]

    def perform_content_negotiation(self, request, force=False):
        return super().perform_content_negotiation(request, force=True)


class DashboardView(APIView):
    permission_classes = [CanViewDashboard]

    def get(self, request):
        data = dashboard_stats(
            province_id=request.query_params.get('province'),
            produit_id=request.query_params.get('produit'),
            date_debut=request.query_params.get('date_debut'),
            date_fin=request.query_params.get('date_fin'),
        )
        return Response(data)


class InboxValidationView(APIView):
    """File unique des demandes à traiter (admin / ministère / forestier)."""
    permission_classes = [CanViewDashboard]

    def get(self, request):
        from pnlf_platform.offre_statut import read_statut
        from traceability.models import Certification, Cooperative, Producteur

        producteurs = list(
            Producteur.objects.filter(deleted_at__isnull=True, statut='EN_VALIDATION')
            .order_by('-created_at')
            .values('id', 'nom', 'prenoms', 'code_producteur', 'created_at')[:20]
        )
        coops = list(
            Cooperative.objects.filter(statut='EN_VALIDATION')
            .order_by('-created_at')
            .values('id', 'nom', 'code', 'created_at')[:20]
        )
        certifs = list(
            Certification.objects.filter(statut__in=('DEMANDEE', 'EN_COURS'))
            .select_related('type_certification', 'producteur')
            .order_by('-created_at')[:20]
        )
        offres = []
        for o in OffreDemande.objects.order_by('-created_at')[:80]:
            if read_statut(o) != 'EN_VALIDATION':
                continue
            offres.append({
                'id': o.id,
                'titre': o.titre,
                'type_annonce': o.type_annonce,
                'created_at': o.created_at,
                'statut': 'EN_VALIDATION',
            })
            if len(offres) >= 20:
                break
        items_cert = [
            {
                'id': c.id,
                'type_libelle': c.type_certification.libelle if c.type_certification_id else None,
                'producteur_nom': f'{c.producteur.prenoms} {c.producteur.nom}'.strip() if c.producteur_id else None,
                'statut': c.statut,
                'created_at': c.created_at,
            }
            for c in certifs
        ]
        acheteurs = list(
            Utilisateur.objects.filter(
                deleted_at__isnull=True,
                statut=Utilisateur.Statut.EN_ATTENTE,
                role=Utilisateur.Role.ACHETEUR,
            )
            .order_by('-created_at')
            .values('id', 'nom', 'prenoms', 'email', 'created_at')[:20]
        )
        return Response({
            'producteurs': {
                'count': Producteur.objects.filter(deleted_at__isnull=True, statut='EN_VALIDATION').count(),
                'results': producteurs,
            },
            'cooperatives': {
                'count': Cooperative.objects.filter(statut='EN_VALIDATION').count(),
                'results': coops,
            },
            'certifications': {
                'count': Certification.objects.filter(statut__in=('DEMANDEE', 'EN_COURS')).count(),
                'results': items_cert,
            },
            'offres': {'count': len(offres), 'results': offres},
            'acheteurs': {
                'count': Utilisateur.objects.filter(
                    deleted_at__isnull=True,
                    statut=Utilisateur.Statut.EN_ATTENTE,
                    role=Utilisateur.Role.ACHETEUR,
                ).count(),
                'results': acheteurs,
            },
        })


class ExportLotsView(ExportFileView):

    def get(self, request):
        from accounts.permissions import scope_lots_qs
        qs = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
        fmt = request.query_params.get('export_format', 'csv').lower()
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='lots',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': fmt},
        )
        if fmt == 'xlsx':
            return export_lots_xlsx(qs)
        if fmt == 'pdf':
            return export_lots_pdf(qs)
        return export_lots_csv(qs)


class JournalPeriodesView(APIView):
    """Historique des périodes (jour / semaine / mois) pour lesquelles un journal d'audit existe."""
    permission_classes = [CanViewDashboard]

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
    return {
        'utilisateur_id': src.get('utilisateur_id') or None,
        'action': (src.get('action') or '').strip().upper() or None,
        'q': (src.get('q') or '').strip() or None,
        'date_debut': src.get('date_debut') or None,
        'date_fin': src.get('date_fin') or None,
    }


class JournalDetailView(APIView):
    permission_classes = [CanViewDashboard]

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
        fmt = (request.query_params.get('export_format') or 'csv').lower()
        filtres = _journal_filtres(request)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='audit_logs',
            ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': fmt, 'granularite': granularite, 'date': date_ref, **filtres},
        )
        return export_journal(granularite, date_ref, fmt, **filtres)


class ExportLotsTicketView(APIView):
    """Génère le PDF des lots sous JWT et le renvoie directement (octets, pas de redirection).

    Historiquement cette vue renvoyait une URL de « ticket » à charger dans un nouvel
    onglet ouvert via window.open() ; Chrome bloque/annule silencieusement ce type de
    navigation asynchrone (ERR_ABORTED, considéré comme un téléchargement automatique
    non rattaché à un geste utilisateur direct). Le frontend récupère désormais ce PDF
    en Blob authentifié (fetch/XHR classique) puis l'affiche dans un aperçu intégré à la
    page — robuste sur tous les navigateurs, sans dépendre du blocage anti-pop-up.
    """

    permission_classes = [CanViewDashboard]

    def post(self, request):
        from accounts.permissions import scope_lots_qs
        from pnlf_platform.pdf_export import lots_pdf_bytes

        qs = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
        try:
            pdf, filename = lots_pdf_bytes(qs)
        except Exception:
            return Response({'detail': 'Impossible de générer le PDF des lots.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='lots',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)


class ExportJournalTicketView(APIView):
    """Génère le PDF du journal sous JWT et le renvoie directement (voir ExportLotsTicketView)."""

    permission_classes = [CanExportJournal]

    def post(self, request):
        granularite = (request.data.get('granularite') or 'jour').lower()
        if granularite not in ('jour', 'semaine', 'mois'):
            granularite = 'jour'
        date_ref = request.data.get('date')
        filtres = _journal_filtres(request)
        try:
            response = export_journal(granularite, date_ref, 'pdf', **filtres)
        except Exception:
            return Response({'detail': 'Impossible de générer le PDF du journal.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='audit_logs',
            ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf', 'granularite': granularite, 'date': date_ref, **filtres},
        )
        return response


class ExportDownloadView(APIView):
    """Ancien endpoint ticket sans JWT — désactivé (SEC-12). Utiliser /exports/*/ticket/."""

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
    # 405 avant même d'atteindre l'action — bug à l'origine du bouton
    # « tout marquer comme lu » silencieusement inopérant.
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        return Notification.objects.filter(destinataire_id=self.request.user.id)

    @action(detail=False, methods=['get'], url_path='non-lues')
    def non_lues(self, request):
        """Compteur pour la cloche (ex. demandes d'inscription en attente non traitées)."""
        count = Notification.objects.filter(destinataire_id=request.user.id, lue=False).count()
        return Response({'count': count})

    @action(detail=True, methods=['post'])
    def lire(self, request, pk=None):
        n = self.get_object()
        n.lue = True
        n.save(update_fields=['lue'])
        return Response(NotificationSerializer(n).data)

    @action(detail=False, methods=['post'], url_path='lire-tout')
    def lire_tout(self, request):
        Notification.objects.filter(destinataire_id=request.user.id, lue=False).update(lue=True)
        return Response({'detail': 'OK'})


class OffreDemandeViewSet(viewsets.ModelViewSet):
    permission_classes = [CanUseMarketplace]
    serializer_class = OffreDemandeSerializer
    filterset_fields = ('type_annonce', 'produit_id', 'province_id')
    search_fields = ('titre', 'description')
    parser_classes = [FormParser, MultiPartParser, JSONParser]

    def get_queryset(self):
        user = self.request.user
        qs = OffreDemande.objects.all().order_by('-created_at')
        statut = (self.request.query_params.get('statut') or '').strip()
        if user.role not in ROLES_VALIDATION_OFFRES:
            if enum_supports('EN_VALIDATION'):
                qs = qs.filter(Q(statut='OUVERTE') | Q(auteur_id=user.id))
            else:
                qs = qs.filter(Q(id__in=published_ids()) | Q(auteur_id=user.id))
        if statut:
            if enum_supports(statut) and enum_supports('EN_VALIDATION'):
                qs = qs.filter(statut=statut)
            else:
                from django.db import connection
                with connection.cursor() as cur:
                    cur.execute(
                        'SELECT offre_id::text FROM offres_statut_workflow WHERE statut = %s',
                        [statut],
                    )
                    ids = [row[0] for row in cur.fetchall()]
                qs = qs.filter(id__in=ids)
        return qs

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

    def perform_update(self, serializer):
        obj = self.get_object()
        if obj.auteur_id != self.request.user.id and self.request.user.role != Utilisateur.Role.ADMINISTRATEUR:
            raise PermissionDenied()
        serializer.save(updated_at=timezone.now())

    @action(detail=True, methods=['post'], url_path='photos')
    def photos(self, request, pk=None):
        """Ajoute jusqu'à 2 photos illustrant l'annonce (auteur ou modérateur)."""
        from traceability.services import enregistrer_photo, photo_url

        obj = self.get_object()
        if obj.auteur_id != request.user.id and request.user.role not in ROLES_VALIDATION_OFFRES:
            raise PermissionDenied('Vous ne pouvez modifier que vos propres annonces.')
        fichiers = request.FILES.getlist('photos')
        if not fichiers and 'photo' in request.FILES:
            fichiers = [request.FILES['photo']]
        if not fichiers:
            raise ValidationError({'photos': 'Aucun fichier reçu.'})

        libres = [i for i in (1, 2) if not photo_url('offres', obj.id, suffixe=f'_{i}')]
        if not libres:
            raise ValidationError({'photos': 'Deux photos maximum par annonce. Supprimez-en une avant d\'en ajouter.'})
        for fichier in fichiers[: len(libres)]:
            enregistrer_photo(fichier, 'offres', obj.id, suffixe=f'_{libres.pop(0)}')

        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='valider')
    def valider(self, request, pk=None):
        """Validation par un administrateur / agent du ministère : publication + génération du QR."""
        obj = self.get_object()
        if request.user.role not in ROLES_VALIDATION_OFFRES:
            raise PermissionDenied('Seuls les administrateurs et agents du ministère peuvent valider une annonce.')
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
            raise PermissionDenied()
        motif = (request.data.get('motif') or '').strip()
        write_statut(obj, 'REJETEE')

        corps = f'Votre annonce « {obj.titre} » a été rejetée.' + (f' Motif : {motif}' if motif else '')
        creer_notification(
            obj.auteur_id, 'Annonce rejetée', corps,
            metadata={'table_cible': 'offres_demandes', 'enregistrement_id': str(obj.id)},
        )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='offres_demandes',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='cloturer')
    def cloturer(self, request, pk=None):
        obj = self.get_object()
        # L'auteur ou un modérateur (admin, agent ministère — mêmes rôles habilités à
        # valider/rejeter une annonce) peut clôturer. Sans agent ministère ici, le bouton
        # « Clôturer » visible côté frontend pour ce rôle échouait systématiquement en 403.
        est_moderateur = request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE,
        )
        if obj.auteur_id != request.user.id and not est_moderateur:
            raise PermissionDenied()
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
        if enum_supports('EN_VALIDATION'):
            qs = OffreDemande.objects.filter(statut='OUVERTE').order_by('-updated_at')
        else:
            qs = OffreDemande.objects.filter(id__in=published_ids()).order_by('-updated_at')
        type_annonce = request.query_params.get('type_annonce')
        if type_annonce:
            qs = qs.filter(type_annonce=type_annonce)
        recherche = (request.query_params.get('q') or '').strip()
        if recherche:
            qs = qs.filter(Q(titre__icontains=recherche) | Q(description__icontains=recherche))
        province = request.query_params.get('province')
        if province:
            qs = qs.filter(province_id=province)
        produit = request.query_params.get('produit')
        if produit:
            qs = qs.filter(produit_id=produit)

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
        data = OffreDemandeSerializer(rows, many=True, context={'request': request}).data
        return Response({
            'count': total,
            'next': None,
            'previous': None,
            'results': data,
            'page': page,
            'page_size': page_size,
        })


class PublicOffreDemandeDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        obj = OffreDemande.objects.filter(pk=pk).first()
        from pnlf_platform.offre_statut import read_statut
        if not obj or read_statut(obj) != 'OUVERTE':
            return Response({'detail': 'Annonce introuvable ou non publiée.'}, status=404)
        return Response(OffreDemandeSerializer(obj, context={'request': request}).data)


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
        if not nom or not email or not message:
            return Response({'detail': 'Nom, e-mail et message sont requis.'}, status=400)
        try:
            validate_email(email)
        except DjangoValidationError:
            return Response({'detail': 'Adresse e-mail invalide.'}, status=400)
        if len(message) < 10:
            return Response({'detail': 'Votre message est trop court (10 caractères minimum).'}, status=400)
        if len(message) > 2000:
            return Response({'detail': 'Message trop long (2000 caractères maximum).'}, status=400)
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


def _uuid_or_none(value):
    if value is None:
        return None
    text = str(value).strip()
    if not text or text.lower() in ('null', 'undefined', 'none'):
        return None
    return text


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
        producteur_id = self.request.query_params.get('producteur_id')
        cooperative_id = self.request.query_params.get('cooperative_id')
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
        offre_id = _uuid_or_none(request.data.get('offre_id'))
        producteur_id = _uuid_or_none(request.data.get('producteur_id'))
        cooperative_id = _uuid_or_none(request.data.get('cooperative_id'))
        destinataire_id = _uuid_or_none(request.data.get('destinataire_id'))
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
            sujet = sujet or f'Groupe — {coop.nom}'
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

        other_id = None
        if producteur_id:
            fiche = Producteur.objects.filter(pk=producteur_id, deleted_at__isnull=True).first()
            if not fiche or not fiche.utilisateur_id:
                raise ValidationError({
                    'producteur_id': "Ce producteur n'a pas de compte connecté : utilisez le formulaire de contact.",
                })
            if str(fiche.utilisateur_id) == str(request.user.id):
                raise ValidationError({'producteur_id': 'Vous ne pouvez pas discuter avec vous-même.'})
            other_id = fiche.utilisateur_id
            sujet = sujet or f'Discussion avec {fiche.prenoms} {fiche.nom}'.strip()
        elif cooperative_id:
            coop = Cooperative.objects.filter(pk=cooperative_id).first()
            if not coop or not coop.utilisateur_id:
                raise ValidationError({
                    'cooperative_id': "Cette coopérative n'a pas de compte connecté.",
                })
            if str(coop.utilisateur_id) == str(request.user.id):
                raise ValidationError({'cooperative_id': 'Vous ne pouvez pas discuter avec vous-même.'})
            other_id = coop.utilisateur_id
            sujet = sujet or f'Discussion avec {coop.nom}'
        elif offre_id:
            offre = OffreDemande.objects.filter(pk=offre_id).first()
            if not offre:
                raise ValidationError({'offre_id': 'Annonce introuvable.'})
            if str(offre.auteur_id) != str(request.user.id):
                other_id = offre.auteur_id
            sujet = sujet or offre.titre
        elif destinataire_id:
            if str(destinataire_id) == str(request.user.id):
                raise ValidationError({'destinataire_id': 'Vous ne pouvez pas discuter avec vous-même.'})
            dest = Utilisateur.objects.filter(
                pk=destinataire_id, deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
            ).first()
            if not dest:
                raise ValidationError({'destinataire_id': 'Destinataire introuvable ou inactif.'})
            if not is_staff_chat(request.user):
                allowed = is_staff_chat(dest)
                if request.user.role == Utilisateur.Role.ACHETEUR and dest.role in (
                    Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE,
                ):
                    allowed = True
                if request.user.role in (
                    Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE,
                ) and dest.role == Utilisateur.Role.ACHETEUR:
                    allowed = True
                if not allowed:
                    raise PermissionDenied(
                        'Vous ne pouvez ouvrir une discussion qu’avec un acheteur, un producteur ou une coopérative.'
                    )
            other_id = dest.id
            sujet = sujet or f'Discussion avec {nom_utilisateur(dest)}'
        else:
            raise ValidationError({'detail': 'Indiquez une offre, un producteur, une coopérative ou un destinataire.'})

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
        if other_id:
            _ajouter_participant(conv, other_id, now)
        ser = self.get_serializer(conv)
        return Response(ser.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def contacts(self, request):
        qs = Utilisateur.objects.filter(
            deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
        ).exclude(id=request.user.id)
        role = request.user.role
        if is_staff_chat(request.user):
            pass
        elif role == Utilisateur.Role.ACHETEUR:
            qs = qs.filter(role__in=[Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE])
        elif role in (Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE):
            qs = qs.filter(role=Utilisateur.Role.ACHETEUR)
        else:
            qs = qs.none()
        users = list(qs.order_by('nom', 'prenoms')[:120])
        photos = photos_utilisateurs([u.id for u in users], request)
        data = [
            {
                'id': str(u.id),
                'nom': u.nom,
                'prenoms': u.prenoms,
                'role': u.role,
                'libelle': nom_utilisateur(u),
                'photo_url': photos.get(str(u.id)),
            }
            for u in users
        ]
        return Response(data)

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
        """Recherche admin en lecture seule — hors inbox personnelle."""
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
        conv = Conversation.objects.prefetch_related('participants').filter(pk=pk).first()
        if not conv:
            raise ValidationError({'detail': 'Conversation introuvable.'})
        msgs = list(Message.objects.filter(conversation=conv).order_by('created_at')[:500])
        ser = MessageSerializer(msgs, many=True, context={'request': request})
        _hydrate_message_users(ser, msgs, conversation=conv, request=request)
        return Response({'conversation_id': str(conv.id), 'lecture_seule': True, 'results': ser.data})

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
            _marquer_lu(conv.id, request.user.id)
            msgs = Message.objects.filter(conversation=conv).order_by('created_at')
            since = request.query_params.get('since')
            if since:
                msgs = msgs.filter(created_at__gt=since)
            msgs = list(msgs[:500])
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
    """Push offline — lots et producteurs par client_uuid."""
    permission_classes = [CanSyncTerrain]

    def post(self, request):
        ser = SyncPushSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        device_id = ser.validated_data['device_id']
        now = timezone.now()
        appareil, _ = AppareilSync.objects.update_or_create(
            utilisateur_id=request.user.id, device_id=device_id,
            defaults={'libelle': ser.validated_data.get('libelle'), 'actif': True, 'created_at': now},
        )
        synced = {'producteurs': 0, 'lots': 0, 'conflits': 0}
        for item in ser.validated_data.get('producteurs', []):
            client_uuid = item.get('client_uuid')
            if not client_uuid:
                continue
            existing = Producteur.objects.filter(client_uuid=client_uuid).first()
            if existing and existing.sync_version > item.get('sync_version', 0):
                SyncConflict.objects.create(
                    appareil_id=appareil.id, entite='producteurs', client_uuid=client_uuid,
                    payload_client=item, payload_serveur={'id': str(existing.id)},
                    created_at=now,
                )
                synced['conflits'] += 1
                continue
            if existing:
                Producteur.objects.filter(pk=existing.pk).update(
                    nom=item.get('nom', existing.nom),
                    updated_at=now, sync_statut='SYNCED',
                )
            synced['producteurs'] += 1
        appareil.dernier_sync_at = now
        appareil.save(update_fields=['dernier_sync_at'])
        return Response({'synced': synced, 'server_time': now.isoformat()})


class SyncPullView(APIView):
    permission_classes = [CanSyncTerrain]
    def get(self, request):
        since = request.query_params.get('since')
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


class AnnuaireView(APIView):
    """Annuaire producteurs / coopératives — module 6.9."""
    permission_classes = [CanUseMarketplace]

    def get(self, request):
        from django.db.models import Q

        from traceability.models import Cooperative
        from traceability.serializers import CooperativeSerializer, ProducteurSerializer

        qs_prod = Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF')
        produit = request.query_params.get('produit')
        province = request.query_params.get('province')
        recherche = (request.query_params.get('q') or '').strip()
        if province:
            qs_prod = qs_prod.filter(province_id=province)
        # Filtre produit via lots déclarés (annuaire simplifié)
        if produit:
            qs_prod = qs_prod.filter(id__in=Lot.objects.filter(produit_id=produit).values('producteur_id'))

        coops = Cooperative.objects.filter(actif=True)
        if province:
            coops = coops.filter(province_id=province)

        if recherche:
            qs_prod = qs_prod.filter(
                Q(nom__icontains=recherche) | Q(prenoms__icontains=recherche)
                | Q(code_producteur__icontains=recherche) | Q(telephone__icontains=recherche)
            )
            coops = coops.filter(
                Q(nom__icontains=recherche) | Q(code__icontains=recherche)
                | Q(telephone__icontains=recherche) | Q(email__icontains=recherche)
            )

        return Response({
            'producteurs': ProducteurSerializer(qs_prod[:100], many=True, context={'request': request}).data,
            'cooperatives': CooperativeSerializer(coops[:50], many=True, context={'request': request}).data,
        })
