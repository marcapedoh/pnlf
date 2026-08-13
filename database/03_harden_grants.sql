-- Durcissement des privilèges PNLF (défense en profondeur)
-- Exécuter dans pgAdmin sur la base pnlf en tant que superuser (postgres)

-- Immutabilité réelle : l'app ne peut plus UPDATE/DELETE mouvements & audit
REVOKE UPDATE, DELETE ON TABLE pnlf.mouvements FROM pnlf_app;
REVOKE UPDATE, DELETE ON TABLE pnlf.audit_logs FROM pnlf_app;

-- Conserver lecture + insertion
GRANT SELECT, INSERT ON TABLE pnlf.mouvements TO pnlf_app;
GRANT SELECT, INSERT ON TABLE pnlf.audit_logs TO pnlf_app;

-- Réduire le droit de créer des objets arbitraires dans le schéma métier
-- (Django crée ses tables dans public — CREATE sur public peut rester)
REVOKE CREATE ON SCHEMA pnlf FROM pnlf_app;
GRANT USAGE ON SCHEMA pnlf TO pnlf_app;

-- S'assurer que les séquences d'audit restent utilisables
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pnlf TO pnlf_app;
