from django.conf import settings
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
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
    UtilisateurAdminSerializer,
    UtilisateurSerializer,
)
from pnlf_platform.services import creer_notification


class PasswordResetThrottle(AnonRateThrottle):
    scope = 'password_reset'


def _lien_reinitialisation(token: str) -> str:
    base = (getattr(settings, 'PNLF_FRONTEND_URL', None) or 'http://localhost:4200').rstrip('/')
    return f'{base}/reinitialiser-mot-de-passe?token={token}'


class MeView(generics.RetrieveAPIView):
    serializer_class = UtilisateurSerializer

    def get_object(self):
        return self.request.user


class UtilisateurViewSet(viewsets.ModelViewSet):
    """Gestion des comptes — module 6.1."""
    permission_classes = [CanManageUsers]
    serializer_class = UtilisateurAdminSerializer
    search_fields = ('email', 'nom', 'prenoms', 'telephone')
    filterset_fields = ('role', 'statut')
    http_method_names = ['get', 'post', 'put', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return Utilisateur.objects.filter(deleted_at__isnull=True).order_by('-created_at')

    def perform_create(self, serializer):
        user = serializer.save()
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='CREATE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'email': user.email, 'role': user.role},
        )

    def perform_update(self, serializer):
        user = serializer.save()
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='UPDATE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
        )

    def perform_destroy(self, instance):
        if instance.role == Utilisateur.Role.ADMINISTRATEUR:
            raise PermissionDenied('Impossible de supprimer un administrateur.')
        instance.deleted_at = timezone.now()
        instance.statut = Utilisateur.Statut.INACTIF
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'statut', 'updated_at'])

    @action(detail=True, methods=['post'])
    def activer(self, request, pk=None):
        u = self.get_object()
        if u.statut == Utilisateur.Statut.EN_ATTENTE:
            from traceability.views import _activer_compte_lie
            libelles = {
                Utilisateur.Role.ACHETEUR: 'acheteur',
                Utilisateur.Role.PRODUCTEUR: 'producteur',
                Utilisateur.Role.COOPERATIVE: 'coopérative',
            }
            _activer_compte_lie(u.id, type_libelle=libelles.get(u.role, 'utilisateur'))
            u.refresh_from_db()
            return Response(UtilisateurSerializer(u).data)
        u.statut = Utilisateur.Statut.ACTIF
        u.updated_at = timezone.now()
        u.save(update_fields=['statut', 'updated_at'])
        return Response(UtilisateurSerializer(u).data)

    @action(detail=True, methods=['post'])
    def suspendre(self, request, pk=None):
        u = self.get_object()
        u.statut = Utilisateur.Statut.SUSPENDU
        u.updated_at = timezone.now()
        u.save(update_fields=['statut', 'updated_at'])
        return Response(UtilisateurSerializer(u).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Ajoute ou remplace la photo de profil d'un utilisateur."""
        from traceability.services import enregistrer_photo

        user = self.get_object()
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Aucune image reçue.'})
        enregistrer_photo(fichier, 'utilisateurs', user.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=self.request.user.id, action='UPDATE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'photo': 'mise à jour'},
        )
        return Response(UtilisateurAdminSerializer(user, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='envoyer-reinitialisation')
    def envoyer_reinitialisation(self, request, pk=None):
        user = self.get_object()
        import hashlib
        import secrets
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        now = timezone.now()
        ReinitialisationMdp.objects.create(
            utilisateur=user, token_hash=token_hash,
            expire_at=now + timezone.timedelta(hours=24), created_at=now,
        )
        lien = _lien_reinitialisation(token)
        envoyer_email(
            destinataire_id=user.id, email=user.email,
            sujet='PNLF-PFNL — Réinitialisation de mot de passe',
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
        return Response({'detail': 'Lien de réinitialisation envoyé.'})


class ChangePasswordView(APIView):
    def post(self, request):
        ser = ChangePasswordSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        user = request.user
        if not user.check_password(ser.validated_data['ancien_mot_de_passe']):
            return Response({'detail': 'Ancien mot de passe incorrect.'}, status=400)
        user.set_password(ser.validated_data['nouveau_mot_de_passe'])
        user.doit_changer_mdp = False
        user.updated_at = timezone.now()
        user.save(update_fields=['mot_de_passe_hash', 'doit_changer_mdp', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=user.id, action='PASSWORD_CHANGE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
        )
        return Response({'detail': 'Mot de passe modifié.'})


class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [PasswordResetThrottle]

    def post(self, request):
        ser = PasswordResetRequestSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        email = ser.validated_data['email']
        reponse = {'detail': 'Si le compte existe, un email sera envoyé.'}
        try:
            user = Utilisateur.objects.get(email__iexact=email, deleted_at__isnull=True)
        except Utilisateur.DoesNotExist:
            return Response(reponse)
        import hashlib
        import secrets
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        now = timezone.now()
        ReinitialisationMdp.objects.create(
            utilisateur=user, token_hash=token_hash,
            expire_at=now + timezone.timedelta(hours=24), created_at=now,
        )
        lien = _lien_reinitialisation(token)
        envoyer_email(
            destinataire_id=user.id, email=user.email,
            sujet='PNLF-PFNL — Réinitialisation de mot de passe',
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
        return Response(reponse)


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [PasswordResetThrottle]

    def post(self, request):
        ser = PasswordResetConfirmSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        import hashlib
        token_hash = hashlib.sha256(ser.validated_data['token'].encode()).hexdigest()
        now = timezone.now()
        try:
            reset = ReinitialisationMdp.objects.select_related('utilisateur').get(
                token_hash=token_hash, utilise_at__isnull=True, expire_at__gt=now,
            )
        except ReinitialisationMdp.DoesNotExist:
            return Response({'detail': 'Token invalide ou expiré.'}, status=400)
        user = reset.utilisateur
        user.set_password(ser.validated_data['nouveau_mot_de_passe'])
        user.updated_at = now
        user.save(update_fields=['mot_de_passe_hash', 'updated_at'])
        reset.utilise_at = now
        reset.save(update_fields=['utilise_at'])
        return Response({'detail': 'Mot de passe réinitialisé.'})
