from django.http import FileResponse, Http404
from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.audit import request_meta, write_audit
from accounts.models import Utilisateur
from accounts.permissions import (
    CanManageCertifications,
    CanManageCooperatives,
    CanManageLots,
    CanManageProducteurs,
    CanManageReferentiel,
    CanManageZones,
    CanReadGeo,
    CanValidateProducteurs,
    scope_lots_qs,
    scope_mouvements_qs,
    scope_producteurs_qs,
    user_can_access_lot,
    user_can_access_producteur,
)

from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
    Lot,
    Mouvement,
    Producteur,
    Produit,
    Province,
    TypeCertification,
    Village,
    ZoneCollecte,
)
from .serializers import (
    CategorieProduitSerializer,
    CertificationSerializer,
    CooperativeMembreSerializer,
    CooperativeSerializer,
    DepartementSerializer,
    LotSerializer,
    LotVerifySerializer,
    MouvementSerializer,
    ProducteurSerializer,
    ProduitSerializer,
    ProvinceSerializer,
    TypeCertificationSerializer,
    VillageSerializer,
    ZoneCollecteSerializer,
)
from .services import (
    appliquer_mouvement_sur_lot,
    generer_qr_image,
    qr_image_bytes,
    transition_lot_statut,
    valider_type_mouvement,
)


def _user_id(user):
    return getattr(user, 'id', None)


class ProvinceViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Province.objects.filter(actif=True)
    serializer_class = ProvinceSerializer
    search_fields = ('nom', 'code')


class DepartementViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Departement.objects.filter(actif=True).select_related('province')
    serializer_class = DepartementSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('province',)


class VillageViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Village.objects.filter(actif=True).select_related('departement')
    serializer_class = VillageSerializer
    search_fields = ('nom',)
    filterset_fields = ('departement',)


class CategorieProduitViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = CategorieProduit.objects.filter(actif=True)
    serializer_class = CategorieProduitSerializer
    search_fields = ('libelle', 'code')


class ProduitViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = Produit.objects.filter(actif=True).select_related('categorie')
    serializer_class = ProduitSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('categorie', 'soumis_cites')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def perform_create(self, serializer):
        now = timezone.now()
        obj = serializer.save(created_at=now, updated_at=now)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='CREATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'code': obj.code},
        )

    def perform_update(self, serializer):
        obj = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='UPDATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua,
        )


class CooperativeViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCooperatives]
    serializer_class = CooperativeSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('province', 'actif')

    def get_queryset(self):
        qs = Cooperative.objects.filter(actif=True).select_related('province')
        user = self.request.user
        if user.role == Utilisateur.Role.COOPERATIVE:
            return qs.filter(utilisateur_id=user.id)
        return qs

    def perform_create(self, serializer):
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now}
        if self.request.user.role == Utilisateur.Role.COOPERATIVE:
            extra['utilisateur_id'] = self.request.user.id
        serializer.save(**extra)

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.COOPERATIVE and instance.utilisateur_id != user.id:
            raise PermissionDenied('Accès refusé.')
        serializer.save(updated_at=timezone.now())

    @action(detail=True, methods=['get', 'post'], url_path='membres')
    def membres(self, request, pk=None):
        coop = self.get_object()
        if request.method == 'GET':
            membres = CooperativeMembre.objects.filter(cooperative=coop, actif=True).select_related('producteur')
            return Response(CooperativeMembreSerializer(membres, many=True).data)
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied()
        ser = CooperativeMembreSerializer(data={**request.data, 'cooperative': str(coop.id)})
        ser.is_valid(raise_exception=True)
        now = timezone.now()
        obj, _ = CooperativeMembre.objects.update_or_create(
            cooperative=coop,
            producteur=ser.validated_data['producteur'],
            defaults={
                'date_adhesion': ser.validated_data.get('date_adhesion') or timezone.localdate(),
                'actif': True,
                'created_at': now,
            },
        )
        Producteur.objects.filter(pk=obj.producteur_id).update(cooperative=coop, updated_at=now)
        return Response(CooperativeMembreSerializer(obj).data, status=status.HTTP_201_CREATED)


class ZoneCollecteViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageZones]
    serializer_class = ZoneCollecteSerializer
    search_fields = ('libelle', 'code')
    filterset_fields = ('province', 'actif')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def get_queryset(self):
        return ZoneCollecte.objects.filter(actif=True).select_related('province')

    def perform_create(self, serializer):
        now = timezone.now()
        serializer.save(created_at=now, updated_at=now)

    def perform_update(self, serializer):
        serializer.save(updated_at=timezone.now())


class ProducteurViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageProducteurs]
    serializer_class = ProducteurSerializer
    search_fields = ('nom', 'prenoms', 'code_producteur', 'telephone')
    filterset_fields = ('province', 'statut', 'cooperative')

    def get_queryset(self):
        qs = Producteur.objects.filter(deleted_at__isnull=True).select_related('province')
        return scope_producteurs_qs(qs, self.request.user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if request.method not in ('GET', 'HEAD', 'OPTIONS') and not user_can_access_producteur(request.user, obj):
            raise PermissionDenied('Accès refusé à ce producteur.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now, 'sync_statut': 'SYNCED', 'statut': 'EN_VALIDATION'}
        if user.role == Utilisateur.Role.PRODUCTEUR:
            extra['utilisateur_id'] = user.id
        obj = serializer.save(**extra)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='producteurs',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'code_producteur': obj.code_producteur},
        )

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.PRODUCTEUR and instance.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre fiche.')
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        obj = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE', table_cible='producteurs',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
        )

    def perform_destroy(self, instance):
        user = self.request.user
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='SOFT_DELETE', table_cible='producteurs',
            enregistrement_id=instance.id, ip_adresse=ip, user_agent=ua,
        )

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def valider(self, request, pk=None):
        prod = self.get_object()
        now = timezone.now()
        prod.statut = 'ACTIF'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.updated_at = now
        prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def rejeter(self, request, pk=None):
        prod = self.get_object()
        now = timezone.now()
        prod.statut = 'REJETE'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.notes = request.data.get('motif') or prod.notes
        prod.updated_at = now
        prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'notes', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod).data)


class LotViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = LotSerializer
    search_fields = ('code_lot', 'uuid_public')
    filterset_fields = ('produit', 'producteur', 'statut', 'cooperative', 'zone_collecte')

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        qs = (
            Lot.objects.filter(deleted_at__isnull=True)
            .select_related('produit', 'producteur', 'producteur__province')
            .prefetch_related('mouvements')
        )
        return scope_lots_qs(qs, self.request.user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if request.method not in ('GET', 'HEAD', 'OPTIONS') and not user_can_access_lot(request.user, obj):
            raise PermissionDenied('Accès refusé à ce lot.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        producteur = serializer.validated_data.get('producteur')
        if user.role == Utilisateur.Role.PRODUCTEUR:
            if not producteur or producteur.utilisateur_id != user.id:
                raise PermissionDenied('Lot autorisé uniquement pour votre profil.')
        lot = serializer.save(
            created_at=now, updated_at=now, sync_statut='SYNCED',
            declare_par_id=user.id, code_lot='', statut='DECLARE',
        )
        lot.refresh_from_db()
        from .services import generer_qr_payload
        lot.qr_payload = generer_qr_payload(lot)
        lot.save(update_fields=['qr_payload'])
        generer_qr_image(lot)
        Mouvement.objects.create(
            lot=lot, type_mouvement='COLLECTE', date_mouvement=now,
            lieu_libelle='Déclaration initiale', quantite=lot.quantite, unite=lot.unite,
            latitude=lot.latitude, longitude=lot.longitude,
            acteur_utilisateur_id=user.id, acteur_producteur_id=lot.producteur_id,
            created_at=now, sync_statut='SYNCED',
        )
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'code_lot': lot.code_lot},
        )

    def perform_update(self, serializer):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        serializer.save(updated_at=timezone.now())

    def perform_destroy(self, instance):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])

    @action(detail=True, methods=['get'], url_path='tracabilite')
    def tracabilite(self, request, pk=None):
        lot = self.get_object()
        return Response(LotSerializer(lot, context={'request': request}).data)

    @action(detail=True, methods=['get'], url_path='qr')
    def qr(self, request, pk=None):
        lot = self.get_object()
        return FileResponse(
            __import__('io').BytesIO(qr_image_bytes(lot)),
            content_type='image/png',
            as_attachment=False,
            filename=f'{lot.code_lot}.png',
        )

    @action(detail=True, methods=['post'], url_path='changer-statut')
    def changer_statut(self, request, pk=None):
        lot = self.get_object()
        if request.user.role not in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            raise PermissionDenied()
        nouveau = request.data.get('statut')
        force = request.data.get('force', False)
        transition_lot_statut(lot, nouveau, force=bool(force))
        return Response(LotSerializer(lot, context={'request': request}).data)


class MouvementViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = MouvementSerializer
    http_method_names = ['get', 'post', 'head', 'options']
    filterset_fields = ('lot', 'type_mouvement')

    def get_queryset(self):
        qs = Mouvement.objects.select_related('lot', 'lot__producteur').filter(lot__deleted_at__isnull=True)
        return scope_mouvements_qs(qs, self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        lot = serializer.validated_data.get('lot')
        if lot is None:
            raise ValidationError({'lot': 'Lot obligatoire.'})
        if lot.deleted_at is not None:
            raise ValidationError({'lot': 'Lot archivé.'})
        if not user_can_access_lot(user, lot):
            raise PermissionDenied('Accès refusé à ce lot.')
        type_mvt = valider_type_mouvement(serializer.validated_data.get('type_mouvement'))
        now = timezone.now()
        obj = serializer.save(
            created_at=now, sync_statut='SYNCED', acteur_utilisateur_id=user.id,
            type_mouvement=type_mvt,
            date_mouvement=serializer.validated_data.get('date_mouvement') or now,
        )
        appliquer_mouvement_sur_lot(lot, type_mvt)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='mouvements',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'type_mouvement': type_mvt},
        )


class TypeCertificationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageCertifications]
    queryset = TypeCertification.objects.filter(actif=True)
    serializer_class = TypeCertificationSerializer
    search_fields = ('libelle', 'code')


class CertificationViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCertifications]
    serializer_class = CertificationSerializer
    filterset_fields = ('statut', 'lot', 'producteur', 'type_certification')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = Certification.objects.select_related('type_certification', 'lot', 'producteur')
        user = self.request.user
        if user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER):
            return qs
        if user.role == Utilisateur.Role.COOPERATIVE:
            from traceability.models import Cooperative
            coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            return qs.filter(lot__cooperative_id__in=coop_ids) | qs.filter(producteur__cooperative_id__in=coop_ids)
        if user.role == Utilisateur.Role.PRODUCTEUR:
            return qs.filter(producteur__utilisateur_id=user.id)
        return qs.none()

    def perform_create(self, serializer):
        now = timezone.now()
        serializer.save(created_at=now, updated_at=now, date_demande=timezone.localdate())

    def perform_update(self, serializer):
        serializer.save(updated_at=timezone.now())


class LotVerifyView(generics.RetrieveAPIView):
    """Vérification publique QR — sans authentification."""
    permission_classes = [AllowAny]
    serializer_class = LotVerifySerializer
    lookup_field = 'uuid_public'

    def get_queryset(self):
        return Lot.objects.filter(deleted_at__isnull=True).select_related(
            'produit', 'producteur', 'producteur__province'
        )

    def retrieve(self, request, *args, **kwargs):
        try:
            lot = self.get_object()
        except Http404:
            return Response({'detail': 'Lot introuvable ou invalide.'}, status=404)
        data = self.get_serializer(lot).data
        data['authenticite'] = 'VERIFIE'
        data['mouvements_count'] = lot.mouvements.count()
        return Response(data)
