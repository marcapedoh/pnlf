from django.contrib.auth.backends import BaseBackend

from .models import Utilisateur


class PnlfAuthBackend(BaseBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        email = kwargs.get('email') or username
        if not email or password is None:
            return None
        try:
            user = Utilisateur.objects.get(email__iexact=email, deleted_at__isnull=True)
        except Utilisateur.DoesNotExist:
            return None
        if user.statut != Utilisateur.Statut.ACTIF:
            return None
        if not user.check_password(password):
            return None
        return user

    def get_user(self, user_id):
        try:
            return Utilisateur.objects.get(pk=user_id, deleted_at__isnull=True)
        except Utilisateur.DoesNotExist:
            return None
