-- =============================================================================
-- PNLF — Documents administratifs (superuser postgres)
-- Identique à 12_documents_administratifs.sql — à exécuter si pnlf_app n'a pas
-- les droits CREATE TABLE sur le schéma public.
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.documents_inscription (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_type    VARCHAR(20) NOT NULL,
    entite_id      UUID NOT NULL,
    type_document  VARCHAR(30) NOT NULL,
    chemin         TEXT NOT NULL,
    nom_original   VARCHAR(255),
    depose_par_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_doc_entite_type CHECK (entite_type IN ('PRODUCTEUR', 'COOPERATIVE', 'UTILISATEUR')),
    CONSTRAINT ck_doc_type CHECK (
        type_document IN ('CNI', 'FICHE_CIRCUIT', 'AGREMENT_NAGOYA', 'AUTRE')
    )
);

CREATE INDEX IF NOT EXISTS idx_documents_inscription_entite
    ON public.documents_inscription (entite_type, entite_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents_inscription TO pnlf_app;

COMMIT;
