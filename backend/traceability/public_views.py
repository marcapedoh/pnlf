"""Vitrine publique — annuaire, fiche producteur, stats et contact (sans authentification)."""

import uuid

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Count, Q
from django.http import Http404
from django.utils import timezone
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.views import APIView

from accounts.audit import request_meta
from accounts.models import Utilisateur
from accounts.permissions import RolePermission

from .db_utils import column_exists, get_optional_column, table_exists
from .models import Certification, Cooperative, Departement, Lot, MessagePublic, Producteur, Produit, Province, Village
from .serializers import (
    MessagePublicSerializer,
    ProduitSerializer,
    PublicProducteurDetailSerializer,
    PublicProducteurSerializer,
)
from .services import photo_url as _photo_url_of
from .services import photos_urls_lot

# Statuts de lot jugés « présentables » au public dans les statistiques globales
# (on masque brouillons et lots annulés, mais on garde les lots commercialisés
# car ils représentent une traçabilité complète et réussie).
STATUTS_LOTS_PUBLICS = ('DECLARE', 'VALIDE', 'EN_TRANSIT', 'TRANSFORME', 'COMMERCIALISE')

# Statuts affichés dans la liste des lots d'un producteur consultée par un acheteur :
# un lot déjà commercialisé (vendu) n'a plus d'intérêt commercial et ne doit plus
# apparaître comme disponible à l'achat.
STATUTS_LOTS_DISPONIBLES = ('DECLARE', 'VALIDE', 'EN_TRANSIT', 'TRANSFORME')


def _producteurs_publics_qs():
    qs = Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF').select_related(
        'province', 'cooperative'
    )
    if column_exists('producteurs', 'visible_public'):
        qs = qs.extra(where=['COALESCE(visible_public, TRUE) = TRUE'])
    return qs


def _uuid_ou_none(valeur):
    try:
        return uuid.UUID(str(valeur))
    except (TypeError, ValueError, AttributeError):
        return None


def _lots_publics_qs():
    return Lot.objects.filter(deleted_at__isnull=True, statut__in=STATUTS_LOTS_PUBLICS)


def _gps_public(valeur):
    """Position arrondie (environ 1 km) : la parcelle exacte n'est pas diffusée publiquement."""
    return round(valeur, 2) if valeur is not None else None


def _produits_par_producteur(producteur_ids: list) -> dict:
    rows = (
        _lots_publics_qs().filter(producteur_id__in=producteur_ids)
        .values_list('producteur_id', 'produit__nom')
        .distinct()
    )
    out: dict = {}
    for pid, nom in rows:
        out.setdefault(pid, [])
        if nom and nom not in out[pid]:
            out[pid].append(nom)
    return out


def _nb_lots_par_producteur(producteur_ids: list) -> dict:
    rows = (
        _lots_publics_qs().filter(producteur_id__in=producteur_ids)
        .values('producteur_id')
        .annotate(n=Count('id'))
    )
    return {r['producteur_id']: r['n'] for r in rows}


def _lot_public_payload(lot, request=None) -> dict:
    labels = {
        'BROUILLON': 'Brouillon',
        'DECLARE': 'Déclaré',
        'VALIDE': 'Validé',
        'EN_TRANSIT': 'En transit',
        'TRANSFORME': 'Transformé',
        'COMMERCIALISE': 'Commercialisé',
        'ARCHIVE': 'Archivé',
        'ANNULE': 'Annulé',
    }
    mouvements = [
        {
            'type_libelle': {
                'COLLECTE': 'Collecte',
                'RECEPTION_COOPERATIVE': 'Réception coopérative',
                'TRANSFERT': 'Transfert',
                'TRANSFORMATION': 'Transformation',
                'CONTROLE': 'Contrôle',
                'VENTE': 'Vente',
                'EXPORT': 'Export',
                'AUTRE': 'Autre',
            }.get(m.type_mouvement, m.type_mouvement),
            'date_mouvement': m.date_mouvement,
            'lieu_libelle': m.lieu_libelle,
        }
        for m in lot.mouvements.all().order_by('date_mouvement', 'created_at')[:12]
    ] if hasattr(lot, 'mouvements') else []
    return {
        'id': str(lot.id),
        'code_lot': lot.code_lot,
        'uuid_public': str(lot.uuid_public) if lot.uuid_public else None,
        'produit_nom': lot.produit.nom,
        'quantite': lot.quantite,
        'unite': lot.unite,
        'qualite_indicateur': lot.qualite_indicateur,
        'prix_indicatif': lot.prix_indicatif,
        'devise': lot.devise,
        'date_collecte': lot.date_collecte,
        'statut': lot.statut,
        'statut_libelle': labels.get(lot.statut, lot.statut),
        'latitude': _gps_public(lot.latitude),
        'longitude': _gps_public(lot.longitude),
        'photos_urls': photos_urls_lot(lot.id, request),
        'mouvements': mouvements,
    }


