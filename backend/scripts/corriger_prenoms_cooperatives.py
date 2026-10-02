"""
Retire le prénom fictif « Coopérative » des comptes COOPERATIVE.

Les anciennes inscriptions enregistraient prenoms='Coopérative', d'où un nom affiché
« Coopérative Coopérative des Saveurs… ». Le script est idempotent : une fois les
lignes corrigées, il ne modifie plus rien.

Usage (depuis backend/) :
  python scripts/corriger_prenoms_cooperatives.py
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))


def main() -> int:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    import django

    django.setup()
    from django.db import connection, transaction

    with transaction.atomic(), connection.cursor() as cur:
        cur.execute(
            "UPDATE utilisateurs SET prenoms = '' "
            "WHERE role = 'COOPERATIVE' AND prenoms = 'Coopérative'"
        )
        corriges = cur.rowcount
    print(f'Prénoms de coopératives corrigés : {corriges}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
