import uuid

from django.db import models


class Province(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=10, unique=True)
    nom = models.CharField(max_length=100, unique=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'provinces'
        ordering = ['nom']

    def __str__(self):
        return self.nom


class Departement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    province = models.ForeignKey(
        Province, on_delete=models.DO_NOTHING, db_column='province_id', related_name='departements'
    )
    code = models.CharField(max_length=20, unique=True)
    nom = models.CharField(max_length=120)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'departements'
        ordering = ['nom']


class Village(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    departement = models.ForeignKey(
        Departement, on_delete=models.DO_NOTHING, db_column='departement_id', related_name='villages'
    )
    nom = models.CharField(max_length=150)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'villages'
        ordering = ['nom']


class CategorieProduit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=30, unique=True)
    libelle = models.CharField(max_length=150, unique=True)
    description = models.TextField(null=True, blank=True)
    parent = models.ForeignKey(
        'self', null=True, blank=True, on_delete=models.DO_NOTHING,
        db_column='parent_id', related_name='enfants'
    )
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'categories_produit'
        ordering = ['libelle']


class Produit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=40, unique=True)
    nom = models.CharField(max_length=200, unique=True)
    nom_scientifique = models.CharField(max_length=200, null=True, blank=True)
    categorie = models.ForeignKey(
        CategorieProduit, on_delete=models.DO_NOTHING, db_column='categorie_id', related_name='produits'
    )
    description = models.TextField(null=True, blank=True)
    unite_defaut = models.CharField(max_length=20, default='KG')
    soumis_cites = models.BooleanField(default=False)
    code_cites = models.CharField(max_length=50, null=True, blank=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'produits'
        ordering = ['nom']


class Cooperative(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=30, unique=True)
    nom = models.CharField(max_length=200, unique=True)
    numero_agrement = models.CharField(max_length=80, null=True, blank=True)
    telephone = models.CharField(max_length=30, null=True, blank=True)
    email = models.EmailField(null=True, blank=True)
    adresse = models.TextField(null=True, blank=True)
    province = models.ForeignKey(
        Province, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='province_id'
    )
    utilisateur_id = models.UUIDField(null=True, blank=True)
    actif = models.BooleanField(default=True)
    statut = models.CharField(max_length=20, default='ACTIF')
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'cooperatives'
        ordering = ['nom']


class Producteur(models.Model):
    class TypeActeur(models.TextChoices):
        PRODUCTEUR = 'PRODUCTEUR', 'Producteur'
        COLLECTEUR = 'COLLECTEUR', 'Collecteur'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code_producteur = models.CharField(max_length=30, unique=True)
    nom = models.CharField(max_length=100)
    prenoms = models.CharField(max_length=150)
    date_naissance = models.DateField(null=True, blank=True)
    type_piece_identite = models.CharField(max_length=50, null=True, blank=True)
    numero_piece = models.CharField(max_length=80, null=True, blank=True)
    telephone = models.CharField(max_length=30, null=True, blank=True)
    email = models.EmailField(null=True, blank=True)
    communaute = models.CharField(max_length=120, null=True, blank=True)
    province = models.ForeignKey(Province, on_delete=models.DO_NOTHING, db_column='province_id')
    departement = models.ForeignKey(
        Departement, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='departement_id'
    )
    village = models.ForeignKey(
        Village, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='village_id'
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    cooperative = models.ForeignKey(
        Cooperative, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='cooperative_id'
    )
    utilisateur_id = models.UUIDField(null=True, blank=True)
    statut = models.CharField(max_length=20, default='EN_VALIDATION')
    valide_par_id = models.UUIDField(null=True, blank=True, db_column='valide_par')
    valide_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_statut = models.CharField(max_length=20, default='SYNCED')
    sync_version = models.BigIntegerField(default=1)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'producteurs'
        ordering = ['nom', 'prenoms']

    def __str__(self):
        return f'{self.code_producteur} — {self.prenoms} {self.nom}'


class MessagePublic(models.Model):
    """Message d'un visiteur (annuaire public, sans authentification) vers un producteur."""

    class Statut(models.TextChoices):
        NOUVEAU = 'NOUVEAU', 'Nouveau'
        TRAITE = 'TRAITE', 'Traité'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    producteur = models.ForeignKey(
        Producteur, on_delete=models.DO_NOTHING, db_column='producteur_id', related_name='messages_publics'
    )
    nom_visiteur = models.CharField(max_length=150)
    email_visiteur = models.EmailField()
    telephone_visiteur = models.CharField(max_length=30, null=True, blank=True)
    message = models.TextField()
    ip_adresse = models.CharField(max_length=64, null=True, blank=True)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.NOUVEAU)
    created_at = models.DateTimeField()
    traite_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'messages_publics'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.nom_visiteur} -> {self.producteur_id}'