def _lots_par_producteur(producteur_ids: list, request=None) -> dict:
    """Détail des lots disponibles présentés à l'acheteur : produit, quantité, prix, GPS et photos.

    Les lots déjà commercialisés (vendus) sont exclus : ils n'ont plus d'intérêt
    commercial pour un acheteur qui consulte la fiche du producteur.
    """
    rows = (
        Lot.objects.filter(
            producteur_id__in=producteur_ids, deleted_at__isnull=True, statut__in=STATUTS_LOTS_DISPONIBLES,
        )
        .select_related('produit')
        .order_by('-date_collecte')
    )
    out: dict = {}
    for lot in rows:
        out.setdefault(lot.producteur_id, [])
        out[lot.producteur_id].append(_lot_public_payload(lot, request))
    return out


def _certifications_par_producteur(producteur_ids: list) -> dict:
    rows = (
        Certification.objects.filter(producteur_id__in=producteur_ids, statut='OBTENUE')
        .exclude(date_expiration__lt=timezone.localdate())
        .select_related('type_certification')
        .values_list('producteur_id', 'type_certification__libelle')
    )
    out: dict = {}
    for pid, libelle in rows:
        out.setdefault(pid, [])
        if libelle and libelle not in out[pid]:
            out[pid].append(libelle)
    return out


from rest_framework.pagination import PageNumberPagination


class PublicListPagination(PageNumberPagination):
    page_size = 12
    page_size_query_param = 'page_size'
    max_page_size = 50


class PublicProducteursListView(generics.ListAPIView):
    """Annuaire public des producteurs/collecteurs actifs."""
    permission_classes = [AllowAny]
    serializer_class = PublicProducteurSerializer
    pagination_class = PublicListPagination

    def get_queryset(self):
        qs = _producteurs_publics_qs()
        province = self.request.query_params.get('province')
        type_acteur = self.request.query_params.get('type_acteur')
        produit = self.request.query_params.get('produit')
        recherche = (self.request.query_params.get('q') or '').strip()

        province_id = _uuid_ou_none(province) if province else None
        if province_id:
            qs = qs.filter(province_id=province_id)
        if type_acteur in ('PRODUCTEUR', 'COLLECTEUR') and column_exists('producteurs', 'type_acteur'):
            qs = qs.extra(where=["COALESCE(producteurs.type_acteur::text, 'PRODUCTEUR') = %s"], params=[type_acteur])
        if recherche:
            ids_par_produit = (
                _lots_publics_qs().filter(produit__nom__icontains=recherche)
                .values_list('producteur_id', flat=True)
            )
            qs = qs.filter(
                Q(nom__icontains=recherche)
                | Q(prenoms__icontains=recherche)
                | Q(communaute__icontains=recherche)
                | Q(id__in=ids_par_produit)
            )
        if produit:
            ids_avec_produit = (
                _lots_publics_qs().filter(produit__nom__icontains=produit)
                .values_list('producteur_id', flat=True)
                .distinct()
            )
            qs = qs.filter(id__in=ids_avec_produit)
        return qs.order_by('nom', 'prenoms')

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        producteurs = list(page) if page is not None else list(queryset)
        ids = [p.id for p in producteurs]
        context = {
            'request': request,
            'produits_par_producteur': _produits_par_producteur(ids),
            'nb_lots_par_producteur': _nb_lots_par_producteur(ids),
            'certifications_par_producteur': _certifications_par_producteur(ids),
        }
        data = self.get_serializer(producteurs, many=True, context=context).data
        if page is not None:
            return self.get_paginated_response(data)
        return Response({'count': len(data), 'results': data})


