-- =============================================================================
-- PNLF — Statuts d'offres/demandes alignés sur le workflow de validation
-- L'enum d'origine (OUVERTE, CLOTUREE, ANNULEE) ne contenait pas EN_VALIDATION
-- ni REJETEE, ce qui faisait planter POST /api/offres-demandes/ (500).
-- ALTER TYPE ... ADD VALUE ne peut pas toujours s'exécuter dans un BEGIN/COMMIT
-- (PostgreSQL < 12) : ce fichier n'utilise donc pas de transaction.
-- =============================================================================

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
