"""Copie de référence des médias dans un stockage objet S3 (Cloudflare R2).

Le disque local (MEDIA_ROOT) reste le cache de lecture, mais Render l'efface à
chaque déploiement : quand ``MEDIA_S3_BUCKET`` est défini, chaque fichier écrit
est aussi envoyé dans le bucket, et le conteneur le restaure au démarrage.
Sans configuration, toutes les fonctions sont sans effet (développement local).
"""

from __future__ import annotations

import logging
import mimetypes
from functools import lru_cache
from pathlib import Path

from django.conf import settings

logger = logging.getLogger('pfnl.media')


def actif() -> bool:
    return bool(getattr(settings, 'MEDIA_S3_BUCKET', ''))


@lru_cache(maxsize=1)
def _client():
    import boto3
    from botocore.config import Config

    return boto3.client(
        's3',
        endpoint_url=settings.MEDIA_S3_ENDPOINT_URL or None,
        aws_access_key_id=settings.MEDIA_S3_ACCESS_KEY_ID,
        aws_secret_access_key=settings.MEDIA_S3_SECRET_ACCESS_KEY,
        region_name=settings.MEDIA_S3_REGION or 'auto',
        config=Config(retries={'max_attempts': 5, 'mode': 'standard'}, connect_timeout=10, read_timeout=60),
    )


def _racine() -> Path:
    return Path(settings.MEDIA_ROOT)


def _rel(chemin: str | Path) -> str:
    """Chemin relatif à MEDIA_ROOT, séparateurs '/'."""
    p = Path(chemin)
    if p.is_absolute():
        p = p.resolve().relative_to(_racine().resolve())
    rel = p.as_posix().lstrip('/')
    if not rel or '..' in rel.split('/'):
        raise ValueError(f'Chemin média invalide : {chemin!r}')
    return rel


def _cle(rel: str) -> str:
    return f'{settings.MEDIA_S3_PREFIX}{rel}'


def pousser(chemin: str | Path) -> bool:
    """Envoie un fichier local vers le bucket. N'interrompt jamais la requête en cours."""
    if not actif():
        return False
    try:
        rel = _rel(chemin)
        local = _racine() / rel
        type_mime = mimetypes.guess_type(local.name)[0] or 'application/octet-stream'
        _client().upload_file(str(local), settings.MEDIA_S3_BUCKET, _cle(rel), ExtraArgs={'ContentType': type_mime})
        return True
    except Exception:
        logger.exception('Envoi du média %s vers le stockage objet impossible', chemin)
        return False


def supprimer(chemin: str | Path) -> None:
    if not actif():
        return
    try:
        _client().delete_object(Bucket=settings.MEDIA_S3_BUCKET, Key=_cle(_rel(chemin)))
    except Exception:
        logger.exception('Suppression du média %s dans le stockage objet impossible', chemin)


def assurer_local(rel: str) -> bool:
    """Garantit la présence locale d'un média, en le récupérant du bucket si besoin."""
    local = _racine() / rel
    if local.is_file():
        return True
    if not actif():
        return False
    try:
        local.parent.mkdir(parents=True, exist_ok=True)
        temporaire = local.with_name(local.name + '.part')
        _client().download_file(settings.MEDIA_S3_BUCKET, _cle(rel), str(temporaire))
        temporaire.replace(local)
        return True
    except Exception as exc:
        code = getattr(exc, 'response', {}).get('Error', {}).get('Code')
        if code not in ('404', 'NoSuchKey', 'NotFound'):
            logger.exception('Récupération du média %s depuis le stockage objet impossible', rel)
        return False


def _objets_distants() -> dict[str, int]:
    prefixe = settings.MEDIA_S3_PREFIX
    objets = {}
    pages = _client().get_paginator('list_objects_v2').paginate(Bucket=settings.MEDIA_S3_BUCKET, Prefix=prefixe)
    for page in pages:
        for obj in page.get('Contents', []):
            rel = obj['Key'][len(prefixe):]
            if rel and not rel.endswith('/'):
                objets[rel] = obj['Size']
    return objets


def restaurer_tout() -> dict:
    """Télécharge les médias absents (ou de taille différente) du bucket vers le disque local."""
    stats = {'distants': 0, 'telecharges': 0, 'erreurs': 0}
    if not actif():
        return stats
    racine = _racine()
    for rel, taille in _objets_distants().items():
        stats['distants'] += 1
        local = racine / rel
        if local.is_file() and local.stat().st_size == taille:
            continue
        if local.is_file():
            local.unlink()
        stats['telecharges' if assurer_local(rel) else 'erreurs'] += 1
    return stats


def pousser_tout() -> dict:
    """Envoie les médias locaux absents du bucket (rattrapage après un envoi échoué)."""
    stats = {'locaux': 0, 'envoyes': 0, 'erreurs': 0}
    if not actif():
        return stats
    racine = _racine()
    if not racine.is_dir():
        return stats
    distants = _objets_distants()
    for local in racine.rglob('*'):
        if not local.is_file() or local.name.endswith('.part'):
            continue
        stats['locaux'] += 1
        rel = local.relative_to(racine).as_posix()
        if distants.get(rel) == local.stat().st_size:
            continue
        stats['envoyes' if pousser(rel) else 'erreurs'] += 1
    return stats
