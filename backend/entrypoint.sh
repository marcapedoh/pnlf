#!/bin/sh
set -e

echo "==> migrate"
python manage.py migrate --noinput

echo "==> restauration des medias depuis le stockage objet (non bloquant)"
python scripts/media_sync.py restaurer || echo "WARN: restauration medias incomplete"

echo "==> jeu de demonstration (cree une seule fois, non bloquant)"
python scripts/seed_demo_acteurs.py || echo "WARN: seed demo ignore"
python scripts/corriger_prenoms_cooperatives.py || echo "WARN: correction prenoms cooperatives ignoree"

echo "==> envoi des medias manquants vers le stockage objet (non bloquant)"
python scripts/media_sync.py pousser || echo "WARN: envoi medias incomplet"

echo "==> collectstatic"
python manage.py collectstatic --noinput

echo "==> gunicorn"
exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 2 --timeout 120
