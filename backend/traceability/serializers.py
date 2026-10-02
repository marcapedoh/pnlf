import re
from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers
from rest_framework.validators import UniqueValidator

from config.validators import (
    CoordonneesGabonMixin,
    TelephoneField,
    valider_date_non_future,
    valider_montant_positif,
    valider_quantite_positive,
)

from .db_utils import get_optional_column, set_optional_column
from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
    DocumentInscription,
    Lot,
    MessagePublic,
    Mouvement,
    Producteur,
    Produit,
    Province,
    TypeCertification,
    Village,
    ZoneCollecte,
)
from .services import UNITES_MESURE
from .services import document_url as _document_url
from .services import photo_url as _photo_url
from .services import photos_urls_lot as _photos_urls_lot

UNITE_MESSAGE = 'Unité inconnue : « {input} ». Unités acceptées : ' + ', '.join(UNITES_MESURE) + '.'


def _documents_administratifs(entite_type: str, entite_id, request=None) -> list[dict]:
    """Liste les documents administratifs joints (CNI, fiche circuit, agrément Nagoya…)."""
    qs = DocumentInscription.objects.filter(entite_type=entite_type, entite_id=entite_id)
    return [
        {
            'type_document': doc.type_document,
            'nom_original': doc.nom_original,
            'url': _document_url(doc.chemin, request),
            'created_at': doc.created_at,
        }
        for doc in qs
    ]


class ProvinceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Province
        fields = ('id', 'code', 'nom', 'actif')


class DepartementSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)

    class Meta:
        model = Departement
        fields = ('id', 'code', 'nom', 'province', 'province_nom', 'actif')


class VillageSerializer(serializers.ModelSerializer):
    departement_nom = serializers.CharField(source='departement.nom', read_only=True)

    class Meta:
        model = Village
        fields = (
            'id', 'nom', 'departement', 'departement_nom',
            'latitude', 'longitude', 'actif',
        )


class CategorieProduitSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategorieProduit
        fields = ('id', 'code', 'libelle', 'description', 'parent', 'actif')


