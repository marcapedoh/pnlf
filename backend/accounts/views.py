from rest_framework import generics, permissions, throttling
from rest_framework_simplejwt.views import TokenObtainPairView

from .audit import request_meta, write_audit
from .serializers import PnlfTokenObtainPairSerializer, UtilisateurSerializer


class LoginRateThrottle(throttling.AnonRateThrottle):
    scope = 'login'


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
        return response


class MeView(generics.RetrieveAPIView):
    serializer_class = UtilisateurSerializer

    def get_object(self):
        return self.request.user
