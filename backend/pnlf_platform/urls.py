from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AnnuaireView,
    AppareilSyncViewSet,
    ConversationViewSet,
    DashboardResumeView,
    DashboardView,
    ExportDownloadView,
    ExportJournalTicketView,
    ExportJournalView,
    ExportLotsTicketView,
    ExportLotsView,
    InboxValidationView,
    JournalDetailView,
    JournalPeriodesView,
    NotificationViewSet,
    OffreDemandeViewSet,
    PublicContactOffreView,
    PublicOffreDemandeDetailView,
    PublicOffresDemandesListView,
    SyncConflictViewSet,
    SyncPullView,
    SyncPushView,
)
from .moderation_images_views import ModerationImageViewSet
from .views_rapports import (
    ExportRapportView,
    PublicVisiteView,
    RapportConnexionsListeView,
    RapportConnexionsView,
    RapportEnLigneView,
    RapportFiliereView,
    RapportInscriptionsView,
)

router = DefaultRouter()
router.register('notifications', NotificationViewSet, basename='notification')
router.register('offres-demandes', OffreDemandeViewSet, basename='offre-demande')
router.register('conversations', ConversationViewSet, basename='conversation')
router.register('appareils-sync', AppareilSyncViewSet, basename='appareil-sync')
router.register('sync-conflicts', SyncConflictViewSet, basename='sync-conflict')
router.register('moderation-images', ModerationImageViewSet, basename='moderation-image')

urlpatterns = [
    path('dashboard/stats/', DashboardView.as_view(), name='dashboard-stats'),
    path('dashboard/a-traiter/', InboxValidationView.as_view(), name='dashboard-a-traiter'),
    path('dashboard/resume/', DashboardResumeView.as_view(), name='dashboard-resume'),
    path('rapports/connexions/', RapportConnexionsView.as_view(), name='rapport-connexions'),
    path('rapports/connexions/liste/', RapportConnexionsListeView.as_view(), name='rapport-connexions-liste'),
    path('rapports/en-ligne/', RapportEnLigneView.as_view(), name='rapport-en-ligne'),
    path('rapports/inscriptions/', RapportInscriptionsView.as_view(), name='rapport-inscriptions'),
    path('rapports/filiere/', RapportFiliereView.as_view(), name='rapport-filiere'),
    path('exports/rapports/<slug:rapport>/', ExportRapportView.as_view(), name='export-rapport'),
    path('public/visite/', PublicVisiteView.as_view(), name='public-visite'),
    path('exports/lots/', ExportLotsView.as_view(), name='export-lots'),
    path('exports/lots/ticket/', ExportLotsTicketView.as_view(), name='export-lots-ticket'),
    path('exports/journal/ticket/', ExportJournalTicketView.as_view(), name='export-journal-ticket'),
    path('exports/download/', ExportDownloadView.as_view(), name='export-download'),
    path('rapports/journal/', JournalPeriodesView.as_view(), name='journal-periodes'),
    path('rapports/journal/detail/', JournalDetailView.as_view(), name='journal-detail'),
    path('exports/journal/', ExportJournalView.as_view(), name='export-journal'),
    path('sync/push/', SyncPushView.as_view(), name='sync-push'),
    path('sync/pull/', SyncPullView.as_view(), name='sync-pull'),
    path('annuaire/', AnnuaireView.as_view(), name='annuaire'),
    path('public/offres-demandes/', PublicOffresDemandesListView.as_view(), name='public-offres-demandes'),
    path('public/offres-demandes/<uuid:pk>/', PublicOffreDemandeDetailView.as_view(), name='public-offre-demande-detail'),
    path('public/offres-demandes/<uuid:pk>/contact/', PublicContactOffreView.as_view(), name='public-offre-contact'),
    path('', include(router.urls)),
]
