#!/bin/bash
# =============================================================================
# Exécuté une seule fois, à l'initialisation du volume, AVANT 10-db_pfnl.sql.
# Le dump attribue des objets et des droits à pnlf_app et pnlf_readonly :
# ces rôles doivent exister avant l'import.
# =============================================================================
if [ -z "${PNLF_APP_PASSWORD:-}" ]; then
    echo "ERREUR : PNLF_APP_PASSWORD (= DB_PASSWORD) est vide" >&2
    exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v app_pwd="$PNLF_APP_PASSWORD" <<'EOSQL'
CREATE ROLE pnlf_app LOGIN PASSWORD :'app_pwd';
CREATE ROLE pnlf_readonly NOLOGIN;
EOSQL