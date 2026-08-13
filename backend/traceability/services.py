"""Services métier traçabilité : workflow lots, QR, mouvements."""

from __future__ import annotations

import io
from pathlib import Path

from django.conf import settings
from django.utils import timezone
from rest_framework.exceptions import ValidationError

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

TYPES_MOUVEMENT = {
    'COLLECTE', 'RECEPTION_COOPERATIVE', 'TRANSFERT', 'TRANSFORMATION',
    'CONTROLE', 'VENTE', 'EXPORT', 'AUTRE',
}


def valider_type_mouvement(type_mouvement: str) -> str:
    t = (type_mouvement or '').upper()
    if t not in TYPES_MOUVEMENT:
        raise ValidationError({'type_mouvement': f'Type invalide. Valeurs: {sorted(TYPES_MOUVEMENT)}'})
    return t


def appliquer_mouvement_sur_lot(lot: Lot, type_mouvement: str, *, force: bool = False) -> None:
    """Met à jour le statut du lot selon le mouvement enregistré."""
    nouveau = MOUVEMENT_STATUT_LOT.get(type_mouvement)
    if not nouveau or lot.statut == nouveau:
        return
    if not force:
        cur = STATUT_ORDRE.get(lot.statut, 0)
        nxt = STATUT_ORDRE.get(nouveau, 0)
        if nxt < cur and nouveau not in ('ANNULE', 'ARCHIVE'):
            raise ValidationError(
                {'type_mouvement': f'Transition interdite : lot {lot.statut} → {nouveau}'}
            )
    lot.statut = nouveau
    lot.updated_at = timezone.now()
    lot.save(update_fields=['statut', 'updated_at'])


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


def transition_lot_statut(lot: Lot, nouveau_statut: str, *, force: bool = False) -> None:
    """Transition manuelle (validation agent / admin)."""
    if nouveau_statut not in STATUT_ORDRE:
        raise ValidationError({'statut': 'Statut lot invalide.'})
    if not force:
        cur = STATUT_ORDRE.get(lot.statut, 0)
        nxt = STATUT_ORDRE.get(nouveau_statut, 0)
        if nxt < cur and nouveau_statut not in ('ANNULE', 'ARCHIVE'):
            raise ValidationError({'statut': f'Transition interdite : {lot.statut} → {nouveau_statut}'})
    lot.statut = nouveau_statut
    lot.updated_at = timezone.now()
    lot.save(update_fields=['statut', 'updated_at'])
