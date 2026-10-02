import hashlib
import logging
import secrets
import threading

from django.conf import settings
from django.db import close_old_connections, connection, transaction
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.views import APIView

from accounts.audit import request_meta, write_audit
from accounts.messaging import envoyer_email
from accounts.models import ReinitialisationMdp, Utilisateur
from accounts.permissions import CanManageUsers
from accounts.serializers import (
    ChangePasswordSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    PnlfTokenObtainPairSerializer,
    UtilisateurAdminSerializer,
    UtilisateurSerializer,
)
from accounts.views import set_refresh_cookie
from pnlf_platform.services import creer_notification

logger = logging.getLogger(__name__)

LIEN_RESET_INVALIDE = 'Ce lien de réinitialisation est invalide ou a expiré. Demandez-en un nouveau.'


class PasswordResetThrottle(AnonRateThrottle):
    scope = 'password_reset'


def _lien_reinitialisation(token: str) -> str:
    base = (getattr(settings, 'PNLF_FRONTEND_URL', None) or 'http://localhost:4200').rstrip('/')
    # Fragment plutôt que query : évite fuite via Referer / logs proxy.
    return f'{base}/reinitialiser-mot-de-passe#token={token}'


def _creer_jeton_reinitialisation(user: Utilisateur) -> str:
    token = secrets.token_urlsafe(32)
    now = timezone.now()
    ReinitialisationMdp.objects.create(
        utilisateur=user, token_hash=hashlib.sha256(token.encode()).hexdigest(),
        expire_at=now + timezone.timedelta(hours=24), created_at=now,
    )
    return token


def _envoyer_lien_reinitialisation(user_id) -> None:
    """Crée le jeton, envoie l'e-mail et la notification (compte actif uniquement)."""
    user = Utilisateur.objects.filter(
        pk=user_id, deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
    ).first()
    if user is None:
        return
    lien = _lien_reinitialisation(_creer_jeton_reinitialisation(user))
    envoyer_email(
        destinataire_id=user.id, email=user.email,
        sujet='PFNL : réinitialisation de mot de passe',
        corps_texte=(
            f'Bonjour {user.prenoms} {user.nom},\n\n'
            'Une demande de réinitialisation de mot de passe a été faite pour votre compte. '
            f'Ouvrez ce lien (valable 24 h) :\n{lien}\n\n'
            'Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail.'
        ),
    )
    creer_notification(
        user.id, 'Réinitialisation mot de passe',
        'Un lien de réinitialisation vous a été envoyé par e-mail. Il expire dans 24 h.',
        metadata={'type': 'reset_mdp'},
    )


def _tache_reinitialisation(user_id) -> None:
    try:
        _envoyer_lien_reinitialisation(user_id)
    except Exception:
        logger.exception('Échec de l’envoi du lien de réinitialisation')
    finally:
        close_old_connections()
        connection.close()


def programmer_reinitialisation(user_id) -> None:
    """Hors du cycle de la requête : la réponse ne dépend ni de l'existence du compte ni du
    délai du serveur SMTP."""
    transaction.on_commit(
        lambda: threading.Thread(target=_tache_reinitialisation, args=(user_id,), daemon=True).start()
    )


def _interdit_mutation_admin(acteur, cible: Utilisateur) -> None:
    """Seul un administrateur peut modifier un compte administrateur."""
    if cible.role == Utilisateur.Role.ADMINISTRATEUR and getattr(acteur, 'role', None) != Utilisateur.Role.ADMINISTRATEUR:
        raise PermissionDenied(
            'Seul un administrateur peut modifier un compte administrateur.'
        )


def _fiche_liee_non_active(user: Utilisateur) -> str | None:
    """Message d'erreur si la fiche producteur ou coopérative liée au compte n'est pas validée."""
    from traceability.models import Cooperative, Producteur

    if user.role == Utilisateur.Role.PRODUCTEUR:
        fiche = Producteur.objects.filter(utilisateur_id=user.id, deleted_at__isnull=True).first()
        if fiche and fiche.statut != 'ACTIF':
            return (
                'La fiche producteur liée à ce compte n’est pas validée. Validez-la depuis la file '
                '« À traiter » : le compte sera activé en même temps.'
            )
    if user.role == Utilisateur.Role.COOPERATIVE:
        coop = Cooperative.objects.filter(utilisateur_id=user.id).first()
        if coop and (coop.statut != 'ACTIF' or not coop.actif):
            return (
                'La fiche coopérative liée à ce compte n’est pas validée. Validez-la depuis la file '
                '« À traiter » : le compte sera activé en même temps.'
            )
    return None


