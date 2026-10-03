"""Messagerie interne : pièces jointes, rôles staff, résolution des destinataires."""

from __future__ import annotations

from pathlib import Path

from django.conf import settings
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
    'audio/m4a',
    'audio/aac',
    'audio/x-aac',
    'audio/webm;codecs=opus',
}
IMAGE_EXT = {'.jpg', '.jpeg', '.png', '.webp'}
AUDIO_EXT = {'.webm', '.mp3', '.m4a', '.ogg', '.wav', '.aac', '.mp4'}

ROLE_FR = {
    Utilisateur.Role.ADMINISTRATEUR: 'Administrateur',
    Utilisateur.Role.AGENT_MINISTERE: 'Agent du Ministère',
    Utilisateur.Role.AGENT_FORESTIER: 'Agent forestier',
    Utilisateur.Role.PRODUCTEUR: 'Producteur',
    Utilisateur.Role.COOPERATIVE: 'Coopérative',
    Utilisateur.Role.ACHETEUR: 'Acheteur',
}
TYPE_ACTEUR_FR = {'PRODUCTEUR': 'Producteur', 'COLLECTEUR': 'Collecteur', 'RECOLTEUR': 'Récolteur'}


def is_staff_chat(user) -> bool:
    """Agents institutionnels (contacts élargis, pas d'accès global aux fils)."""
    return getattr(user, 'role', None) in STAFF_CHAT_ROLES


def is_admin_superviseur(user) -> bool:
    """Seul le super-utilisateur peut consulter (en lecture) tous les fils via supervision."""
    return getattr(user, 'role', None) == Utilisateur.Role.ADMINISTRATEUR


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
    raise DrfValidationError({'piece': 'Fichier non accepté (image JPEG/PNG/WEBP ou audio webm/ogg/m4a/aac/mp3).'})


def extension_audio_reelle(head: bytes) -> str | None:
    """Extension déduite de la signature du fichier : garantit un Content-Type cohérent à la lecture."""
    if head.startswith(b'\x1a\x45\xdf\xa3'):
        return '.webm'
    if head.startswith(b'OggS'):
        return '.ogg'
    if head[4:8] == b'ftyp':
        return '.m4a'
    if head.startswith(b'RIFF'):
        return '.wav'
    if len(head) >= 2 and head[0] == 0xFF and (head[1] & 0xF6) == 0xF0:
        return '.aac'
    if head.startswith(b'ID3') or head.startswith(b'\xff\xfb') or head.startswith(b'\xff\xf3') or head.startswith(b'\xff\xf2'):
        return '.mp3'
    return None


def piece_mime(rel_path: str | None) -> str | None:
    if not rel_path:
        return None
    from config.media_views import _CHAT_CONTENT_TYPES
    return _CHAT_CONTENT_TYPES.get(Path(rel_path).suffix.lower())


def enregistrer_piece_message(fichier, message_id, piece_type: str) -> str:
    """Enregistre une pièce sous media/chat/ (images analysées par la modération IA). Retourne le chemin relatif."""
    dest_dir = Path(settings.MEDIA_ROOT) / 'chat'
    dest_dir.mkdir(parents=True, exist_ok=True)

    if piece_type == 'IMAGE':
        from config import moderation_images

        image = moderation_images.ouvrir_image(fichier, champ='piece', dimension_max=1600)
        filename = f'{message_id}.jpg'
        rel = f'chat/{filename}'
        analyse = moderation_images.controler(image, champ='piece', rel=rel)
        moderation_images.consigner(analyse, rel)
        image.save(dest_dir / filename, format='JPEG', quality=85)
        media_store.pousser(rel)
        return rel

    pos = fichier.tell()
    try:
        fichier.seek(0)
        head = fichier.read(12)
    finally:
        fichier.seek(pos)
    ext = extension_audio_reelle(head)
    if ext is None:
        raise DrfValidationError({'piece': 'Fichier audio invalide ou non reconnu (formats acceptés : webm, ogg, m4a, aac, mp3, wav).'})
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


def profils_utilisateurs(users) -> dict[str, dict]:
    """Rôle en français (type d'acteur pour les producteurs) et organisation, en lot."""
    from django.db import connection

    from traceability.db_utils import column_exists
    from traceability.models import Cooperative, Producteur

    users = list(users)
    ids = [u.id for u in users]
    if not ids:
        return {}
    coops_comptes = {
        str(uid): nom
        for uid, nom in Cooperative.objects.filter(utilisateur_id__in=ids).values_list('utilisateur_id', 'nom')
    }
    fiches = {
        str(uid): (fid, coop_nom)
        for uid, fid, coop_nom in Producteur.objects.filter(
            utilisateur_id__in=ids, deleted_at__isnull=True,
        ).values_list('utilisateur_id', 'id', 'cooperative__nom')
    }
    types: dict[str, str] = {}
    if fiches and column_exists('producteurs', 'type_acteur'):
        with connection.cursor() as cur:
            cur.execute(
                'SELECT id, type_acteur::text FROM producteurs WHERE id = ANY(%s::uuid[])',
                [[str(fid) for fid, _ in fiches.values()]],
            )
            types = {str(fid): typ for fid, typ in cur.fetchall() if typ}
    out = {}
    for u in users:
        uid = str(u.id)
        role_libelle = ROLE_FR.get(u.role, u.role)
        organisation = None
        if u.role == Utilisateur.Role.COOPERATIVE:
            organisation = coops_comptes.get(uid)
        fiche = fiches.get(uid)
        if fiche:
            if u.role == Utilisateur.Role.PRODUCTEUR:
                role_libelle = TYPE_ACTEUR_FR.get(types.get(str(fiche[0]), 'PRODUCTEUR'), role_libelle)
            organisation = organisation or fiche[1]
        out[uid] = {'role_libelle': role_libelle, 'organisation': organisation}
    return out


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
