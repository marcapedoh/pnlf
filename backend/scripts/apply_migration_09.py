"""Applique database/09_offres_statut_enum.sql (enum + colonnes QR)."""
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / 'backend' / '.env')

sql_path = ROOT / 'database' / '09_offres_statut_enum.sql'
statements = [
    s.strip()
    for s in sql_path.read_text(encoding='utf-8').split(';')
    if s.strip() and not s.strip().startswith('--')
]
# Re-split ignoring comment-only chunks
clean = []
for raw in sql_path.read_text(encoding='utf-8').split(';'):
    lines = [
        ln for ln in raw.splitlines()
        if ln.strip() and not ln.strip().startswith('--')
    ]
    stmt = '\n'.join(lines).strip()
    if stmt:
        clean.append(stmt)

conn = psycopg.connect(
    host=os.getenv('DB_HOST', '127.0.0.1'),
    port=os.getenv('DB_PORT', '5432'),
    dbname=os.getenv('DB_NAME', 'pnlf'),
    user=os.getenv('DB_USER', 'pnlf_app'),
    password=os.getenv('DB_PASSWORD', ''),
    options='-c search_path=pnlf,public',
    autocommit=True,
)
try:
    with conn.cursor() as cur:
        for stmt in clean:
            cur.execute(stmt)
    print('Migration 09_offres_statut_enum.sql OK')
except Exception as e:
    print(f'ERREUR: {e}', file=sys.stderr)
    print(
        'Exécutez database/09_offres_statut_enum_superuser.sql via pgAdmin '
        '(compte postgres) si droits insuffisants.',
        file=sys.stderr,
    )
    sys.exit(1)
finally:
    conn.close()
