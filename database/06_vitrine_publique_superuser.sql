-- =============================================================================
-- PNLF — Vitrine publique (superuser postgres)
-- Identique à 06_vitrine_publique.sql — à exécuter si pnlf_app n'a pas ALTER TABLE
-- =============================================================================

BEGIN;

ALTER TABLE pnlf.producteurs
    ADD COLUMN IF NOT EXISTS photo_path TEXT;

ALTER TABLE pnlf.produits
    ADD COLUMN IF NOT EXISTS image_path TEXT;

ALTER TABLE pnlf.producteurs
    ADD COLUMN IF NOT EXISTS visible_public BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS pnlf.messages_publics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producteur_id UUID NOT NULL REFERENCES pnlf.producteurs(id) ON DELETE CASCADE,
    nom_visiteur VARCHAR(150) NOT NULL,
    email_visiteur VARCHAR(255) NOT NULL,
    telephone_visiteur VARCHAR(30),
    message TEXT NOT NULL,
    ip_adresse VARCHAR(64),
    statut VARCHAR(20) NOT NULL DEFAULT 'NOUVEAU',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    traite_at TIMESTAMPTZ
);

ALTER TABLE pnlf.messages_publics DROP CONSTRAINT IF EXISTS ck_messages_publics_statut;
ALTER TABLE pnlf.messages_publics
    ADD CONSTRAINT ck_messages_publics_statut
    CHECK (statut IN ('NOUVEAU', 'TRAITE'));

CREATE INDEX IF NOT EXISTS idx_messages_publics_producteur
    ON pnlf.messages_publics (producteur_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_publics_statut
    ON pnlf.messages_publics (statut, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_producteurs_visible_public
    ON pnlf.producteurs (statut, visible_public) WHERE deleted_at IS NULL;

GRANT SELECT, INSERT, UPDATE ON pnlf.messages_publics TO pnlf_app;

COMMIT;
