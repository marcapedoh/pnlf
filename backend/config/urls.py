from django.contrib import admin
from django.urls import include, path

from accounts.views import LogoutView, PnlfTokenObtainPairView, PnlfTokenRefreshView
from config.media_views import AuthenticatedMediaView, PublicMediaView, SecureMediaView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/login/', PnlfTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', PnlfTokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/logout/', LogoutView.as_view(), name='token_logout'),
    path('api/accounts/', include('accounts.urls')),
    path('api/', include('traceability.urls')),
    path('api/', include('pnlf_platform.urls')),
    path('api/media/public/<path:relpath>', PublicMediaView.as_view(), name='media-public'),
    path('api/media/secure/<str:token>/', SecureMediaView.as_view(), name='media-secure'),
    path('api/media/auth/<path:relpath>', AuthenticatedMediaView.as_view(), name='media-auth'),
]

handler400 = 'config.error_views.bad_request'
handler403 = 'config.error_views.permission_denied'
handler404 = 'config.error_views.not_found'
handler500 = 'config.error_views.server_error'
