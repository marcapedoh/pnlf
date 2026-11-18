#!/bin/sh
# =============================================================================
# PFNL — Point d'entrée de l'image Jenkins
# 1. attend PostgreSQL  2. applique les migrations  3. lance Gunicorn
# =============================================================================
set -eu

echo ">>> Attente de PostgreSQL sur ${DB_HOST:-127.0.0.1}:${DB_PORT:-5432}..."
python - <<'PY'
import os, socket, sys, time
host, port = os.getenv("DB_HOST", "127.0.0.1"), int(os.getenv("DB_PORT", "5432"))
for _ in range(60):
    try:
        socket.create_connection((host, port), timeout=2).close()
        sys.exit(0)
    except OSError:
        time.sleep(2)
print(f"PostgreSQL injoignable sur {host}:{port}", file=sys.stderr)
sys.exit(1)
PY

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    echo ">>> Migrations Django"
    python manage.py migrate --noinput
fi

echo ">>> Démarrage de Gunicorn"
exec gunicorn config.wsgi:application \
    --bind 0.0.0.0:8000 \
    --worker-class gthread \
    --workers "${GUNICORN_WORKERS:-3}" \
    --threads "${GUNICORN_THREADS:-4}" \
    --timeout "${GUNICORN_TIMEOUT:-60}" \
    --graceful-timeout 30 \
    --keep-alive 5 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --worker-tmp-dir /dev/shm \
    --access-logfile - \
    --error-logfile -