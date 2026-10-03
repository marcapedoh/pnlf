from rest_framework import serializers

from pnlf_platform.annonces import (
    CHAMPS_DETAILS,
    MODES_REMISE,
    MOYENS_PAIEMENT,
    PHOTOS_OFFRE_MAX,
    contact_auteur,
    details_de,
    enregistrer_details,
    moderation_visible,
    profil_auteur,
)
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


UNITES_MESURE = ('KG', 'G', 'LITRE', 'ML', 'UNITE', 'BOTTE', 'SAC', 'M3', 'METRE')


class OffreDemandeSerializer(serializers.ModelSerializer):
    type_annonce = serializers.ChoiceField(
        choices=(('OFFRE', 'Offre'), ('DEMANDE', 'Demande')),
        error_messages={'invalid_choice': 'Type d’annonce invalide (OFFRE ou DEMANDE).'},
    )
    unite = serializers.ChoiceField(
        choices=UNITES_MESURE, required=False, allow_null=True, allow_blank=True,
        error_messages={'invalid_choice': 'Unité de mesure invalide.'},
    )
    description = serializers.CharField(
        required=False, allow_null=True, allow_blank=True, max_length=4000,
        error_messages={'max_length': 'La description est trop longue (4000 caractères maximum).'},
    )
    categorie_id = serializers.UUIDField(
        write_only=True, required=False, allow_null=True,
        error_messages={'invalid': 'Catégorie invalide.'},
    )
    prix_total = serializers.DecimalField(
        write_only=True, required=False, allow_null=True, max_digits=16, decimal_places=2,
        error_messages={'invalid': 'Saisissez un prix total valide (en FCFA).'},
    )
    negociable = serializers.BooleanField(write_only=True, required=False)
    conditionnement = serializers.CharField(
        write_only=True, required=False, allow_null=True, allow_blank=True, max_length=150,
        error_messages={'max_length': 'Le conditionnement est trop long (150 caractères maximum).'},
    )
    qualite = serializers.CharField(
        write_only=True, required=False, allow_null=True, allow_blank=True, max_length=200,
        error_messages={'max_length': 'La qualité est trop longue (200 caractères maximum).'},
    )
    localite = serializers.CharField(
        write_only=True, required=False, allow_null=True, allow_blank=True, max_length=150,
        error_messages={'max_length': 'La localité est trop longue (150 caractères maximum).'},
    )
    disponible_du = serializers.DateField(
        write_only=True, required=False, allow_null=True,
        error_messages={'invalid': 'Date de disponibilité invalide (format attendu : AAAA-MM-JJ).'},
    )
    mode_remise = serializers.ChoiceField(
        write_only=True, required=False, allow_null=True, allow_blank=True, choices=list(MODES_REMISE),
        error_messages={'invalid_choice': 'Modalité de remise invalide (livraison, retrait ou les deux).'},
    )
    modalites_livraison = serializers.CharField(
        write_only=True, required=False, allow_null=True, allow_blank=True, max_length=1000,
        error_messages={'max_length': 'Les modalités de livraison sont trop longues (1000 caractères maximum).'},
    )
    moyens_paiement = serializers.ListField(
        write_only=True, required=False, max_length=len(MOYENS_PAIEMENT),
        child=serializers.ChoiceField(
            choices=list(MOYENS_PAIEMENT), error_messages={'invalid_choice': 'Moyen de paiement invalide.'},
        ),
    )
    conditions_paiement = serializers.CharField(
        write_only=True, required=False, allow_null=True, allow_blank=True, max_length=1000,
        error_messages={'max_length': 'Les conditions de paiement sont trop longues (1000 caractères maximum).'},
    )
    afficher_telephone = serializers.BooleanField(write_only=True, required=False)
    afficher_email = serializers.BooleanField(write_only=True, required=False)
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
            *CHAMPS_DETAILS,
        )
        read_only_fields = (
            'auteur_id', 'statut', 'uuid_public', 'created_at', 'updated_at',
        )
        extra_kwargs = {
            'titre': {'error_messages': {'max_length': 'Le titre est trop long (200 caractères maximum).'}},
        }

    def _cache(self) -> dict:
        return self.context.setdefault('_cache_offres', {})

    def validate_categorie_id(self, valeur):
        from traceability.models import CategorieProduit
        if valeur is not None and not CategorieProduit.objects.filter(pk=valeur, actif=True).exists():
            raise serializers.ValidationError('Catégorie introuvable.')
        return valeur

    def validate_prix_total(self, valeur):
        from config.validators import valider_montant_positif
        return valider_montant_positif(valeur, 'Le prix total ne peut pas être négatif.')

    def validate_moyens_paiement(self, valeur):
        return list(dict.fromkeys(valeur or []))

    def validate(self, attrs):
        from traceability.models import Produit

        produit_id = attrs.get('produit_id', getattr(self.instance, 'produit_id', None))
        categorie_id = attrs.get('categorie_id')
        if categorie_id and produit_id:
            produit = Produit.objects.select_related('categorie').filter(pk=produit_id).first()
            if produit and categorie_id not in (produit.categorie_id, produit.categorie.parent_id):
                raise serializers.ValidationError({
                    'categorie_id': 'Le produit choisi n’appartient pas à cette catégorie.',
                })
        expire_at = attrs.get('expire_at', getattr(self.instance, 'expire_at', None))
        disponible_du = attrs.get('disponible_du')
        if disponible_du and expire_at and disponible_du > expire_at.date():
            raise serializers.ValidationError({
                'disponible_du': 'La date de disponibilité doit précéder la date limite de l’annonce.',
            })
        return attrs

    @staticmethod
    def _extraire_details(validated_data: dict) -> dict:
        details = {champ: validated_data.pop(champ) for champ in CHAMPS_DETAILS if champ in validated_data}
        for champ in ('conditionnement', 'qualite', 'localite', 'modalites_livraison', 'conditions_paiement',
                      'mode_remise'):
            if champ in details:
                details[champ] = (details[champ] or '').strip() or None
        return details

    def details_modifies(self, instance) -> list[str]:
        """Champs complémentaires dont la valeur soumise diffère de la valeur enregistrée."""
        actuels = details_de(instance)
        modifies = []
        for champ in CHAMPS_DETAILS:
            if champ not in self.validated_data:
                continue
            valeur = self.validated_data[champ]
            if isinstance(valeur, str):
                valeur = valeur.strip() or None
            if valeur != (getattr(actuels, champ, None) if actuels else None):
                modifies.append(champ)
        return modifies

    def create(self, validated_data):
        details = self._extraire_details(validated_data)
        instance = super().create(validated_data)
        enregistrer_details(instance, details)
        return instance

    def update(self, instance, validated_data):
        details = self._extraire_details(validated_data)
        instance = super().update(instance, validated_data)
        enregistrer_details(instance, details)
        return instance

    def validate_quantite(self, valeur):
        from config.validators import valider_quantite_positive
        return valider_quantite_positive(valeur)

    def validate_prix_unitaire(self, valeur):
        from config.validators import valider_montant_positif
        return valider_montant_positif(valeur, 'Le prix unitaire ne peut pas être négatif.')

    def validate_unite(self, valeur):
        return valeur or None

    def validate_titre(self, valeur):
        valeur = (valeur or '').strip()
        if not valeur:
            raise serializers.ValidationError('Donnez un titre à votre annonce.')
        if len(valeur) < 5:
            raise serializers.ValidationError('Le titre doit contenir au moins 5 caractères.')
        return valeur

    def validate_description(self, valeur):
        return (valeur or '').strip() or None

    def validate_expire_at(self, valeur):
        from django.utils import timezone
        if valeur is not None and valeur <= timezone.now():
            raise serializers.ValidationError('La date d’expiration doit être dans le futur.')
        return valeur

    def validate_produit_id(self, valeur):
        from traceability.models import Produit
        if not Produit.objects.filter(pk=valeur, actif=True).exists():
            raise serializers.ValidationError('Produit introuvable.')
        return valeur

    def validate_province_id(self, valeur):
        from traceability.models import Province
        if valeur is not None and not Province.objects.filter(pk=valeur).exists():
            raise serializers.ValidationError('Province introuvable.')
        return valeur

    inclure_moderation = True

    def to_representation(self, instance):
        from django.utils import timezone

        from pnlf_platform.offre_statut import read_statut
        from traceability.models import CategorieProduit

        data = super().to_representation(instance)
        data['statut'] = read_statut(instance)
        details = details_de(instance)
        for champ in CHAMPS_DETAILS:
            valeur = getattr(details, champ, None) if details else None
            if champ == 'prix_total':
                valeur = str(valeur) if valeur is not None else None
            elif champ in ('categorie_id', 'disponible_du'):
                valeur = str(valeur) if valeur else None
            elif champ in ('negociable', 'afficher_telephone', 'afficher_email'):
                valeur = bool(valeur)
            elif champ == 'moyens_paiement':
                valeur = list(valeur or [])
            data[champ] = valeur
        cache = self._cache()
        categorie_id = data['categorie_id']
        if categorie_id and f'cat:{categorie_id}' not in cache:
            cache[f'cat:{categorie_id}'] = (
                CategorieProduit.objects.filter(pk=categorie_id).values_list('libelle', flat=True).first()
            )
        data['categorie_nom'] = cache.get(f'cat:{categorie_id}') if categorie_id else None
        request = self.context.get('request')
        data['auteur'] = profil_auteur(instance.auteur_id, request, cache)
        data['contact'] = contact_auteur(instance, details, cache)
        data['expiree'] = bool(instance.expire_at and instance.expire_at <= timezone.now())
        data['photos_max'] = PHOTOS_OFFRE_MAX
        if self.inclure_moderation:
            data['moderation'] = moderation_visible(instance, getattr(request, 'user', None))
        return data

    def get_produit_nom(self, obj):
        from traceability.models import Produit
        cache = self._cache()
        cle = f'produit:{obj.produit_id}'
        if cle not in cache:
            cache[cle] = Produit.objects.filter(pk=obj.produit_id).values_list('nom', flat=True).first()
        return cache[cle]

    def get_province_nom(self, obj):
        if not obj.province_id:
            return None
        from traceability.models import Province
        cache = self._cache()
        cle = f'province:{obj.province_id}'
        if cle not in cache:
            cache[cle] = Province.objects.filter(pk=obj.province_id).values_list('nom', flat=True).first()
        return cache[cle]

    def get_auteur_nom(self, obj):
        profil = profil_auteur(obj.auteur_id, self.context.get('request'), self._cache())
        return profil['nom'] if profil else None

    def get_photos_urls(self, obj):
        from traceability.services import photo_url
        request = self.context.get('request')
        urls = []
        for i in range(1, PHOTOS_OFFRE_MAX + 1):
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


