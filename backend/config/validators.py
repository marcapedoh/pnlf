"""Validateurs partagés par les serializers PFNL (téléphone, coordonnées GPS, dates, montants)."""

from __future__ import annotations

import re
from decimal import Decimal

from django.utils import timezone
from rest_framework import serializers

TELEPHONE_MESSAGE = 'Numéro de téléphone invalide. Format attendu : +241 77 00 01 02.'
_TELEPHONE_SEPARATEURS = re.compile(r'[\s.\-()]')
# Doit rester aligné sur la contrainte SQL ck_utilisateurs_telephone (^\+?[0-9]{8,20}$).
_TELEPHONE_RE = re.compile(r'^\+?\d{8,20}$')

LATITUDE_GABON = (Decimal('-4'), Decimal('2.5'))
LONGITUDE_GABON = (Decimal('8.5'), Decimal('14.6'))
LATITUDE_MESSAGE = 'La latitude doit être comprise entre -4 et 2,5 (territoire gabonais).'
LONGITUDE_MESSAGE = 'La longitude doit être comprise entre 8,5 et 14,6 (territoire gabonais).'


def normaliser_telephone(valeur: str | None) -> str | None:
    """Retire espaces, points, tirets et parenthèses puis vérifie le format international."""
    if valeur is None:
        return None
    texte = _TELEPHONE_SEPARATEURS.sub('', str(valeur).strip())
    if not texte:
        return ''
    if not _TELEPHONE_RE.match(texte):
        raise serializers.ValidationError(TELEPHONE_MESSAGE)
    return texte


class TelephoneField(serializers.CharField):
    """Champ téléphone normalisé (``+241 77 00 01 02`` -> ``+24177000102``)."""

    def __init__(self, **kwargs):
        kwargs.setdefault('max_length', 30)
        super().__init__(**kwargs)

    def run_validation(self, data=serializers.empty):
        valeur = super().run_validation(data)
        if valeur == '' and self.allow_null:
            return None
        return valeur

    def to_internal_value(self, data):
        return normaliser_telephone(super().to_internal_value(data))


def valider_latitude_gabon(valeur):
    if valeur is not None and not (LATITUDE_GABON[0] <= Decimal(valeur) <= LATITUDE_GABON[1]):
        raise serializers.ValidationError(LATITUDE_MESSAGE)
    return valeur


def valider_longitude_gabon(valeur):
    if valeur is not None and not (LONGITUDE_GABON[0] <= Decimal(valeur) <= LONGITUDE_GABON[1]):
        raise serializers.ValidationError(LONGITUDE_MESSAGE)
    return valeur


class CoordonneesGabonMixin:
    """Borne ``latitude`` / ``longitude`` au territoire gabonais."""

    def validate_latitude(self, valeur):
        return valider_latitude_gabon(valeur)

    def validate_longitude(self, valeur):
        return valider_longitude_gabon(valeur)


def valider_date_non_future(valeur, message: str = 'La date ne peut pas être postérieure à aujourd’hui.'):
    if valeur is not None and valeur > timezone.localdate():
        raise serializers.ValidationError(message)
    return valeur


def valider_montant_positif(valeur, message: str = 'Le montant ne peut pas être négatif.'):
    if valeur is not None and valeur < 0:
        raise serializers.ValidationError(message)
    return valeur


def valider_quantite_positive(valeur, message: str = 'La quantité doit être supérieure à 0.'):
    if valeur is not None and valeur <= 0:
        raise serializers.ValidationError(message)
    return valeur
