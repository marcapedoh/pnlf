from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .inscription_views import PublicInscriptionView
from .public_views import (
    MessagePublicViewSet,
    PublicContactProducteurView,
    PublicDepartementsListView,
    PublicLotDetailView,
    PublicProducteurDetailView,
    PublicProducteursListView,
    PublicProduitsListView,
    PublicProvincesListView,
    PublicStatsView,
    PublicVillagesListView,
)
from .views import (
    CertificationViewSet,
    CategorieProduitViewSet,
    CooperativeViewSet,
    DepartementViewSet,
    LotViewSet,
    LotVerifyView,
    MouvementViewSet,
    ProducteurViewSet,
    ProduitViewSet,
    ProvinceViewSet,
    TypeCertificationViewSet,
    VillageViewSet,
    ZoneCollecteViewSet,
)

router = DefaultRouter()
router.register('provinces', ProvinceViewSet, basename='province')
router.register('departements', DepartementViewSet, basename='departement')
router.register('villages', VillageViewSet, basename='village')
router.register('categories-produits', CategorieProduitViewSet, basename='categorie-produit')
router.register('produits', ProduitViewSet, basename='produit')
router.register('cooperatives', CooperativeViewSet, basename='cooperative')
router.register('zones-collecte', ZoneCollecteViewSet, basename='zone-collecte')
router.register('producteurs', ProducteurViewSet, basename='producteur')
router.register('lots', LotViewSet, basename='lot')
router.register('mouvements', MouvementViewSet, basename='mouvement')
router.register('types-certification', TypeCertificationViewSet, basename='type-certification')
router.register('certifications', CertificationViewSet, basename='certification')
router.register('messages-publics', MessagePublicViewSet, basename='message-public')

urlpatterns = [
    path('verify/<uuid:uuid_public>/', LotVerifyView.as_view(), name='lot-verify'),
    # Vitrine publique (sans authentification)
    path('public/stats/', PublicStatsView.as_view(), name='public-stats'),
    path('public/provinces/', PublicProvincesListView.as_view(), name='public-provinces'),
    path('public/departements/', PublicDepartementsListView.as_view(), name='public-departements'),
    path('public/villages/', PublicVillagesListView.as_view(), name='public-villages'),
    path('public/inscription/', PublicInscriptionView.as_view(), name='public-inscription'),
    path('public/produits/', PublicProduitsListView.as_view(), name='public-produits'),
    path('public/producteurs/', PublicProducteursListView.as_view(), name='public-producteurs'),
    path('public/producteurs/<uuid:pk>/', PublicProducteurDetailView.as_view(), name='public-producteur-detail'),
    path('public/lots/<uuid:pk>/', PublicLotDetailView.as_view(), name='public-lot-detail'),
    path(
        'public/producteurs/<uuid:producteur_id>/contact/',
        PublicContactProducteurView.as_view(),
        name='public-contact-producteur',
    ),
    path('', include(router.urls)),
]