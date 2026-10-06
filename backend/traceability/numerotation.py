"""Numéros officiels attribués automatiquement (agréments de coopérative, certificats).

Séquence annuelle, sous verrou PostgreSQL de transaction : deux créations simultanées
ne peuvent pas obtenir le même numéro. Les appelants doivent être dans un transaction.atomic().
"""

from __future__ import annotations

import re

from django.db import connection
from django.utils import timezone

_VERROU_AGREMENT = 7_310_001
_VERROU_CERTIFICAT = 7_310_002


def _verrouiller(cle: int) -> None:
    with connection.cursor() as cur:
        cur.execute('SELECT pg_advisory_xact_lock(%s)', [cle])


def _suivant(valeurs, motif: re.Pattern) -> int:
    rangs = [int(m.group(1)) for v in valeurs if v and (m := motif.match(v))]
    return max(rangs, default=0) + 1


def numero_agrement(province) -> str:
    """AGR-<code province>-<année>-<rang annuel sur 3 chiffres>, ex. AGR-OGO-2026-018."""
    from .models import Cooperative

    _verrouiller(_VERROU_AGREMENT)
    annee = timezone.localdate().year
    code_province = (getattr(province, 'code', '') or 'GAB').upper()[:5]
    motif = re.compile(rf'^AGR-[A-Z0-9]+-{annee}-(\d+)$')
    existants = Cooperative.objects.filter(numero_agrement__startswith='AGR-', numero_agrement__contains=f'-{annee}-')
    rang = _suivant(existants.values_list('numero_agrement', flat=True), motif)
    return f'AGR-{code_province}-{annee}-{rang:03d}'


def numero_certificat(type_certification) -> str:
    """<sigle du type>-GA-<année>-<rang annuel par type sur 4 chiffres>, ex. BIO-GA-2026-0143."""
    from .models import Certification

    _verrouiller(_VERROU_CERTIFICAT)
    annee = timezone.localdate().year
    code = (getattr(type_certification, 'code', '') or 'CERT').upper()
    sigle = code if len(code) <= 5 else code[:3]
    prefixe = f'{sigle}-GA-{annee}-'
    motif = re.compile(rf'^{re.escape(prefixe)}(\d+)$')
    existants = Certification.objects.filter(numero_certificat__startswith=prefixe)
    rang = _suivant(existants.values_list('numero_certificat', flat=True), motif)
    return f'{prefixe}{rang:04d}'
