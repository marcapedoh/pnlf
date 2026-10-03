import uuid

from django.db import models


class Utilisateur(models.Model):
    """Modèle mappé sur pnlf.utilisateurs (schéma SQL existant)."""

    class Role(models.TextChoices):
        ADMINISTRATEUR = 'ADMINISTRATEUR', 'Administrateur'
        AGENT_MINISTERE = 'AGENT_MINISTERE', 'Agent ministère'
        AGENT_FORESTIER = 'AGENT_FORESTIER', 'Agent forestier'
        PRODUCTEUR = 'PRODUCTEUR', 'Producteur'
        COOPERATIVE = 'COOPERATIVE', 'Coopérative'
        ACHETEUR = 'ACHETEUR', 'Acheteur'

    class Statut(models.TextChoices):
        ACTIF = 'ACTIF', 'Actif'
        INACTIF = 'INACTIF', 'Inactif'
        SUSPENDU = 'SUSPENDU', 'Suspendu'
        EN_ATTENTE = 'EN_ATTENTE', 'En attente'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    telephone = models.CharField(max_length=30, null=True, blank=True)
    mot_de_passe_hash = models.TextField()
    role = models.CharField(max_length=30, choices=Role.choices)
    statut = models.CharField(max_length=20, choices=Statut.choices, default=Statut.EN_ATTENTE)
    nom = models.CharField(max_length=100)
    prenoms = models.CharField(max_length=150)
    double_auth_active = models.BooleanField(default=False)
    derniere_connexion = models.DateTimeField(null=True, blank=True)
    tentatives_echec = models.SmallIntegerField(default=0)
    verrouille_jusquau = models.DateTimeField(null=True, blank=True)
    doit_changer_mdp = models.BooleanField(default=False)
    preferences_notif = models.CharField(max_length=20, default='EMAIL')
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'utilisateurs'
        verbose_name = 'Utilisateur'
        verbose_name_plural = 'Utilisateurs'

    def __str__(self):
        return f'{self.email} ({self.role})'

    # Compatibilité Django / DRF (pas de table auth_user)
    @property
    def is_authenticated(self):
        return self.statut == self.Statut.ACTIF and self.deleted_at is None

    @property
    def is_anonymous(self):
        return False

    @property
    def is_active(self):
        return self.is_authenticated

    @property
    def is_staff(self):
        return self.role == self.Role.ADMINISTRATEUR

    @property
    def is_superuser(self):
        return self.role == self.Role.ADMINISTRATEUR

    def get_username(self):
        return self.email

    def get_full_name(self):
        return f'{self.prenoms} {self.nom}'.strip()

    def check_password(self, raw_password: str) -> bool:
        """Vérifie un mot de passe (hash bcrypt pgcrypto / bcrypt Python)."""
        if not self.mot_de_passe_hash or raw_password is None:
            return False
        try:
            from django.db import connection

            with connection.cursor() as cur:
                cur.execute(
                    'SELECT %s = crypt(%s, %s)',
                    [self.mot_de_passe_hash, raw_password, self.mot_de_passe_hash],
                )
                row = cur.fetchone()
                if row and row[0] is True:
                    return True
        except Exception:
            pass
        try:
            import bcrypt as bcrypt_lib

            return bcrypt_lib.checkpw(
                raw_password.encode('utf-8'),
                self.mot_de_passe_hash.encode('utf-8'),
            )
        except (ValueError, TypeError):
            return False

    def set_password(self, raw_password: str) -> None:
        import bcrypt as bcrypt_lib

        self.mot_de_passe_hash = bcrypt_lib.hashpw(
            raw_password.encode('utf-8'),
            bcrypt_lib.gensalt(rounds=12),
        ).decode('utf-8')


class Session(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    utilisateur = models.ForeignKey(
        Utilisateur, on_delete=models.DO_NOTHING, db_column='utilisateur_id', related_name='sessions'
    )
    jti = models.CharField(max_length=64, unique=True)
    refresh_token_hash = models.TextField()
    ip_adresse = models.GenericIPAddressField(null=True, blank=True, protocol='both')
    user_agent = models.TextField(null=True, blank=True)
    expire_at = models.DateTimeField()
    revoquee_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'sessions'


class Connexion(models.Model):
    """Tentative de connexion (public.connexions, évolution 16)."""

    id = models.BigAutoField(primary_key=True)
    utilisateur_id = models.UUIDField(null=True, blank=True)
    email_saisi = models.CharField(max_length=254, null=True, blank=True)
    role = models.CharField(max_length=30, null=True, blank=True)
    succes = models.BooleanField()
    motif_echec = models.CharField(max_length=30, null=True, blank=True)
    ip_adresse = models.GenericIPAddressField(null=True, blank=True, protocol='both')
    appareil = models.CharField(max_length=20, default='INCONNU')
    systeme = models.CharField(max_length=40, null=True, blank=True)
    navigateur = models.CharField(max_length=40, null=True, blank=True)
    empreinte_appareil = models.CharField(max_length=64, null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'connexions'
        ordering = ['-created_at']


class Presence(models.Model):
    """Activité récente d'un utilisateur sur un appareil (public.presences, évolution 16)."""

    utilisateur_id = models.UUIDField()
    empreinte_appareil = models.CharField(max_length=64)
    appareil = models.CharField(max_length=20, default='INCONNU')
    systeme = models.CharField(max_length=40, null=True, blank=True)
    navigateur = models.CharField(max_length=40, null=True, blank=True)
    ip_adresse = models.GenericIPAddressField(null=True, blank=True, protocol='both')
    debut_at = models.DateTimeField()
    derniere_activite = models.DateTimeField()
    pk = models.CompositePrimaryKey('utilisateur_id', 'empreinte_appareil')

    class Meta:
        managed = False
        db_table = 'presences'


class ReinitialisationMdp(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    utilisateur = models.ForeignKey(
        Utilisateur, on_delete=models.DO_NOTHING, db_column='utilisateur_id', related_name='resets_mdp'
    )
    token_hash = models.TextField(unique=True)
    expire_at = models.DateTimeField()
    utilise_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'reinitialisations_mdp'