class ProduitSerializer(serializers.ModelSerializer):
    categorie_libelle = serializers.CharField(source='categorie.libelle', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Produit
        fields = (
            'id', 'code', 'nom', 'nom_scientifique', 'categorie', 'categorie_libelle',
            'description', 'unite_defaut', 'soumis_cites', 'code_cites', 'actif', 'image_url',
        )

    def get_image_url(self, obj):
        return _photo_url('produits', obj.id, self.context.get('request'))


class CooperativeSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)
    telephone = TelephoneField(required=False, allow_blank=True, allow_null=True)
    photo_url = serializers.SerializerMethodField()
    documents = serializers.SerializerMethodField()
    mon_adhesion = serializers.SerializerMethodField()

    class Meta:
        model = Cooperative
        fields = (
            'id', 'code', 'nom', 'numero_agrement', 'telephone', 'email', 'adresse',
            'province', 'province_nom', 'utilisateur_id', 'actif', 'statut', 'photo_url', 'documents',
            'mon_adhesion', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at', 'statut', 'utilisateur_id', 'actif')
        extra_kwargs = {
            'code': {
                'required': False,
                'allow_blank': True,
                'validators': [UniqueValidator(
                    queryset=Cooperative.objects.all(), message='Ce code de coopérative est déjà utilisé.',
                )],
            },
            'nom': {
                'validators': [UniqueValidator(
                    queryset=Cooperative.objects.all(), lookup='iexact',
                    message='Une coopérative porte déjà ce nom.',
                )],
            },
        }

    def validate(self, attrs):
        attrs = super().validate(attrs)
        request = self.context.get('request')
        role = getattr(getattr(request, 'user', None), 'role', None)
        if self.instance is not None and role not in ('ADMINISTRATEUR', 'AGENT_MINISTERE'):
            attrs.pop('code', None)
        return attrs

    def get_photo_url(self, obj):
        return _photo_url('cooperatives', obj.id, self.context.get('request'))

    def get_documents(self, obj):
        request = self.context.get('request')
        role = getattr(getattr(request, 'user', None), 'role', None)
        if role not in ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER'):
            return []
        return _documents_administratifs('COOPERATIVE', obj.id, request)

    def get_mon_adhesion(self, obj):
        """Situation du producteur connecté vis-à-vis de cette coopérative."""
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if getattr(user, 'role', None) != 'PRODUCTEUR':
            return None
        cache = self.context.setdefault('_adhesion_producteur', {})
        if 'fiche' not in cache:
            fiche = Producteur.objects.filter(utilisateur_id=user.id, deleted_at__isnull=True).first()
            cache['fiche'] = fiche
            cache['en_attente'] = set(
                CooperativeMembre.objects.filter(producteur=fiche, actif=False)
                .values_list('cooperative_id', flat=True)
            ) if fiche else set()
        fiche = cache['fiche']
        if fiche is None:
            return None
        if fiche.cooperative_id == obj.id:
            return 'MEMBRE'
        if obj.id in cache['en_attente']:
            return 'EN_ATTENTE'
        if fiche.cooperative_id:
            return 'AUTRE_COOPERATIVE'
        if cache['en_attente']:
            return 'DEMANDE_AILLEURS'
        return None


class CooperativeMembreSerializer(serializers.ModelSerializer):
    producteur = serializers.PrimaryKeyRelatedField(
        queryset=Producteur.objects.filter(deleted_at__isnull=True),
        pk_field=serializers.UUIDField(error_messages={'invalid': 'Identifiant de producteur invalide.'}),
        error_messages={
            'required': 'Indiquez le producteur concerné.',
            'null': 'Indiquez le producteur concerné.',
            'does_not_exist': 'Producteur introuvable.',
            'incorrect_type': 'Identifiant de producteur invalide.',
        },
    )
    producteur_nom = serializers.SerializerMethodField()
    producteur_code = serializers.CharField(source='producteur.code_producteur', read_only=True)
    producteur_statut = serializers.CharField(source='producteur.statut', read_only=True)

    class Meta:
        model = CooperativeMembre
        fields = (
            'cooperative', 'producteur', 'producteur_nom', 'producteur_code', 'producteur_statut',
            'date_adhesion', 'actif', 'created_at',
        )
        read_only_fields = ('created_at', 'actif')
        extra_kwargs = {'date_adhesion': {'required': False, 'allow_null': True}}

    def validate_date_adhesion(self, valeur):
        return valider_date_non_future(
            valeur, 'La date d’adhésion ne peut pas être postérieure à aujourd’hui.',
        )

    def get_producteur_nom(self, obj):
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()


class ZoneCollecteSerializer(CoordonneesGabonMixin, serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)

    class Meta:
        model = ZoneCollecte
        fields = (
            'id', 'code', 'libelle', 'province', 'province_nom', 'description',
            'latitude', 'longitude', 'actif', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at')
        extra_kwargs = {
            'code': {
                'required': False,
                'allow_blank': True,
                'validators': [UniqueValidator(
                    queryset=ZoneCollecte.objects.all(), message='Ce code de zone est déjà utilisé.',
                )],
            },
        }

    def validate(self, attrs):
        attrs = super().validate(attrs)
        libelle = (attrs.get('libelle') or getattr(self.instance, 'libelle', '') or '').strip()
        province = attrs.get('province') or getattr(self.instance, 'province', None)
        if 'libelle' in attrs:
            attrs['libelle'] = libelle
        if libelle and province is not None:
            doublons = ZoneCollecte.objects.filter(province=province, libelle__iexact=libelle)
            if self.instance is not None:
                doublons = doublons.exclude(pk=self.instance.pk)
            if doublons.exists():
                raise serializers.ValidationError({
                    'libelle': 'Une zone de collecte porte déjà ce libellé dans cette province.',
                })
        return attrs


ROLES_AGENTS = ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER')
# Données personnelles d'une fiche producteur : lisibles par les agents et par le titulaire.
CHAMPS_PRIVES_PRODUCTEUR = (
    'type_piece_identite', 'numero_piece', 'date_naissance', 'notes', 'telephone', 'email',
)
# Notes d'instruction (motif de rejet, origine de l'inscription) : écriture réservée aux agents.
CHAMPS_AGENTS_PRODUCTEUR = ('notes',)


class ProducteurSerializer(CoordonneesGabonMixin, serializers.ModelSerializer):
    code_producteur = serializers.CharField(required=False, allow_blank=True, max_length=30)
    province_nom = serializers.CharField(source='province.nom', read_only=True)
    cooperative_nom = serializers.CharField(source='cooperative.nom', read_only=True, default=None)
    telephone = TelephoneField(required=False, allow_blank=True, allow_null=True)
    type_acteur = serializers.ChoiceField(
        choices=[('PRODUCTEUR', 'Producteur'), ('COLLECTEUR', 'Collecteur')],
        required=False,
        default='PRODUCTEUR',
    )
    visible_public = serializers.BooleanField(required=False, default=True)
    photo_url = serializers.SerializerMethodField()
    documents = serializers.SerializerMethodField()

    class Meta:
        model = Producteur
        fields = (
            'id', 'code_producteur', 'nom', 'prenoms', 'date_naissance', 'type_acteur',
            'type_piece_identite', 'numero_piece', 'telephone', 'email', 'communaute',
            'province', 'province_nom', 'departement', 'village',
            'latitude', 'longitude', 'cooperative', 'cooperative_nom', 'utilisateur_id', 'statut',
            'valide_par_id', 'valide_at', 'notes', 'visible_public', 'photo_url', 'documents',
            'client_uuid', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'created_at', 'updated_at', 'utilisateur_id', 'valide_par_id', 'valide_at', 'statut',
        )

    def _demandeur(self):
        request = self.context.get('request')
        return getattr(request, 'user', None)

    def _est_agent(self) -> bool:
        return getattr(self._demandeur(), 'role', None) in ROLES_AGENTS

    def _peut_lire_prives(self, instance) -> bool:
        if self._est_agent():
            return True
        user_id = getattr(self._demandeur(), 'id', None)
        return bool(user_id and instance.utilisateur_id and instance.utilisateur_id == user_id)

    def validate_date_naissance(self, valeur):
        if valeur is not None and valeur >= timezone.localdate():
            raise serializers.ValidationError('La date de naissance doit être antérieure à aujourd’hui.')
        return valeur

    def validate(self, attrs):
        attrs = super().validate(attrs)
        if self.instance is not None:
            attrs.pop('code_producteur', None)
            # Un champ que le demandeur ne peut pas lire (donc renvoyé vide par un formulaire)
            # ne doit jamais écraser la valeur enregistrée.
            if not self._peut_lire_prives(self.instance):
                for champ in CHAMPS_PRIVES_PRODUCTEUR:
                    attrs.pop(champ, None)
            if not self._est_agent():
                for champ in CHAMPS_AGENTS_PRODUCTEUR:
                    attrs.pop(champ, None)
        else:
            code = (attrs.pop('code_producteur', '') or '').strip()
            if code and self._est_agent():
                if Producteur.objects.filter(code_producteur__iexact=code).exists():
                    raise serializers.ValidationError({'code_producteur': 'Ce code producteur est déjà utilisé.'})
                attrs['code_producteur'] = code

        type_piece = attrs.get('type_piece_identite', getattr(self.instance, 'type_piece_identite', None))
        numero = attrs.get('numero_piece', getattr(self.instance, 'numero_piece', None))
        if type_piece and numero and ('type_piece_identite' in attrs or 'numero_piece' in attrs):
            doublons = Producteur.objects.filter(type_piece_identite=type_piece, numero_piece=numero)
            if self.instance is not None:
                doublons = doublons.exclude(pk=self.instance.pk)
            if doublons.exists():
                raise serializers.ValidationError({
                    'numero_piece': 'Une fiche est déjà enregistrée avec cette pièce d’identité.',
                })

        client_uuid = attrs.get('client_uuid')
        if client_uuid:
            doublons = Producteur.objects.filter(client_uuid=client_uuid)
            if self.instance is not None:
                doublons = doublons.exclude(pk=self.instance.pk)
            if doublons.exists():
                raise serializers.ValidationError({'client_uuid': 'Cette fiche a déjà été synchronisée.'})
        return attrs

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['type_acteur'] = (
            get_optional_column('producteurs', 'type_acteur', instance.id, default='PRODUCTEUR')
        )
        data['visible_public'] = bool(
            get_optional_column('producteurs', 'visible_public', instance.id, default=True)
        )
        request = self.context.get('request')
        data['photo_url'] = _photo_url('producteurs', instance.id, request)
        if not self._peut_lire_prives(instance):
            for key in CHAMPS_PRIVES_PRODUCTEUR:
                data.pop(key, None)
        if self._est_agent():
            # Documents administratifs (CNI, fiche circuit, agrément Nagoya…) réservés
            # aux agents/administrateurs pour l'examen du dossier d'inscription.
            data['documents'] = _documents_administratifs('PRODUCTEUR', instance.id, request)
        else:
            data['documents'] = []
        return data

    def get_photo_url(self, obj):
        # Valeur définitive calculée dans to_representation ; requis car photo_url est
        # déclaré comme SerializerMethodField (aucune colonne modèle correspondante).
        return _photo_url('producteurs', obj.id, self.context.get('request'))

    def get_documents(self, obj):
        # Valeur définitive calculée dans to_representation (nécessite le contexte de rôle).
        return []

    def create(self, validated_data):
        type_acteur = validated_data.pop('type_acteur', 'PRODUCTEUR')
        visible_public = validated_data.pop('visible_public', True)
        obj = super().create(validated_data)
        set_optional_column('producteurs', 'type_acteur', obj.id, type_acteur)
        set_optional_column('producteurs', 'visible_public', obj.id, visible_public)
        return obj

    def update(self, instance, validated_data):
        type_acteur = validated_data.pop('type_acteur', None)
        visible_public = validated_data.pop('visible_public', None)
        obj = super().update(instance, validated_data)
        if type_acteur:
            set_optional_column('producteurs', 'type_acteur', obj.id, type_acteur)
        if visible_public is not None:
            set_optional_column('producteurs', 'visible_public', obj.id, visible_public)
        return obj


class MouvementSerializer(serializers.ModelSerializer):
    date_mouvement = serializers.DateTimeField(required=False)
    unite = serializers.ChoiceField(
        choices=UNITES_MESURE, required=False, allow_null=True, allow_blank=True,
        error_messages={'invalid_choice': UNITE_MESSAGE},
    )

    class Meta:
        model = Mouvement
        fields = (
            'id', 'lot', 'type_mouvement', 'date_mouvement', 'lieu_libelle',
            'latitude', 'longitude', 'quantite', 'unite',
            'acteur_utilisateur_id', 'acteur_producteur_id', 'acteur_cooperative_id',
            'destinataire_libelle', 'commentaire', 'created_at',
        )
        read_only_fields = (
            'created_at',
            'acteur_utilisateur_id',
            'acteur_producteur_id',
            'acteur_cooperative_id',
        )

    def validate_quantite(self, valeur):
        return valider_quantite_positive(valeur)

    def validate_unite(self, valeur):
        return valeur or None

    def validate_date_mouvement(self, valeur):
        if valeur is not None and valeur > timezone.now() + timedelta(minutes=5):
            raise serializers.ValidationError('La date de l’étape ne peut pas être dans le futur.')
        return valeur

    def validate_latitude(self, valeur):
        if valeur is not None and not (-90 <= valeur <= 90):
            raise serializers.ValidationError('La latitude doit être comprise entre -90 et 90.')
        return valeur

    def validate_longitude(self, valeur):
        if valeur is not None and not (-180 <= valeur <= 180):
            raise serializers.ValidationError('La longitude doit être comprise entre -180 et 180.')
        return valeur


class LotSerializer(CoordonneesGabonMixin, serializers.ModelSerializer):
    produit_nom = serializers.CharField(source='produit.nom', read_only=True)
    producteur_nom = serializers.SerializerMethodField()
    zone_collecte_nom = serializers.SerializerMethodField()
    mouvements = MouvementSerializer(many=True, read_only=True)
    qr_image_url = serializers.SerializerMethodField()
    photos_urls = serializers.SerializerMethodField()
    unite = serializers.ChoiceField(choices=UNITES_MESURE, error_messages={'invalid_choice': UNITE_MESSAGE})

    class Meta:
        model = Lot
        fields = (
            'id', 'code_lot', 'uuid_public', 'produit', 'produit_nom',
            'producteur', 'producteur_nom', 'cooperative', 'zone_collecte', 'zone_collecte_nom',
            'date_collecte', 'quantite', 'unite', 'qualite_indicateur',
            'prix_indicatif', 'devise', 'latitude', 'longitude', 'statut',
            'qr_payload', 'qr_image_path', 'qr_image_url', 'photos_urls',
            'declare_par_id', 'observations', 'client_uuid',
            'mouvements', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'code_lot', 'uuid_public', 'qr_payload', 'qr_image_path', 'qr_image_url', 'photos_urls',
            'declare_par_id', 'created_at', 'updated_at', 'mouvements', 'zone_collecte_nom', 'statut',
        )

    def validate_date_collecte(self, valeur):
        return valider_date_non_future(
            valeur, 'La date de collecte ne peut pas être postérieure à aujourd’hui.',
        )

    def validate_quantite(self, valeur):
        return valider_quantite_positive(valeur)

    def validate_prix_indicatif(self, valeur):
        return valider_montant_positif(valeur, 'Le prix indicatif ne peut pas être négatif.')

    def validate_devise(self, valeur):
        devise = (valeur or 'XAF').strip().upper()
        if not re.fullmatch(r'[A-Z]{3}', devise):
            raise serializers.ValidationError('La devise doit être un code de 3 lettres (exemple : XAF).')
        return devise

    def validate_produit(self, produit):
        changement = self.instance is None or self.instance.produit_id != produit.id
        if changement and not produit.actif:
            raise serializers.ValidationError('Ce produit n’est plus proposé dans le référentiel.')
        return produit

    def validate_producteur(self, producteur):
        if producteur.deleted_at is not None:
            raise serializers.ValidationError('Ce producteur a été supprimé.')
        return producteur

    def validate_zone_collecte(self, zone):
        if zone is None:
            return zone
        changement = self.instance is None or self.instance.zone_collecte_id != zone.id
        if changement and not zone.actif:
            raise serializers.ValidationError('Cette zone de collecte est désactivée.')
        return zone

    def validate_client_uuid(self, valeur):
        if valeur:
            doublons = Lot.objects.filter(client_uuid=valeur)
            if self.instance is not None:
                doublons = doublons.exclude(pk=self.instance.pk)
            if doublons.exists():
                raise serializers.ValidationError('Ce lot a déjà été synchronisé.')
        return valeur

    def get_producteur_nom(self, obj):
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()

    def get_zone_collecte_nom(self, obj):
        if not obj.zone_collecte_id:
            return None
        return obj.zone_collecte.libelle

    def get_qr_image_url(self, obj):
        if obj.qr_image_path:
            from config.media_views import build_media_url
            return build_media_url(obj.qr_image_path, self.context.get('request'))
        return None

    def get_photos_urls(self, obj):
        return _photos_urls_lot(obj.id, self.context.get('request'))


class TypeCertificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = TypeCertification
        fields = ('id', 'code', 'libelle', 'organisme', 'description', 'duree_mois', 'actif', 'created_at')
        read_only_fields = ('created_at',)


class CertificationSerializer(serializers.ModelSerializer):
    type_libelle = serializers.CharField(source='type_certification.libelle', read_only=True)
    type_organisme = serializers.CharField(source='type_certification.organisme', read_only=True)
    type_description = serializers.CharField(source='type_certification.description', read_only=True)
    type_duree_mois = serializers.IntegerField(source='type_certification.duree_mois', read_only=True)
    producteur_nom = serializers.SerializerMethodField()
    lot_code = serializers.CharField(source='lot.code_lot', read_only=True, default=None)
    document_url = serializers.SerializerMethodField()

    class Meta:
        model = Certification
        fields = (
            'id', 'type_certification', 'type_libelle', 'type_organisme', 'type_description',
            'type_duree_mois', 'lot', 'lot_code', 'producteur', 'producteur_nom',
            'numero_certificat', 'statut', 'date_demande', 'date_obtention', 'date_expiration',
            'document_path', 'document_url', 'valide_par_id', 'observations', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'created_at', 'updated_at', 'valide_par_id', 'document_path',
            'numero_certificat', 'date_demande', 'date_obtention', 'date_expiration', 'statut',
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if (
            instance.statut == 'OBTENUE'
            and instance.date_expiration is not None
            and instance.date_expiration < timezone.localdate()
        ):
            data['statut'] = 'EXPIREE'
        return data

    def get_producteur_nom(self, obj):
        if not obj.producteur_id:
            return None
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()

    def get_document_url(self, obj):
        from .services import document_url as _document_url

        return _document_url(obj.document_path, self.context.get('request'))


class LotVerifySerializer(serializers.ModelSerializer):
    produit_nom = serializers.CharField(source='produit.nom', read_only=True)
    producteur_nom = serializers.SerializerMethodField()
    province_nom = serializers.CharField(source='producteur.province.nom', read_only=True)
    photos_urls = serializers.SerializerMethodField()
    statut_libelle = serializers.SerializerMethodField()
    mouvements = serializers.SerializerMethodField()

    class Meta:
        model = Lot
        fields = (
            'code_lot', 'uuid_public', 'produit_nom', 'producteur_nom', 'province_nom',
            'date_collecte', 'quantite', 'unite', 'statut', 'statut_libelle', 'qr_payload',
            'photos_urls', 'mouvements',
        )

    def get_producteur_nom(self, obj):
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()

    def get_photos_urls(self, obj):
        return _photos_urls_lot(obj.id, self.context.get('request'))

    def get_statut_libelle(self, obj):
        from .services import libelle_statut_lot

        return libelle_statut_lot(obj.statut)

    def get_mouvements(self, obj):
        from .services import TYPES_MOUVEMENT_LIBELLES

        return [
            {
                'type_mouvement': m.type_mouvement,
                'type_libelle': TYPES_MOUVEMENT_LIBELLES.get(m.type_mouvement, m.type_mouvement),
                'date_mouvement': m.date_mouvement,
                'lieu_libelle': m.lieu_libelle,
            }
            for m in obj.mouvements.all().order_by('date_mouvement', 'created_at')[:12]
        ]


# =============================================================================
# Vitrine publique — annuaire producteurs/collecteurs sans authentification.
# Aucune donnée sensible (téléphone, email, pièce d'identité) n'est exposée ;
# la mise en relation passe par le formulaire de contact (MessagePublic).
# =============================================================================

class PublicProducteurSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)
    cooperative_nom = serializers.CharField(source='cooperative.nom', read_only=True, default=None)
    type_acteur = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()
    produits = serializers.SerializerMethodField()
    nb_lots = serializers.SerializerMethodField()
    certifications = serializers.SerializerMethodField()

    class Meta:
        model = Producteur
        fields = (
            'id', 'nom', 'prenoms', 'type_acteur', 'communaute',
            'province', 'province_nom', 'cooperative_nom', 'photo_url',
            'produits', 'nb_lots', 'certifications',
        )

    def get_type_acteur(self, obj):
        return get_optional_column('producteurs', 'type_acteur', obj.id, default='PRODUCTEUR')

    def get_photo_url(self, obj):
        return _photo_url('producteurs', obj.id, self.context.get('request'))

    def get_produits(self, obj):
        produits = self.context.get('produits_par_producteur', {})
        return produits.get(obj.id, [])

    def get_nb_lots(self, obj):
        nb_lots = self.context.get('nb_lots_par_producteur', {})
        return nb_lots.get(obj.id, 0)

    def get_certifications(self, obj):
        certs = self.context.get('certifications_par_producteur', {})
        return certs.get(obj.id, [])


class PublicProducteurDetailSerializer(PublicProducteurSerializer):
    lots = serializers.SerializerMethodField()
    compte_connecte = serializers.SerializerMethodField()

    class Meta(PublicProducteurSerializer.Meta):
        fields = PublicProducteurSerializer.Meta.fields + ('lots', 'compte_connecte')

    def get_lots(self, obj):
        lots = self.context.get('lots_par_producteur', {})
        return lots.get(obj.id, [])

    def get_compte_connecte(self, obj):
        return bool(obj.utilisateur_id)


class MessagePublicSerializer(serializers.ModelSerializer):
    telephone_visiteur = TelephoneField(required=False, allow_blank=True, allow_null=True)

    class Meta:
        model = MessagePublic
        fields = (
            'id', 'producteur', 'nom_visiteur', 'email_visiteur', 'telephone_visiteur',
            'message', 'statut', 'created_at', 'traite_at',
        )
        read_only_fields = ('id', 'statut', 'created_at', 'traite_at')
        extra_kwargs = {
            'nom_visiteur': {'error_messages': {'blank': 'Votre nom est requis.', 'required': 'Votre nom est requis.'}},
            'email_visiteur': {'error_messages': {
                'blank': 'Votre adresse e-mail est requise.',
                'required': 'Votre adresse e-mail est requise.',
                'invalid': 'Adresse e-mail invalide.',
            }},
        }

    def validate_message(self, value):
        if len(value.strip()) < 10:
            raise serializers.ValidationError("Votre message est trop court (10 caractères minimum).")
        return value.strip()
