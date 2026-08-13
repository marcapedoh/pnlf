from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import Utilisateur
from accounts.audit import request_meta, write_audit
from accounts.permissions import CanUseMarketplace, CanViewDashboard
from pnlf_platform.models import (
    AppareilSync,
    Conversation,
    ConversationParticipant,
    Message,
    Notification,
    OffreDemande,
    SyncConflict,
)
from pnlf_platform.serializers import (
    AppareilSyncSerializer,
    ConversationSerializer,
    MessageSerializer,
    NotificationSerializer,
    OffreDemandeSerializer,
    SyncConflictSerializer,
    SyncPushSerializer,
)
from pnlf_platform.services import (
    creer_notification,
    dashboard_stats,
    export_lots_csv,
    export_lots_pdf,
    export_lots_xlsx,
)
from traceability.models import Lot, Producteur


class DashboardView(APIView):
    permission_classes = [CanViewDashboard]

    def get(self, request):
        data = dashboard_stats(
            province_id=request.query_params.get('province'),
            produit_id=request.query_params.get('produit'),
            date_debut=request.query_params.get('date_debut'),
            date_fin=request.query_params.get('date_fin'),
        )
        return Response(data)


class ExportLotsView(APIView):
    permission_classes = [CanViewDashboard]

    def get(self, request):
        from accounts.permissions import scope_lots_qs
        qs = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
        fmt = request.query_params.get('export_format', 'csv').lower()
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='lots',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': fmt},
        )
        if fmt == 'xlsx':
            return export_lots_xlsx(qs)
        if fmt == 'pdf':
            return export_lots_pdf(qs)
        return export_lots_csv(qs)


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    http_method_names = ['get', 'patch', 'head', 'options']

    def get_queryset(self):
        return Notification.objects.filter(destinataire_id=self.request.user.id)

    @action(detail=True, methods=['post'])
    def lire(self, request, pk=None):
        n = self.get_object()
        n.lue = True
        n.save(update_fields=['lue'])
        return Response(NotificationSerializer(n).data)

    @action(detail=False, methods=['post'], url_path='lire-tout')
    def lire_tout(self, request):
        Notification.objects.filter(destinataire_id=request.user.id, lue=False).update(lue=True)
        return Response({'detail': 'OK'})


class OffreDemandeViewSet(viewsets.ModelViewSet):
    permission_classes = [CanUseMarketplace]
    serializer_class = OffreDemandeSerializer
    filterset_fields = ('type_annonce', 'produit_id', 'province_id', 'statut')
    search_fields = ('titre', 'description')

    def get_queryset(self):
        return OffreDemande.objects.filter(statut='OUVERTE').order_by('-created_at')

    def perform_create(self, serializer):
        if self.request.user.role == Utilisateur.Role.ACHETEUR and serializer.validated_data.get('type_annonce') == 'OFFRE':
            pass
        now = timezone.now()
        serializer.save(auteur_id=self.request.user.id, created_at=now, updated_at=now)

    def perform_update(self, serializer):
        obj = self.get_object()
        if obj.auteur_id != self.request.user.id and self.request.user.role != Utilisateur.Role.ADMINISTRATEUR:
            raise PermissionDenied()
        serializer.save(updated_at=timezone.now())


class ConversationViewSet(viewsets.ModelViewSet):
    permission_classes = [CanUseMarketplace]
    serializer_class = ConversationSerializer
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        conv_ids = ConversationParticipant.objects.filter(
            utilisateur_id=self.request.user.id
        ).values_list('conversation_id', flat=True)
        return Conversation.objects.filter(id__in=conv_ids)

    def perform_create(self, serializer):
        now = timezone.now()
        conv = serializer.save(created_at=now)
        ConversationParticipant.objects.create(
            conversation=conv, utilisateur_id=self.request.user.id, joined_at=now,
        )
        autres = self.request.data.get('participants', [])
        for uid in autres:
            if str(uid) != str(self.request.user.id):
                ConversationParticipant.objects.get_or_create(
                    conversation=conv, utilisateur_id=uid,
                    defaults={'joined_at': now},
                )

    @action(detail=True, methods=['get', 'post'], url_path='messages')
    def messages(self, request, pk=None):
        conv = self.get_object()
        if request.method == 'GET':
            msgs = Message.objects.filter(conversation=conv)
            return Response(MessageSerializer(msgs, many=True).data)
        contenu = request.data.get('contenu', '').strip()
        if not contenu:
            return Response({'contenu': 'Requis.'}, status=400)
        now = timezone.now()
        msg = Message.objects.create(
            conversation=conv, expediteur_id=request.user.id,
            contenu=contenu, created_at=now,
        )
        for p in ConversationParticipant.objects.filter(conversation=conv).exclude(utilisateur_id=request.user.id):
            creer_notification(
                p.utilisateur_id, f'Message: {conv.sujet or "Conversation"}', contenu[:200],
            )
        return Response(MessageSerializer(msg).data, status=status.HTTP_201_CREATED)


