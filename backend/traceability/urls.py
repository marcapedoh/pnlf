from django.urls import include, path
from rest_framework.routers import DefaultRouter

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

urlpatterns = [
    path('verify/<uuid:uuid_public>/', LotVerifyView.as_view(), name='lot-verify'),
    path('', include(router.urls)),
]
