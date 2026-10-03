"""Filtres de liste : valeurs d'énumération contrôlées (400 explicite au lieu d'une erreur SQL)."""

import django_filters

from .db_utils import column_exists
from .models import Certification, Cooperative, Lot, Mouvement, Producteur, ZoneCollecte
from .services import STATUT_LIBELLES, TYPES_MOUVEMENT_LIBELLES

STATUTS_PRODUCTEUR = (
    ('ACTIF', 'Actif'),
    ('INACTIF', 'Inactif'),
    ('EN_VALIDATION', 'En validation'),
    ('REJETE', 'Rejeté'),
)

STATUTS_COOPERATIVE = STATUTS_PRODUCTEUR

STATUTS_CERTIFICATION = (
    ('DEMANDEE', 'Demandée'),
    ('EN_COURS', 'En cours'),
    ('OBTENUE', 'Obtenue'),
    ('REFUSEE', 'Refusée'),
    ('EXPIREE', 'Expirée'),
    ('REVOQUEE', 'Révoquée'),
)

TYPES_ACTEUR = (('PRODUCTEUR', 'Producteur'), ('COLLECTEUR', 'Collecteur'))


def _choix(message: str):
    return {'invalid_choice': message}


class LotFilter(django_filters.FilterSet):
    statut = django_filters.ChoiceFilter(
        choices=tuple(STATUT_LIBELLES.items()),
        error_messages=_choix(
            'Statut de lot inconnu : « %(value)s ». Statuts possibles : BROUILLON, VALIDE, COMMERCIALISE.'
        ),
    )

    class Meta:
        model = Lot
        fields = ('produit', 'producteur', 'statut', 'cooperative', 'zone_collecte')


class MouvementFilter(django_filters.FilterSet):
    type_mouvement = django_filters.ChoiceFilter(
        choices=tuple(TYPES_MOUVEMENT_LIBELLES.items()),
        error_messages=_choix('Type de mouvement inconnu : « %(value)s ».'),
    )

    class Meta:
        model = Mouvement
        fields = ('lot', 'type_mouvement')


class ProducteurFilter(django_filters.FilterSet):
    statut = django_filters.ChoiceFilter(
        choices=STATUTS_PRODUCTEUR,
        error_messages=_choix('Statut de producteur inconnu : « %(value)s ».'),
    )
    type_acteur = django_filters.ChoiceFilter(
        choices=TYPES_ACTEUR,
        method='filtrer_type_acteur',
        error_messages=_choix('Type d’acteur inconnu : « %(value)s ».'),
    )

    class Meta:
        model = Producteur
        fields = ('province', 'statut', 'cooperative', 'type_acteur')

    def filtrer_type_acteur(self, queryset, name, value):
        if not value or not column_exists('producteurs', 'type_acteur'):
            return queryset
        return queryset.extra(
            where=["COALESCE(producteurs.type_acteur::text, 'PRODUCTEUR') = %s"],
            params=[value],
        )


class CooperativeFilter(django_filters.FilterSet):
    statut = django_filters.ChoiceFilter(
        choices=STATUTS_COOPERATIVE,
        error_messages=_choix('Statut de coopérative inconnu : « %(value)s ».'),
    )

    class Meta:
        model = Cooperative
        fields = ('province', 'actif', 'statut')


class ZoneCollecteFilter(django_filters.FilterSet):
    class Meta:
        model = ZoneCollecte
        fields = ('province', 'actif')


class CertificationFilter(django_filters.FilterSet):
    statut = django_filters.ChoiceFilter(
        choices=STATUTS_CERTIFICATION,
        error_messages=_choix('Statut de certification inconnu : « %(value)s ».'),
    )

    class Meta:
        model = Certification
        fields = ('statut', 'lot', 'producteur', 'type_certification')
