from rest_framework import serializers

from .db_utils import get_optional_column, set_optional_column
from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
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


def _media_url(request, path):
    if not path:
        return None
    if request:
        return request.build_absolute_uri(f'/media/{path}')
    return f'/media/{path}'


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
        path = get_optional_column('produits', 'image_path', obj.id)
        return _media_url(self.context.get('request'), path)


class CooperativeSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)

    class Meta:
        model = Cooperative
        fields = (
            'id', 'code', 'nom', 'numero_agrement', 'telephone', 'email', 'adresse',
            'province', 'province_nom', 'utilisateur_id', 'actif', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at')


class CooperativeMembreSerializer(serializers.ModelSerializer):
    producteur_nom = serializers.SerializerMethodField()

    class Meta:
        model = CooperativeMembre
        fields = ('cooperative', 'producteur', 'producteur_nom', 'date_adhesion', 'actif', 'created_at')
        read_only_fields = ('created_at',)

    def get_producteur_nom(self, obj):
        return str(obj.producteur)


class ZoneCollecteSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)

    class Meta:
        model = ZoneCollecte
        fields = (
            'id', 'code', 'libelle', 'province', 'province_nom', 'description',
            'latitude', 'longitude', 'actif', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at')


class ProducteurSerializer(serializers.ModelSerializer):
    province_nom = serializers.CharField(source='province.nom', read_only=True)
    type_acteur = serializers.ChoiceField(
        choices=[('PRODUCTEUR', 'Producteur'), ('COLLECTEUR', 'Collecteur')],
        required=False,
        default='PRODUCTEUR',
    )
    visible_public = serializers.BooleanField(required=False, default=True)
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Producteur
        fields = (
            'id', 'code_producteur', 'nom', 'prenoms', 'date_naissance', 'type_acteur',
            'type_piece_identite', 'numero_piece', 'telephone', 'email', 'communaute',
            'province', 'province_nom', 'departement', 'village',
            'latitude', 'longitude', 'cooperative', 'utilisateur_id', 'statut',
            'valide_par_id', 'valide_at', 'notes', 'visible_public', 'photo_url',
            'client_uuid', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at', 'utilisateur_id', 'valide_par_id', 'valide_at')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['type_acteur'] = (
            get_optional_column('producteurs', 'type_acteur', instance.id, default='PRODUCTEUR')
        )
        data['visible_public'] = bool(
            get_optional_column('producteurs', 'visible_public', instance.id, default=True)
        )
        data['photo_url'] = _media_url(
            self.context.get('request'),
            get_optional_column('producteurs', 'photo_path', instance.id),
        )
        return data

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


class LotSerializer(serializers.ModelSerializer):
    produit_nom = serializers.CharField(source='produit.nom', read_only=True)
    producteur_nom = serializers.SerializerMethodField()
    mouvements = MouvementSerializer(many=True, read_only=True)
    qr_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Lot
        fields = (
            'id', 'code_lot', 'uuid_public', 'produit', 'produit_nom',
            'producteur', 'producteur_nom', 'cooperative', 'zone_collecte',
            'date_collecte', 'quantite', 'unite', 'qualite_indicateur',
            'prix_indicatif', 'devise', 'latitude', 'longitude', 'statut',
            'qr_payload', 'qr_image_path', 'qr_image_url', 'declare_par_id', 'observations', 'client_uuid',
            'mouvements', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'code_lot', 'uuid_public', 'qr_payload', 'qr_image_path', 'qr_image_url',
            'declare_par_id', 'created_at', 'updated_at', 'mouvements',
        )

    def get_producteur_nom(self, obj):
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()

    def get_qr_image_url(self, obj):
        if obj.qr_image_path:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(f'/media/{obj.qr_image_path}')
            return f'/media/{obj.qr_image_path}'
        return None


class TypeCertificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = TypeCertification
        fields = ('id', 'code', 'libelle', 'organisme', 'description', 'duree_mois', 'actif', 'created_at')
        read_only_fields = ('created_at',)


class CertificationSerializer(serializers.ModelSerializer):
    type_libelle = serializers.CharField(source='type_certification.libelle', read_only=True)

    class Meta:
        model = Certification
        fields = (
            'id', 'type_certification', 'type_libelle', 'lot', 'producteur',
            'numero_certificat', 'statut', 'date_demande', 'date_obtention', 'date_expiration',
            'document_path', 'valide_par_id', 'observations', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at', 'valide_par_id')


class LotVerifySerializer(serializers.ModelSerializer):
    produit_nom = serializers.CharField(source='produit.nom', read_only=True)
    producteur_nom = serializers.SerializerMethodField()
    province_nom = serializers.CharField(source='producteur.province.nom', read_only=True)

    class Meta:
        model = Lot
        fields = (
            'code_lot', 'uuid_public', 'produit_nom', 'producteur_nom', 'province_nom',
            'date_collecte', 'quantite', 'unite', 'statut', 'qr_payload',
        )

    def get_producteur_nom(self, obj):
        return f'{obj.producteur.prenoms} {obj.producteur.nom}'.strip()


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

    class Meta:
        model = Producteur
        fields = (
            'id', 'nom', 'prenoms', 'type_acteur', 'communaute',
            'province', 'province_nom', 'cooperative_nom', 'photo_url',
            'produits', 'nb_lots',
        )

    def get_type_acteur(self, obj):
        return get_optional_column('producteurs', 'type_acteur', obj.id, default='PRODUCTEUR')

    def get_photo_url(self, obj):
        return _media_url(self.context.get('request'), get_optional_column('producteurs', 'photo_path', obj.id))

    def get_produits(self, obj):
        produits = self.context.get('produits_par_producteur', {})
        return produits.get(obj.id, [])

    def get_nb_lots(self, obj):
        nb_lots = self.context.get('nb_lots_par_producteur', {})
        return nb_lots.get(obj.id, 0)


class PublicProducteurDetailSerializer(PublicProducteurSerializer):
    certifications = serializers.SerializerMethodField()

    class Meta(PublicProducteurSerializer.Meta):
        fields = PublicProducteurSerializer.Meta.fields + ('certifications',)

    def get_certifications(self, obj):
        certs = self.context.get('certifications_par_producteur', {})
        return certs.get(obj.id, [])


class MessagePublicSerializer(serializers.ModelSerializer):
    class Meta:
        model = MessagePublic
        fields = (
            'id', 'producteur', 'nom_visiteur', 'email_visiteur', 'telephone_visiteur',
            'message', 'statut', 'created_at', 'traite_at',
        )
        read_only_fields = ('id', 'statut', 'created_at', 'traite_at')

    def validate_message(self, value):
        if len(value.strip()) < 10:
            raise serializers.ValidationError("Votre message est trop court (10 caractères minimum).")
        return value.strip()