def _fiche_liee(user: Utilisateur) -> str | None:
    from traceability.models import Cooperative, Producteur

    if Producteur.objects.filter(utilisateur_id=user.id, deleted_at__isnull=True).exists():
        return 'producteur'
    if Cooperative.objects.filter(utilisateur_id=user.id).exists():
        return 'coopérative'
    return None


class UtilisateurViewSet(viewsets.ModelViewSet):
    """Gestion des comptes : module 6.1."""
    permission_classes = [CanManageUsers]
    serializer_class = UtilisateurAdminSerializer
    search_fields = ('email', 'nom', 'prenoms', 'telephone')
    filterset_fields = ('role', 'statut')
    http_method_names = ['get', 'post', 'put', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return Utilisateur.objects.filter(deleted_at__isnull=True).order_by('-created_at')

    def _audit(self, action_code: str, cible: Utilisateur, **valeurs) -> None:
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action=action_code, table_cible='utilisateurs',
            enregistrement_id=cible.id, ip_adresse=ip, user_agent=ua, **valeurs,
        )

    def perform_create(self, serializer):
        user = serializer.save()
        self._audit('CREATE', user, nouvelles_valeurs={'email': user.email, 'role': user.role})

    def perform_update(self, serializer):
        _interdit_mutation_admin(self.request.user, serializer.instance)
        champs = sorted(k for k in serializer.validated_data if k != 'password')
        user = serializer.save()
        self._audit('UPDATE', user, nouvelles_valeurs={'champs': champs})

    def perform_destroy(self, instance):
        _interdit_mutation_admin(self.request.user, instance)
        if instance.id == self.request.user.id:
            raise PermissionDenied('Vous ne pouvez pas désactiver votre propre compte.')
        if instance.role == Utilisateur.Role.ADMINISTRATEUR:
            raise PermissionDenied('Impossible de supprimer un administrateur.')
        ancien_statut = instance.statut
        instance.deleted_at = timezone.now()
        instance.statut = Utilisateur.Statut.INACTIF
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'statut', 'updated_at'])
        self._audit(
            'SOFT_DELETE', instance,
            anciennes_valeurs={'statut': ancien_statut}, nouvelles_valeurs={'statut': instance.statut},
        )

    @action(detail=True, methods=['post'])
    def activer(self, request, pk=None):
        u = self.get_object()
        _interdit_mutation_admin(request.user, u)
        if u.statut == Utilisateur.Statut.ACTIF:
            return Response(UtilisateurSerializer(u, context={'request': request}).data)
        erreur = _fiche_liee_non_active(u)
        if erreur:
            raise ValidationError({'detail': erreur})
        ancien_statut = u.statut
        if u.statut == Utilisateur.Statut.EN_ATTENTE:
            from traceability.views import _activer_compte_lie
            libelles = {
                Utilisateur.Role.ACHETEUR: 'acheteur',
                Utilisateur.Role.PRODUCTEUR: 'producteur',
                Utilisateur.Role.COOPERATIVE: 'coopérative',
            }
            _activer_compte_lie(u.id, type_libelle=libelles.get(u.role, 'utilisateur'))
            u.refresh_from_db()
        else:
            u.statut = Utilisateur.Statut.ACTIF
            u.updated_at = timezone.now()
            u.save(update_fields=['statut', 'updated_at'])
        self._audit(
            'ACTIVATE', u, anciennes_valeurs={'statut': ancien_statut}, nouvelles_valeurs={'statut': u.statut},
        )
        return Response(UtilisateurSerializer(u, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def suspendre(self, request, pk=None):
        u = self.get_object()
        _interdit_mutation_admin(request.user, u)
        if u.id == request.user.id:
            raise PermissionDenied('Vous ne pouvez pas suspendre votre propre compte.')
        if u.statut != Utilisateur.Statut.ACTIF:
            raise ValidationError({'detail': 'Seul un compte actif peut être suspendu.'})
        u.statut = Utilisateur.Statut.SUSPENDU
        u.updated_at = timezone.now()
        u.save(update_fields=['statut', 'updated_at'])
        self._audit(
            'DEACTIVATE', u,
            anciennes_valeurs={'statut': Utilisateur.Statut.ACTIF}, nouvelles_valeurs={'statut': u.statut},
        )
        return Response(UtilisateurSerializer(u, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def rejeter(self, request, pk=None):
        """Rejette une inscription d'acheteur en attente (les fiches producteur / coopérative
        suivent leur propre circuit de validation)."""
        from traceability.views import _rejeter_compte_lie

        u = self.get_object()
        _interdit_mutation_admin(request.user, u)
        if u.statut != Utilisateur.Statut.EN_ATTENTE:
            raise ValidationError({'detail': 'Seule une inscription en attente de validation peut être rejetée.'})
        if u.role != Utilisateur.Role.ACHETEUR:
            raise ValidationError({
                'detail': 'Les inscriptions de producteurs et de coopératives se rejettent depuis leur fiche '
                          '(file « À traiter »).',
            })
        motif = (request.data.get('motif') or '').strip()[:500]
        cible = {'id': u.id, 'email': u.email}
        with transaction.atomic():
            _rejeter_compte_lie(u.id, type_libelle='acheteur', motif=motif)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='utilisateurs',
            enregistrement_id=cible['id'], ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'email': cible['email'], 'motif': motif or None},
        )
        return Response({'detail': 'Inscription rejetée. Le demandeur a été informé.'})

    @action(detail=True, methods=['post'], url_path='changer-role')
    def changer_role(self, request, pk=None):
        u = self.get_object()
        _interdit_mutation_admin(request.user, u)
        if u.id == request.user.id:
            raise PermissionDenied('Vous ne pouvez pas modifier votre propre rôle.')
        role = (request.data.get('role') or '').strip()
        if role not in Utilisateur.Role.values:
            raise ValidationError({'role': 'Rôle inconnu.'})
        if role == u.role:
            return Response(UtilisateurAdminSerializer(u, context={'request': request}).data)
        if role == Utilisateur.Role.ADMINISTRATEUR and request.user.role != Utilisateur.Role.ADMINISTRATEUR:
            raise PermissionDenied('Seul un administrateur peut attribuer le rôle administrateur.')
        fiche = _fiche_liee(u)
        if fiche:
            raise ValidationError({
                'role': f'Ce compte est lié à une fiche {fiche} : son rôle ne peut pas être modifié. '
                        'Créez un nouveau compte pour ce profil.',
            })
        ancien = u.role
        u.role = role
        u.updated_at = timezone.now()
        u.save(update_fields=['role', 'updated_at'])
        self._audit('UPDATE', u, anciennes_valeurs={'role': ancien}, nouvelles_valeurs={'role': role})
        return Response(UtilisateurAdminSerializer(u, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Ajoute ou remplace la photo de profil d'un utilisateur."""
        from traceability.services import enregistrer_photo

        user = self.get_object()
        _interdit_mutation_admin(request.user, user)
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Aucune image reçue.'})
        enregistrer_photo(fichier, 'utilisateurs', user.id)
        self._audit('UPDATE_PHOTO', user)
        return Response(UtilisateurAdminSerializer(user, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='envoyer-reinitialisation')
    def envoyer_reinitialisation(self, request, pk=None):
        user = self.get_object()
        _interdit_mutation_admin(request.user, user)
        if user.statut != Utilisateur.Statut.ACTIF:
            raise ValidationError({
                'detail': 'Le compte doit être actif pour recevoir un lien de réinitialisation.',
            })
        lien = _lien_reinitialisation(_creer_jeton_reinitialisation(user))
        envoyer_email(
            destinataire_id=user.id, email=user.email,
            sujet='PFNL : réinitialisation de mot de passe',
            corps_texte=(
                f'Bonjour {user.prenoms} {user.nom},\n\n'
                'Un administrateur a demandé la réinitialisation de votre mot de passe. '
                f'Ouvrez ce lien (valable 24 h) :\n{lien}\n'
            ),
        )
        creer_notification(
            user.id, 'Réinitialisation mot de passe',
            'Un lien de réinitialisation vous a été envoyé par e-mail.',
            metadata={'type': 'reset_mdp'},
        )
        self._audit('PASSWORD_RESET_REQUEST', user)
        return Response({'detail': 'Lien de réinitialisation envoyé.'})


class ChangePasswordView(APIView):
    """Changement de mot de passe : renvoie une nouvelle session (l'ancienne est révoquée
    par l'empreinte ``pwd`` des jetons) pour que l'utilisateur reste connecté."""

    allow_password_change_required = True

    def post(self, request):
        user = request.user
        ser = ChangePasswordSerializer(data=request.data, context={'user': user})
        ser.is_valid(raise_exception=True)
        if not user.check_password(ser.validated_data['ancien_mot_de_passe']):
            return Response(
                {'ancien_mot_de_passe': ['Le mot de passe actuel est incorrect.']}, status=400,
            )
        user.set_password(ser.validated_data['nouveau_mot_de_passe'])
        user.doit_changer_mdp = False
        user.updated_at = timezone.now()
        user.save(update_fields=['mot_de_passe_hash', 'doit_changer_mdp', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=user.id, action='PASSWORD_CHANGE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
        )
        refresh = PnlfTokenObtainPairSerializer.get_token(user)
        response = Response({
            'detail': 'Mot de passe modifié.',
            'access': str(refresh.access_token),
            'user': UtilisateurSerializer(user, context={'request': request}).data,
        })
        set_refresh_cookie(response, str(refresh))
        return response


class PasswordResetRequestView(APIView):
    """Réponse identique, que le compte existe, soit actif ou non : aucun lien n'est créé pour
    un compte en attente, suspendu ou désactivé."""
    permission_classes = [AllowAny]
    throttle_classes = [PasswordResetThrottle]

    def post(self, request):
        ser = PasswordResetRequestSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user_id = (
            Utilisateur.objects.filter(
                email__iexact=ser.validated_data['email'],
                deleted_at__isnull=True,
                statut=Utilisateur.Statut.ACTIF,
            )
            .values_list('id', flat=True)
            .first()
        )
        if user_id:
            programmer_reinitialisation(user_id)
        return Response({'detail': 'Si un compte actif correspond à cette adresse, un e-mail vient de lui être envoyé.'})


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [PasswordResetThrottle]

    def post(self, request):
        ser = PasswordResetConfirmSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        token_hash = hashlib.sha256(ser.validated_data['token'].encode()).hexdigest()
        now = timezone.now()
        reset = (
            ReinitialisationMdp.objects.select_related('utilisateur')
            .filter(token_hash=token_hash, utilise_at__isnull=True, expire_at__gt=now)
            .first()
        )
        user = reset.utilisateur if reset else None
        if user is None or user.deleted_at is not None or user.statut != Utilisateur.Statut.ACTIF:
            return Response({'detail': LIEN_RESET_INVALIDE}, status=status.HTTP_400_BAD_REQUEST)
        with transaction.atomic():
            user.set_password(ser.validated_data['nouveau_mot_de_passe'])
            # Le mot de passe vient d'être choisi par le titulaire lui-même.
            user.doit_changer_mdp = False
            user.tentatives_echec = 0
            user.verrouille_jusquau = None
            user.updated_at = now
            user.save(update_fields=[
                'mot_de_passe_hash', 'doit_changer_mdp', 'tentatives_echec', 'verrouille_jusquau', 'updated_at',
            ])
            ReinitialisationMdp.objects.filter(utilisateur=user, utilise_at__isnull=True).update(utilise_at=now)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=user.id, action='PASSWORD_RESET', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
        )
        return Response({'detail': 'Mot de passe réinitialisé.'})
