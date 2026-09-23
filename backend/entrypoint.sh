#!/bin/sh
set -e

echo "==> migrate"
python manage.py migrate --noinput

echo "==> purge non-admins (idempotent, non bloquant)"
python scripts/purge_non_admins.py --production || echo "WARN: purge skipped"

echo "==> collectstatic"
python manage.py collectstatic --noinput

echo "==> gunicorn"
exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 2 --timeout 120
