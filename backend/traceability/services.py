"""Services métier traçabilité : workflow lots, QR, mouvements."""

from __future__ import annotations

import io
from pathlib import Path

from django.conf import settings
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from config import media_store

from .models import Lot, Mouvement

# Transitions lot déclenchées par type de mouvement (cadrage §6.4)
MOUVEMENT_STATUT_LOT: dict[str, str] = {
    'COLLECTE': 'DECLARE',
    'RECEPTION_COOPERATIVE': 'VALIDE',
    'CONTROLE': 'VALIDE',
    'TRANSFERT': 'EN_TRANSIT',
    'TRANSFORMATION': 'TRANSFORME',
    'VENTE': 'COMMERCIALISE',
    'EXPORT': 'COMMERCIALISE',
}

# Ordre autorisé des statuts (pas de retour arrière sauf admin)
STATUT_ORDRE = {
    'BROUILLON': 0,
    'DECLARE': 1,
    'VALIDE': 2,
    'EN_TRANSIT': 3,
    'TRANSFORME': 4,
    'COMMERCIALISE': 5,
    'ARCHIVE': 6,
    'ANNULE': 7,
}

STATUT_LIBELLES = {
    'BROUILLON': 'Brouillon',
    'DECLARE': 'Déclaré',
    'VALIDE': 'Validé',
    'EN_TRANSIT': 'En transit',
    'TRANSFORME': 'Transformé',
    'COMMERCIALISE': 'Commercialisé',
    'ARCHIVE': 'Archivé',
    'ANNULE': 'Annulé',
}

TYPES_MOUVEMENT = {
    'COLLECTE', 'RECEPTION_COOPERATIVE', 'TRANSFERT', 'TRANSFORMATION',
    'CONTROLE', 'VENTE', 'EXPORT', 'AUTRE',
}

TYPES_MOUVEMENT_LIBELLES = {
    'COLLECTE': 'Collecte',
    'RECEPTION_COOPERATIVE': 'Réception coopérative',
    'TRANSFERT': 'Transfert',
    'TRANSFORMATION': 'Transformation',
    'CONTROLE': 'Contrôle',
    'VENTE': 'Vente',
    'EXPORT': 'Export',
    'AUTRE': 'Autre',
}

UNITES_MESURE = ('KG', 'G', 'LITRE', 'ML', 'UNITE', 'BOTTE', 'SAC', 'M3', 'METRE')

ROLES_AGENTS = ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER')

TYPES_MOUVEMENT_PAR_ROLE: dict[str, set[str]] = {
    'ADMINISTRATEUR': set(TYPES_MOUVEMENT),
    'AGENT_MINISTERE': set(TYPES_MOUVEMENT),
    'AGENT_FORESTIER': set(TYPES_MOUVEMENT),
    'COOPERATIVE': {'RECEPTION_COOPERATIVE', 'TRANSFERT', 'TRANSFORMATION', 'VENTE', 'EXPORT', 'AUTRE'},
    'PRODUCTEUR': {'TRANSFERT', 'TRANSFORMATION', 'VENTE', 'EXPORT', 'AUTRE'},
}

STATUTS_LOT_SANS_MOUVEMENT = ('BROUILLON', 'ANNULE', 'ARCHIVE')

STATUTS_LOT_MODIFIABLES = ('BROUILLON', 'DECLARE')

TRANSITIONS_MANUELLES_LOT: dict[str, tuple[str, ...]] = {
    'BROUILLON': ('DECLARE', 'ANNULE'),
    'DECLARE': ('VALIDE', 'ANNULE', 'ARCHIVE'),
    'VALIDE': ('EN_TRANSIT', 'TRANSFORME', 'COMMERCIALISE', 'ANNULE', 'ARCHIVE'),
    'EN_TRANSIT': ('TRANSFORME', 'COMMERCIALISE', 'ANNULE', 'ARCHIVE'),
    'TRANSFORME': ('EN_TRANSIT', 'COMMERCIALISE', 'ANNULE', 'ARCHIVE'),
    'COMMERCIALISE': ('ARCHIVE',),
    'ANNULE': ('ARCHIVE',),
    'ARCHIVE': (),
}


def libelle_statut_lot(statut: str) -> str:
    return STATUT_LIBELLES.get(statut, statut)


def valider_type_mouvement(type_mouvement: str) -> str:
    t = (type_mouvement or '').upper()
    if t not in TYPES_MOUVEMENT:
        valeurs = ', '.join(TYPES_MOUVEMENT_LIBELLES[k] for k in sorted(TYPES_MOUVEMENT))
        raise ValidationError({'type_mouvement': f'Type de mouvement inconnu. Valeurs acceptées : {valeurs}.'})
    return t


def valider_type_mouvement_pour_role(type_mouvement: str, role: str | None) -> None:
    autorises = TYPES_MOUVEMENT_PAR_ROLE.get(role or '', set())
    if type_mouvement not in autorises:
        libelle = TYPES_MOUVEMENT_LIBELLES.get(type_mouvement, type_mouvement)
        raise ValidationError({
            'type_mouvement': f'Votre profil ne permet pas d’enregistrer une étape « {libelle} ».',
        })


