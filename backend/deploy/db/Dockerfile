# =============================================================================
# PFNL — PostgreSQL 18 + PostGIS dédié au projet (pfnl-db)
# Le dump est en PostgreSQL 18.1 (méta-commande \restrict) et utilise PostGIS,
# d'où cette image. Les scripts d'init ne s'exécutent QUE sur un volume vide.
# =============================================================================
FROM postgis/postgis:18-3.6

ENV POSTGRES_USER=postgres \
    POSTGRES_DB=pnlf \
    TZ=Africa/Libreville

# 00-roles.sh (+ 10-db_pfnl.sql copié par le pipeline lors de la 1re initialisation)
COPY . /docker-entrypoint-initdb.d/

# Test en TCP : le serveur temporaire d'initialisation n'écoute que sur le socket local,
# donc "healthy" signifie : import terminé ET serveur définitif démarré.
HEALTHCHECK --interval=10s --timeout=5s --start-period=120s --retries=5 \
    CMD pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1

# Réglages modestes (VPS ~2-4 Go RAM, disque SSD) : ajustables ici
CMD ["postgres", \
    "-c", "shared_buffers=256MB", \
    "-c", "effective_cache_size=768MB", \
    "-c", "work_mem=8MB", \
    "-c", "maintenance_work_mem=64MB", \
    "-c", "max_connections=60", \
    "-c", "random_page_cost=1.1"]