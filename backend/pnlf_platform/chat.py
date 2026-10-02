"""Messagerie interne : pièces jointes, rôles staff, résolution des destinataires."""

from __future__ import annotations

from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from rest_framework.exceptions import ValidationError as DrfValidationError

from accounts.models import Utilisateur
from config import media_store

PLACEHOLDER_PHOTO = '[Photo]'
PLACEHOLDER_AUDIO = '[Message vocal]'
PLACEHOLDERS = {PLACEHOLDER_PHOTO, PLACEHOLDER_AUDIO}

STAFF_CHAT_ROLES = {
    Utilisateur.Role.ADMINISTRATEUR,
    Utilisateur.Role.AGENT_MINISTERE,
    Utilisateur.Role.AGENT_FORESTIER,
}

CHAT_IMAGE_MAX_BYTES = 5 * 1024 * 1024
CHAT_AUDIO_MAX_BYTES = 8 * 1024 * 1024
CHAT_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/jpg'}
CHAT_AUDIO_TYPES = {
    'audio/webm',
    'audio/mpeg',
    'audio/mp3',
    'audio/mp4',
    'audio/ogg',
    'audio/wav',
    'audio/x-wav',
    'audio/x-m4a',
    'audio/aac',
    'audio/webm;codecs=opus',
}
IMAGE_EXT = {'.jpg', '.jpeg', '.png', '.webp'}
AUDIO_EXT = {'.webm', '.mp3', '.m4a', '.ogg', '.wav', '.aac', '.mp4'}


def is_staff_chat(user) -> bool:
    """Agents institutionnels (contacts élargis, pas d'accès global aux fils)."""
    return getattr(user, 'role', None) in STAFF_CHAT_ROLES


def is_admin_superviseur(user) -> bool:
    """Seul le super-utilisateur peut consulter (en lecture) tous les fils via supervision."""
    return getattr(user, 'role', None) == Utilisateur.Role.ADMINISTRATEUR


def _ext_from_name(name: str, fallback: str) -> str:
    suffix = Path(name or '').suffix.lower()
    if suffix in IMAGE_EXT or suffix in AUDIO_EXT:
        return suffix
    return fallback


def detecter_piece(fichier) -> str:
    """Retourne IMAGE ou AUDIO, ou lève une ValidationError DRF."""
    ctype = (getattr(fichier, 'content_type', None) or '').split(';')[0].strip().lower()
    name = getattr(fichier, 'name', '') or ''
    ext = Path(name).suffix.lower()
    if ctype in CHAT_IMAGE_TYPES or ext in IMAGE_EXT:
        if fichier.size > CHAT_IMAGE_MAX_BYTES:
            raise DrfValidationError({'piece': 'Image trop volumineuse (5 Mo maximum).'})
        return 'IMAGE'
    if ctype in CHAT_AUDIO_TYPES or ext in AUDIO_EXT:
        if fichier.size > CHAT_AUDIO_MAX_BYTES:
            raise DrfValidationError({'piece': 'Audio trop volumineux (8 Mo maximum).'})
        return 'AUDIO'
    raise DrfValidationError({'piece': 'Fichier non accepté (image JPEG/PNG/WEBP ou audio webm/mp3/m4a/ogg).'})


def enregistrer_piece_message(fichier, message_id, piece_type: str) -> str:
    """Enregistre une pièce sous media/chat/. Retourne le chemin relatif."""
    from PIL import Image, UnidentifiedImageError

    dest_dir = Path(settings.MEDIA_ROOT) / 'chat'
    dest_dir.mkdir(parents=True, exist_ok=True)

    if piece_type == 'IMAGE':
        try:
            image = Image.open(fichier)
            image.verify()
            fichier.seek(0)
            image = Image.open(fichier)
            image = image.convert('RGB')
        except (UnidentifiedImageError, OSError, ValidationError) as exc:
            raise DrfValidationError({'piece': 'Fichier image invalide (JPEG/PNG/WEBP attendu).'}) from exc
        image.thumbnail((1600, 1600))
        filename = f'{message_id}.jpg'
        image.save(dest_dir / filename, format='JPEG', quality=85)
        media_store.pousser(f'chat/{filename}')
        return f'chat/{filename}'

    ext = _ext_from_name(getattr(fichier, 'name', ''), '.webm')
    if ext not in AUDIO_EXT:
        ext = '.webm'
    # En-têtes audio courants (webm/ogg/mp3/wav/mp4)
    pos = fichier.tell()
    try:
        fichier.seek(0)
        head = fichier.read(12)
    finally:
        fichier.seek(pos)
    audio_ok = (
        head.startswith(b'\x1a\x45\xdf\xa3')  # EBML / webm
        or head.startswith(b'OggS')
        or head.startswith(b'ID3')
        or head.startswith(b'\xff\xfb')
        or head.startswith(b'\xff\xf3')
        or head.startswith(b'RIFF')
        or head[4:8] == b'ftyp'
    )
    if not audio_ok:
        raise DrfValidationError({'piece': 'Fichier audio invalide ou non reconnu.'})
    filename = f'{message_id}{ext}'
    filepath = dest_dir / filename
    fichier.seek(0)
    with filepath.open('wb') as out:
        for chunk in fichier.chunks():
            out.write(chunk)
    media_store.pousser(f'chat/{filename}')
    return f'chat/{filename}'


def piece_url(rel_path: str | None, request=None) -> str | None:
    if not rel_path:
        return None
    from config.media_views import build_media_url
    return build_media_url(rel_path, request)


def nom_utilisateur(user: Utilisateur | None) -> str:
    if not user:
        return 'Utilisateur'
    return f'{user.prenoms} {user.nom}'.strip() or user.email


def _media_url(rel: str, request=None) -> str:
    from config.media_views import build_media_url
    return build_media_url(rel, request) or ''


def photo_url_utilisateur(utilisateur_id, request=None) -> str | None:
    """Résout la photo de profil liée à un compte (producteur, coop ou acheteur)."""
    from pathlib import Path as _Path

    from django.conf import settings as _settings
    from traceability.models import Cooperative, Producteur

    uid = str(utilisateur_id)
    root = _Path(_settings.MEDIA_ROOT)

    prod = Producteur.objects.filter(utilisateur_id=utilisateur_id, deleted_at__isnull=True).first()
    if prod:
        rel = f'photos/producteurs/{prod.id}.jpg'
        if (root / rel).exists():
            return _media_url(rel, request)

    coop = Cooperative.objects.filter(utilisateur_id=utilisateur_id).first()
    if coop:
        rel = f'photos/cooperatives/{coop.id}.jpg'
        if (root / rel).exists():
            return _media_url(rel, request)

    for folder in ('acheteurs', 'utilisateurs'):
        rel = f'photos/{folder}/{uid}.jpg'
        if (root / rel).exists():
            return _media_url(rel, request)
    return None


def photos_utilisateurs(utilisateur_ids, request=None) -> dict[str, str | None]:
    return {str(uid): photo_url_utilisateur(uid, request) for uid in utilisateur_ids}


def statut_message_pour(msg_created_at, other_last_reads: list) -> str:
    """ENVOYE | RECU | LU — style WhatsApp pour les messages sortants."""
    if not other_last_reads:
        return 'ENVOYE'
    if all(ts is not None and ts >= msg_created_at for ts in other_last_reads):
        return 'LU'
    if any(ts is not None and ts >= msg_created_at for ts in other_last_reads):
        return 'RECU'
    # Message persisté côté serveur = reçu (double coche grise) en attendant la lecture
    return 'RECU'
