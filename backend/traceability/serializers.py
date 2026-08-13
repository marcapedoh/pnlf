from rest_framework import serializers

from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
    Lot,
    Mouvement,
    Producteur,
    Produit,
    Province,
    TypeCertification,
    Village,
    ZoneCollecte,
)


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

    class Meta:
        model = Produit
        fields = (
            'id', 'code', 'nom', 'nom_scientifique', 'categorie', 'categorie_libelle',
            'description', 'unite_defaut', 'soumis_cites', 'code_cites', 'actif',
        )


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

    class Meta:
        model = Producteur
        fields = (
            'id', 'code_producteur', 'nom', 'prenoms', 'date_naissance', 'type_acteur',
            'type_piece_identite', 'numero_piece', 'telephone', 'email', 'communaute',
            'province', 'province_nom', 'departement', 'village',
            'latitude', 'longitude', 'cooperative', 'utilisateur_id', 'statut',
            'valide_par_id', 'valide_at', 'notes',
            'client_uuid', 'created_at', 'updated_at',
        )
        read_only_fields = ('created_at', 'updated_at', 'utilisateur_id', 'valide_par_id', 'valide_at')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        from traceability.db_utils import column_exists
        if column_exists('producteurs', 'type_acteur'):
            from django.db import connection
            with connection.cursor() as cur:
                cur.execute('SELECT type_acteur FROM producteurs WHERE id = %s', [str(instance.id)])
                row = cur.fetchone()
                data['type_acteur'] = row[0] if row else 'PRODUCTEUR'
        else:
            data['type_acteur'] = 'PRODUCTEUR'
        return data

    def create(self, validated_data):
        type_acteur = validated_data.pop('type_acteur', 'PRODUCTEUR')
        obj = super().create(validated_data)
        self._save_type_acteur(obj.id, type_acteur)
        return obj

    def update(self, instance, validated_data):
        type_acteur = validated_data.pop('type_acteur', None)
        obj = super().update(instance, validated_data)
        if type_acteur:
            self._save_type_acteur(obj.id, type_acteur)
        return obj

    @staticmethod
    def _save_type_acteur(producteur_id, type_acteur):
        from traceability.db_utils import column_exists
        from django.db import connection
        if column_exists('producteurs', 'type_acteur'):
            with connection.cursor() as cur:
                cur.execute(
                    'UPDATE producteurs SET type_acteur = %s WHERE id = %s',
                    [type_acteur, str(producteur_id)],
                )


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
