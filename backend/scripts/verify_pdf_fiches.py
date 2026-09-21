"""Vérifie les exports PDF fiche/liste producteurs & coopératives (ticket + fichier valide)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import django

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / 'backend'
sys.path.insert(0, str(BACKEND))
from dotenv import load_dotenv

load_dotenv(BACKEND / '.env')
load_dotenv(BACKEND / '.env.local', override=True)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

import urllib.request

import fitz
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import Utilisateur
from traceability.models import Cooperative, Producteur


def jwt_for_admin() -> str:
    user = Utilisateur.objects.filter(email='admin@pnlf.ga', deleted_at__isnull=True).first()
    if user is None:
        user = Utilisateur.objects.filter(role='ADMINISTRATEUR', deleted_at__isnull=True).first()
    if user is None:
        raise SystemExit('Aucun administrateur trouvé.')
    return str(RefreshToken.for_user(user).access_token)


def post_json(url: str, token: str, payload: dict) -> dict:
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        url, data=data,
        headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode('utf-8'))


def fetch_pdf(path: str) -> bytes:
    url = path if path.startswith('http') else f'http://127.0.0.1:8000{path}'
    req = urllib.request.Request(url, method='GET')
    with urllib.request.urlopen(req, timeout=60) as resp:
        status = resp.status
        body = resp.read()
        ctype = resp.headers.get('Content-Type', '')
    if status != 200:
        raise SystemExit(f'HTTP {status} pour {url}')
    if 'application/pdf' not in ctype:
        raise SystemExit(f'Content-Type inattendu ({ctype}) pour {url}')
    if not body.startswith(b'%PDF'):
        raise SystemExit(f'Réponse non PDF ({len(body)} octets) pour {url}')
    return body


def check_pdf(label: str, pdf_bytes: bytes) -> None:
    doc = fitz.open(stream=pdf_bytes, filetype='pdf')
    pages = doc.page_count
    text = doc[0].get_text()[:200].replace('\n', ' | ')
    doc.close()
    print(f'{label}_OK', len(pdf_bytes), 'octets', pages, 'page(s)')
    print(f'{label}_TEXT', text[:200])


def main() -> None:
    token = jwt_for_admin()
    base = 'http://127.0.0.1:8000/api'

    prod = Producteur.objects.filter(deleted_at__isnull=True).first()
    if prod is None:
        raise SystemExit('Aucun producteur en base pour le test.')
    coop = Cooperative.objects.first()
    if coop is None:
        raise SystemExit('Aucune coopérative en base pour le test.')

    t1 = post_json(f'{base}/producteurs/{prod.id}/pdf/', token, {})
    check_pdf('FICHE_PRODUCTEUR', fetch_pdf(t1['url']))

    t2 = post_json(f'{base}/producteurs/pdf-liste/', token, {})
    check_pdf('LISTE_PRODUCTEURS', fetch_pdf(t2['url']))

    t3 = post_json(f'{base}/cooperatives/{coop.id}/pdf/', token, {})
    check_pdf('FICHE_COOPERATIVE', fetch_pdf(t3['url']))

    t4 = post_json(f'{base}/cooperatives/pdf-liste/', token, {})
    check_pdf('LISTE_COOPERATIVES', fetch_pdf(t4['url']))

    print('TOUS_LES_TESTS_OK')


if __name__ == '__main__':
    main()
