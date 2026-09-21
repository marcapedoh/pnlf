"""Applique database/06_vitrine_publique.sql sur la base pnlf (compte pnlf_app)."""
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / 'backend' / '.env')

sql_path = ROOT / 'database' / '06_vitrine_publique.sql'
sql = sql_path.read_text(encoding='utf-8')

conn = psycopg.connect(
    host=os.getenv('DB_HOST', '127.0.0.1'),
    port=os.getenv('DB_PORT', '5432'),
    dbname=os.getenv('DB_NAME', 'pnlf'),
    user=os.getenv('DB_USER', 'pnlf_app'),
    password=os.getenv('DB_PASSWORD', ''),
    options='-c search_path=pnlf,public',
)
try:
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    print('Migration 06_vitrine_publique.sql OK')
except Exception as e:
    conn.rollback()
    print(f'ERREUR: {e}', file=sys.stderr)
    print('Exécutez database/06_vitrine_publique.sql via pgAdmin (compte postgres) si droits insuffisants.', file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
