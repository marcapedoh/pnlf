from rest_framework import serializers

from pnlf_platform.models import (
    AppareilSync,
    Conversation,
    Message,
    Notification,
    OffreDemande,
    SyncConflict,
)


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            'id', 'type_notif', 'titre', 'corps', 'lue',
            'envoyee_at', 'metadata', 'created_at',
        )
        read_only_fields = ('id', 'type_notif', 'titre', 'corps', 'envoyee_at', 'metadata', 'created_at')


class OffreDemandeSerializer(serializers.ModelSerializer):
    produit_nom = serializers.SerializerMethodField()
    province_nom = serializers.SerializerMethodField()
    auteur_nom = serializers.SerializerMethodField()
    photos_urls = serializers.SerializerMethodField()
    qr_image_url = serializers.SerializerMethodField()
    uuid_public = serializers.SerializerMethodField()

    class Meta:
        model = OffreDemande
        fields = (
            'id', 'type_annonce', 'auteur_id', 'auteur_nom', 'produit_id', 'produit_nom',
            'province_id', 'province_nom', 'quantite', 'unite', 'prix_unitaire', 'devise',
            'titre', 'description', 'certification_requise', 'statut', 'expire_at',
            'uuid_public', 'photos_urls', 'qr_image_url', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'auteur_id', 'statut', 'uuid_public', 'created_at', 'updated_at',
        )

    def validate_quantite(self, valeur):
        from config.validators import valider_quantite_positive
        return valider_quantite_positive(valeur)

    def validate_prix_unitaire(self, valeur):
        from config.validators import valider_montant_positif
        return valider_montant_positif(valeur, 'Le prix unitaire ne peut pas être négatif.')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        from pnlf_platform.offre_statut import read_statut
        data['statut'] = read_statut(instance)
        return data

    def get_produit_nom(self, obj):
        from traceability.models import Produit
        p = Produit.objects.filter(pk=obj.produit_id).first()
        return p.nom if p else None

    def get_province_nom(self, obj):
        if not obj.province_id:
            return None
        from traceability.models import Province
        p = Province.objects.filter(pk=obj.province_id).first()
        return p.nom if p else None

    def get_auteur_nom(self, obj):
        from accounts.models import Utilisateur
        u = Utilisateur.objects.filter(pk=obj.auteur_id).first()
        return f'{u.prenoms} {u.nom}'.strip() if u else None

    def get_photos_urls(self, obj):
        from traceability.services import photo_url
        request = self.context.get('request')
        urls = []
        for i in (1, 2):
            url = photo_url('offres', obj.id, request, suffixe=f'_{i}')
            if url:
                urls.append(url)
        return urls

    def get_qr_image_url(self, obj):
        from traceability.db_utils import get_optional_column
        from config.media_views import build_media_url

        path = get_optional_column('offres_demandes', 'qr_image_path', obj.id)
        if not path:
            return None
        return build_media_url(path, self.context.get('request'))

    def get_uuid_public(self, obj):
        from traceability.db_utils import get_optional_column
        value = get_optional_column('offres_demandes', 'uuid_public', obj.id)
        return str(value) if value else None


class ConversationSerializer(serializers.ModelSerializer):
    destinataire_id = serializers.UUIDField(write_only=True, required=False)
    producteur_id = serializers.SerializerMethodField()
    cooperative_id = serializers.SerializerMethodField()
    est_groupe = serializers.SerializerMethodField()
    participants = serializers.SerializerMethodField()
    interlocuteur_nom = serializers.SerializerMethodField()
    interlocuteur_photo_url = serializers.SerializerMethodField()
    dernier_message = serializers.SerializerMethodField()
    dernier_at = serializers.DateTimeField(read_only=True, required=False)
    non_lus = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = (
            'id', 'sujet', 'offre_id', 'producteur_id', 'cooperative_id', 'est_groupe',
            'destinataire_id', 'created_at', 'participants', 'interlocuteur_nom',
            'interlocuteur_photo_url', 'dernier_message', 'dernier_at', 'non_lus',
        )
        read_only_fields = ('created_at',)
        extra_kwargs = {
            'offre_id': {'required': False, 'allow_null': True},
        }

    def _context_row(self, obj):
        cache = self.context.get('_ctx_by_conv') or {}
        return cache.get(str(obj.id))

    def get_producteur_id(self, obj):
        ctx = self._context_row(obj)
        return str(ctx.producteur_id) if ctx and ctx.producteur_id else None

    def get_cooperative_id(self, obj):
        ctx = self._context_row(obj)
        return str(ctx.cooperative_id) if ctx and ctx.cooperative_id else None

    def get_est_groupe(self, obj):
        ctx = self._context_row(obj)
        return bool(ctx and getattr(ctx, 'est_groupe', False))

    def get_participants(self, obj):
        cache = self.context.setdefault('_users_by_id', {})
        photos = self.context.get('_photos_by_user') or {}
        rows = []
        for p in obj.participants.all():
            uid = str(p.utilisateur_id)
            user = cache.get(uid)
            if user is None:
                continue
            rows.append({
                'id': uid,
                'nom': f'{user.prenoms} {user.nom}'.strip(),
                'role': user.role,
                'photo_url': photos.get(uid),
            })
        return rows

    def get_interlocuteur_nom(self, obj):
        request = self.context.get('request')
        me = str(getattr(getattr(request, 'user', None), 'id', '') or '')
        if self.get_est_groupe(obj):
            return obj.sujet or 'Groupe coopérative'
        names = [p['nom'] for p in self.get_participants(obj) if p['id'] != me]
        if names:
            return ', '.join(names)
        return obj.sujet or 'Discussion'

    def get_interlocuteur_photo_url(self, obj):
        request = self.context.get('request')
        me = str(getattr(getattr(request, 'user', None), 'id', '') or '')
        photos = self.context.get('_photos_by_user') or {}
        if self.get_est_groupe(obj):
            return None
        for p in self.get_participants(obj):
            if p['id'] != me:
                return photos.get(p['id']) or p.get('photo_url')
        return None

    def get_dernier_message(self, obj):
        from pnlf_platform.chat import PLACEHOLDER_AUDIO, PLACEHOLDER_PHOTO
        preview = getattr(obj, 'dernier_contenu', None)
        if preview == PLACEHOLDER_PHOTO:
            return 'Photo'
        if preview == PLACEHOLDER_AUDIO:
            return 'Message vocal'
        if preview:
            return preview[:160]
        return None

    def get_non_lus(self, obj):
        counts = self.context.get('_unread_by_conv') or {}
        return int(counts.get(str(obj.id), 0))


