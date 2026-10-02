"""Login / refresh JWT avec cookie HttpOnly pour le refresh + empreinte mot de passe."""

from __future__ import annotations

from django.conf import settings
from rest_framework import generics, permissions, status, throttling
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .audit import request_meta, write_audit
from .serializers import PnlfTokenObtainPairSerializer, PnlfTokenRefreshSerializer, UtilisateurSerializer


class LoginRateThrottle(throttling.AnonRateThrottle):
    scope = 'login'


class RefreshRateThrottle(throttling.AnonRateThrottle):
    scope = 'login'


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


class PnlfTokenObtainPairView(TokenObtainPairView):
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
            refresh = response.data.pop('refresh', None)
            if refresh:
                set_refresh_cookie(response, refresh)
        return response


class PnlfTokenRefreshView(TokenRefreshView):
    """Refresh depuis cookie HttpOnly (prioritaire) ou corps JSON (compat)."""
    serializer_class = PnlfTokenRefreshSerializer
    permission_classes = [permissions.AllowAny]
    throttle_classes = [RefreshRateThrottle]

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


class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Pas de blacklist SimpleJWT (incompatible avec Utilisateur UUID).
        response = Response({'detail': 'Déconnexion effectuée.'})
        clear_refresh_cookie(response)
        return response


class MeView(generics.RetrieveAPIView):
    serializer_class = UtilisateurSerializer

    def get_object(self):
        return self.request.user
