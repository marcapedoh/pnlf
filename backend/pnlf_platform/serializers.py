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
        read_only_fields = fields


class OffreDemandeSerializer(serializers.ModelSerializer):
    class Meta:
        model = OffreDemande
        fields = (
            'id', 'type_annonce', 'auteur_id', 'produit_id', 'province_id',
            'quantite', 'unite', 'prix_unitaire', 'devise', 'titre', 'description',
            'certification_requise', 'statut', 'expire_at', 'created_at', 'updated_at',
        )
        read_only_fields = ('auteur_id', 'created_at', 'updated_at')


class ConversationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conversation
        fields = ('id', 'sujet', 'offre_id', 'created_at')
        read_only_fields = ('created_at',)


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ('id', 'conversation', 'expediteur_id', 'contenu', 'lu_at', 'created_at')
        read_only_fields = ('expediteur_id', 'lu_at', 'created_at')


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
    libelle = serializers.CharField(required=False, allow_blank=True)
    producteurs = serializers.ListField(child=serializers.DictField(), required=False, default=list)
    lots = serializers.ListField(child=serializers.DictField(), required=False, default=list)
