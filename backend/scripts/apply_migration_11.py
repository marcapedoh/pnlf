"""Applique database/11_chat_v2.sql (lecture, soft-delete, groupes)."""
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / 'backend' / '.env')

sql_path = ROOT / 'database' / '11_chat_v2.sql'
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
    options='-c search_path=public,pnlf',
    autocommit=True,
)
try:
    with conn.cursor() as cur:
        for stmt in clean:
            cur.execute(stmt)
    print('Migration 11_chat_v2.sql OK')
except Exception as e:
    print(f'ERREUR: {e}', file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