class MessageSerializer(serializers.ModelSerializer):
    piece_url = serializers.SerializerMethodField()
    piece_type = serializers.SerializerMethodField()
    contenu = serializers.SerializerMethodField()
    expediteur_nom = serializers.SerializerMethodField()
    expediteur_photo_url = serializers.SerializerMethodField()
    statut = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = (
            'id', 'conversation', 'expediteur_id', 'expediteur_nom', 'expediteur_photo_url',
            'contenu', 'piece_type', 'piece_url', 'statut', 'lu_at', 'created_at',
        )
        read_only_fields = ('expediteur_id', 'lu_at', 'created_at', 'piece_type')

    def _piece(self, obj):
        cache = self.context.get('_pieces_by_msg') or {}
        return cache.get(str(obj.id))

    def get_piece_type(self, obj):
        piece = self._piece(obj)
        return piece.piece_type if piece else None

    def get_piece_url(self, obj):
        from pnlf_platform.chat import piece_url
        piece = self._piece(obj)
        return piece_url(piece.piece_path, self.context.get('request')) if piece else None

    def get_contenu(self, obj):
        from pnlf_platform.chat import PLACEHOLDERS
        if obj.contenu in PLACEHOLDERS:
            return None
        return obj.contenu

    def get_expediteur_nom(self, obj):
        cache = self.context.setdefault('_users_by_id', {})
        user = cache.get(str(obj.expediteur_id))
        if not user:
            return None
        return f'{user.prenoms} {user.nom}'.strip()

    def get_expediteur_photo_url(self, obj):
        photos = self.context.get('_photos_by_user') or {}
        return photos.get(str(obj.expediteur_id))

    def get_statut(self, obj):
        """Statut WhatsApp pour les messages de l'utilisateur courant uniquement."""
        from pnlf_platform.chat import statut_message_pour
        request = self.context.get('request')
        me = getattr(getattr(request, 'user', None), 'id', None)
        if not me or str(obj.expediteur_id) != str(me):
            return None
        reads = self.context.get('_other_reads_by_conv') or {}
        other_reads = reads.get(str(obj.conversation_id), [])
        return statut_message_pour(obj.created_at, other_reads)


class AppareilSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppareilSync
        fields = ('id', 'device_id', 'libelle', 'dernier_sync_at', 'actif', 'created_at')
        read_only_fields = ('dernier_sync_at', 'created_at')


class SyncConflictSerializer(serializers.ModelSerializer):
    class Meta:
        model = SyncConflict
        fields = (
            'id', 'appareil_id', 'entite', 'client_uuid',
            'payload_client', 'payload_serveur', 'resolu', 'resolution',
            'created_at', 'resolved_at',
        )


class SyncPushSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=120)
    libelle = serializers.CharField(required=False, allow_blank=True, max_length=120)
    producteurs = serializers.ListField(child=serializers.DictField(), required=False, default=list, max_length=200)
    lots = serializers.ListField(child=serializers.DictField(), required=False, default=list, max_length=200)

    def _nettoyer_entites(self, items):
        cleaned = []
        for item in items:
            if not isinstance(item, dict):
                continue
            cleaned.append({
                'client_uuid': item.get('client_uuid'),
                'sync_version': item.get('sync_version', 0),
                'nom': item.get('nom'),
            })
        return cleaned

    def validate_producteurs(self, value):
        return self._nettoyer_entites(value)

    def validate_lots(self, value):
        return self._nettoyer_entites(value)
