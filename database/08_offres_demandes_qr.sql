-- =============================================================================
-- PNLF — Offres & demandes : validation avec QR code public
-- Ajoute les colonnes nécessaires à la génération d'un QR code de vérification
-- publique une fois l'annonce validée par un administrateur/agent du ministère,
-- sur le même principe que le QR des lots (traceability.Lot).
-- Exécuter sur la base pnlf après 01-07.
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