class AppareilSyncViewSet(viewsets.ModelViewSet):
    serializer_class = AppareilSyncSerializer
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        return AppareilSync.objects.filter(utilisateur_id=self.request.user.id, actif=True)

    def perform_create(self, serializer):
        serializer.save(utilisateur_id=self.request.user.id, created_at=timezone.now())


class SyncPushView(APIView):
    """Push offline — lots et producteurs par client_uuid."""

    def post(self, request):
        ser = SyncPushSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        device_id = ser.validated_data['device_id']
        now = timezone.now()
        appareil, _ = AppareilSync.objects.update_or_create(
            utilisateur_id=request.user.id, device_id=device_id,
            defaults={'libelle': ser.validated_data.get('libelle'), 'actif': True, 'created_at': now},
        )
        synced = {'producteurs': 0, 'lots': 0, 'conflits': 0}
        for item in ser.validated_data.get('producteurs', []):
            client_uuid = item.get('client_uuid')
            if not client_uuid:
                continue
            existing = Producteur.objects.filter(client_uuid=client_uuid).first()
            if existing and existing.sync_version > item.get('sync_version', 0):
                SyncConflict.objects.create(
                    appareil_id=appareil.id, entite='producteurs', client_uuid=client_uuid,
                    payload_client=item, payload_serveur={'id': str(existing.id)},
                    created_at=now,
                )
                synced['conflits'] += 1
                continue
            if existing:
                Producteur.objects.filter(pk=existing.pk).update(
                    nom=item.get('nom', existing.nom),
                    updated_at=now, sync_statut='SYNCED',
                )
            synced['producteurs'] += 1
        appareil.dernier_sync_at = now
        appareil.save(update_fields=['dernier_sync_at'])
        return Response({'synced': synced, 'server_time': now.isoformat()})


class SyncPullView(APIView):
    def get(self, request):
        since = request.query_params.get('since')
        from accounts.permissions import scope_lots_qs, scope_producteurs_qs
        prods = scope_producteurs_qs(Producteur.objects.filter(deleted_at__isnull=True), request.user)
        lots = scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), request.user)
        if since:
            prods = prods.filter(updated_at__gt=since)
            lots = lots.filter(updated_at__gt=since)
        return Response({
            'producteurs': list(prods.values('id', 'code_producteur', 'nom', 'statut', 'client_uuid', 'updated_at')[:200]),
            'lots': list(lots.values('id', 'code_lot', 'statut', 'client_uuid', 'updated_at')[:200]),
        })


class SyncConflictViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SyncConflictSerializer

    def get_queryset(self):
        if self.request.user.role not in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            return SyncConflict.objects.none()
        return SyncConflict.objects.filter(resolu=False).order_by('-created_at')

    @action(detail=True, methods=['post'])
    def resoudre(self, request, pk=None):
        if self.request.user.role not in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            raise PermissionDenied()
        c = self.get_object()
        c.resolu = True
        c.resolution = request.data.get('resolution', '')
        c.resolved_at = timezone.now()
        c.save(update_fields=['resolu', 'resolution', 'resolved_at'])
        return Response(SyncConflictSerializer(c).data)


class AnnuaireView(APIView):
    """Annuaire producteurs / coopératives — module 6.9."""
    permission_classes = [CanUseMarketplace]

    def get(self, request):
        from traceability.models import Cooperative
        from traceability.serializers import CooperativeSerializer, ProducteurSerializer
        from accounts.permissions import scope_producteurs_qs

        qs_prod = scope_producteurs_qs(
            Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF'), request.user
        )
        produit = request.query_params.get('produit')
        province = request.query_params.get('province')
        if province:
            qs_prod = qs_prod.filter(province_id=province)
        # Filtre produit via lots déclarés (annuaire simplifié)
        if produit:
            qs_prod = qs_prod.filter(id__in=Lot.objects.filter(produit_id=produit).values('producteur_id'))

        coops = Cooperative.objects.filter(actif=True)
        if province:
            coops = coops.filter(province_id=province)

        return Response({
            'producteurs': ProducteurSerializer(qs_prod[:100], many=True).data,
            'cooperatives': CooperativeSerializer(coops[:50], many=True).data,
        })
