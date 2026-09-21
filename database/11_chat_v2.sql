-- =============================================================================
-- PNLF — Messagerie v2 : lecture, suppression soft, groupes
-- Tables dans public (créables par pnlf_app).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.conversation_participant_meta (
    conversation_id UUID NOT NULL REFERENCES pnlf.conversations(id) ON DELETE CASCADE,
    utilisateur_id  UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    last_read_at    TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ,
    PRIMARY KEY (conversation_id, utilisateur_id)
);

CREATE INDEX IF NOT EXISTS idx_cpm_user_active
    ON public.conversation_participant_meta (utilisateur_id)
    WHERE deleted_at IS NULL;

ALTER TABLE public.conversation_context
    ADD COLUMN IF NOT EXISTS est_groupe BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_conversation_context_groupe
    ON public.conversation_context (cooperative_id)
    WHERE est_groupe = TRUE;
