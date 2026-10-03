import calendar
import logging
import uuid
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path

from django.conf import settings
from django.db import DatabaseError, IntegrityError, transaction
from django.http import FileResponse, Http404
from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.audit import request_meta, write_audit
from config import media_store
from config.validators import LATITUDE_GABON, LONGITUDE_GABON
from accounts.messaging import envoyer_email, envoyer_sms
from accounts.models import Utilisateur
from accounts.permissions import (
    CanImportZones,
    CanManageCertifications,
    CanManageCooperatives,
    CanManageLots,
    CanManageProducteurs,
    CanManageReferentiel,
    CanManageZones,
    CanReadGeo,
    CanValidateCertifications,
    CanValidateCooperatives,
    CanValidateProducteurs,
    scope_lots_qs,
    scope_mouvements_qs,
    scope_producteurs_qs,
    user_can_access_lot,
    user_can_access_producteur,
)

from .filters import (
    CertificationFilter,
    CooperativeFilter,
    LotFilter,
    MouvementFilter,
    ProducteurFilter,
    ZoneCollecteFilter,
)
from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
    DocumentInscription,
    InvitationCooperative,
    Lot,
    Mouvement,
    Producteur,
    Produit,
    Province,
    TypeCertification,
    Village,
    ZoneCollecte,
)
from .serializers import (
    CategorieProduitSerializer,
    CertificationSerializer,
    CooperativeMembreSerializer,
    CooperativeSerializer,
    InvitationCooperativeSerializer,
    DepartementSerializer,
    LotSerializer,
    MouvementSerializer,
    ProducteurSerializer,
    ProduitSerializer,
    ProvinceSerializer,
    TypeCertificationSerializer,
    VillageSerializer,
    ZoneCollecteSerializer,
)
from .services import (
    PIECES_CERTIFICATION_MAX,
    PIECES_TYPES_MIME,
    ROLES_AGENTS,
    STATUTS_LOT_VERIFIABLES,
    appliquer_mouvement_sur_lot,
    chemin_photo,
    commercialiser_lot,
    controler_piece_justificative,
    droits_lot,
    enregistrer_document,
    enregistrer_photo,
    generer_qr_image,
    libelle_statut_lot,
    qr_image_bytes,
    valider_lot,
    valider_type_mouvement,
    valider_type_mouvement_pour_role,
    verifier_mouvement_compatible,
)

logger = logging.getLogger(__name__)

ROLES_GESTION_ADHESIONS = ('ADMINISTRATEUR', 'AGENT_MINISTERE')

DOCUMENTS_FICHE_PRODUCTEUR = ('CNI', 'FICHE_CIRCUIT', 'AGREMENT_NAGOYA')
MESSAGE_TYPE_DOCUMENT = (
    'Type de document inconnu. Valeurs acceptées : pièce d’identité (CNI), fiche circuit, '
    'agrément CITES / Nagoya.'
)
TYPES_MIME_DOCUMENT = {'application/pdf', 'image/jpeg', 'image/jpg', 'image/png'}


def _user_id(user):
    return getattr(user, 'id', None)


def _est_agent(user) -> bool:
    return getattr(user, 'role', None) in ROLES_AGENTS


def _parse_booleen(valeur) -> bool:
    """Interprétation stricte : seules les valeurs explicitement vraies activent l'option."""
    if isinstance(valeur, bool):
        return valeur
    return str(valeur).strip().lower() in ('1', 'true', 'oui', 'yes')


def _cooperatives_du_compte(user):
    return Cooperative.objects.filter(utilisateur_id=getattr(user, 'id', None))


def _journaliser(request, action: str, table_cible: str, enregistrement_id=None, *,
                 anciennes=None, nouvelles=None) -> None:
    """Journal d'audit isolé dans un point de sauvegarde : un échec n'invalide pas la transaction."""
    ip, ua = request_meta(request)
    try:
        with transaction.atomic():
            write_audit(
                utilisateur_id=_user_id(request.user), action=action, table_cible=table_cible,
                enregistrement_id=enregistrement_id, ip_adresse=ip, user_agent=ua,
                anciennes_valeurs=anciennes, nouvelles_valeurs=nouvelles,
            )
    except DatabaseError:
        logger.exception('Écriture du journal d’audit impossible (%s %s)', action, table_cible)


def _notifier(destinataire_id, titre: str, corps: str, **metadata) -> None:
    if not destinataire_id:
        return
    from pnlf_platform.services import creer_notification

    try:
        with transaction.atomic():
            creer_notification(destinataire_id, titre, corps, metadata=metadata or None)
    except Exception:
        logger.exception('Notification impossible pour %s', destinataire_id)


def _notifier_validateurs(roles, titre: str, corps: str, **metadata) -> None:
    ids = Utilisateur.objects.filter(
        role__in=roles, statut=Utilisateur.Statut.ACTIF, deleted_at__isnull=True,
    ).values_list('id', flat=True)[:20]
    for uid in ids:
        _notifier(uid, titre, corps, **metadata)


def _notifier_statut_lot(lot, ancien: str, *, auteur_id, mode: str | None = None) -> None:
    """Prévient les titulaires du lot (producteur et coopérative gestionnaire) de chaque transition.

    L'auteur reçoit aussi la notification en auto-validation : elle lui sert d'accusé de réception.
    """
    if lot.statut == ancien:
        return
    destinataires = []
    if lot.producteur_id and lot.producteur.utilisateur_id:
        destinataires.append(lot.producteur.utilisateur_id)
    if lot.cooperative_id and lot.cooperative.utilisateur_id:
        destinataires.append(lot.cooperative.utilisateur_id)
    nouveau = libelle_statut_lot(lot.statut)
    if lot.statut == 'VALIDE':
        precision = (
            ' Validation effectuée au titre de votre certification active.' if mode == 'AUTO'
            else ' Validation effectuée par une autorité habilitée.'
        )
        precision += ' Le lot est désormais vérifiable publiquement par son QR code.'
    elif lot.statut == 'COMMERCIALISE':
        precision = (
            ' Il n’apparaît plus dans les listes publiques ; son QR code reste vérifiable.'
        )
    else:
        precision = ''
    for destinataire in dict.fromkeys(destinataires):
        if destinataire == auteur_id and mode != 'AUTO':
            continue
        _notifier(
            destinataire, f'Lot {lot.code_lot} : {nouveau}',
            f'Votre lot {lot.code_lot} est passé du statut « {libelle_statut_lot(ancien)} » '
            f'au statut « {nouveau} ».{precision}',
            lot_id=str(lot.id), statut=lot.statut,
        )


def _valeurs_modifiees(instance, validated_data) -> tuple[dict, dict]:
    anciennes, nouvelles = {}, {}
    for champ, valeur in validated_data.items():
        avant = getattr(instance, champ, None)
        avant_cmp = getattr(avant, 'pk', avant)
        apres_cmp = getattr(valeur, 'pk', valeur)
        if avant_cmp != apres_cmp:
            anciennes[champ] = str(avant_cmp) if avant_cmp is not None else None
            nouvelles[champ] = str(apres_cmp) if apres_cmp is not None else None
    return anciennes, nouvelles


def _expirer_certifications_echues() -> None:
    try:
        with transaction.atomic():
            Certification.objects.filter(
                statut='OBTENUE', date_expiration__lt=timezone.localdate(),
            ).update(statut='EXPIREE', updated_at=timezone.now())
    except DatabaseError:
        logger.exception('Mise à jour des certifications expirées impossible')


def _ajouter_mois(depart: date, mois: int) -> date:
    total = depart.month - 1 + mois
    annee, mois_final = depart.year + total // 12, total % 12 + 1
    jour = min(depart.day, calendar.monthrange(annee, mois_final)[1])
    return date(annee, mois_final, jour)


def _uuid_ou_400(valeur, champ: str, message: str):
    try:
        return uuid.UUID(str(valeur))
    except (TypeError, ValueError, AttributeError):
        raise ValidationError({champ: message})


def _code_unique(prefixe: str, model, champ: str) -> str:
    for _ in range(10):
        code = f'{prefixe}-{uuid.uuid4().hex[:8].upper()}'
        if not model.objects.filter(**{champ: code}).exists():
            return code
    return f'{prefixe}-{uuid.uuid4().hex[:12].upper()}'


def _activer_compte_lie(utilisateur_id, *, type_libelle: str) -> None:
    """Active le compte lié à une fiche self-inscrite validée, puis notifie par email/SMS."""
    if not utilisateur_id:
        return
    try:
        user = Utilisateur.objects.get(pk=utilisateur_id, deleted_at__isnull=True)
    except Utilisateur.DoesNotExist:
        return
    if user.statut != Utilisateur.Statut.EN_ATTENTE:
        return
    user.statut = Utilisateur.Statut.ACTIF
    user.updated_at = timezone.now()
    user.save(update_fields=['statut', 'updated_at'])

    lien = f'{settings.PNLF_FRONTEND_URL}/connexion'
    sujet = 'PFNL : votre inscription a été validée'
    corps = (
        f'Bonjour {user.get_full_name()},\n\n'
        f'Votre inscription en tant que {type_libelle} sur la plateforme PFNL a été validée '
        'par un administrateur.\n'
        'Vous pouvez désormais vous connecter avec votre adresse e-mail et le mot de passe choisi '
        f'lors de votre inscription :\n{lien}\n\n'
        "Cordialement,\nL'équipe PFNL, École Nationale des Eaux et Forêts"
    )
    envoyer_email(destinataire_id=user.id, email=user.email, sujet=sujet, corps_texte=corps)
    envoyer_sms(
        destinataire_id=user.id, telephone=user.telephone,
        message=f'PFNL : votre inscription a ete validee. Connectez-vous sur {lien}',
    )


def _rejeter_compte_lie(utilisateur_id, *, type_libelle: str, motif: str) -> None:
    """Notifie le rejet d'une fiche self-inscrite puis libère l'email pour une nouvelle tentative."""
    if not utilisateur_id:
        return
    try:
        user = Utilisateur.objects.get(pk=utilisateur_id, deleted_at__isnull=True)
    except Utilisateur.DoesNotExist:
        return
    if user.statut != Utilisateur.Statut.EN_ATTENTE:
        return

    motif_txt = motif or 'les informations fournies ne permettent pas de valider votre dossier.'
    sujet = "PFNL : votre demande d'inscription n'a pas été retenue"
    corps = (
        f'Bonjour {user.get_full_name()},\n\n'
        f"Votre demande d'inscription en tant que {type_libelle} sur la plateforme PFNL "
        "n'a pas pu être validée.\n"
        f'Motif : {motif_txt}\n\n'
        'Vous pouvez soumettre une nouvelle demande en corrigeant les éléments concernés.\n\n'
        "Cordialement,\nL'équipe PFNL"
    )
    envoyer_email(destinataire_id=user.id, email=user.email, sujet=sujet, corps_texte=corps)
    envoyer_sms(
        destinataire_id=user.id, telephone=user.telephone,
        message=f"PFNL : votre demande d'inscription n'a pas ete retenue. Motif : {motif_txt[:100]}",
    )

    # Suppression définitive (et non un simple soft-delete) : le compte n'a jamais été
    # activé, la contrainte UNIQUE(email) est stricte en base et un soft-delete ne
    # libérerait donc pas l'adresse pour une nouvelle tentative d'inscription légitime.
    user.delete()


