-- Identique à 10_chat.sql (tables dans public, créables par pnlf_app).

CREATE TABLE IF NOT EXISTS public.conversation_context (
    conversation_id UUID PRIMARY KEY REFERENCES pnlf.conversations(id) ON DELETE CASCADE,
    producteur_id   UUID REFERENCES pnlf.producteurs(id) ON DELETE SET NULL,
    cooperative_id  UUID REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_conversation_context_producteur
    ON public.conversation_context (producteur_id)
    WHERE producteur_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_conversation_context_cooperative
    ON public.conversation_context (cooperative_id)
    WHERE cooperative_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.message_pieces (
    message_id  UUID PRIMARY KEY REFERENCES pnlf.messages(id) ON DELETE CASCADE,
    piece_type  VARCHAR(10) NOT NULL CHECK (piece_type IN ('IMAGE', 'AUDIO')),
    piece_path  VARCHAR(400) NOT NULL
);