def verifier_lot_accepte_mouvement(lot: Lot) -> None:
    if lot.statut in STATUTS_LOT_SANS_MOUVEMENT:
        message = f'Aucune étape ne peut être ajoutée à un lot « {libelle_statut_lot(lot.statut)} ».'
        if lot.statut == 'BROUILLON':
            message += ' Publiez d’abord le brouillon.'
        raise ValidationError({'lot': message})


def statut_apres_mouvement(lot: Lot, type_mouvement: str) -> str:
    """Statut du lot après un mouvement : progression uniquement, jamais de retour arrière."""
    cible = MOUVEMENT_STATUT_LOT.get(type_mouvement)
    if not cible or cible == lot.statut:
        return lot.statut
    if STATUT_ORDRE.get(cible, 0) > STATUT_ORDRE.get(lot.statut, 0):
        return cible
    return lot.statut


def appliquer_mouvement_sur_lot(lot: Lot, type_mouvement: str) -> bool:
    """Met à jour le statut du lot selon le mouvement enregistré. Retourne True si le statut change."""
    nouveau = statut_apres_mouvement(lot, type_mouvement)
    if nouveau == lot.statut:
        return False
    lot.statut = nouveau
    lot.updated_at = timezone.now()
    lot.save(update_fields=['statut', 'updated_at'])
    return True


def generer_qr_payload(lot: Lot) -> str:
    return f'PNLF:{lot.uuid_public}'


def generer_qr_image(lot: Lot) -> str:
    """Génère PNG QR et retourne le chemin relatif media."""
    import qrcode

    payload = lot.qr_payload or generer_qr_payload(lot)
    qr_dir = Path(settings.MEDIA_ROOT) / 'qr'
    qr_dir.mkdir(parents=True, exist_ok=True)
    filename = f'{lot.uuid_public}.png'
    filepath = qr_dir / filename

    img = qrcode.make(payload)
    img.save(filepath)

    rel = f'qr/{filename}'
    media_store.pousser(rel)
    if lot.qr_payload != payload or lot.qr_image_path != rel:
        lot.qr_payload = payload
        lot.qr_image_path = rel
        lot.save(update_fields=['qr_payload', 'qr_image_path'])
    return rel


def qr_image_bytes(lot: Lot) -> bytes:
    """Retourne les octets PNG du QR (génère si absent)."""
    rel = generer_qr_image(lot)
    path = Path(settings.MEDIA_ROOT) / rel
    return path.read_bytes()


PHOTO_MAX_SIZE_BYTES = 5 * 1024 * 1024
PHOTO_MAX_DIMENSION = 1200


LOT_MAX_PHOTOS = 2


def chemin_photo(sous_dossier: str, entite_id, suffixe: str = '') -> Path:
    return Path(settings.MEDIA_ROOT) / 'photos' / sous_dossier / f'{entite_id}{suffixe}.jpg'


def photo_url(sous_dossier: str, entite_id, request=None, suffixe: str = '') -> str | None:
    """Résout l'URL d'une photo par convention de nommage (aucune colonne BDD requise)."""
    if not chemin_photo(sous_dossier, entite_id, suffixe).exists():
        return None
    rel = f'photos/{sous_dossier}/{entite_id}{suffixe}.jpg'
    from config.media_views import build_media_url
    return build_media_url(rel, request)


DOCUMENT_MAX_SIZE_BYTES = 8 * 1024 * 1024
DOCUMENT_ALLOWED_EXT = {'.pdf', '.jpg', '.jpeg', '.png'}
DOCUMENT_MAGIC = {
    '.pdf': (b'%PDF',),
    '.jpg': (b'\xff\xd8\xff',),
    '.jpeg': (b'\xff\xd8\xff',),
    '.png': (b'\x89PNG\r\n\x1a\n',),
}


def _valider_magic_document(fichier, ext: str) -> None:
    """Vérifie les magic bytes ; refuse les polyglottes basiques."""
    expected = DOCUMENT_MAGIC.get(ext)
    if not expected:
        raise ValidationError({'document': 'Formats acceptés : PDF, JPG, PNG.'})
    pos = fichier.tell()
    try:
        fichier.seek(0)
        head = fichier.read(16)
    finally:
        fichier.seek(pos)
    if not any(head.startswith(sig) for sig in expected):
        raise ValidationError({'document': 'Contenu du fichier incohérent avec l’extension déclarée.'})


