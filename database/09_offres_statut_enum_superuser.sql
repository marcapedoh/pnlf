-- Identique à 09_offres_statut_enum.sql — à exécuter en superuser postgres
-- si pnlf_app n'a pas le droit ALTER TYPE / ALTER TABLE.

ALTER TYPE pnlf.statut_offre ADD VALUE IF NOT EXISTS 'EN_VALIDATION';
ALTER TYPE pnlf.statut_offre ADD VALUE IF NOT EXISTS 'REJETEE';

ALTER TABLE pnlf.offres_demandes
    ADD COLUMN IF NOT EXISTS uuid_public UUID,
    ADD COLUMN IF NOT EXISTS qr_payload TEXT,
    ADD COLUMN IF NOT EXISTS qr_image_path TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_offres_demandes_uuid_public
    ON pnlf.offres_demandes (uuid_public)
    WHERE uuid_public IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_offres_demandes_statut ON pnlf.offres_demandes (statut);
