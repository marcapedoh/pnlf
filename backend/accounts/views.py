"""Login / refresh JWT avec cookie HttpOnly pour le refresh + empreinte mot de passe."""

from __future__ import annotations

import re

from django.conf import settings
from rest_framework import generics, permissions, status, throttling
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .audit import request_meta, write_audit
from .connexions import enregistrer_connexion, retirer_presence, signaler_presence
from .models import Utilisateur
from .serializers import (
    MonProfilSerializer,
    PnlfTokenObtainPairSerializer,
    PnlfTokenRefreshSerializer,
    UtilisateurSerializer,
)


class LoginRateThrottle(throttling.AnonRateThrottle):
    scope = 'login'


class RefreshRateThrottle(throttling.AnonRateThrottle):
    scope = 'refresh'


def origine_autorisee(request) -> bool:
    """Absence d'en-tête Origin (client non navigateur, même origine en GET) : accepté.
    Sinon l'origine doit figurer dans la configuration CORS ou être celle de l'API elle-même."""
    origine = (request.META.get('HTTP_ORIGIN') or '').strip().rstrip('/')
    if not origine:
        return True
    if origine in settings.CORS_ALLOWED_ORIGINS:
        return True
    if any(re.match(motif, origine) for motif in settings.CORS_ALLOWED_ORIGIN_REGEXES):
        return True
    return origine == f'{request.scheme}://{request.get_host()}'


class OrigineAutoriseeMixin:
    """Refuse les requêtes navigateur venant d'un site tiers sur les vues qui posent ou
    consomment le cookie de session (refresh HttpOnly envoyé avec ``SameSite=None``)."""

    def initial(self, request, *args, **kwargs):
        if not origine_autorisee(request):
            raise PermissionDenied('Origine non autorisée.')
        super().initial(request, *args, **kwargs)


def set_refresh_cookie(response, refresh_token: str) -> None:
    response.set_cookie(
        settings.PNLF_REFRESH_COOKIE,
        refresh_token,
        max_age=int(settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'].total_seconds()),
        httponly=True,
        secure=getattr(settings, 'PNLF_REFRESH_COOKIE_SECURE', True),
        samesite=getattr(settings, 'PNLF_REFRESH_COOKIE_SAMESITE', 'Lax'),
        path=settings.PNLF_REFRESH_COOKIE_PATH,
    )


def clear_refresh_cookie(response) -> None:
    response.delete_cookie(
        settings.PNLF_REFRESH_COOKIE,
        path=settings.PNLF_REFRESH_COOKIE_PATH,
        samesite=getattr(settings, 'PNLF_REFRESH_COOKIE_SAMESITE', 'Lax'),
    )


class PnlfTokenObtainPairView(OrigineAutoriseeMixin, TokenObtainPairView):
    serializer_class = PnlfTokenObtainPairSerializer
    permission_classes = [permissions.AllowAny]
    throttle_classes = [LoginRateThrottle]

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            user_data = response.data.get('user') or {}
            ip, ua = request_meta(request)
            write_audit(
                utilisateur_id=user_data.get('id'),
                action='LOGIN',
                table_cible='utilisateurs',
                enregistrement_id=user_data.get('id'),
                ip_adresse=ip,
                user_agent=ua,
                nouvelles_valeurs={'email': user_data.get('email'), 'role': user_data.get('role')},
            )
            utilisateur = Utilisateur.objects.filter(pk=user_data.get('id')).first()
            if utilisateur is not None:
                enregistrer_connexion(request, succes=True, utilisateur=utilisateur)
            refresh = response.data.pop('refresh', None)
            if refresh:
                set_refresh_cookie(response, refresh)
        return response


class PnlfTokenRefreshView(OrigineAutoriseeMixin, TokenRefreshView):
    """Refresh depuis cookie HttpOnly (prioritaire) ou corps JSON (compat)."""
    serializer_class = PnlfTokenRefreshSerializer
    permission_classes = [permissions.AllowAny]
    throttle_classes = [RefreshRateThrottle]
    allow_password_change_required = True

    def post(self, request, *args, **kwargs):
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        if not data.get('refresh'):
            cookie_token = request.COOKIES.get(settings.PNLF_REFRESH_COOKIE)
            if cookie_token:
                data['refresh'] = cookie_token
        serializer = self.get_serializer(data=data)
        try:
            serializer.is_valid(raise_exception=True)
        except TokenError as exc:
            raise InvalidToken(exc.args[0]) from exc
        response = Response(serializer.validated_data, status=status.HTTP_200_OK)
        new_refresh = response.data.pop('refresh', None)
        if new_refresh:
            set_refresh_cookie(response, new_refresh)
        return response


class LogoutView(OrigineAutoriseeMixin, APIView):
    permission_classes = [permissions.IsAuthenticated]
    allow_password_change_required = True

    def post(self, request):
        # Pas de blacklist SimpleJWT (incompatible avec Utilisateur UUID).
        retirer_presence(request, request.user)
        response = Response({'detail': 'Déconnexion effectuée.'})
        clear_refresh_cookie(response)
        return response


class PresenceView(APIView):
    """POST /api/accounts/presence/ : signal d'activité envoyé par le front toutes les 60 s
    tant que l'onglet est visible (« en ligne » = signal reçu il y a moins de 2 minutes)."""
    allow_password_change_required = True

    def post(self, request):
        signaler_presence(request, request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(generics.RetrieveUpdateAPIView):
    """Profil de l'utilisateur connecté : lecture, et modification de nom, prénoms, téléphone."""
    allow_password_change_required = True
    http_method_names = ['get', 'patch', 'head', 'options']

    def get_serializer_class(self):
        return MonProfilSerializer if self.request.method == 'PATCH' else UtilisateurSerializer

    def get_object(self):
        return self.request.user

    def partial_update(self, request, *args, **kwargs):
        user = self.get_object()
        if user.doit_changer_mdp:
            raise PermissionDenied(
                'Vous devez changer votre mot de passe avant de modifier votre profil.',
                code='password_change_required',
            )
        avant = {'nom': user.nom, 'prenoms': user.prenoms, 'telephone': user.telephone}
        serializer = MonProfilSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=user.id, action='UPDATE', table_cible='utilisateurs',
            enregistrement_id=user.id, ip_adresse=ip, user_agent=ua,
            anciennes_valeurs={k: v for k, v in avant.items() if k in serializer.validated_data},
            nouvelles_valeurs=dict(serializer.validated_data),
        )
        return Response(UtilisateurSerializer(user, context={'request': request}).data)


class MaPhotoView(APIView):
    """POST /api/accounts/me/photo/ : ajoute ou remplace sa propre photo de profil."""
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        from traceability.services import enregistrer_photo

        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Aucune image reçue.'})
        enregistrer_photo(fichier, 'utilisateurs', request.user.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='UPDATE_PHOTO', table_cible='utilisateurs',
            enregistrement_id=request.user.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(UtilisateurSerializer(request.user, context={'request': request}).data)
