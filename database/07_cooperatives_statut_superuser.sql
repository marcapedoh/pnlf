-- =============================================================================
- - PNLF — Cycle de vie des coopératives (superuser postgres)
.

 
-- Identique à 07_cooperatives_statut.sql — à exécuter si pnlf_app n'a pas ALTER TABLE
-- =============================================================================

BEGIN;

ALTER TABLE pnlf.cooperatives
    ADD COLUMN IF NOT EXISTS statut VARCHAR(20) NOT NULL DEFAULT 'ACTIF';

UPDATE pnlf.cooperatives SET statut = 'ACTIF' WHERE actif = TRUE;
UPDATE pnlf.cooperatives SET statut = 'REJETE' WHERE actif = FALSE AND nom LIKE '%[REJETÉ%';
UPDATE pnlf.cooperatives SET statut = 'EN_VALIDATION' WHERE actif = FALSE AND nom NOT LIKE '%[REJETÉ%';

ALTER TABLE pnlf.cooperatives DROP CONSTRAINT IF EXISTS ck_cooperatives_statut;
ALTER TABLE pnlf.cooperatives
    ADD CONSTRAINT ck_cooperatives_statut
    CHECK (statut IN ('EN_VALIDATION', 'ACTIF', 'INACTIF', 'REJETE'));

CREATE INDEX IF NOT EXISTS idx_cooperatives_statut ON pnlf.cooperatives (statut);

COMMIT;
