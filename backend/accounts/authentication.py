from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, AuthenticationFailed

from .models import Utilisateur
from .token_utils import password_fingerprint

PASSWORD_CHANGE_REQUIRED_CODE = 'password_change_required'


class PasswordChangeRequired(PermissionDenied):
    default_code = PASSWORD_CHANGE_REQUIRED_CODE

    def __init__(self):
        super().__init__(detail={
            'detail': 'Vous devez changer votre mot de passe provisoire avant de continuer.',
            'code': PASSWORD_CHANGE_REQUIRED_CODE,
        })


def _vue_publique(view) -> bool:
    try:
        permissions = view.get_permissions()
    except Exception:
        return False
    return bool(permissions) and all(isinstance(p, AllowAny) for p in permissions)


def _verifier_changement_mdp(request, user) -> None:
    """Tant que ``doit_changer_mdp`` est vrai, seules les vues marquées
    ``allow_password_change_required`` (profil, changement de mot de passe, déconnexion,
    rafraîchissement) et les vues publiques restent accessibles."""
    if not getattr(user, 'doit_changer_mdp', False):
        return
    view = (getattr(request, 'parser_context', None) or {}).get('view')
    if view is None or getattr(view, 'allow_password_change_required', False) or _vue_publique(view):
        return
    raise PasswordChangeRequired()


class PnlfJWTAuthentication(JWTAuthentication):
    def authenticate(self, request):
        result = super().authenticate(request)
        if result is not None:
            _verifier_changement_mdp(request, result[0])
        return result

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
        if validated_token.get('pwd') != password_fingerprint(user):
            raise AuthenticationFailed('Session révoquée', code='password_changed')
        return user
