from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, AuthenticationFailed

from .models import Utilisateur


class PnlfJWTAuthentication(JWTAuthentication):
    def get_user(self, validated_token):
        user_id = validated_token.get('user_id')
        if not user_id:
            raise InvalidToken('Jeton sans user_id')
        try:
            user = Utilisateur.objects.get(pk=user_id, deleted_at__isnull=True)
        except Utilisateur.DoesNotExist as exc:
            raise AuthenticationFailed('Utilisateur introuvable', code='user_not_found') from exc
        if not user.is_active:
            raise AuthenticationFailed('Compte inactif', code='user_inactive')
        return user