def _clore_invitations_en_attente(producteur, *, motif: str, sauf=None) -> None:
    """Rend sans objet les invitations en attente d'un producteur devenu membre d'une coopérative."""
    invitations = InvitationCooperative.objects.filter(
        producteur=producteur, statut=InvitationCooperative.Statut.EN_ATTENTE,
    ).select_related('cooperative')
    if sauf is not None:
        invitations = invitations.exclude(pk=sauf.pk)
    invitations = list(invitations)
    if not invitations:
        return
    InvitationCooperative.objects.filter(pk__in=[i.pk for i in invitations]).update(
        statut=InvitationCooperative.Statut.CADUQUE, motif_reponse=motif, repondu_at=timezone.now(),
    )
    nom = f'{producteur.prenoms} {producteur.nom}'.strip()
    for inv in invitations:
        _notifier(
            inv.cooperative.utilisateur_id, 'Invitation sans objet',
            f'Votre invitation adressée à {nom} est devenue sans objet : {motif[:1].lower()}{motif[1:]}',
            table_cible='cooperatives', enregistrement_id=str(inv.cooperative_id),
        )


class ProvinceViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Province.objects.filter(actif=True)
    serializer_class = ProvinceSerializer
    search_fields = ('nom', 'code')


class DepartementViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Departement.objects.filter(actif=True).select_related('province')
    serializer_class = DepartementSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('province',)


class VillageViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Village.objects.filter(actif=True).select_related('departement')
    serializer_class = VillageSerializer
    search_fields = ('nom',)
    filterset_fields = ('departement',)


class CategorieProduitViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = CategorieProduit.objects.filter(actif=True)
    serializer_class = CategorieProduitSerializer
    search_fields = ('libelle', 'code')


class ProduitViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = Produit.objects.filter(actif=True).select_related('categorie')
    serializer_class = ProduitSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('categorie', 'soumis_cites')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def perform_create(self, serializer):
        now = timezone.now()
        obj = serializer.save(created_at=now, updated_at=now)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='CREATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'code': obj.code},
        )

    def perform_update(self, serializer):
        obj = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='UPDATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua,
        )

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def image(self, request, pk=None):
        """Upload de la photo représentative du produit (référentiel — admin/agent ministère)."""
        produit = self.get_object()
        fichier = request.FILES.get('image')
        if not fichier:
            raise ValidationError({'image': 'Fichier « image » manquant.'})
        enregistrer_photo(fichier, 'produits', produit.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='UPDATE_IMAGE', table_cible='produits',
            enregistrement_id=produit.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProduitSerializer(produit, context={'request': request}).data)


class CanPrintCooperatives(CanManageCooperatives):
    """L'impression (POST) est une lecture : ouverte à tous les profils autorisés à consulter les coopératives."""

    def has_permission(self, request, view):
        role = getattr(request.user, 'role', None)
        return bool(getattr(request.user, 'is_authenticated', False)) and (
            role in self.read_roles or role in self.write_roles
        )


class CanPrintProducteurs(CanManageProducteurs):
    """L'impression (POST) est une lecture : ouverte à tous les profils autorisés à consulter les producteurs."""

    def has_permission(self, request, view):
        role = getattr(request.user, 'role', None)
        return bool(getattr(request.user, 'is_authenticated', False)) and (
            role in self.read_roles or role in self.write_roles
        )


class CooperativeViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCooperatives]
    serializer_class = CooperativeSerializer
    search_fields = ('nom', 'code')
    filterset_class = CooperativeFilter

    def get_queryset(self):
        qs = Cooperative.objects.select_related('province')
        user = self.request.user
        if user.role == Utilisateur.Role.COOPERATIVE:
            return qs.filter(utilisateur_id=user.id)
        if user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            # Agents institutionnels voient aussi les demandes en attente.
            return qs
        return qs.filter(actif=True)

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now}
        code = (serializer.validated_data.get('code') or '').strip()
        if user.role == Utilisateur.Role.COOPERATIVE:
            if _cooperatives_du_compte(user).exclude(statut='REJETE').exists():
                raise ValidationError({
                    'detail': 'Votre compte est déjà rattaché à une coopérative : une seule fiche par compte.',
                })
            extra.update({
                'utilisateur_id': user.id, 'actif': False, 'statut': 'EN_VALIDATION',
                'code': _code_unique('COOP', Cooperative, 'code'),
            })
        elif not code:
            extra['code'] = _code_unique('COOP', Cooperative, 'code')
        coop = serializer.save(**extra)
        _journaliser(self.request, 'CREATE', 'cooperatives', coop.id,
                     nouvelles={'code': coop.code, 'statut': coop.statut})
        if coop.statut == 'EN_VALIDATION':
            _notifier_validateurs(
                ROLES_GESTION_ADHESIONS, 'Nouvelle coopérative à valider',
                f'La coopérative « {coop.nom} » attend une validation.',
                cooperative_id=str(coop.id),
            )

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.COOPERATIVE and instance.utilisateur_id != user.id:
            raise PermissionDenied('Accès refusé.')
        anciennes, nouvelles = _valeurs_modifiees(instance, serializer.validated_data)
        coop = serializer.save(updated_at=timezone.now())
        _journaliser(self.request, 'UPDATE', 'cooperatives', coop.id, anciennes=anciennes, nouvelles=nouvelles)

    def _verifier_en_validation(self, coop, verbe: str) -> None:
        if coop.statut != 'EN_VALIDATION':
            raise ValidationError({
                'detail': f'Seule une demande en attente de validation peut être {verbe}.',
            })

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def valider(self, request, pk=None):
        """Valide une demande d'inscription de coopérative et active le compte lié."""
        coop = self.get_object()
        self._verifier_en_validation(coop, 'validée')
        coop.actif = True
        coop.statut = 'ACTIF'
        coop.updated_at = timezone.now()
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        _activer_compte_lie(coop.utilisateur_id, type_libelle='coopérative')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def rejeter(self, request, pk=None):
        """Rejette une demande d'inscription de coopérative."""
        coop = self.get_object()
        self._verifier_en_validation(coop, 'rejetée')
        motif = (request.data.get('motif') or '').strip()
        now = timezone.now()
        _rejeter_compte_lie(coop.utilisateur_id, type_libelle='coopérative', motif=motif)
        # Le nom de la coopérative est contraint UNIQUE en base : on le suffixe pour
        # libérer ce nom en vue d'une nouvelle demande, tout en conservant l'historique.
        if '[REJETÉ ' not in coop.nom:
            coop.nom = f"{coop.nom} [REJETÉ {now:%Y%m%d%H%M%S}]"
        coop.actif = False
        coop.statut = 'REJETE'
        coop.updated_at = now
        coop.save(update_fields=['nom', 'actif', 'statut', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'statut': 'REJETE', 'motif': motif or None},
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='pdf', permission_classes=[CanPrintCooperatives])
    def pdf(self, request, pk=None):
        """Génère et renvoie directement la fiche PDF de cette coopérative (octets bruts)."""
        from pnlf_platform.pdf_export import cooperative_fiche_pdf_bytes

        coop = self.get_object()
        titulaire = bool(coop.utilisateur_id and coop.utilisateur_id == request.user.id)
        try:
            pdf, filename = cooperative_fiche_pdf_bytes(
                coop, masquer_contacts=not (_est_agent(request.user) or titulaire), utilisateur=request.user,
            )
        except Exception:
            logger.exception('Génération de la fiche PDF de la coopérative %s impossible', coop.id)
            return Response({'detail': 'Impossible de générer la fiche PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['post'], url_path='pdf-liste', permission_classes=[CanPrintCooperatives])
    def pdf_liste(self, request):
        """Génère et renvoie directement la liste PDF des coopératives visibles."""
        from pnlf_platform.pdf_export import cooperatives_liste_pdf_bytes

        qs = self.filter_queryset(self.get_queryset())
        try:
            pdf, filename = cooperatives_liste_pdf_bytes(qs, utilisateur=request.user)
        except Exception:
            return Response({'detail': 'Impossible de générer la liste PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='cooperatives',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def desactiver(self, request, pk=None):
        """Désactive une coopérative active (la retire de l'annuaire public et bloque son compte)."""
        coop = self.get_object()
        if coop.statut != 'ACTIF':
            raise ValidationError({'detail': 'Seule une coopérative active peut être désactivée.'})
        now = timezone.now()
        coop.actif = False
        coop.statut = 'INACTIF'
        coop.updated_at = now
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        if coop.utilisateur_id:
            Utilisateur.objects.filter(pk=coop.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.INACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='DEACTIVATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def activer(self, request, pk=None):
        """Réactive une coopérative précédemment désactivée."""
        coop = self.get_object()
        if coop.statut != 'INACTIF':
            raise ValidationError({'detail': 'Seule une coopérative inactive peut être réactivée.'})
        now = timezone.now()
        coop.actif = True
        coop.statut = 'ACTIF'
        coop.updated_at = now
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        if coop.utilisateur_id:
            Utilisateur.objects.filter(pk=coop.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.ACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='ACTIVATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Upload du logo/photo de la coopérative (admin, agent ministère ou la coopérative elle-même)."""
        coop = self.get_object()
        user = request.user
        if user.role == Utilisateur.Role.COOPERATIVE and coop.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre coopérative.')
        if user.role in (Utilisateur.Role.ACHETEUR, Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.AGENT_FORESTIER):
            raise PermissionDenied('Action non autorisée.')
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Fichier « photo » manquant.'})
        enregistrer_photo(fichier, 'cooperatives', coop.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE_PHOTO', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    def _verifier_gestion_membres(self, request, coop) -> None:
        role = request.user.role
        if role == Utilisateur.Role.COOPERATIVE:
            if coop.utilisateur_id != request.user.id:
                raise PermissionDenied('Vous ne pouvez gérer que les membres de votre coopérative.')
        elif role not in ROLES_GESTION_ADHESIONS:
            raise PermissionDenied('Seuls la coopérative, l’administrateur ou l’agent du ministère gèrent les membres.')

    def _producteur_depuis_requete(self, request):
        producteur_id = _uuid_ou_400(
            request.data.get('producteur'), 'producteur', 'Identifiant de producteur manquant ou invalide.',
        )
        prod = Producteur.objects.filter(pk=producteur_id, deleted_at__isnull=True).first()
        if prod is None:
            raise NotFound('Producteur introuvable.')
        return prod

    @action(detail=True, methods=['get', 'post'], url_path='membres')
    def membres(self, request, pk=None):
        coop = self.get_object()
        if request.method == 'GET':
            membres = CooperativeMembre.objects.filter(
                cooperative=coop, actif=True, producteur__deleted_at__isnull=True,
            ).select_related('producteur')
            return Response(CooperativeMembreSerializer(membres, many=True).data)
        self._verifier_gestion_membres(request, coop)
        ser = CooperativeMembreSerializer(data={**request.data, 'cooperative': str(coop.id)})
        ser.is_valid(raise_exception=True)
        prod = ser.validated_data['producteur']
        date_adhesion = ser.validated_data.get('date_adhesion') or timezone.localdate()

        if coop.statut != 'ACTIF':
            raise ValidationError({'detail': 'La coopérative doit être active pour accueillir des membres.'})
        if prod.statut != 'ACTIF':
            raise ValidationError({
                'producteur': 'Seule une fiche producteur validée (active) peut rejoindre une coopérative.',
            })
        existante = CooperativeMembre.objects.filter(cooperative=coop, producteur=prod).first()
        deja_membre = prod.cooperative_id == coop.id
        if request.user.role == Utilisateur.Role.COOPERATIVE and not deja_membre:
            if prod.cooperative_id:
                raise ValidationError({
                    'producteur': 'Ce producteur est déjà membre d’une autre coopérative.',
                })
            if existante is None or existante.actif:
                raise ValidationError({
                    'producteur': (
                        'Ce producteur n’a pas demandé à rejoindre votre coopérative : '
                        'il doit d’abord envoyer une demande d’adhésion depuis son espace.'
                    ),
                })

        ancienne_coop_id = prod.cooperative_id
        now = timezone.now()
        with transaction.atomic():
            CooperativeMembre.objects.filter(producteur=prod).exclude(cooperative=coop).delete()
            if existante is None:
                existante = CooperativeMembre.objects.create(
                    cooperative=coop, producteur=prod, date_adhesion=date_adhesion,
                    actif=True, created_at=now,
                )
            else:
                CooperativeMembre.objects.filter(cooperative=coop, producteur=prod).update(
                    date_adhesion=date_adhesion, actif=True,
                )
                existante.date_adhesion, existante.actif = date_adhesion, True
            Producteur.objects.filter(pk=prod.pk).update(cooperative=coop, updated_at=now)
            if not deja_membre:
                InvitationCooperative.objects.filter(
                    cooperative=coop, producteur=prod, statut=InvitationCooperative.Statut.EN_ATTENTE,
                ).update(
                    statut=InvitationCooperative.Statut.ACCEPTEE, repondu_at=now,
                    motif_reponse='Adhésion enregistrée par la coopérative ou l’administration.',
                )
                _clore_invitations_en_attente(
                    prod, motif=f'Le producteur a rejoint la coopérative « {coop.nom} ».',
                )

        _journaliser(
            request, 'ADD_MEMBER', 'cooperative_membres', coop.id,
            anciennes={'cooperative_id': str(ancienne_coop_id) if ancienne_coop_id else None},
            nouvelles={'producteur_id': str(prod.id), 'date_adhesion': date_adhesion.isoformat()},
        )
        if not deja_membre:
            _notifier(
                prod.utilisateur_id, 'Adhésion acceptée',
                f'Vous êtes désormais membre de la coopérative « {coop.nom} ».',
                cooperative_id=str(coop.id),
            )
        return Response(
            CooperativeMembreSerializer(existante).data,
            status=status.HTTP_200_OK if deja_membre else status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'], url_path='membres/retirer')
    def retirer_membre(self, request, pk=None):
        coop = self.get_object()
        self._verifier_gestion_membres(request, coop)
        prod = self._producteur_depuis_requete(request)
        if not CooperativeMembre.objects.filter(cooperative=coop, producteur=prod, actif=True).exists():
            raise NotFound('Ce producteur n’est pas membre de cette coopérative.')
        now = timezone.now()
        with transaction.atomic():
            CooperativeMembre.objects.filter(cooperative=coop, producteur=prod).delete()
            Producteur.objects.filter(pk=prod.pk, cooperative=coop).update(cooperative=None, updated_at=now)
        _journaliser(request, 'REMOVE_MEMBER', 'cooperative_membres', coop.id,
                     anciennes={'producteur_id': str(prod.id)})
        _notifier(
            prod.utilisateur_id, 'Fin d’adhésion',
            f'Vous n’êtes plus membre de la coopérative « {coop.nom} ».',
            cooperative_id=str(coop.id),
        )
        return Response({'detail': 'Membre retiré.'})

    @action(detail=True, methods=['get'], url_path='demandes-adhesion')
    def demandes_adhesion(self, request, pk=None):
        coop = self.get_object()
        self._verifier_gestion_membres(request, coop)
        demandes = CooperativeMembre.objects.filter(
            cooperative=coop, actif=False, producteur__deleted_at__isnull=True,
        ).select_related('producteur').order_by('created_at')
        return Response(CooperativeMembreSerializer(demandes, many=True).data)

    @action(detail=True, methods=['post'], url_path='membres/refuser')
    def refuser_adhesion(self, request, pk=None):
        coop = self.get_object()
        self._verifier_gestion_membres(request, coop)
        prod = self._producteur_depuis_requete(request)
        demandes = CooperativeMembre.objects.filter(cooperative=coop, producteur=prod, actif=False)
        if not demandes.exists():
            raise NotFound('Aucune demande d’adhésion en attente pour ce producteur.')
        demandes.delete()
        motif = (request.data.get('motif') or '').strip()
        _journaliser(request, 'REJECT_MEMBER', 'cooperative_membres', coop.id,
                     nouvelles={'producteur_id': str(prod.id), 'motif': motif or None})
        corps = f'Votre demande d’adhésion à la coopérative « {coop.nom} » n’a pas été retenue.'
        if motif:
            corps += f' Motif : {motif}'
        _notifier(prod.utilisateur_id, 'Demande d’adhésion refusée', corps, cooperative_id=str(coop.id))
        return Response({'detail': 'Demande d’adhésion refusée.'})

    @action(detail=True, methods=['post'], url_path='demander-adhesion', permission_classes=[IsAuthenticated])
    def demander_adhesion(self, request, pk=None):
        coop = self.get_object()
        if request.user.role != Utilisateur.Role.PRODUCTEUR:
            raise PermissionDenied('Seuls les producteurs peuvent demander à rejoindre une coopérative.')
        prod = Producteur.objects.filter(utilisateur_id=request.user.id, deleted_at__isnull=True).first()
        if not prod:
            raise ValidationError({'detail': 'Aucune fiche producteur n’est liée à votre compte.'})
        if prod.statut != 'ACTIF':
            raise ValidationError({'detail': 'Votre fiche doit être validée avant de demander une adhésion.'})
        if coop.statut != 'ACTIF':
            raise ValidationError({'detail': 'Cette coopérative n’accepte pas de nouvelles adhésions pour le moment.'})
        if prod.cooperative_id == coop.id:
            raise ValidationError({'detail': 'Vous êtes déjà membre de cette coopérative.'})
        if prod.cooperative_id:
            raise ValidationError({
                'detail': (
                    'Vous êtes déjà membre d’une autre coopérative : '
                    'demandez d’abord votre retrait à celle-ci.'
                ),
            })
        if InvitationCooperative.objects.filter(
            cooperative=coop, producteur=prod, statut=InvitationCooperative.Statut.EN_ATTENTE,
        ).exists():
            raise ValidationError({
                'detail': (
                    'Cette coopérative vous a déjà invité : acceptez son invitation '
                    '(page Coopératives ou votre fiche) pour devenir membre.'
                ),
            })
        en_attente = CooperativeMembre.objects.filter(producteur=prod, actif=False).select_related('cooperative').first()
        if en_attente is not None:
            if en_attente.cooperative_id == coop.id:
                raise ValidationError({'detail': 'Une demande est déjà en attente auprès de cette coopérative.'})
            raise ValidationError({
                'detail': (
                    f'Vous avez déjà une demande en attente auprès de « {en_attente.cooperative.nom} » : '
                    'attendez sa réponse avant d’en envoyer une autre.'
                ),
            })
        now = timezone.now()
        CooperativeMembre.objects.create(
            cooperative=coop, producteur=prod, date_adhesion=timezone.localdate(),
            actif=False, created_at=now,
        )
        _journaliser(request, 'REQUEST_MEMBERSHIP', 'cooperative_membres', coop.id,
                     nouvelles={'producteur_id': str(prod.id)})
        _notifier(
            coop.utilisateur_id, 'Demande d’adhésion',
            f'{prod.prenoms} {prod.nom} ({prod.code_producteur}) souhaite rejoindre {coop.nom}.',
            cooperative_id=str(coop.id), producteur_id=str(prod.id),
        )
        return Response({'detail': 'Demande transmise à la coopérative.'}, status=status.HTTP_201_CREATED)

    # ------------------------------------------------------------------
    # Invitations : la coopérative invite un producteur actif sans coopérative
    # ------------------------------------------------------------------

    @action(detail=True, methods=['get'], url_path='candidats-invitation')
    def candidats_invitation(self, request, pk=None):
        """Recherche dynamique des producteurs actifs sans coopérative (10 résultats au plus)."""
        from django.db.models import Q

        from .db_utils import get_optional_column
        from .services import photo_url

        # get_object() appliquerait le filtre « search » (nom de coopérative) au paramètre de recherche.
        from rest_framework.generics import get_object_or_404

        coop = get_object_or_404(self.get_queryset(), pk=pk)
        self.check_object_permissions(request, coop)
        self._verifier_gestion_membres(request, coop)
        terme = (request.query_params.get('search') or '').strip()[:80]
        if len(terme) < 2:
            return Response([])
        qs = Producteur.objects.filter(
            statut='ACTIF', deleted_at__isnull=True, cooperative__isnull=True,
        ).select_related('province')
        for mot in terme.split()[:4]:
            qs = qs.filter(
                Q(nom__icontains=mot) | Q(prenoms__icontains=mot)
                | Q(code_producteur__icontains=mot) | Q(communaute__icontains=mot)
            )
        candidats = list(qs.order_by('nom', 'prenoms')[:10])
        ids = [p.id for p in candidats]
        invites = set(InvitationCooperative.objects.filter(
            cooperative=coop, producteur_id__in=ids, statut=InvitationCooperative.Statut.EN_ATTENTE,
        ).values_list('producteur_id', flat=True))
        demandes = set(CooperativeMembre.objects.filter(
            cooperative=coop, producteur_id__in=ids, actif=False,
        ).values_list('producteur_id', flat=True))
        return Response([
            {
                'id': str(p.id),
                'nom': p.nom,
                'prenoms': p.prenoms,
                'code_producteur': p.code_producteur,
                'type_acteur': get_optional_column('producteurs', 'type_acteur', p.id, default='PRODUCTEUR'),
                'province_nom': getattr(p.province, 'nom', None),
                'communaute': p.communaute,
                'photo_url': photo_url('producteurs', p.id, request),
                'a_un_compte': bool(p.utilisateur_id),
                'invitation_en_attente': p.id in invites,
                'demande_en_attente': p.id in demandes,
            }
            for p in candidats
        ])

    @action(detail=True, methods=['get', 'post'], url_path='invitations')
    def invitations(self, request, pk=None):
        """GET : invitations envoyées par la coopérative. POST : inviter un producteur actif sans coopérative."""
        coop = self.get_object()
        self._verifier_gestion_membres(request, coop)
        if request.method == 'GET':
            qs = InvitationCooperative.objects.filter(cooperative=coop).select_related(
                'cooperative', 'cooperative__province', 'producteur',
            )[:50]
            return Response(InvitationCooperativeSerializer(qs, many=True, context={'request': request}).data)

        prod = self._producteur_depuis_requete(request)
        message = (request.data.get('message') or '').strip()
        if len(message) > 500:
            raise ValidationError({'message': 'Le message ne doit pas dépasser 500 caractères.'})
        if coop.statut != 'ACTIF':
            raise ValidationError({'detail': 'La coopérative doit être active pour inviter des producteurs.'})
        if prod.statut != 'ACTIF':
            raise ValidationError({'producteur': 'Seul un producteur dont la fiche est validée (active) peut être invité.'})
        if prod.cooperative_id == coop.id:
            raise ValidationError({'producteur': 'Ce producteur est déjà membre de votre coopérative.'})
        if prod.cooperative_id:
            raise ValidationError({'producteur': 'Ce producteur est déjà membre d’une autre coopérative.'})
        if CooperativeMembre.objects.filter(cooperative=coop, producteur=prod, actif=False).exists():
            raise ValidationError({
                'producteur': (
                    'Ce producteur a déjà demandé à rejoindre votre coopérative : '
                    'acceptez sa demande dans la liste des demandes reçues.'
                ),
            })
        if InvitationCooperative.objects.filter(
            cooperative=coop, producteur=prod, statut=InvitationCooperative.Statut.EN_ATTENTE,
        ).exists():
            raise ValidationError({'producteur': 'Une invitation est déjà en attente pour ce producteur.'})
        try:
            with transaction.atomic():
                inv = InvitationCooperative.objects.create(
                    cooperative=coop, producteur=prod, message=message or None,
                    invite_par_id=request.user.id, created_at=timezone.now(),
                )
        except IntegrityError:
            raise ValidationError({'producteur': 'Une invitation est déjà en attente pour ce producteur.'})
        _journaliser(request, 'INVITE_MEMBER', 'invitations_cooperative', inv.id,
                     nouvelles={'cooperative_id': str(coop.id), 'producteur_id': str(prod.id)})
        corps = f'La coopérative « {coop.nom} » vous invite à devenir membre.'
        if message:
            corps += f' Message : {message}'
        corps += ' Acceptez ou refusez depuis la page Coopératives.'
        _notifier(
            prod.utilisateur_id, 'Invitation à rejoindre une coopérative', corps,
            table_cible='cooperatives', enregistrement_id=str(coop.id), invitation_id=str(inv.id),
        )
        inv = InvitationCooperative.objects.select_related('cooperative', 'cooperative__province', 'producteur').get(pk=inv.pk)
        return Response(
            InvitationCooperativeSerializer(inv, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'], url_path=r'invitations/(?P<invitation_id>[0-9a-fA-F-]{36})/annuler')
    def annuler_invitation(self, request, pk=None, invitation_id=None):
        coop = self.get_object()
        self._verifier_gestion_membres(request, coop)
        inv = InvitationCooperative.objects.select_related('producteur').filter(
            pk=invitation_id, cooperative=coop,
        ).first()
        if inv is None:
            raise NotFound('Invitation introuvable.')
        if inv.statut != InvitationCooperative.Statut.EN_ATTENTE:
            raise ValidationError({'detail': 'Seule une invitation en attente peut être annulée.'})
        inv.statut = InvitationCooperative.Statut.ANNULEE
        inv.repondu_at = timezone.now()
        inv.repondu_par_id = request.user.id
        inv.save(update_fields=['statut', 'repondu_at', 'repondu_par_id'])
        _journaliser(request, 'CANCEL_INVITATION', 'invitations_cooperative', inv.id,
                     nouvelles={'cooperative_id': str(coop.id), 'producteur_id': str(inv.producteur_id)})
        _notifier(
            inv.producteur.utilisateur_id, 'Invitation annulée',
            f'La coopérative « {coop.nom} » a annulé son invitation.',
            table_cible='cooperatives', enregistrement_id=str(coop.id),
        )
        return Response({'detail': 'Invitation annulée.'})

    def _producteur_du_compte(self, request):
        if request.user.role != Utilisateur.Role.PRODUCTEUR:
            raise PermissionDenied('Seuls les producteurs et collecteurs reçoivent des invitations de coopérative.')
        prod = Producteur.objects.filter(utilisateur_id=request.user.id, deleted_at__isnull=True).first()
        if prod is None:
            raise ValidationError({'detail': 'Aucune fiche producteur n’est liée à votre compte.'})
        return prod

    @action(detail=False, methods=['get'], url_path='invitations-recues', permission_classes=[IsAuthenticated])
    def invitations_recues(self, request):
        """Invitations en attente adressées au producteur connecté."""
        prod = self._producteur_du_compte(request)
        qs = InvitationCooperative.objects.filter(
            producteur=prod, statut=InvitationCooperative.Statut.EN_ATTENTE,
        ).select_related('cooperative', 'cooperative__province', 'producteur')
        return Response(InvitationCooperativeSerializer(qs, many=True, context={'request': request}).data)

    def _invitation_recue(self, request, invitation_id):
        prod = self._producteur_du_compte(request)
        inv = InvitationCooperative.objects.select_related('cooperative').filter(
            pk=invitation_id, producteur=prod,
        ).first()
        if inv is None:
            raise NotFound('Invitation introuvable.')
        if inv.statut != InvitationCooperative.Statut.EN_ATTENTE:
            raise ValidationError({'detail': 'Cette invitation n’est plus en attente.'})
        return prod, inv

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated],
            url_path=r'invitations-recues/(?P<invitation_id>[0-9a-fA-F-]{36})/refuser')
    def refuser_invitation(self, request, invitation_id=None):
        prod, inv = self._invitation_recue(request, invitation_id)
        motif = (request.data.get('motif') or '').strip()
        if len(motif) > 500:
            raise ValidationError({'motif': 'Le motif ne doit pas dépasser 500 caractères.'})
        inv.statut = InvitationCooperative.Statut.REFUSEE
        inv.repondu_at = timezone.now()
        inv.repondu_par_id = request.user.id
        inv.motif_reponse = motif or None
        inv.save(update_fields=['statut', 'repondu_at', 'repondu_par_id', 'motif_reponse'])
        _journaliser(request, 'REFUSE_INVITATION', 'invitations_cooperative', inv.id,
                     nouvelles={'cooperative_id': str(inv.cooperative_id), 'motif': motif or None})
        corps = f'{prod.prenoms} {prod.nom} ({prod.code_producteur}) a décliné votre invitation.'
        if motif:
            corps += f' Motif : {motif}'
        _notifier(
            inv.cooperative.utilisateur_id, 'Invitation déclinée', corps,
            table_cible='cooperatives', enregistrement_id=str(inv.cooperative_id),
        )
        return Response({'detail': 'Invitation refusée.'})

    @action(detail=False, methods=['post'], permission_classes=[IsAuthenticated],
            url_path=r'invitations-recues/(?P<invitation_id>[0-9a-fA-F-]{36})/accepter')
    def accepter_invitation(self, request, invitation_id=None):
        prod, inv = self._invitation_recue(request, invitation_id)
        coop = inv.cooperative
        now = timezone.now()
        with transaction.atomic():
            prod = Producteur.objects.select_for_update().get(pk=prod.pk)
            if prod.statut != 'ACTIF':
                raise ValidationError({'detail': 'Votre fiche doit être validée (active) pour rejoindre une coopérative.'})
            if coop.statut != 'ACTIF':
                raise ValidationError({'detail': 'Cette coopérative n’accepte pas de nouveaux membres pour le moment.'})
            if prod.cooperative_id:
                raise ValidationError({
                    'detail': 'Vous êtes déjà membre d’une coopérative : demandez d’abord votre retrait à celle-ci.',
                })
            CooperativeMembre.objects.filter(producteur=prod).exclude(cooperative=coop).delete()
            aujourd_hui = timezone.localdate()
            if CooperativeMembre.objects.filter(cooperative=coop, producteur=prod).exists():
                CooperativeMembre.objects.filter(cooperative=coop, producteur=prod).update(
                    actif=True, date_adhesion=aujourd_hui,
                )
            else:
                CooperativeMembre.objects.create(
                    cooperative=coop, producteur=prod, date_adhesion=aujourd_hui, actif=True, created_at=now,
                )
            Producteur.objects.filter(pk=prod.pk).update(cooperative=coop, updated_at=now)
            InvitationCooperative.objects.filter(pk=inv.pk).update(
                statut=InvitationCooperative.Statut.ACCEPTEE, repondu_at=now, repondu_par_id=request.user.id,
            )
            _clore_invitations_en_attente(prod, motif=f'Le producteur a rejoint la coopérative « {coop.nom} ».')
        _journaliser(request, 'ACCEPT_INVITATION', 'invitations_cooperative', inv.id,
                     nouvelles={'cooperative_id': str(coop.id), 'producteur_id': str(prod.id)})
        _notifier(
            coop.utilisateur_id, 'Invitation acceptée',
            f'{prod.prenoms} {prod.nom} ({prod.code_producteur}) a accepté votre invitation '
            'et devient membre de la coopérative.',
            table_cible='cooperatives', enregistrement_id=str(coop.id),
        )
        return Response({
            'detail': f'Vous êtes désormais membre de la coopérative « {coop.nom} ».',
            'cooperative': str(coop.id),
        })


def _normaliser_entetes(entetes: list) -> list:
    return [(str(e or '')).strip().lower() for e in entetes]


def _lire_lignes_csv(fichier):
    import csv
    import io

    contenu = fichier.read().decode('utf-8-sig', errors='replace')
    lecteur = csv.reader(io.StringIO(contenu), delimiter=';' if ';' in contenu.splitlines()[0] else ',')
    lignes = list(lecteur)
    if not lignes:
        return
    entetes = _normaliser_entetes(lignes[0])
    for ligne in lignes[1:]:
        if not any((c or '').strip() for c in ligne):
            continue
        yield dict(zip(entetes, ligne))


def _lire_lignes_xlsx(fichier):
    from openpyxl import load_workbook

    classeur = load_workbook(filename=fichier, data_only=True, read_only=True)
    feuille = classeur.active
    lignes_iter = feuille.iter_rows(values_only=True)
    try:
        entetes = _normaliser_entetes(list(next(lignes_iter)))
    except StopIteration:
        return
    for ligne in lignes_iter:
        if not any(c is not None and str(c).strip() for c in ligne):
            continue
        yield dict(zip(entetes, ligne))


class ZoneCollecteViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageZones]
    serializer_class = ZoneCollecteSerializer
    search_fields = ('libelle', 'code')
    filterset_class = ZoneCollecteFilter
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']
    parser_classes = [FormParser, MultiPartParser, JSONParser]

    def get_queryset(self):
        qs = ZoneCollecte.objects.select_related('province')
        if _est_agent(self.request.user):
            return qs
        return qs.filter(actif=True)

    @action(detail=False, methods=['get'], url_path='modele-import')
    def modele_import(self, request):
        import csv
        from django.http import HttpResponse

        # Pas de Content-Disposition : fichier récupéré en Blob XHR (voir export_lots_csv).
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response.write('\ufeff')
        writer = csv.writer(response)
        writer.writerow(['code', 'libelle', 'province', 'description', 'latitude', 'longitude'])
        writer.writerow(['ZC-EXEMPLE', 'Forêt de Minkébé (secteur nord)', 'WOL', 'Zone d’exemple', '-0.5546', '11.6642'])
        return response

    def perform_create(self, serializer):
        now = timezone.now()
        extra = {}
        if not serializer.validated_data.get('code'):
            extra['code'] = _code_unique('ZC', ZoneCollecte, 'code')
        zone = serializer.save(created_at=now, updated_at=now, **extra)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='CREATE', table_cible='zones_collecte',
            enregistrement_id=zone.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'code': zone.code, 'libelle': zone.libelle, 'actif': zone.actif},
        )

    def perform_update(self, serializer):
        anciennes, nouvelles = _valeurs_modifiees(serializer.instance, serializer.validated_data)
        zone = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='UPDATE', table_cible='zones_collecte',
            enregistrement_id=zone.id, ip_adresse=ip, user_agent=ua,
            anciennes_valeurs=anciennes or None, nouvelles_valeurs=nouvelles or None,
        )

    @action(detail=False, methods=['post'], url_path='import', permission_classes=[CanImportZones])
    def import_fichier(self, request):
        """Import en masse de zones de collecte depuis un fichier CSV ou XLSX.

        Colonnes attendues (en-tête, insensible à la casse, ordre libre) :
        ``code``, ``libelle``, ``province`` ou ``province_code`` (code ou nom de la province),
        ``description`` (optionnel), ``latitude`` (optionnel), ``longitude`` (optionnel).
        Une ligne existante (même ``code``) est mise à jour plutôt que dupliquée.
        Réservé à l'administrateur, seul gestionnaire du référentiel des zones.
        """
        fichier = request.FILES.get('fichier')
        if not fichier:
            raise ValidationError({'fichier': 'Aucun fichier reçu.'})

        nom = (fichier.name or '').lower()
        try:
            if nom.endswith('.xlsx'):
                lignes = list(_lire_lignes_xlsx(fichier))
            else:
                lignes = list(_lire_lignes_csv(fichier))
        except Exception as exc:  # fichier corrompu / format invalide
            raise ValidationError({'fichier': f'Impossible de lire le fichier : {exc}'})

        if not lignes:
            raise ValidationError({'fichier': 'Le fichier ne contient aucune donnée exploitable.'})

        provinces_par_code = {p.code.strip().upper(): p for p in Province.objects.all()}
        provinces_par_nom = {p.nom.strip().upper(): p for p in Province.objects.all()}

        now = timezone.now()
        crees, mis_a_jour, erreurs = 0, 0, []

        def _texte(valeur) -> str:
            return str(valeur).strip() if valeur is not None else ''

        def _parse_coord(valeur, bornes):
            valeur = _texte(valeur)
            if not valeur:
                return None
            try:
                nombre = Decimal(valeur.replace(',', '.'))
            except InvalidOperation:
                return '__INVALID__'
            if not (bornes[0] <= nombre <= bornes[1]):
                return '__INVALID__'
            return round(nombre, 7)

        for i, ligne in enumerate(lignes, start=2):  # ligne 1 = en-tête
            code = _texte(ligne.get('code'))
            libelle = _texte(ligne.get('libelle'))
            province_ref = _texte(ligne.get('province')) or _texte(ligne.get('province_code'))
            if not code or not libelle or not province_ref:
                erreurs.append(f'Ligne {i} : code, libellé et province sont obligatoires.')
                continue
            if len(code) > 40 or len(libelle) > 200:
                erreurs.append(f'Ligne {i} : code (40 caractères maximum) ou libellé (200 maximum) trop long.')
                continue
            province = provinces_par_code.get(province_ref.upper()) or provinces_par_nom.get(province_ref.upper())
            if not province:
                erreurs.append(f'Ligne {i} : province « {province_ref} » introuvable.')
                continue

            latitude = _parse_coord(ligne.get('latitude'), LATITUDE_GABON)
            longitude = _parse_coord(ligne.get('longitude'), LONGITUDE_GABON)
            if latitude == '__INVALID__' or longitude == '__INVALID__':
                erreurs.append(f'Ligne {i} : coordonnées GPS invalides ou hors du territoire gabonais.')
                continue

            existante = ZoneCollecte.objects.filter(code=code).first()
            homonymes = ZoneCollecte.objects.filter(province=province, libelle__iexact=libelle)
            if existante:
                homonymes = homonymes.exclude(pk=existante.pk)
            if homonymes.exists():
                erreurs.append(
                    f'Ligne {i} : une zone « {libelle} » existe déjà dans la province {province.nom}.'
                )
                continue

            defaults = {
                'libelle': libelle,
                'province': province,
                'description': _texte(ligne.get('description')) or None,
                'latitude': latitude,
                'longitude': longitude,
                'actif': True,
                'updated_at': now,
            }
            try:
                with transaction.atomic():
                    if existante:
                        for champ, valeur in defaults.items():
                            setattr(existante, champ, valeur)
                        existante.save(update_fields=list(defaults.keys()))
                    else:
                        ZoneCollecte.objects.create(code=code, created_at=now, **defaults)
            except DatabaseError:
                logger.exception('Import zone ligne %s', i)
                erreurs.append(f'Ligne {i} : enregistrement impossible (données refusées par la base).')
                continue
            if existante:
                mis_a_jour += 1
            else:
                crees += 1

        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='IMPORT', table_cible='zones_collecte',
            ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'crees': crees, 'mis_a_jour': mis_a_jour, 'erreurs': len(erreurs)},
        )
        return Response({
            'crees': crees,
            'mis_a_jour': mis_a_jour,
            'total_lignes': len(lignes),
            'erreurs': erreurs,
        })


class ProducteurViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageProducteurs]
    serializer_class = ProducteurSerializer
    filterset_class = ProducteurFilter

    @property
    def search_fields(self):
        # Le téléphone est masqué hors agents : il ne doit pas non plus servir de critère de recherche.
        request = getattr(self, 'request', None)
        if request is not None and _est_agent(request.user):
            return ('nom', 'prenoms', 'code_producteur', 'telephone')
        return ('nom', 'prenoms', 'code_producteur')

    def get_queryset(self):
        qs = Producteur.objects.filter(deleted_at__isnull=True).select_related(
            'province', 'departement', 'village', 'cooperative',
        )
        user = self.request.user
        if self.request.query_params.get('candidats_adhesion') == '1' and user.role in ROLES_GESTION_ADHESIONS:
            qs = qs.filter(statut='ACTIF', cooperative__isnull=True)
            return qs
        return scope_producteurs_qs(qs, user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        en_lecture = request.method in ('GET', 'HEAD', 'OPTIONS') or self.action == 'pdf'
        if not en_lecture and not user_can_access_producteur(request.user, obj):
            raise PermissionDenied('Accès refusé à ce producteur.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now, 'sync_statut': 'SYNCED', 'statut': 'EN_VALIDATION'}
        if user.role == Utilisateur.Role.PRODUCTEUR:
            if Producteur.objects.filter(utilisateur_id=user.id, deleted_at__isnull=True).exists():
                raise ValidationError({'detail': 'Une fiche producteur est déjà liée à votre compte.'})
            extra['utilisateur_id'] = user.id
            extra['cooperative'] = None
        elif user.role == Utilisateur.Role.COOPERATIVE:
            coop = _cooperatives_du_compte(user).filter(statut='ACTIF').first()
            if coop is None:
                raise ValidationError({
                    'detail': 'Votre coopérative doit être validée avant d’enregistrer des membres.',
                })
            extra['cooperative'] = coop
        if not serializer.validated_data.get('code_producteur'):
            extra['code_producteur'] = _code_unique('PRD', Producteur, 'code_producteur')
        with transaction.atomic():
            obj = serializer.save(**extra)
            if obj.cooperative_id:
                CooperativeMembre.objects.create(
                    cooperative_id=obj.cooperative_id, producteur=obj,
                    date_adhesion=timezone.localdate(), actif=True, created_at=now,
                )
        _journaliser(
            self.request, 'CREATE', 'producteurs', obj.id,
            nouvelles={
                'code_producteur': obj.code_producteur,
                'cooperative_id': str(obj.cooperative_id) if obj.cooperative_id else None,
            },
        )

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.PRODUCTEUR and instance.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre fiche.')
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        # SEC-15 : ni un producteur ni une coopérative ne modifient directement le rattachement
        # (workflow d'adhésion / gestion des membres). Renvoyer la valeur actuelle reste permis.
        if user.role in (Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.COOPERATIVE) and (
            'cooperative' in serializer.validated_data
        ):
            nouvelle = serializer.validated_data['cooperative']
            if getattr(nouvelle, 'pk', None) != instance.cooperative_id:
                raise PermissionDenied(
                    'Le rattachement à une coopérative se fait via le workflow d’adhésion.'
                )
            serializer.validated_data.pop('cooperative')
        nouvelle_coop = serializer.validated_data.get('cooperative', instance.cooperative)
        changement_coop = getattr(nouvelle_coop, 'pk', None) != instance.cooperative_id
        anciennes, nouvelles = _valeurs_modifiees(
            instance, {k: v for k, v in serializer.validated_data.items() if k != 'produits'},
        )
        if 'produits' in serializer.validated_data:
            nouvelles['produits'] = ', '.join(p.nom for p in serializer.validated_data['produits']) or None
        now = timezone.now()
        with transaction.atomic():
            obj = serializer.save(updated_at=now)
            if changement_coop:
                CooperativeMembre.objects.filter(producteur=obj).delete()
                if obj.cooperative_id:
                    CooperativeMembre.objects.create(
                        cooperative_id=obj.cooperative_id, producteur=obj,
                        date_adhesion=timezone.localdate(), actif=True, created_at=now,
                    )
                    _clore_invitations_en_attente(obj, motif='Rattachement effectué par l’administration.')
        _journaliser(self.request, 'UPDATE', 'producteurs', obj.id, anciennes=anciennes, nouvelles=nouvelles)

    def perform_destroy(self, instance):
        user = self.request.user
        if user.role not in ROLES_GESTION_ADHESIONS:
            raise PermissionDenied(
                'Seuls l’administrateur et l’agent du ministère peuvent supprimer une fiche.'
            )
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='SOFT_DELETE', table_cible='producteurs',
            enregistrement_id=instance.id, ip_adresse=ip, user_agent=ua,
        )

    @action(detail=True, methods=['post'], url_path='pdf', permission_classes=[CanPrintProducteurs])
    def pdf(self, request, pk=None):
        """Génère et renvoie directement la fiche PDF de ce producteur/collecteur (octets bruts).

        Le frontend récupère ce PDF en Blob authentifié puis l'affiche dans un aperçu
        intégré à la page (plus robuste multi-navigateurs que la navigation d'un onglet
        ouvert via window.open(), que Chrome peut bloquer/annuler silencieusement).
        """
        from pnlf_platform.pdf_export import producteur_fiche_pdf_bytes

        from .serializers import peut_lire_prives_producteur

        prod = self.get_object()
        try:
            pdf, filename = producteur_fiche_pdf_bytes(
                prod,
                masquer_contacts=not peut_lire_prives_producteur(request.user, prod),
                masquer_piece=not _est_agent(request.user),
                utilisateur=request.user,
            )
        except Exception:
            logger.exception('Génération de la fiche PDF du producteur %s impossible', prod.id)
            return Response({'detail': 'Impossible de générer la fiche PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['post'], url_path='pdf-liste', permission_classes=[CanPrintProducteurs])
    def pdf_liste(self, request):
        """Génère et renvoie directement la liste PDF des producteurs/collecteurs visibles."""
        from pnlf_platform.pdf_export import producteurs_liste_pdf_bytes

        qs = self.filter_queryset(self.get_queryset())
        try:
            # Le périmètre d'une coopérative (ses membres) ou d'un producteur (sa fiche) est déjà autorisé.
            pdf, filename = producteurs_liste_pdf_bytes(
                qs,
                masquer_contacts=request.user.role not in (*ROLES_AGENTS, 'COOPERATIVE', 'PRODUCTEUR'),
                utilisateur=request.user,
            )
        except Exception:
            return Response({'detail': 'Impossible de générer la liste PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='producteurs',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['get'], url_path='en-attente/compte', permission_classes=[CanValidateProducteurs])
    def en_attente_compte(self, request):
        """Nombre de demandes d'inscription (producteurs/collecteurs + coopératives) non encore traitées.

        Utilisé par la cloche de notifications du back-office pour afficher un
        compteur fiable, indépendant du statut de lecture des notifications.
        """
        nb_producteurs = Producteur.objects.filter(deleted_at__isnull=True, statut='EN_VALIDATION').count()
        nb_cooperatives = 0
        if request.user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            try:
                nb_cooperatives = Cooperative.objects.filter(statut='EN_VALIDATION').count()
            except DatabaseError:
                # Filet de sécurité tant que la migration 07_cooperatives_statut.sql
                # (colonne « statut ») n'a pas encore été appliquée en base.
                nb_cooperatives = Cooperative.objects.filter(actif=False).count()
        return Response({
            'producteurs_en_attente': nb_producteurs,
            'cooperatives_en_attente': nb_cooperatives,
            'total': nb_producteurs + nb_cooperatives,
        })

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def valider(self, request, pk=None):
        prod = self.get_object()
        if prod.statut != 'EN_VALIDATION':
            raise ValidationError({'detail': 'Seule une fiche en attente de validation peut être validée.'})
        now = timezone.now()
        prod.statut = 'ACTIF'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.updated_at = now
        prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'updated_at'])
        _activer_compte_lie(prod.utilisateur_id, type_libelle='producteur/collecteur')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def desactiver(self, request, pk=None):
        """Désactive un producteur/collecteur actif (le retire de l'annuaire public et bloque son compte)."""
        prod = self.get_object()
        if prod.statut != 'ACTIF':
            raise ValidationError({'detail': 'Seule une fiche active peut être désactivée.'})
        now = timezone.now()
        prod.statut = 'INACTIF'
        prod.updated_at = now
        prod.save(update_fields=['statut', 'updated_at'])
        if prod.utilisateur_id:
            Utilisateur.objects.filter(pk=prod.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.INACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='DEACTIVATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def activer(self, request, pk=None):
        """Réactive un producteur/collecteur précédemment désactivé."""
        prod = self.get_object()
        if prod.statut != 'INACTIF':
            raise ValidationError({'detail': 'Seule une fiche inactive peut être réactivée.'})
        now = timezone.now()
        prod.statut = 'ACTIF'
        prod.updated_at = now
        prod.save(update_fields=['statut', 'updated_at'])
        if prod.utilisateur_id:
            Utilisateur.objects.filter(pk=prod.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.ACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='ACTIVATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def rejeter(self, request, pk=None):
        prod = self.get_object()
        if prod.statut != 'EN_VALIDATION':
            raise ValidationError({'detail': 'Seule une fiche en attente de validation peut être rejetée.'})
        now = timezone.now()
        motif = (request.data.get('motif') or '').strip()
        prod.statut = 'REJETE'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.notes = motif or prod.notes
        prod.updated_at = now
        prod.cooperative = None
        with transaction.atomic():
            prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'notes', 'cooperative', 'updated_at'])
            CooperativeMembre.objects.filter(producteur=prod).delete()
        _rejeter_compte_lie(prod.utilisateur_id, type_libelle='producteur/collecteur', motif=motif)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'statut': 'REJETE', 'motif': motif or None},
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Upload de la photo de profil (producteur/collecteur lui-même, agent ou admin)."""
        prod = self.get_object()
        user = request.user
        if user.role == Utilisateur.Role.PRODUCTEUR and prod.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre photo.')
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Fichier « photo » manquant.'})
        enregistrer_photo(fichier, 'producteurs', prod.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE_PHOTO', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['get', 'post'], url_path='documents',
            parser_classes=[MultiPartParser, FormParser, JSONParser])
    def documents(self, request, pk=None):
        """Pièces justificatives de la fiche : lecture, dépôt ou remplacement (un document par type)."""
        from .serializers import _documents_administratifs, peut_lire_prives_producteur

        prod = self.get_object()
        if not peut_lire_prives_producteur(request.user, prod):
            raise PermissionDenied('Les pièces justificatives de cette fiche ne vous sont pas accessibles.')
        if request.method == 'GET':
            return Response(_documents_administratifs('PRODUCTEUR', prod.id, request))

        type_document = str(request.data.get('type_document') or '').strip().upper()
        if type_document not in DOCUMENTS_FICHE_PRODUCTEUR:
            raise ValidationError({'type_document': MESSAGE_TYPE_DOCUMENT})
        fichier = request.FILES.get('document')
        if not fichier:
            raise ValidationError({'document': 'Sélectionnez le fichier à joindre (PDF, JPG ou PNG, 8 Mo maximum).'})
        if (fichier.content_type or '').lower() not in TYPES_MIME_DOCUMENT:
            raise ValidationError({'document': 'Formats acceptés : PDF, JPG, PNG.'})
        chemin = enregistrer_document(
            fichier, 'inscriptions/producteurs', f'{prod.id}_{type_document.lower()}',
        )
        now = timezone.now()
        with transaction.atomic():
            remplace = DocumentInscription.objects.filter(
                entite_type=DocumentInscription.EntiteType.PRODUCTEUR, entite_id=prod.id,
                type_document=type_document,
            ).delete()[0] > 0
            DocumentInscription.objects.create(
                id=uuid.uuid4(), entite_type=DocumentInscription.EntiteType.PRODUCTEUR, entite_id=prod.id,
                type_document=type_document, chemin=chemin,
                nom_original=Path(fichier.name or '').name[:255] or None,
                depose_par_id=_user_id(request.user), created_at=now,
            )
        _journaliser(
            request, 'UPDATE_DOCUMENT' if remplace else 'ADD_DOCUMENT', 'producteurs', prod.id,
            nouvelles={'type_document': type_document, 'nom_original': fichier.name[:255] if fichier.name else None},
        )
        if prod.utilisateur_id and prod.utilisateur_id != _user_id(request.user):
            _notifier(
                prod.utilisateur_id, 'Pièce justificative mise à jour',
                f'Le document « {DocumentInscription.TypeDocument(type_document).label} » de votre fiche '
                'a été ajouté ou remplacé.',
                table_cible='producteurs', enregistrement_id=str(prod.id),
            )
        return Response(
            _documents_administratifs('PRODUCTEUR', prod.id, request),
            status=status.HTTP_200_OK if remplace else status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['delete'], url_path=r'documents/(?P<type_document>[A-Za-z_]+)')
    def supprimer_document(self, request, pk=None, type_document=None):
        from .serializers import _documents_administratifs, peut_lire_prives_producteur

        prod = self.get_object()
        if not peut_lire_prives_producteur(request.user, prod):
            raise PermissionDenied('Les pièces justificatives de cette fiche ne vous sont pas accessibles.')
        type_document = (type_document or '').upper()
        if type_document not in DOCUMENTS_FICHE_PRODUCTEUR:
            raise ValidationError({'type_document': MESSAGE_TYPE_DOCUMENT})
        if type_document == 'CNI' and not _est_agent(request.user):
            raise ValidationError({
                'type_document': (
                    'La pièce d’identité est obligatoire : remplacez-la par un nouveau fichier '
                    'au lieu de la supprimer.'
                ),
            })
        docs = list(DocumentInscription.objects.filter(
            entite_type=DocumentInscription.EntiteType.PRODUCTEUR, entite_id=prod.id,
            type_document=type_document,
        ))
        if not docs:
            raise NotFound('Aucun document de ce type n’est joint à la fiche.')
        with transaction.atomic():
            DocumentInscription.objects.filter(pk__in=[d.pk for d in docs]).delete()
        for doc in docs:
            chemin_local = Path(settings.MEDIA_ROOT) / doc.chemin
            chemin_local.unlink(missing_ok=True)
            media_store.supprimer(doc.chemin)
        _journaliser(request, 'DELETE_DOCUMENT', 'producteurs', prod.id,
                     anciennes={'type_document': type_document})
        return Response(_documents_administratifs('PRODUCTEUR', prod.id, request))


class LotViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = LotSerializer
    search_fields = ('code_lot', 'uuid_public')
    filterset_class = LotFilter

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        ctx['avec_detail'] = self.action != 'list'
        return ctx

    def get_queryset(self):
        qs = (
            Lot.objects.filter(deleted_at__isnull=True)
            .select_related(
                'produit', 'producteur', 'producteur__province', 'producteur__cooperative',
                'cooperative', 'zone_collecte', 'zone_collecte__province',
            )
            .prefetch_related('mouvements')
        )
        return scope_lots_qs(qs, self.request.user)

    def _reponse_lot(self, lot, request, **kwargs):
        lot = self.get_queryset().get(pk=lot.pk)
        return Response(
            LotSerializer(lot, context={'request': request, 'avec_detail': True}).data, **kwargs,
        )

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if request.method not in ('GET', 'HEAD', 'OPTIONS') and not user_can_access_lot(request.user, obj):
            raise PermissionDenied('Accès refusé à ce lot.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        producteur = serializer.validated_data.get('producteur')
        if user.role == Utilisateur.Role.PRODUCTEUR:
            if not producteur or producteur.utilisateur_id != user.id:
                raise PermissionDenied('Lot autorisé uniquement pour votre profil.')
        elif user.role == Utilisateur.Role.COOPERATIVE:
            if not producteur:
                raise PermissionDenied('Indiquez le producteur membre concerné.')
            coop_ids = set(_cooperatives_du_compte(user).values_list('id', flat=True))
            if producteur.cooperative_id not in coop_ids:
                raise PermissionDenied('Ce producteur n’appartient pas à votre coopérative.')
        self._verifier_producteur_actif(producteur)
        extra = {'cooperative_id': producteur.cooperative_id if producteur else None}
        serializer.validated_data.pop('cooperative', None)
        zone = serializer.validated_data.get('zone_collecte')
        if zone and serializer.validated_data.get('latitude') is None and zone.latitude is not None:
            extra['latitude'] = zone.latitude
            extra['longitude'] = zone.longitude
        # Tout lot naît en brouillon : il devient vérifiable publiquement après validation.
        extra['statut'] = 'BROUILLON'
        # Code unique côté appli : évite l'INSERT avec code_lot='' (contrainte UNIQUE
        # + lots orphelins vides en prod si le trigger SQL ne s'applique pas).
        code_lot = (
            f"PNLF-{now.strftime('%Y%m%d')}-{uuid.uuid4().hex[:10].upper()}"
        )
        from .services import generer_qr_payload

        with transaction.atomic():
            lot = serializer.save(
                created_at=now, updated_at=now, sync_statut='SYNCED',
                declare_par_id=user.id, code_lot=code_lot,
                **extra,
            )
            lot.refresh_from_db()
            lot.qr_payload = generer_qr_payload(lot)
            lot.save(update_fields=['qr_payload'])
            self._creer_mouvement_collecte(lot, user, now)
        generer_qr_image(lot)
        _journaliser(self.request, 'CREATE', 'lots', lot.id,
                     nouvelles={'code_lot': lot.code_lot, 'statut': lot.statut})

    @staticmethod
    def _verifier_producteur_actif(producteur) -> None:
        if producteur is not None and producteur.statut != 'ACTIF':
            raise ValidationError({
                'producteur': 'Le producteur doit avoir une fiche validée (active) pour déclarer un lot.',
            })

    @staticmethod
    def _creer_mouvement_collecte(lot, user, now) -> None:
        Mouvement.objects.create(
            lot=lot, type_mouvement='COLLECTE', date_mouvement=now,
            lieu_libelle=(lot.zone_collecte.libelle if lot.zone_collecte_id else 'Déclaration initiale'),
            quantite=lot.quantite, unite=lot.unite,
            latitude=lot.latitude, longitude=lot.longitude,
            acteur_utilisateur_id=user.id, acteur_producteur_id=lot.producteur_id,
            created_at=now, sync_statut='SYNCED',
        )

    def _verifier_lot_modifiable(self, lot, action: str) -> None:
        droits = droits_lot(self.request.user, lot)
        if droits['peut_modifier' if action == 'modifié' else 'peut_supprimer']:
            return
        if lot.statut == 'COMMERCIALISE':
            detail = (
                f'Ce lot est commercialisé : il ne peut plus être {action}, '
                'afin que son QR code reste fidèle à la marchandise vendue.'
            )
        elif lot.statut == 'VALIDE' and not _est_agent(self.request.user):
            detail = (
                f'Ce lot a été validé : il ne peut plus être {action} par son titulaire. '
                'Pour une correction, contactez un agent ou l’administration.'
            )
        else:
            detail = f'Vous n’êtes pas autorisé à intervenir sur ce lot ({action}).'
        raise ValidationError({'detail': detail})

    def perform_update(self, serializer):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        instance = serializer.instance
        self._verifier_lot_modifiable(instance, 'modifié')
        # Interdit de réaffecter producteur / coopérative après création (SEC-05).
        for field in ('producteur', 'cooperative'):
            if field in serializer.validated_data and serializer.validated_data[field] != getattr(instance, field):
                raise PermissionDenied(
                    f'Le champ « {field} » ne peut pas être modifié après la création du lot.'
                )
            serializer.validated_data.pop(field, None)
        anciennes, nouvelles = _valeurs_modifiees(instance, serializer.validated_data)
        lot = serializer.save(updated_at=timezone.now())
        _journaliser(self.request, 'UPDATE', 'lots', lot.id, anciennes=anciennes, nouvelles=nouvelles)

    def perform_destroy(self, instance):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        self._verifier_lot_modifiable(instance, 'supprimé')
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])
        _journaliser(self.request, 'SOFT_DELETE', 'lots', instance.id,
                     anciennes={'code_lot': instance.code_lot, 'statut': instance.statut})

    def _transition(self, request, lot, cible: str, *, motif: str | None = None):
        """Validation ou commercialisation, journalisées (audit + historique) et notifiées."""
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        with transaction.atomic():
            lot = Lot.objects.select_for_update(of=('self',)).select_related(
                'producteur', 'cooperative',
            ).get(pk=lot.pk)
            ancien = lot.statut
            if cible == 'VALIDE':
                mode = valider_lot(lot, request.user)
            elif cible == 'COMMERCIALISE':
                commercialiser_lot(lot, request.user, motif=motif)
                mode = 'AGENT' if _est_agent(request.user) else 'PROPRIETAIRE'
            else:
                raise ValidationError({
                    'statut': 'Statut cible inconnu. Valeurs possibles : VALIDE ou COMMERCIALISE.',
                })
        _journaliser(request, 'VALIDATE' if cible == 'VALIDE' else 'CHANGE_STATUT', 'lots', lot.id,
                     anciennes={'statut': ancien}, nouvelles={'statut': lot.statut, 'mode': mode})
        _notifier_statut_lot(lot, ancien, auteur_id=request.user.id, mode=mode)
        return self._reponse_lot(lot, request)

    @action(detail=True, methods=['post'], url_path='valider')
    def valider(self, request, pk=None):
        """BROUILLON vers VALIDE : autorité, ou titulaire disposant d'une certification active."""
        return self._transition(request, self.get_object(), 'VALIDE')

    @action(detail=True, methods=['post'], url_path='commercialiser')
    def commercialiser(self, request, pk=None):
        """VALIDE vers COMMERCIALISE : titulaire du lot ou autorité."""
        motif = str(request.data.get('motif') or '').strip()[:300] or None
        return self._transition(request, self.get_object(), 'COMMERCIALISE', motif=motif)

    @action(detail=True, methods=['get'], url_path='tracabilite')
    def tracabilite(self, request, pk=None):
        lot = self.get_object()
        return Response(LotSerializer(lot, context={'request': request, 'avec_detail': True}).data)

    @action(detail=True, methods=['get'], url_path='qr')
    def qr(self, request, pk=None):
        lot = self.get_object()
        return FileResponse(
            __import__('io').BytesIO(qr_image_bytes(lot)),
            content_type='image/png',
            as_attachment=False,
            filename=f'{lot.code_lot}.png',
        )

    @action(detail=True, methods=['post'], url_path='changer-statut')
    def changer_statut(self, request, pk=None):
        """Compatibilité : ``{"statut": "VALIDE" | "COMMERCIALISE"}`` équivaut aux actions dédiées."""
        lot = self.get_object()
        nouveau = str(request.data.get('statut') or '').strip().upper()
        if nouveau not in ('VALIDE', 'COMMERCIALISE'):
            raise ValidationError({
                'statut': (
                    'Transition impossible : un lot passe de « Brouillon » à « Validé », '
                    'puis de « Validé » à « Commercialisé ».'
                ),
            })
        motif = str(request.data.get('motif') or '').strip()[:300] or None
        return self._transition(request, lot, nouveau, motif=motif)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photos(self, request, pk=None):
        """Upload d'1 à 2 photos illustrant la marchandise du lot (comble les emplacements libres)."""
        lot = self.get_object()
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        fichiers = request.FILES.getlist('photos') or ([request.FILES['photo']] if 'photo' in request.FILES else [])
        if not fichiers:
            raise ValidationError({'photos': 'Au moins un fichier « photos » requis.'})
        emplacements_libres = [i for i in (1, 2) if not chemin_photo('lots', lot.id, suffixe=f'_{i}').exists()]
        if len(fichiers) > len(emplacements_libres):
            raise ValidationError({
                'photos': f'Il ne reste que {len(emplacements_libres)} emplacement(s) photo disponible(s) (2 maximum par lot).',
            })
        for index, fichier in zip(emplacements_libres, fichiers):
            enregistrer_photo(fichier, 'lots', lot.id, suffixe=f'_{index}')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='UPDATE_PHOTO', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
        )
        return self._reponse_lot(lot, request)

    @photos.mapping.delete
    def supprimer_photo(self, request, pk=None):
        """Retire une des photos du lot (paramètre ?index=1|2)."""
        lot = self.get_object()
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        try:
            index = int(request.query_params.get('index', ''))
        except (TypeError, ValueError):
            raise ValidationError({'index': 'Paramètre "index" (1 ou 2) requis.'})
        if index not in (1, 2):
            raise ValidationError({'index': 'Paramètre "index" doit être 1 ou 2.'})
        chemin = chemin_photo('lots', lot.id, suffixe=f'_{index}')
        if chemin.exists():
            chemin.unlink()
        media_store.supprimer(f'photos/lots/{lot.id}_{index}.jpg')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='DELETE_PHOTO', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
        )
        return self._reponse_lot(lot, request)


class MouvementViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = MouvementSerializer
    http_method_names = ['get', 'post', 'head', 'options']
    filterset_class = MouvementFilter

    def get_queryset(self):
        qs = Mouvement.objects.select_related('lot', 'lot__producteur').filter(lot__deleted_at__isnull=True)
        return scope_mouvements_qs(qs, self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        lot = serializer.validated_data.get('lot')
        if lot is None:
            raise ValidationError({'lot': 'Lot obligatoire.'})
        if lot.deleted_at is not None:
            raise ValidationError({'lot': 'Ce lot a été supprimé.'})
        if not user_can_access_lot(user, lot):
            raise PermissionDenied('Accès refusé à ce lot.')
        type_mvt = valider_type_mouvement(serializer.validated_data.get('type_mouvement'))
        valider_type_mouvement_pour_role(type_mvt, user.role)

        now = timezone.now()
        date_mouvement = serializer.validated_data.get('date_mouvement') or now
        if timezone.localdate(date_mouvement) < lot.date_collecte:
            raise ValidationError({
                'date_mouvement': 'La date de l’étape ne peut pas précéder la date de collecte du lot.',
            })
        quantite = serializer.validated_data.get('quantite')
        unite = serializer.validated_data.get('unite') or (lot.unite if quantite is not None else None)
        if quantite is not None and unite == lot.unite and quantite > lot.quantite:
            quantite_lot = f'{lot.quantite:f}'.rstrip('0').rstrip('.')
            raise ValidationError({
                'quantite': f'La quantité ne peut pas dépasser celle du lot ({quantite_lot} {lot.unite}).',
            })

        with transaction.atomic():
            lot = Lot.objects.select_for_update(of=('self',)).select_related(
                'producteur', 'cooperative',
            ).get(pk=lot.pk)
            verifier_mouvement_compatible(lot, type_mvt)
            ancien_statut = lot.statut
            obj = serializer.save(
                lot=lot, created_at=now, sync_statut='SYNCED', acteur_utilisateur_id=user.id,
                type_mouvement=type_mvt, date_mouvement=date_mouvement, unite=unite,
            )
            appliquer_mouvement_sur_lot(lot, type_mvt, user)
        _journaliser(
            self.request, 'CREATE', 'mouvements', obj.id,
            nouvelles={'type_mouvement': type_mvt, 'lot_id': str(lot.id), 'statut_lot': lot.statut},
        )
        if lot.statut != ancien_statut:
            mode = 'AGENT' if _est_agent(user) else 'PROPRIETAIRE'
            _journaliser(self.request, 'CHANGE_STATUT', 'lots', lot.id,
                         anciennes={'statut': ancien_statut}, nouvelles={'statut': lot.statut, 'mode': mode})
            _notifier_statut_lot(lot, ancien_statut, auteur_id=user.id, mode=mode)


class TypeCertificationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageCertifications]
    queryset = TypeCertification.objects.filter(actif=True)
    serializer_class = TypeCertificationSerializer
    search_fields = ('libelle', 'code')


class CertificationViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCertifications]
    serializer_class = CertificationSerializer
    filterset_class = CertificationFilter
    http_method_names = ['get', 'post', 'put', 'patch', 'delete', 'head', 'options']
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def destroy(self, request, *args, **kwargs):
        # DELETE n'est ouvert que pour retirer une pièce (route pieces/<id>/) : une demande ne se supprime pas.
        raise PermissionDenied('Une demande de certification ne peut pas être supprimée.')

    @staticmethod
    def _pieces_recues(request) -> list[tuple]:
        """Associe chaque fichier ``pieces`` à son intitulé ``intitules`` (même ordre) et les contrôle tous."""
        fichiers = request.FILES.getlist('pieces')
        if not fichiers:
            return []
        if hasattr(request.data, 'getlist'):
            intitules = request.data.getlist('intitules')
        else:
            intitules = list(request.data.get('intitules') or [])
        return [
            (fichier, controler_piece_justificative(fichier, intitules[i] if i < len(intitules) else '', i + 1))
            for i, fichier in enumerate(fichiers)
        ]

    @staticmethod
    def _enregistrer_pieces(cert, pieces, user) -> list:
        """Écrit les pièces dans le stockage sécurisé ; en cas d'échec, aucun fichier orphelin ne subsiste."""
        from .models import PieceCertification

        ecrits, crees = [], []
        try:
            with transaction.atomic():
                for fichier, intitule in pieces:
                    piece_id = uuid.uuid4()
                    chemin = enregistrer_document(fichier, f'certifications/{cert.id}', piece_id)
                    ecrits.append(chemin)
                    ext = Path(chemin).suffix.lower()
                    crees.append(PieceCertification.objects.create(
                        id=piece_id, certification=cert, intitule=intitule, chemin=chemin,
                        nom_original=Path(fichier.name or '').name[:255] or None,
                        type_mime=PIECES_TYPES_MIME.get(ext), taille_octets=fichier.size,
                        depose_par_id=_user_id(user), created_at=timezone.now(),
                    ))
        except Exception:
            for chemin in ecrits:
                (Path(settings.MEDIA_ROOT) / chemin).unlink(missing_ok=True)
                media_store.supprimer(chemin)
            raise
        return crees

    def _verifier_demandeur(self, cert) -> None:
        """Le dossier est complété par le demandeur (ou l'administrateur) tant qu'il n'est pas traité."""
        user = self.request.user
        if user.role != Utilisateur.Role.ADMINISTRATEUR:
            est_producteur = bool(cert.producteur_id and cert.producteur.utilisateur_id == user.id)
            est_coop = (
                user.role == Utilisateur.Role.COOPERATIVE and cert.producteur_id
                and cert.producteur.cooperative_id in set(_cooperatives_du_compte(user).values_list('id', flat=True))
            )
            if not (est_producteur or est_coop):
                raise PermissionDenied('Seul le demandeur ou un administrateur peut gérer les pièces de ce dossier.')
        if cert.statut not in ('DEMANDEE', 'EN_COURS'):
            raise ValidationError({'pieces': 'Cette demande a déjà été traitée : ses pièces ne sont plus modifiables.'})

    def create(self, request, *args, **kwargs):
        pieces = self._pieces_recues(request)
        if len(pieces) > PIECES_CERTIFICATION_MAX:
            raise ValidationError({'pieces': f'{PIECES_CERTIFICATION_MAX} documents au maximum par demande.'})
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            self.perform_create(serializer)
            if pieces:
                self._enregistrer_pieces(serializer.instance, pieces, request.user)
        cert = self.get_queryset().get(pk=serializer.instance.pk)
        return Response(self.get_serializer(cert).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='pieces')
    def ajouter_pieces(self, request, pk=None):
        """Ajoute une ou plusieurs pièces (``pieces`` + ``intitules``) à une demande non traitée."""
        cert = self.get_object()
        self._verifier_demandeur(cert)
        pieces = self._pieces_recues(request)
        if not pieces:
            raise ValidationError({'pieces': 'Sélectionnez au moins un document (PDF, JPG ou PNG, 8 Mo maximum).'})
        if cert.pieces.count() + len(pieces) > PIECES_CERTIFICATION_MAX:
            raise ValidationError({'pieces': f'{PIECES_CERTIFICATION_MAX} documents au maximum par demande.'})
        crees = self._enregistrer_pieces(cert, pieces, request.user)
        _journaliser(request, 'ADD_DOCUMENT', 'certifications', cert.id,
                     nouvelles={'pieces': [p.intitule for p in crees]})
        cert = self.get_queryset().get(pk=cert.pk)
        return Response(self.get_serializer(cert).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['delete'], url_path=r'pieces/(?P<piece_id>[0-9a-fA-F-]{36})')
    def retirer_piece(self, request, pk=None, piece_id=None):
        cert = self.get_object()
        self._verifier_demandeur(cert)
        piece = cert.pieces.filter(pk=piece_id).first()
        if piece is None:
            raise NotFound('Ce document ne fait pas partie du dossier.')
        chemin = piece.chemin
        piece.delete()
        (Path(settings.MEDIA_ROOT) / chemin).unlink(missing_ok=True)
        media_store.supprimer(chemin)
        _journaliser(request, 'DELETE_DOCUMENT', 'certifications', cert.id,
                     anciennes={'piece': piece.intitule})
        cert = self.get_queryset().get(pk=cert.pk)
        return Response(self.get_serializer(cert).data)

    def list(self, request, *args, **kwargs):
        _expirer_certifications_echues()
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        _expirer_certifications_echues()
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        qs = Certification.objects.select_related('type_certification', 'lot', 'producteur').prefetch_related('pieces')
        user = self.request.user
        if user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER):
            return qs
        if user.role == Utilisateur.Role.COOPERATIVE:
            from traceability.models import Cooperative
            coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            return qs.filter(lot__cooperative_id__in=coop_ids) | qs.filter(producteur__cooperative_id__in=coop_ids)
        if user.role == Utilisateur.Role.PRODUCTEUR:
            return qs.filter(producteur__utilisateur_id=user.id)
        return qs.none()

    @staticmethod
    def _verifier_coherence(prod, lot, type_cert, *, exclure_id=None) -> None:
        if lot is not None:
            if lot.deleted_at is not None:
                raise ValidationError({'lot': 'Ce lot a été supprimé.'})
            if prod is not None and lot.producteur_id != prod.id:
                raise ValidationError({'lot': 'Ce lot n’appartient pas au producteur concerné.'})
        if prod is not None and prod.deleted_at is not None:
            raise ValidationError({'producteur': 'Cette fiche producteur a été supprimée.'})
        if type_cert is not None and not type_cert.actif:
            raise ValidationError({'type_certification': 'Ce type de certification n’est plus proposé.'})
        doublons = Certification.objects.filter(
            producteur=prod, type_certification=type_cert, lot=lot,
            statut__in=('DEMANDEE', 'EN_COURS', 'OBTENUE'),
        ).exclude(statut='OBTENUE', date_expiration__lt=timezone.localdate())
        if exclure_id is not None:
            doublons = doublons.exclude(pk=exclure_id)
        if doublons.exists():
            raise ValidationError({
                'type_certification': 'Une certification de ce type est déjà en cours ou obtenue pour ce producteur.',
            })

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {
            'created_at': now,
            'updated_at': now,
            'date_demande': timezone.localdate(),
            'statut': 'DEMANDEE',
        }
        prod = serializer.validated_data.get('producteur')
        lot = serializer.validated_data.get('lot')
        if user.role == Utilisateur.Role.PRODUCTEUR:
            prod = Producteur.objects.filter(
                utilisateur_id=user.id, deleted_at__isnull=True,
            ).first()
            if not prod:
                raise ValidationError({
                    'producteur': 'Aucune fiche producteur n’est liée à votre compte.',
                })
            if prod.statut != 'ACTIF':
                raise ValidationError({
                    'producteur': 'Votre fiche doit être validée avant de demander une certification.',
                })
        elif user.role == Utilisateur.Role.COOPERATIVE:
            if not prod:
                raise ValidationError({'producteur': 'Indiquez le producteur membre concerné.'})
            coop_ids = set(_cooperatives_du_compte(user).values_list('id', flat=True))
            if prod.cooperative_id not in coop_ids:
                raise PermissionDenied('Ce producteur n’appartient pas à votre coopérative.')
        elif prod is None:
            if lot is None:
                raise ValidationError({'producteur': 'Indiquez le producteur ou le lot concerné.'})
            prod = lot.producteur
        extra['producteur'] = prod
        self._verifier_coherence(prod, lot, serializer.validated_data.get('type_certification'))
        cert = serializer.save(**extra)
        _journaliser(self.request, 'CREATE', 'certifications', cert.id,
                     nouvelles={'type': cert.type_certification.code, 'producteur_id': str(prod.id)})
        _notifier_validateurs(
            (Utilisateur.Role.ADMINISTRATEUR,), 'Nouvelle demande de certification',
            f'{prod.prenoms} {prod.nom} demande la certification « {cert.type_certification.libelle} ».',
            certification_id=str(cert.id),
        )

    def perform_update(self, serializer):
        user = self.request.user
        instance = serializer.instance
        if user.role != Utilisateur.Role.ADMINISTRATEUR and instance.statut != 'DEMANDEE':
            raise ValidationError({
                'detail': 'Cette demande est déjà en cours de traitement : elle n’est plus modifiable.',
            })
        nouveau_prod = serializer.validated_data.pop('producteur', instance.producteur)
        if getattr(nouveau_prod, 'pk', None) != instance.producteur_id:
            raise PermissionDenied('Le titulaire d’une certification ne peut pas être modifié.')
        lot = serializer.validated_data.get('lot', instance.lot)
        type_cert = serializer.validated_data.get('type_certification', instance.type_certification)
        self._verifier_coherence(instance.producteur, lot, type_cert, exclure_id=instance.id)
        anciennes, nouvelles = _valeurs_modifiees(instance, serializer.validated_data)
        cert = serializer.save(updated_at=timezone.now())
        _journaliser(self.request, 'UPDATE', 'certifications', cert.id, anciennes=anciennes, nouvelles=nouvelles)

    def _prevenir_titulaire(self, cert, sujet: str, message: str) -> None:
        if not cert.producteur_id or not cert.producteur.utilisateur_id:
            return
        uid = cert.producteur.utilisateur_id
        _notifier(uid, sujet, message, certification_id=str(cert.id), statut=cert.statut)
        user = Utilisateur.objects.filter(pk=uid, deleted_at__isnull=True).first()
        if user is None:
            return
        try:
            with transaction.atomic():
                envoyer_email(destinataire_id=user.id, email=user.email, sujet=f'PFNL : {sujet}', corps_texte=message)
                envoyer_sms(destinataire_id=user.id, telephone=user.telephone, message=f'PFNL : {message}'[:300])
        except Exception:
            logger.exception('Envoi e-mail ou SMS de certification impossible')

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def document(self, request, pk=None):
        """Joindre ou remplacer le document justificatif d'une certification (PDF/JPG/PNG)."""
        cert = self.get_object()
        user = request.user
        est_proprietaire = bool(
            cert.producteur_id
            and Producteur.objects.filter(id=cert.producteur_id, utilisateur_id=user.id).exists()
        )
        est_coop_gestionnaire = False
        if not est_proprietaire and user.role == Utilisateur.Role.COOPERATIVE and cert.producteur_id:
            from traceability.models import Cooperative

            coop_ids = set(Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True))
            est_coop_gestionnaire = cert.producteur.cooperative_id in coop_ids
        if not (
            est_proprietaire
            or est_coop_gestionnaire
            or user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER)
        ):
            raise PermissionDenied("Vous n'êtes pas autorisé à modifier ce document.")
        fichier = request.FILES.get('document')
        if not fichier:
            raise ValidationError({'document': 'Aucun fichier reçu.'})
        from .services import enregistrer_document

        rel = enregistrer_document(fichier, 'certifications', cert.id)
        cert.document_path = rel
        cert.updated_at = timezone.now()
        cert.save(update_fields=['document_path', 'updated_at'])
        _journaliser(request, 'UPDATE_DOCUMENT', 'certifications', cert.id)
        return Response(CertificationSerializer(cert, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCertifications])
    def valider(self, request, pk=None):
        cert = self.get_object()
        if cert.statut not in ('DEMANDEE', 'EN_COURS'):
            raise ValidationError({'detail': 'Cette demande a déjà été traitée.'})
        numero = (request.data.get('numero_certificat') or '').strip()
        if len(numero) > 80:
            raise ValidationError({'numero_certificat': 'Le numéro de certificat ne doit pas dépasser 80 caractères.'})
        now = timezone.now()
        aujourd_hui = timezone.localdate()
        cert.statut = 'OBTENUE'
        cert.date_obtention = max(aujourd_hui, cert.date_demande)
        duree = cert.type_certification.duree_mois
        cert.date_expiration = _ajouter_mois(cert.date_obtention, duree) if duree and duree > 0 else None
        cert.valide_par_id = request.user.id
        cert.updated_at = now
        if numero:
            cert.numero_certificat = numero
        cert.save()
        _journaliser(request, 'VALIDATE', 'certifications', cert.id, nouvelles={
            'statut': cert.statut, 'numero_certificat': cert.numero_certificat,
            'date_expiration': cert.date_expiration.isoformat() if cert.date_expiration else None,
        })
        message = f'Votre certification « {cert.type_certification.libelle} » a été accordée'
        if cert.date_expiration:
            message += f' (valable jusqu’au {cert.date_expiration:%d/%m/%Y})'
        self._prevenir_titulaire(cert, 'Certification accordée', message + '.')
        return Response(CertificationSerializer(cert, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCertifications])
    def refuser(self, request, pk=None):
        cert = self.get_object()
        if cert.statut not in ('DEMANDEE', 'EN_COURS'):
            raise ValidationError({'detail': 'Cette demande a déjà été traitée.'})
        motif = (request.data.get('motif') or '').strip()
        if not motif:
            raise ValidationError({'motif': 'Le motif du refus est obligatoire.'})
        cert.statut = 'REFUSEE'
        cert.updated_at = timezone.now()
        cert.valide_par_id = request.user.id
        cert.observations = ((cert.observations or '') + f'\nRefus : {motif}').strip()
        cert.save()
        _journaliser(request, 'REJECT', 'certifications', cert.id, nouvelles={'statut': cert.statut, 'motif': motif})
        self._prevenir_titulaire(
            cert, 'Certification refusée',
            f'Votre demande de certification « {cert.type_certification.libelle} » a été refusée. Motif : {motif}',
        )
        return Response(CertificationSerializer(cert, context={'request': request}).data)


class LotVerifyView(APIView):
    """Vérification publique QR, sans authentification : lots validés ou commercialisés.

    Un brouillon n'a pas encore été contrôlé : il n'est pas vérifiable (404 ``LOT_NON_VALIDE``).
    """
    permission_classes = [AllowAny]

    def get(self, request, uuid_public=None):
        from traceability.public_views import lot_public_complet, lots_complets_qs

        try:
            lot = lots_complets_qs().get(uuid_public=uuid_public)
        except (Lot.DoesNotExist, ValueError, TypeError):
            return Response({
                'detail': 'Aucun lot ne correspond à ce QR code. Vérifiez le lien ou scannez à nouveau l’étiquette.',
                'code': 'LOT_INTROUVABLE',
            }, status=404)
        if lot.statut not in STATUTS_LOT_VERIFIABLES:
            return Response({
                'detail': (
                    'Ce lot est encore en brouillon : il n’a pas été validé par une autorité ou un '
                    'producteur certifié. Il ne peut pas encore être vérifié publiquement.'
                ),
                'code': 'LOT_NON_VALIDE',
                'code_lot': lot.code_lot,
            }, status=404)
        return Response(lot_public_complet(lot, request))
