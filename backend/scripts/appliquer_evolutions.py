"""Applique, dans l'ordre, les évolutions de schéma `backend/database/evolutions/*.sql` non encore appliquées.

Chaque fichier doit être idempotent (CREATE TABLE IF NOT EXISTS, ADD COLUMN IF NOT EXISTS, UPDATE
conditionnels) et ne créer de nouvelles tables que dans le schéma `public` : en local, le compte
applicatif n'a pas le droit CREATE sur le schéma `pnlf`.

Usage : python scripts/appliquer_evolutions.py [--force NOM_FICHIER]
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django  # noqa: E402

django.setup()

from django.db import connection, transaction  # noqa: E402

DOSSIER = BACKEND / 'database' / 'evolutions'


def main() -> int:
    forcer = set(sys.argv[sys.argv.index('--force') + 1:]) if '--force' in sys.argv else set()
    fichiers = sorted(DOSSIER.glob('*.sql')) if DOSSIER.is_dir() else []
    if not fichiers:
        print('Aucune évolution de schéma à appliquer.')
        return 0
    with connection.cursor() as cur:
        cur.execute(
            'CREATE TABLE IF NOT EXISTS public.pnlf_evolutions ('
            ' nom varchar(200) PRIMARY KEY, appliquee_le timestamptz NOT NULL DEFAULT now())'
        )
        cur.execute('SELECT nom FROM public.pnlf_evolutions')
        deja = {r[0] for r in cur.fetchall()}
    echecs = 0
    for fichier in fichiers:
        if fichier.name in deja and fichier.name not in forcer:
            continue
        sql = fichier.read_text(encoding='utf-8')
        try:
            with transaction.atomic(), connection.cursor() as cur:
                cur.execute(sql)
                cur.execute(
                    'INSERT INTO public.pnlf_evolutions (nom) VALUES (%s) '
                    'ON CONFLICT (nom) DO UPDATE SET appliquee_le = now()',
                    [fichier.name],
                )
            print(f'OK      {fichier.name}')
        except Exception as exc:
            echecs += 1
            print(f'ERREUR  {fichier.name} : {exc}', file=sys.stderr)
    return 1 if echecs else 0


if __name__ == '__main__':
    sys.exit(main())
