from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import MaPhotoView, MeView
from .views_users import (
    ChangePasswordView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    UtilisateurViewSet,
)

router = DefaultRouter()
router.register('utilisateurs', UtilisateurViewSet, basename='utilisateur')

urlpatterns = [
    path('me/', MeView.as_view(), name='me'),
    path('me/photo/', MaPhotoView.as_view(), name='me-photo'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('', include(router.urls)),
]