class PublicProducteurDetailView(generics.RetrieveAPIView):
    """Fiche publique d'un producteur/collecteur."""
    permission_classes = [AllowAny]
    serializer_class = PublicProducteurDetailSerializer
    queryset = Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF').select_related(
        'province', 'cooperative'
    )

    def retrieve(self, request, *args, **kwargs):
        try:
            prod = self.get_object()
        except Http404:
            return Response({'detail': 'Producteur introuvable.'}, status=404)
        if not get_optional_column('producteurs', 'visible_public', prod.id, default=True):
            return Response({'detail': 'Fiche non publique.'}, status=404)
        ids = [prod.id]
        context = {
            'request': request,
            'produits_par_producteur': _produits_par_producteur(ids),
            'nb_lots_par_producteur': _nb_lots_par_producteur(ids),
            'certifications_par_producteur': _certifications_par_producteur(ids),
            'lots_par_producteur': _lots_par_producteur(ids, request),
        }
        return Response(self.get_serializer(prod, context=context).data)


class PublicLotDetailView(APIView):
    """Fiche publique d'un lot précis (accessible depuis l'annuaire ou un lien direct)."""
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        try:
            lot = (
                Lot.objects.filter(
                    pk=pk, deleted_at__isnull=True, statut__in=STATUTS_LOTS_PUBLICS,
                )
                .select_related('produit', 'producteur', 'producteur__province', 'producteur__cooperative')
                .prefetch_related('mouvements')
                .get()
            )
        except (Lot.DoesNotExist, ValueError, TypeError, DjangoValidationError):
            return Response({'detail': 'Lot introuvable ou non disponible publiquement.'}, status=404)

        prod = lot.producteur
        if prod is None or prod.deleted_at is not None or prod.statut != 'ACTIF':
            return Response({'detail': 'Lot introuvable ou non disponible publiquement.'}, status=404)
        if not get_optional_column('producteurs', 'visible_public', prod.id, default=True):
            return Response({'detail': 'Lot introuvable ou non disponible publiquement.'}, status=404)

        payload = _lot_public_payload(lot, request)
        payload['producteur'] = {
            'id': str(prod.id),
            'nom': prod.nom,
            'prenoms': prod.prenoms,
            'type_acteur': get_optional_column('producteurs', 'type_acteur', prod.id, default='PRODUCTEUR'),
            'communaute': prod.communaute,
            'province_nom': prod.province.nom if prod.province_id else None,
            'cooperative_nom': prod.cooperative.nom if prod.cooperative_id else None,
            'photo_url': _photo_url_of('producteurs', prod.id, request),
        }
        return Response(payload)


class PublicProduitsListView(generics.ListAPIView):
    """Catalogue produits pour la vitrine."""
    permission_classes = [AllowAny]
    serializer_class = ProduitSerializer
    pagination_class = None
    queryset = Produit.objects.filter(actif=True).select_related('categorie').order_by('nom')


class PublicProvincesListView(generics.ListAPIView):
    """Provinces actives — filtres annuaire public."""
    permission_classes = [AllowAny]
    pagination_class = None

    def list(self, request, *args, **kwargs):
        rows = Province.objects.filter(actif=True).order_by('nom').values('id', 'nom', 'code')
        return Response(list(rows))


class PublicDepartementsListView(generics.ListAPIView):
    """Départements actifs d'une province — utilisé par le formulaire d'inscription publique."""
    permission_classes = [AllowAny]
    pagination_class = None

    def list(self, request, *args, **kwargs):
        qs = Departement.objects.filter(actif=True)
        province = request.query_params.get('province')
        if province:
            qs = qs.filter(province_id=_uuid_ou_none(province))
        rows = qs.order_by('nom').values('id', 'nom', 'code', 'province_id')
        return Response(list(rows))


class PublicVillagesListView(generics.ListAPIView):
    """Villages actifs d'un département — utilisé par le formulaire d'inscription publique."""
    permission_classes = [AllowAny]
    pagination_class = None

    def list(self, request, *args, **kwargs):
        qs = Village.objects.filter(actif=True)
        departement = request.query_params.get('departement')
        if departement:
            qs = qs.filter(departement_id=_uuid_ou_none(departement))
        rows = qs.order_by('nom').values('id', 'nom', 'departement_id')
        return Response(list(rows))


class PublicStatsView(APIView):
    """Chiffres clés pour la page d'accueil publique."""
    permission_classes = [AllowAny]

    def get(self, request):
        producteurs_qs = _producteurs_publics_qs()
        nb_collecteurs = 0
        if column_exists('producteurs', 'type_acteur'):
            nb_collecteurs = producteurs_qs.extra(where=["type_acteur = 'COLLECTEUR'"]).count()
        return Response({
            'nb_producteurs_actifs': producteurs_qs.count(),
            'nb_collecteurs': nb_collecteurs,
            'nb_lots_traces': Lot.objects.filter(
                deleted_at__isnull=True, statut__in=STATUTS_LOTS_PUBLICS,
            ).count(),
            'nb_produits': Produit.objects.filter(actif=True).count(),
            'nb_provinces': Province.objects.filter(actif=True).count(),
            'nb_cooperatives': Cooperative.objects.filter(actif=True).count(),
        })


