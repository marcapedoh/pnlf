"""
Synchronise le disque média local avec le stockage objet (Cloudflare R2).

Usage (depuis backend/) :
  python scripts/media_sync.py restaurer   # bucket -> disque (démarrage du conteneur)
  python scripts/media_sync.py pousser     # disque -> bucket (rattrapage des envois manqués)
  python scripts/media_sync.py etat        # affiche la configuration active

Sans MEDIA_S3_BUCKET, le script ne fait rien (développement local).
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('action', choices=('restaurer', 'pousser', 'etat'))
    args = parser.parse_args()

    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    import django

    django.setup()

    from django.conf import settings

    from config import media_store

    if not media_store.actif():
        print('Stockage objet non configuré (MEDIA_S3_BUCKET vide) : rien à faire.')
        return 0

    print(f'Bucket : {settings.MEDIA_S3_BUCKET} | préfixe : {settings.MEDIA_S3_PREFIX} | disque : {settings.MEDIA_ROOT}')
    if args.action == 'restaurer':
        stats = media_store.restaurer_tout()
    elif args.action == 'pousser':
        stats = media_store.pousser_tout()
    else:
        return 0
    print(f'{args.action} : {stats}')
    return 1 if stats.get('erreurs') else 0


if __name__ == '__main__':
    sys.exit(main())
