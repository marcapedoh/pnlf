-- Modération des images par IA : file des images jugées douteuses, masquées jusqu'à la décision
-- d'un administrateur (les images explicites sont refusées à l'envoi et seulement journalisées).
-- Table dans le schéma public : le compte applicatif n'a pas le droit CREATE sur le schéma pnlf.

CREATE TABLE IF NOT EXISTS public.moderation_images (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chemin         TEXT NOT NULL,
    type_objet     VARCHAR(30) NOT NULL,
    objet_id       UUID,
    envoye_par_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    verdict        VARCHAR(20) NOT NULL DEFAULT 'DOUTEUX',
    score_nsfw     NUMERIC(6, 5),
    scores         JSONB NOT NULL DEFAULT '{}'::jsonb,
    statut         VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE',
    motif          TEXT,
    traite_par_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    traite_at      TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_moderation_images_verdict CHECK (verdict IN ('DOUTEUX', 'EXPLICITE')),
    CONSTRAINT ck_moderation_images_statut
        CHECK (statut IN ('EN_ATTENTE', 'APPROUVEE', 'REJETEE', 'REMPLACEE')),
    CONSTRAINT ck_moderation_images_score CHECK (score_nsfw IS NULL OR score_nsfw BETWEEN 0 AND 1),
    CONSTRAINT ck_moderation_images_traitement
        CHECK (statut = 'EN_ATTENTE' OR traite_at IS NOT NULL)
);

-- Contrôle à chaque média servi : index partiel sur les seules images en attente.
CREATE INDEX IF NOT EXISTS idx_moderation_images_en_attente
    ON public.moderation_images (chemin) WHERE statut = 'EN_ATTENTE';

CREATE INDEX IF NOT EXISTS idx_moderation_images_statut
    ON public.moderation_images (statut, created_at DESC);