class ContactPublicThrottle(AnonRateThrottle):
    scope = 'contact_public'


class PublicContactProducteurView(generics.CreateAPIView):
    """Formulaire de contact public (visiteur → producteur)."""
    permission_classes = [AllowAny]
    serializer_class = MessagePublicSerializer
    throttle_classes = [ContactPublicThrottle]

    def create(self, request, *args, **kwargs):
        if not table_exists('messages_publics'):
            return Response(
                {'detail': 'Fonctionnalité de contact indisponible pour le moment.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        if (request.data.get('site_web') or '').strip():
            return Response({'detail': 'Requête invalide.'}, status=400)
        producteur_id = kwargs.get('producteur_id') or request.data.get('producteur')
        try:
            producteur = Producteur.objects.get(pk=producteur_id, deleted_at__isnull=True, statut='ACTIF')
        except (Producteur.DoesNotExist, ValueError, TypeError, DjangoValidationError):
            return Response({'detail': 'Producteur introuvable.'}, status=404)

        if not get_optional_column('producteurs', 'visible_public', producteur.id, default=True):
            return Response({'detail': 'Ce producteur n\'accepte pas les contacts publics.'}, status=404)

        serializer = self.get_serializer(data={**request.data, 'producteur': str(producteur.id)})
        serializer.is_valid(raise_exception=True)
        ip, _ua = request_meta(request)
        obj = serializer.save(created_at=timezone.now(), ip_adresse=ip)
        self._notifier(producteur, obj)
        return Response(self.get_serializer(obj).data, status=status.HTTP_201_CREATED)

    @staticmethod
    def _notifier(producteur, message_public):
        from pnlf_platform.models import Notification

        destinataires = set()
        if producteur.utilisateur_id:
            destinataires.add(producteur.utilisateur_id)
        destinataires.update(
            Utilisateur.objects.filter(
                role__in=[Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE],
                statut=Utilisateur.Statut.ACTIF,
                deleted_at__isnull=True,
            ).values_list('id', flat=True)[:5]
        )
        now = timezone.now()
        for destinataire_id in destinataires:
            Notification.objects.create(
                destinataire_id=destinataire_id,
                type_notif='INTERNE',
                titre='Nouveau message public',
                corps=(
                    f'{message_public.nom_visiteur} souhaite contacter '
                    f'{producteur.prenoms} {producteur.nom} : {message_public.message[:180]}'
                ),
                metadata={
                    'producteur_id': str(producteur.id),
                    'message_public_id': str(message_public.id),
                },
                created_at=now,
            )


class MessagePublicViewSet(viewsets.ReadOnlyModelViewSet):
    """Boîte de réception des messages publics (producteur, coop, agents)."""

    class _CanManageMessagesPublics(RolePermission):
        read_roles = {
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
            Utilisateur.Role.PRODUCTEUR,
            Utilisateur.Role.COOPERATIVE,
        }
        write_roles = {
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
            Utilisateur.Role.PRODUCTEUR,
            Utilisateur.Role.COOPERATIVE,
        }

    permission_classes = [_CanManageMessagesPublics]
    serializer_class = MessagePublicSerializer
    filterset_fields = ('statut', 'producteur')

    def get_queryset(self):
        if not table_exists('messages_publics'):
            return MessagePublic.objects.none()
        qs = MessagePublic.objects.select_related('producteur')
        user = self.request.user
        role = getattr(user, 'role', None)
        if role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            return qs
        if role == Utilisateur.Role.PRODUCTEUR:
            return qs.filter(producteur__utilisateur_id=user.id, producteur__deleted_at__isnull=True)
        if role == Utilisateur.Role.COOPERATIVE:
            coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            return qs.filter(producteur__cooperative_id__in=coop_ids, producteur__deleted_at__isnull=True)
        return qs.none()

    @action(detail=True, methods=['post'])
    def marquer_traite(self, request, pk=None):
        message_public = self.get_object()
        message_public.statut = MessagePublic.Statut.TRAITE
        message_public.traite_at = timezone.now()
        message_public.save(update_fields=['statut', 'traite_at'])
        return Response(MessagePublicSerializer(message_public).data)
