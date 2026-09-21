-- =============================================================================
-- PNLF — Offres & demandes : validation avec QR code (superuser postgres)
-- Identique à 08_offres_demandes_qr.sql — à exécuter si pnlf_app n'a pas ALTER TABLE
-- =============================================================================

BEGIN;

ALTER TABLE pnlf.offres_demandes
    ADD COLUMN IF NOT EXISTS uuid_public UUID,
    ADD COLUMN IF NOT EXISTS qr_payload TEXT,
    ADD COLUMN IF NOT EXISTS qr_image_path TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_offres_demandes_uuid_public
    ON pnlf.offres_demandes (uuid_public)
    WHERE uuid_public IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_offres_demandes_statut ON pnlf.offres_demandes (statut);

COMMIT;
