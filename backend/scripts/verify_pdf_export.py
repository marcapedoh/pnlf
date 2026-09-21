"""Vérifie l'export PDF (fetch JWT + fichier valide) et génère des captures de page."""
from __future__ import annotations

import json
import os
import sys
from datetime import date
from pathlib import Path

import django
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / 'backend'
sys.path.insert(0, str(BACKEND))
load_dotenv(BACKEND / '.env')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

import urllib.request

import fitz
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import Utilisateur

OUT = ROOT / 'frontend'
SHOT_LOTS = OUT / 'shot-pdf-lots.png'
SHOT_JOURNAL = OUT / 'shot-pdf-journal.png'


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
        url,
        data=data,
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode('utf-8'))


def fetch_pdf_native(path: str) -> bytes:
    url = path if path.startswith('http') else f'http://127.0.0.1:8000{path}'
    req = urllib.request.Request(url, method='GET')
    with urllib.request.urlopen(req, timeout=60) as resp:
        status = resp.status
        body = resp.read()
        ctype = resp.headers.get('Content-Type', '')
        disp = resp.headers.get('Content-Disposition', '')
    if status != 200:
        raise SystemExit(f'HTTP {status} pour {url}')
    if 'application/pdf' not in ctype:
        raise SystemExit(f'Content-Type inattendu ({ctype}) pour {url}')
    if not body.startswith(b'%PDF'):
        raise SystemExit(f'Réponse non PDF ({len(body)} octets) pour {url}')
    return body


def screenshot_pdf(pdf_bytes: bytes, dest: Path) -> tuple[int, str]:
    doc = fitz.open(stream=pdf_bytes, filetype='pdf')
    page = doc[0]
    pix = page.get_pixmap(matrix=fitz.Matrix(1.6, 1.6), alpha=False)
    pix.save(str(dest))
    text = page.get_text()[:400].replace('\n', ' | ')
    pages = doc.page_count
    doc.close()
    return pages, text


def main() -> None:
    token = jwt_for_admin()
    today = date.today().isoformat()
    lots_ticket = post_json('http://127.0.0.1:8000/api/exports/lots/ticket/', token, {})
    journal_ticket = post_json(
        'http://127.0.0.1:8000/api/exports/journal/ticket/',
        token,
        {'granularite': 'jour', 'date': today},
    )
    lots = fetch_pdf_native(lots_ticket['url'])
    journal = fetch_pdf_native(journal_ticket['url'])
    lots_pages, lots_text = screenshot_pdf(lots, SHOT_LOTS)
    journal_pages, journal_text = screenshot_pdf(journal, SHOT_JOURNAL)
    print('LOTS_OK', len(lots), 'octets', lots_pages, 'page(s)', '->', SHOT_LOTS.name)
    print('LOTS_TEXT', lots_text[:220])
    print('JOURNAL_OK', len(journal), 'octets', journal_pages, 'page(s)', '->', SHOT_JOURNAL.name)
    print('JOURNAL_TEXT', journal_text[:220])


if __name__ == '__main__':
    main()
