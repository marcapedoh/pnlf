"""Applique database/05_evolutions_cadrage.sql sur la base pnlf."""
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / 'backend' / '.env')

sql_path = ROOT / 'database' / '05_evolutions_cadrage.sql'
if (ROOT / 'database' / '05_evolutions_cadrage_superuser.sql').exists():
    # fallback si droits pnlf_app insuffisants — tenter version allégée d'abord
    pass
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
    print('Migration 05_evolutions_cadrage.sql OK')
except Exception as e:
    conn.rollback()
    print(f'ERREUR: {e}', file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
