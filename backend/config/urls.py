from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.views import PnlfTokenObtainPairView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/login/', PnlfTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('traceability.urls')),
    path('api/', include('pnlf_platform.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Réponses JSON uniformes en production (DEBUG=False) pour les requêtes non
# prises en charge par un ViewSet DRF (URL inconnue, hôte invalide, erreur
# non interceptée). Voir config/error_views.py.
handler400 = 'config.error_views.bad_request'
handler403 = 'config.error_views.permission_denied'
handler404 = 'config.error_views.not_found'
handler500 = 'config.error_views.server_error'