class OffreDemandePubliqueSerializer(OffreDemandeSerializer):
    """Vitrine publique : sans identifiant interne de l'auteur ni trace de modération."""

    inclure_moderation = False

    class Meta(OffreDemandeSerializer.Meta):
        fields = tuple(f for f in OffreDemandeSerializer.Meta.fields if f != 'auteur_id')


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
        profils = self.context.get('_profils_by_user') or {}
        rows = []
        for p in obj.participants.all():
            uid = str(p.utilisateur_id)
            user = cache.get(uid)
            if user is None:
                continue
            profil = profils.get(uid) or {}
            rows.append({
                'id': uid,
                'nom': f'{user.prenoms} {user.nom}'.strip(),
                'role': user.role,
                'role_libelle': profil.get('role_libelle'),
                'organisation': profil.get('organisation'),
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
    piece_mime = serializers.SerializerMethodField()
    contenu = serializers.SerializerMethodField()
    expediteur_nom = serializers.SerializerMethodField()
    expediteur_photo_url = serializers.SerializerMethodField()
    statut = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = (
            'id', 'conversation', 'expediteur_id', 'expediteur_nom', 'expediteur_photo_url',
            'contenu', 'piece_type', 'piece_url', 'piece_mime', 'statut', 'lu_at', 'created_at',
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

    def get_piece_mime(self, obj):
        from pnlf_platform.chat import piece_mime
        piece = self._piece(obj)
        return piece_mime(piece.piece_path) if piece else None

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
