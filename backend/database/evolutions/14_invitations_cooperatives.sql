-- Invitations envoyées par une coopérative à un producteur/collecteur (sens inverse de la demande d'adhésion).
-- Table dans le schéma public : le compte applicatif n'a pas le droit CREATE sur le schéma pnlf.

CREATE TABLE IF NOT EXISTS public.invitations_cooperative (
    id              UUID PRIMARY KEY,
    cooperative_id  UUID NOT NULL REFERENCES pnlf.cooperatives(id) ON DELETE CASCADE,
    producteur_id   UUID NOT NULL REFERENCES pnlf.producteurs(id) ON DELETE CASCADE,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE',
    message         TEXT,
    invite_par_id   UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    repondu_par_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    motif_reponse   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    repondu_at      TIMESTAMPTZ,
    CONSTRAINT ck_invitation_coop_statut
        CHECK (statut IN ('EN_ATTENTE', 'ACCEPTEE', 'REFUSEE', 'ANNULEE', 'CADUQUE'))
);

-- Une seule invitation en attente par couple coopérative / producteur.
CREATE UNIQUE INDEX IF NOT EXISTS uq_invitation_coop_en_attente
    ON public.invitations_cooperative (cooperative_id, producteur_id)
    WHERE statut = 'EN_ATTENTE';

CREATE INDEX IF NOT EXISTS idx_invitation_coop_producteur
    ON public.invitations_cooperative (producteur_id, statut);

CREATE INDEX IF NOT EXISTS idx_invitation_coop_cooperative
    ON public.invitations_cooperative (cooperative_id, statut, created_at DESC);
