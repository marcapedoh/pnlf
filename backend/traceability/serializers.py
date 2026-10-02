from django.utils import timezone
from rest_framework import serializers

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
from .services import document_url as _document_url
from .services import photo_url as _photo_url
from .services import photos_urls_lot as _photos_urls_lot


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

    class Meta:
        model = Cooperative
        fields = (
            'id', 'code', 'nom', 'numero_agrement', 'telephone', 'email', 'adresse',
            'province', 'province_nom', 'utilisateur_id', 'actif', 'statut', 'photo_url', 'documents',
            'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at', 'statut', 'utilisateur_id', 'actif')

    def get_photo_url(self, obj):
        return _photo_url('cooperatives', obj.id, self.context.get('request'))

    def get_documents(self, obj):
        request = self.context.get('request')
        role = getattr(getattr(request, 'user', None), 'role', None)
        if role not in ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER'):
            return []
        return _documents_administratifs('COOPERATIVE', obj.id, request)


class CooperativeMembreSerializer(serializers.ModelSerializer):
    producteur_nom = serializers.SerializerMethodField()

    class Meta:
        model = CooperativeMembre
        fields = ('cooperative', 'producteur', 'producteur_nom', 'date_adhesion', 'actif', 'created_at')
        read_only_fields = ('created_at',)
        extra_kwargs = {'date_adhesion': {'required': False, 'allow_null': True}}

    def get_producteur_nom(self, obj):
        return str(obj.producteur)


class ZoneCollecteSerializer(CoordonneesGabonMixin, serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)

    class Meta:
        model = ZoneCollecte
        fields = (
            'id', 'code', 'libelle', 'province', 'province_nom', 'description',
            'latitude', 'longitude', 'actif', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at')
        extra_kwargs = {'code': {'required': False, 'allow_blank': True}}


ROLES_AGENTS = ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER')
# Données personnelles d'une fiche producteur : lisibles par les agents et par le titulaire.
CHAMPS_PRIVES_PRODUCTEUR = (
    'type_piece_identite', 'numero_piece', 'date_naissance', 'notes', 'telephone', 'email',
)
# Notes d'instruction (motif de rejet, origine de l'inscription) : écriture réservée aux agents.
CHAMPS_AGENTS_PRODUCTEUR = ('notes',)


class ProducteurSerializer(CoordonneesGabonMixin, serializers.ModelSerializer):
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
            # Un champ que le demandeur ne peut pas lire (donc renvoyé vide par un formulaire)
            # ne doit jamais écraser la valeur enregistrée.
            if not self._peut_lire_prives(self.instance):
                for champ in CHAMPS_PRIVES_PRODUCTEUR:
                    attrs.pop(champ, None)
            if not self._est_agent():
                for champ in CHAMPS_AGENTS_PRODUCTEUR:
                    attrs.pop(champ, None)
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
            'numero_certificat', 'date_obtention', 'date_expiration', 'statut',
        )

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
        return {
            'BROUILLON': 'Brouillon',
            'DECLARE': 'Déclaré',
            'VALIDE': 'Validé',
            'EN_TRANSIT': 'En transit',
            'TRANSFORME': 'Transformé',
            'COMMERCIALISE': 'Commercialisé',
            'ARCHIVE': 'Archivé',
            'ANNULE': 'Annulé',
        }.get(obj.statut, obj.statut)

    def get_mouvements(self, obj):
        labels = {
            'COLLECTE': 'Collecte',
            'RECEPTION_COOPERATIVE': 'Réception coopérative',
            'TRANSFERT': 'Transfert',
            'TRANSFORMATION': 'Transformation',
            'CONTROLE': 'Contrôle',
            'VENTE': 'Vente',
            'EXPORT': 'Export',
            'AUTRE': 'Autre',
        }
        return [
            {
                'type_mouvement': m.type_mouvement,
                'type_libelle': labels.get(m.type_mouvement, m.type_mouvement),
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
