-- =============================================================================
-- PNLF — Cycle de vie des coopératives : statut détaillé (EN_VALIDATION / ACTIF /
-- INACTIF / REJETE), aligné sur le modèle déjà utilisé pour les producteurs.
-- Permet de distinguer une coopérative en attente de validation d'une
-- coopérative active désactivée par un administrateur, deux cas qui étaient
-- jusque-là confondus dans le seul booléen `actif`.
-- Exécuter sur la base pnlf après 01-06.
-- =============================================================================

BEGIN;

ALTER TABLE pnlf.cooperatives
    ADD COLUMN IF NOT EXISTS statut VARCHAR(20) NOT NULL DEFAULT 'ACTIF';

-- Rétro-remplissage à partir de l'état actuel :
--   - actif = true                              -> ACTIF
--   - actif = false et nom suffixé [REJETÉ ...]  -> REJETE
--   - actif = false, non suffixé (jamais validée)-> EN_VALIDATION
UPDATE pnlf.cooperatives SET statut = 'ACTIF' WHERE actif = TRUE;
UPDATE pnlf.cooperatives SET statut = 'REJETE' WHERE actif = FALSE AND nom LIKE '%[REJETÉ%';
UPDATE pnlf.cooperatives SET statut = 'EN_VALIDATION' WHERE actif = FALSE AND nom NOT LIKE '%[REJETÉ%';

ALTER TABLE pnlf.cooperatives DROP CONSTRAINT IF EXISTS ck_cooperatives_statut;
ALTER TABLE pnlf.cooperatives
    ADD CONSTRAINT ck_cooperatives_statut
    CHECK (statut IN ('EN_VALIDATION', 'ACTIF', 'INACTIF', 'REJETE'));

CREATE INDEX IF NOT EXISTS idx_cooperatives_statut ON pnlf.cooperatives (statut);

COMMIT;
