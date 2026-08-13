-- =============================================================================
-- PNLF — Évolutions cadrage (type_acteur, dashboard, index)
-- Exécuter sur la base pnlf après 01-04
-- =============================================================================

BEGIN;

-- 1. Distinction producteur / collecteur (même rôle RBAC PRODUCTEUR)
ALTER TABLE pnlf.producteurs
    ADD COLUMN IF NOT EXISTS type_acteur VARCHAR(20) NOT NULL DEFAULT 'PRODUCTEUR';

ALTER TABLE pnlf.producteurs DROP CONSTRAINT IF EXISTS ck_producteurs_type_acteur;
ALTER TABLE pnlf.producteurs
    ADD CONSTRAINT ck_producteurs_type_acteur
    CHECK (type_acteur IN ('PRODUCTEUR', 'COLLECTEUR'));

CREATE INDEX IF NOT EXISTS idx_producteurs_type_acteur
    ON pnlf.producteurs (type_acteur) WHERE deleted_at IS NULL;

-- 2. Index recherche mise en relation / messagerie
CREATE INDEX IF NOT EXISTS idx_offres_demandes_province
    ON pnlf.offres_demandes (province_id, statut, type_annonce);

CREATE INDEX IF NOT EXISTS idx_offres_demandes_auteur
    ON pnlf.offres_demandes (auteur_id, statut);

CREATE INDEX IF NOT EXISTS idx_messages_expediteur
    ON pnlf.messages (expediteur_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_lots_statut_date
    ON pnlf.lots (statut, date_collecte DESC) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_mouvements_type_date
    ON pnlf.mouvements (type_mouvement, date_mouvement DESC);

-- 3. Vues dashboard (module 6.6)
CREATE OR REPLACE VIEW pnlf.v_dashboard_producteurs AS
SELECT
    pr.id AS province_id,
    pr.nom AS province_nom,
    p.type_acteur,
    p.statut,
    COUNT(*) AS nombre
FROM pnlf.producteurs p
JOIN pnlf.provinces pr ON pr.id = p.province_id
WHERE p.deleted_at IS NULL
GROUP BY pr.id, pr.nom, p.type_acteur, p.statut;

CREATE OR REPLACE VIEW pnlf.v_dashboard_lots AS
SELECT
    pr.id AS province_id,
    pr.nom AS province_nom,
    prod.id AS produit_id,
    prod.nom AS produit_nom,
    l.statut,
    DATE_TRUNC('month', l.date_collecte)::DATE AS periode_mois,
    COUNT(*) AS nb_lots,
    COALESCE(SUM(l.quantite), 0) AS quantite_totale,
    l.unite
FROM pnlf.lots l
JOIN pnlf.produits prod ON prod.id = l.produit_id
JOIN pnlf.producteurs p ON p.id = l.producteur_id
JOIN pnlf.provinces pr ON pr.id = p.province_id
WHERE l.deleted_at IS NULL
GROUP BY pr.id, pr.nom, prod.id, prod.nom, l.statut, DATE_TRUNC('month', l.date_collecte), l.unite;

CREATE OR REPLACE VIEW pnlf.v_dashboard_mouvements AS
SELECT
    m.type_mouvement,
    DATE_TRUNC('month', m.date_mouvement)::DATE AS periode_mois,
    COUNT(*) AS nb_mouvements
FROM pnlf.mouvements m
JOIN pnlf.lots l ON l.id = m.lot_id AND l.deleted_at IS NULL
GROUP BY m.type_mouvement, DATE_TRUNC('month', m.date_mouvement);

GRANT SELECT ON pnlf.v_dashboard_producteurs TO pnlf_app;
GRANT SELECT ON pnlf.v_dashboard_lots TO pnlf_app;
GRANT SELECT ON pnlf.v_dashboard_mouvements TO pnlf_app;

COMMIT;
