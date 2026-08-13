-- Droits pour Django (tables système) + lecture/écriture métier
-- Exécuter dans pgAdmin sur la base pnlf, connecté en superuser (ex: postgres)

GRANT USAGE, CREATE ON SCHEMA public TO pnlf_app;
GRANT USAGE, CREATE ON SCHEMA pnlf TO pnlf_app;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pnlf TO pnlf_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pnlf TO pnlf_app;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA pnlf TO pnlf_app;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pnlf_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pnlf_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA pnlf
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pnlf_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA pnlf
    GRANT USAGE, SELECT ON SEQUENCES TO pnlf_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pnlf_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO pnlf_app;

-- search_path : public (Django) puis pnlf (métier)
ALTER ROLE pnlf_app SET search_path TO public, pnlf;