def enregistrer_document(fichier, sous_dossier: str, entite_id) -> str:
    """Valide et enregistre un document justificatif (PDF/JPEG/PNG). Retourne le chemin relatif media.

    Utilisé pour les pièces jointes administratives (documents d'inscription,
    justificatifs de certification…). Remplace tout document existant pour la
    même entité/sous-dossier (un seul document actif à la fois).
    """
    if fichier.size > DOCUMENT_MAX_SIZE_BYTES:
        raise ValidationError({'document': 'Fichier trop volumineux (8 Mo maximum).'})
    ext = Path(fichier.name or '').suffix.lower()
    if ext not in DOCUMENT_ALLOWED_EXT:
        raise ValidationError({'document': 'Formats acceptés : PDF, JPG, PNG.'})
    _valider_magic_document(fichier, ext)
    doc_dir = Path(settings.MEDIA_ROOT) / 'documents' / sous_dossier
    doc_dir.mkdir(parents=True, exist_ok=True)
    # Supprime toute variante d'extension précédente pour éviter les doublons.
    for old_ext in DOCUMENT_ALLOWED_EXT:
        if old_ext == ext:
            continue
        old_path = doc_dir / f'{entite_id}{old_ext}'
        if old_path.exists():
            old_path.unlink(missing_ok=True)
        media_store.supprimer(f'documents/{sous_dossier}/{entite_id}{old_ext}')
    filename = f'{entite_id}{ext}'
    filepath = doc_dir / filename
    with open(filepath, 'wb') as out:
        for chunk in fichier.chunks():
            out.write(chunk)
    rel = f'documents/{sous_dossier}/{filename}'
    media_store.pousser(rel)
    return rel


def document_url(document_path: str | None, request=None) -> str | None:
    """Résout l'URL d'un document déjà enregistré (chemin relatif media)."""
    if not document_path:
        return None
    from config.media_views import build_media_url
    return build_media_url(document_path, request)


def photos_urls_lot(lot_id, request=None) -> list[str]:
    """Jusqu'à 2 photos illustrant la marchandise d'un lot (suffixes _1 / _2)."""
    urls = []
    for i in range(1, LOT_MAX_PHOTOS + 1):
        url = photo_url('lots', lot_id, request, suffixe=f'_{i}')
        if url:
            urls.append(url)
    return urls


def enregistrer_photo(fichier, sous_dossier: str, entite_id, suffixe: str = '') -> str:
    """Valide, redimensionne et enregistre une photo (producteur/produit/lot). Retourne le chemin relatif media."""
    from PIL import Image, UnidentifiedImageError

    if fichier.size > PHOTO_MAX_SIZE_BYTES:
        raise ValidationError({'photo': 'Image trop volumineuse (5 Mo maximum).'})

    try:
        image = Image.open(fichier)
        image.verify()
        fichier.seek(0)
        image = Image.open(fichier)
        image = image.convert('RGB')
    except (UnidentifiedImageError, OSError):
        raise ValidationError({'photo': 'Fichier image invalide (JPEG/PNG/WEBP attendu).'})

    image.thumbnail((PHOTO_MAX_DIMENSION, PHOTO_MAX_DIMENSION))

    photo_dir = Path(settings.MEDIA_ROOT) / 'photos' / sous_dossier
    photo_dir.mkdir(parents=True, exist_ok=True)
    filename = f'{entite_id}{suffixe}.jpg'
    filepath = photo_dir / filename
    image.save(filepath, format='JPEG', quality=85)

    rel = f'photos/{sous_dossier}/{filename}'
    media_store.pousser(rel)
    return rel


def valider_transition_manuelle(statut_actuel: str, nouveau_statut: str) -> None:
    if nouveau_statut not in STATUT_ORDRE:
        raise ValidationError({'statut': 'Statut de lot inconnu.'})
    if nouveau_statut == statut_actuel:
        raise ValidationError({
            'statut': f'Le lot est déjà au statut « {libelle_statut_lot(nouveau_statut)} ».',
        })
    autorises = TRANSITIONS_MANUELLES_LOT.get(statut_actuel, ())
    if nouveau_statut not in autorises:
        avant = libelle_statut_lot(statut_actuel)
        apres = libelle_statut_lot(nouveau_statut)
        if autorises:
            possibles = ', '.join(f'« {libelle_statut_lot(s)} »' for s in autorises)
            detail = f' Statuts possibles : {possibles}.'
        else:
            detail = ' Ce statut est définitif.'
        raise ValidationError({
            'statut': f'Un lot « {avant} » ne peut pas passer au statut « {apres} ».{detail}',
        })


def transition_lot_statut(lot: Lot, nouveau_statut: str, *, force: bool = False) -> None:
    """Transition manuelle (validation agent / admin). `force` réservé à l'administrateur."""
    if nouveau_statut not in STATUT_ORDRE:
        raise ValidationError({'statut': 'Statut de lot inconnu.'})
    if not force:
        valider_transition_manuelle(lot.statut, nouveau_statut)
    elif nouveau_statut == lot.statut:
        raise ValidationError({
            'statut': f'Le lot est déjà au statut « {libelle_statut_lot(nouveau_statut)} ».',
        })
    lot.statut = nouveau_statut
    lot.updated_at = timezone.now()
    lot.save(update_fields=['statut', 'updated_at'])
