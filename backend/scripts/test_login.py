"""Vérifie le login admin via l'API (mot de passe lu depuis .env / prompt)."""
import json
import os
import sys
from pathlib import Path

import urllib.request

# Mot de passe admin applicatif : variable d'environnement optionnelle
# sinon lecture depuis fichier password_pnlf.txt (ligne admin)
ROOT = Path(__file__).resolve().parents[2]
pwd = os.getenv('PNLF_ADMIN_PASSWORD')
if not pwd:
    txt = (ROOT / 'password_pnlf.txt').read_text(encoding='utf-8')
    for line in txt.splitlines():
        if 'mot_de_passe_hash' in line or 'TonMotDePasseAdmin' in line:
            # format: ...=MonMdp
            if '=' in line:
                pwd = line.split('=')[-1].strip()
            break

if not pwd:
    print('Mot de passe admin introuvable')
    sys.exit(1)

payload = json.dumps({'email': 'admin@pnlf.ga', 'password': pwd}).encode()
req = urllib.request.Request(
    'http://127.0.0.1:8000/api/auth/login/',
    data=payload,
    headers={'Content-Type': 'application/json'},
    method='POST',
)
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode())
        print('LOGIN OK')
        print('role:', data.get('user', {}).get('role'))
        print('access:', 'yes' if data.get('access') else 'no')
except Exception as exc:
    print('LOGIN FAIL:', exc)
    if hasattr(exc, 'read'):
        print(exc.read().decode())
    sys.exit(1)
