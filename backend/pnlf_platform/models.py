import uuid

from django.contrib.postgres.fields import ArrayField
from django.db import models


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    destinataire_id = models.UUIDField(db_column='destinataire_id')
    type_notif = models.CharField(max_length=20, default='INTERNE')
    titre = models.CharField(max_length=200)
    corps = models.TextField()
    lue = models.BooleanField(default=False)
    envoyee_at = models.DateTimeField(null=True, blank=True)
    erreur_envoi = models.TextField(null=True, blank=True)
    metadata = models.JSONField(default=dict)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'notifications'
        ordering = ['-created_at']


class OffreDemande(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_annonce = models.CharField(max_length=10)
    auteur_id = models.UUIDField()
    produit_id = models.UUIDField()
    province_id = models.UUIDField(null=True, blank=True)
    quantite = models.DecimalField(max_digits=14, decimal_places=3, null=True, blank=True)
    unite = models.CharField(max_length=20, null=True, blank=True)
    prix_unitaire = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    devise = models.CharField(max_length=3, default='XAF')
    titre = models.CharField(max_length=200)
    description = models.TextField(null=True, blank=True)
    certification_requise = models.BooleanField(default=False)
    statut = models.CharField(max_length=20, default='OUVERTE')
    expire_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'offres_demandes'
        ordering = ['-created_at']


class OffreDetails(models.Model):
    """Détails complémentaires d'une annonce (public.offres_details, évolution 16)."""

    offre = models.OneToOneField(
        OffreDemande, on_delete=models.DO_NOTHING, db_column='offre_id',
        primary_key=True, related_name='details',
    )
    categorie_id = models.UUIDField(null=True, blank=True)
    prix_total = models.DecimalField(max_digits=16, decimal_places=2, null=True, blank=True)
    negociable = models.BooleanField(default=False)
    conditionnement = models.CharField(max_length=150, null=True, blank=True)
    qualite = models.CharField(max_length=200, null=True, blank=True)
    localite = models.CharField(max_length=150, null=True, blank=True)
    disponible_du = models.DateField(null=True, blank=True)
    mode_remise = models.CharField(max_length=30, null=True, blank=True)
    modalites_livraison = models.TextField(null=True, blank=True)
    moyens_paiement = ArrayField(models.CharField(max_length=30), default=list, blank=True)
    conditions_paiement = models.TextField(null=True, blank=True)
    afficher_telephone = models.BooleanField(default=False)
    afficher_email = models.BooleanField(default=False)
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'offres_details'


class OffreModeration(models.Model):
    """Dernière décision de modération d'une annonce (public.offres_moderation, évolution 16)."""

    offre = models.OneToOneField(
        OffreDemande, on_delete=models.DO_NOTHING, db_column='offre_id',
        primary_key=True, related_name='moderation',
    )
    decision = models.CharField(max_length=20)
    moderateur_id = models.UUIDField(null=True, blank=True)
    moderateur_nom = models.CharField(max_length=260, null=True, blank=True)
    motif = models.TextField(null=True, blank=True)
    decide_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'offres_moderation'


class VisitePublique(models.Model):
    """Compteur anonyme agrégé des visites de pages publiques (public.visites_publiques, évolution 16)."""

    jour = models.DateField()
    page = models.CharField(max_length=120)
    appareil = models.CharField(max_length=20)
    visites = models.IntegerField(default=0)
    pk = models.CompositePrimaryKey('jour', 'page', 'appareil')

    class Meta:
        managed = False
        db_table = 'visites_publiques'


class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sujet = models.CharField(max_length=200, null=True, blank=True)
    offre_id = models.UUIDField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'conversations'
        ordering = ['-created_at']


class ConversationParticipant(models.Model):
    conversation = models.ForeignKey(
        Conversation, on_delete=models.DO_NOTHING, db_column='conversation_id', related_name='participants'
    )
    utilisateur_id = models.UUIDField()
    joined_at = models.DateTimeField()
    pk = models.CompositePrimaryKey('conversation', 'utilisateur_id')

    class Meta:
        managed = False
        db_table = 'conversation_participants'


class Message(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(
        Conversation, on_delete=models.DO_NOTHING, db_column='conversation_id', related_name='messages'
    )
    expediteur_id = models.UUIDField()
    contenu = models.TextField()
    lu_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'messages'
        ordering = ['created_at']


class ConversationContext(models.Model):
    conversation = models.OneToOneField(
        Conversation, on_delete=models.DO_NOTHING, db_column='conversation_id',
        primary_key=True, related_name='context',
    )
    producteur_id = models.UUIDField(null=True, blank=True)
    cooperative_id = models.UUIDField(null=True, blank=True)
    est_groupe = models.BooleanField(default=False)

    class Meta:
        managed = False
        db_table = 'conversation_context'


class ConversationParticipantMeta(models.Model):
    conversation_id = models.UUIDField()
    utilisateur_id = models.UUIDField()
    last_read_at = models.DateTimeField(null=True, blank=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    pk = models.CompositePrimaryKey('conversation_id', 'utilisateur_id')

    class Meta:
        managed = False
        db_table = 'conversation_participant_meta'


class MessagePiece(models.Model):
    message = models.OneToOneField(
        Message, on_delete=models.DO_NOTHING, db_column='message_id',
        primary_key=True, related_name='piece',
    )
    piece_type = models.CharField(max_length=10)
    piece_path = models.CharField(max_length=400)

    class Meta:
        managed = False
        db_table = 'message_pieces'


class AppareilSync(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    utilisateur_id = models.UUIDField()
    device_id = models.CharField(max_length=120)
    libelle = models.CharField(max_length=120, null=True, blank=True)
    dernier_sync_at = models.DateTimeField(null=True, blank=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'appareils_sync'
        unique_together = ('utilisateur_id', 'device_id')


class SyncConflict(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    appareil_id = models.UUIDField(null=True, blank=True)
    entite = models.CharField(max_length=80)
    client_uuid = models.UUIDField()
    payload_client = models.JSONField()
    payload_serveur = models.JSONField(null=True, blank=True)
    resolu = models.BooleanField(default=False)
    resolution = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField()
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'sync_conflicts'
        ordering = ['-created_at']


class ModerationImage(models.Model):
    """Image jugée douteuse par l'IA, masquée jusqu'à décision (public.moderation_images, évolution 17)."""

    class Statut(models.TextChoices):
        EN_ATTENTE = 'EN_ATTENTE', 'En attente'
        APPROUVEE = 'APPROUVEE', 'Approuvée'
        REJETEE = 'REJETEE', 'Rejetée'
        REMPLACEE = 'REMPLACEE', 'Remplacée ou retirée'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chemin = models.TextField()
    type_objet = models.CharField(max_length=30)
    objet_id = models.UUIDField(null=True, blank=True)
    envoye_par_id = models.UUIDField(null=True, blank=True)
    verdict = models.CharField(max_length=20, default='DOUTEUX')
    score_nsfw = models.DecimalField(max_digits=6, decimal_places=5, null=True, blank=True)
    scores = models.JSONField(default=dict)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.EN_ATTENTE)
    motif = models.TextField(null=True, blank=True)
    traite_par_id = models.UUIDField(null=True, blank=True)
    traite_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'moderation_images'
        ordering = ['-created_at']
