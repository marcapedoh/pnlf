"""Export PDF : fichier temporaire + jeton signé (téléchargement natif du navigateur)."""

from __future__ import annotations

import json
import tempfile
import uuid
from pathlib import Path
from urllib.parse import urlencode

from django.core import signing
from django.http import HttpResponse

SALT = 'pnlf-export-v2'
MAX_AGE = 180
_DIR = Path(tempfile.gettempdir()) / 'pnlf_exports'


class ExportTicketError(Exception):
    pass


def store_pdf(pdf: bytes, filename: str, uid: str) -> str:
    if not pdf or not pdf.startswith(b'%PDF'):
        raise ExportTicketError('Le document PDF n’a pas pu être généré.')
    _DIR.mkdir(parents=True, exist_ok=True)
    token = uuid.uuid4().hex
    (_DIR / f'{token}.pdf').write_bytes(pdf)
    (_DIR / f'{token}.json').write_text(
        json.dumps({'filename': filename, 'uid': str(uid)}),
        encoding='utf-8',
    )
    return signing.dumps({'id': token, 'uid': str(uid)}, salt=SALT)


def download_url(ticket: str) -> str:
    return f'/api/exports/download/?{urlencode({"t": ticket})}'


def pop_pdf(ticket: str) -> tuple[bytes, str]:
    try:
        payload = signing.loads(ticket, salt=SALT, max_age=MAX_AGE)
    except signing.SignatureExpired as exc:
        raise ExportTicketError('Le lien de téléchargement a expiré. Relancez l’export.') from exc
    except signing.BadSignature as exc:
        raise ExportTicketError('Lien de téléchargement invalide.') from exc

    token = payload.get('id')
    uid = payload.get('uid')
    if not token or not uid:
        raise ExportTicketError('Lien de téléchargement invalide.')

    pdf_path = _DIR / f'{token}.pdf'
    meta_path = _DIR / f'{token}.json'
    if not pdf_path.is_file() or not meta_path.is_file():
        raise ExportTicketError('Le fichier n’est plus disponible. Relancez l’export.')

    meta = json.loads(meta_path.read_text(encoding='utf-8'))
    if str(meta.get('uid')) != str(uid):
        raise ExportTicketError('Lien de téléchargement invalide.')

    data = pdf_path.read_bytes()
    filename = meta.get('filename') or 'export.pdf'
    pdf_path.unlink(missing_ok=True)
    meta_path.unlink(missing_ok=True)
    return data, filename


def pdf_attachment(pdf: bytes, filename: str) -> HttpResponse:
    from pnlf_platform.pdf_export import pdf_file_response
    return pdf_file_response(pdf, filename)
