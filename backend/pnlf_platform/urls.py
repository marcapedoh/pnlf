from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AnnuaireView,
    AppareilSyncViewSet,
    ConversationViewSet,
    DashboardView,
    ExportLotsView,
    NotificationViewSet,
    OffreDemandeViewSet,
    SyncConflictViewSet,
    SyncPullView,
    SyncPushView,
)

router = DefaultRouter()
router.register('notifications', NotificationViewSet, basename='notification')
router.register('offres-demandes', OffreDemandeViewSet, basename='offre-demande')
router.register('conversations', ConversationViewSet, basename='conversation')
router.register('appareils-sync', AppareilSyncViewSet, basename='appareil-sync')
router.register('sync-conflicts', SyncConflictViewSet, basename='sync-conflict')

urlpatterns = [
    path('dashboard/stats/', DashboardView.as_view(), name='dashboard-stats'),
    path('exports/lots/', ExportLotsView.as_view(), name='export-lots'),
    path('sync/push/', SyncPushView.as_view(), name='sync-push'),
    path('sync/pull/', SyncPullView.as_view(), name='sync-pull'),
    path('annuaire/', AnnuaireView.as_view(), name='annuaire'),
    path('', include(router.urls)),
]
