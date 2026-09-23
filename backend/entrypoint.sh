#!/bin/sh
set -e

python manage.py migrate --noinput

# Purge one-shot idempotente (conserve ADMINISTRATEUR) — no-op si déjà faite
python scripts/purge_non_admins.py --production || echo "WARN: purge_non_admins skipped/failed"

python manage.py collectstatic --noinput

exec gunicorn config.wsgi:application --bind 0.0.0.0:8000