class ZoneCollecte(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=40, unique=True)
    libelle = models.CharField(max_length=200)
    province = models.ForeignKey(Province, on_delete=models.DO_NOTHING, db_column='province_id')
    description = models.TextField(null=True, blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'zones_collecte'
        ordering = ['libelle']


class Lot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code_lot = models.CharField(max_length=40, blank=True, default='')
    uuid_public = models.UUIDField(default=uuid.uuid4, unique=True)
    produit = models.ForeignKey(Produit, on_delete=models.DO_NOTHING, db_column='produit_id')
    producteur = models.ForeignKey(Producteur, on_delete=models.DO_NOTHING, db_column='producteur_id')
    cooperative = models.ForeignKey(
        Cooperative, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='cooperative_id'
    )
    zone_collecte = models.ForeignKey(
        ZoneCollecte, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='zone_collecte_id'
    )
    date_collecte = models.DateField()
    quantite = models.DecimalField(max_digits=14, decimal_places=3)
    unite = models.CharField(max_length=20)
    qualite_indicateur = models.CharField(max_length=100, null=True, blank=True)
    prix_indicatif = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    devise = models.CharField(max_length=3, default='XAF')
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    statut = models.CharField(max_length=20, default='DECLARE')
    qr_payload = models.TextField(null=True, blank=True)
    qr_image_path = models.TextField(null=True, blank=True)
    declare_par_id = models.UUIDField(null=True, blank=True, db_column='declare_par')
    observations = models.TextField(null=True, blank=True)
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_statut = models.CharField(max_length=20, default='SYNCED')
    sync_version = models.BigIntegerField(default=1)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'lots'
        ordering = ['-date_collecte', '-created_at']


class Mouvement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lot = models.ForeignKey(Lot, on_delete=models.DO_NOTHING, db_column='lot_id', related_name='mouvements')
    type_mouvement = models.CharField(max_length=30)
    date_mouvement = models.DateTimeField()
    lieu_libelle = models.CharField(max_length=200, null=True, blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    quantite = models.DecimalField(max_digits=14, decimal_places=3, null=True, blank=True)
    unite = models.CharField(max_length=20, null=True, blank=True)
    acteur_utilisateur_id = models.UUIDField(null=True, blank=True)
    acteur_producteur_id = models.UUIDField(null=True, blank=True)
    acteur_cooperative_id = models.UUIDField(null=True, blank=True)
    destinataire_libelle = models.CharField(max_length=200, null=True, blank=True)
    commentaire = models.TextField(null=True, blank=True)
    client_uuid = models.UUIDField(null=True, blank=True)
    sync_statut = models.CharField(max_length=20, default='SYNCED')
    sync_version = models.BigIntegerField(default=1)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'mouvements'
        ordering = ['date_mouvement']


class CooperativeMembre(models.Model):
    """Adhésion producteur ↔ coopérative. PK composite SQL, sans colonne id."""

    cooperative = models.ForeignKey(
        Cooperative, on_delete=models.DO_NOTHING, db_column='cooperative_id', related_name='membres'
    )
    producteur = models.ForeignKey(
        Producteur, on_delete=models.DO_NOTHING, db_column='producteur_id', related_name='adhesions_coop'
    )
    date_adhesion = models.DateField()
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()
    pk = models.CompositePrimaryKey('cooperative', 'producteur')

    class Meta:
        managed = False
        db_table = 'cooperative_membres'


class TypeCertification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=40, unique=True)
    libelle = models.CharField(max_length=150)
    organisme = models.CharField(max_length=200, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    duree_mois = models.IntegerField(null=True, blank=True)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'types_certification'
        ordering = ['libelle']


class Certification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_certification = models.ForeignKey(
        TypeCertification, on_delete=models.DO_NOTHING, db_column='type_certification_id'
    )
    lot = models.ForeignKey(
        Lot, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='lot_id', related_name='certifications'
    )
    producteur = models.ForeignKey(
        Producteur, null=True, blank=True, on_delete=models.DO_NOTHING, db_column='producteur_id',
        related_name='certifications',
    )
    numero_certificat = models.CharField(max_length=80, null=True, blank=True)
    statut = models.CharField(max_length=20, default='DEMANDEE')
    date_demande = models.DateField()
    date_obtention = models.DateField(null=True, blank=True)
    date_expiration = models.DateField(null=True, blank=True)
    document_path = models.TextField(null=True, blank=True)
    valide_par_id = models.UUIDField(null=True, blank=True, db_column='valide_par')
    observations = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'certifications'
        ordering = ['-date_demande']


class DocumentInscription(models.Model):
    """Document administratif joint à l'inscription (CNI, fiche circuit, agrément Nagoya…).

    Table dans le schéma public (voir database/12_documents_administratifs.sql).
    """

    class EntiteType(models.TextChoices):
        PRODUCTEUR = 'PRODUCTEUR', 'Producteur / collecteur'
        COOPERATIVE = 'COOPERATIVE', 'Coopérative'
        UTILISATEUR = 'UTILISATEUR', 'Utilisateur'

    class TypeDocument(models.TextChoices):
        CNI = 'CNI', "Pièce d'identité (CNI)"
        FICHE_CIRCUIT = 'FICHE_CIRCUIT', 'Fiche circuit'
        AGREMENT_NAGOYA = 'AGREMENT_NAGOYA', 'Agrément CITES / Nagoya'
        AUTRE = 'AUTRE', 'Autre document'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entite_type = models.CharField(max_length=20, choices=EntiteType.choices)
    entite_id = models.UUIDField()
    type_document = models.CharField(max_length=30, choices=TypeDocument.choices)
    chemin = models.TextField()
    nom_original = models.CharField(max_length=255, null=True, blank=True)
    depose_par_id = models.UUIDField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'documents_inscription'
        ordering = ['-created_at']
