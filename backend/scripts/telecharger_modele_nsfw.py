"""Télécharge le modèle ONNX de détection d'images sensibles dans ``backend/modeles/``.

Modèle : Marqo/nsfw-image-detection-384 (ViT-tiny, 2 classes, licence Apache-2.0), export ONNX
validé numériquement (écart max des scores 6e-8). Révision Hugging Face figée et empreinte SHA-256
vérifiée : un fichier altéré ou incomplet n'est jamais installé.

Exécuté au build Docker (échec = build en échec) et utilisable tel quel en local.
Usage : python scripts/telecharger_modele_nsfw.py [--force]
"""
from __future__ import annotations

import hashlib
import sys
import time
import urllib.request
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
DOSSIER = BACKEND / 'modeles'
NOM_FICHIER = 'nsfw-marqo-vit-tiny-384.onnx'
REVISION = '8edc47eedf74b30fd379673bc202fe3b754b1538'
URL = f'https://huggingface.co/KanariKanaru/nsfw-image-detection-384-onnx/resolve/{REVISION}/model.onnx'
SHA256 = 'e9350e576608afe4b57a089ffeb0ebafa1389cdcea4882dd61df28c45f1c24d2'
TAILLE_OCTETS = 22_450_633
TENTATIVES = 4


def empreinte(chemin: Path) -> str:
    h = hashlib.sha256()
    with chemin.open('rb') as f:
        for bloc in iter(lambda: f.read(1024 * 1024), b''):
            h.update(bloc)
    return h.hexdigest()


def telecharger(destination: Path) -> None:
    temporaire = destination.with_name(destination.name + '.part')
    requete = urllib.request.Request(URL, headers={'User-Agent': 'pfnl-backend/1.0'})
    with urllib.request.urlopen(requete, timeout=60) as reponse, temporaire.open('wb') as sortie:
        while bloc := reponse.read(1024 * 1024):
            sortie.write(bloc)
    obtenue = empreinte(temporaire)
    if obtenue != SHA256:
        temporaire.unlink(missing_ok=True)
        raise ValueError(f'empreinte SHA-256 inattendue ({obtenue})')
    temporaire.replace(destination)


def main() -> int:
    destination = DOSSIER / NOM_FICHIER
    if destination.is_file() and '--force' not in sys.argv:
        if destination.stat().st_size == TAILLE_OCTETS and empreinte(destination) == SHA256:
            print(f'Modèle NSFW déjà présent et vérifié : {destination}')
            return 0
        print('Modèle NSFW présent mais altéré : nouveau téléchargement.')
    DOSSIER.mkdir(parents=True, exist_ok=True)
    for tentative in range(1, TENTATIVES + 1):
        try:
            telecharger(destination)
            print(f'Modèle NSFW téléchargé et vérifié (SHA-256 {SHA256[:12]}...) : {destination}')
            return 0
        except Exception as exc:
            print(f'Tentative {tentative}/{TENTATIVES} échouée : {exc}', file=sys.stderr)
            if tentative < TENTATIVES:
                time.sleep(5 * tentative)
    print('ERREUR : modèle NSFW indisponible. Les images seront mises en attente de vérification.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    sys.exit(main())
