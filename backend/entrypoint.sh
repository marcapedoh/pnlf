#!/bin/sh
set -e

echo "==> migrate"
python manage.py migrate --noinput

echo "==> jeu de demonstration (cree une seule fois, non bloquant)"
python scripts/seed_demo_acteurs.py || echo "WARN: seed demo ignore"

echo "==> collectstatic"
python manage.py collectstatic --noinput

echo "==> gunicorn"
exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 2 --timeout 120
