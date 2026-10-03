-- Cycle de vie des lots réduit à trois statuts (BROUILLON, VALIDE, COMMERCIALISE),
-- journal des transitions de statut et pièces justificatives des demandes de certification.
-- Tables dans le schéma public : le compte applicatif n'a pas le droit CREATE sur le schéma pnlf.

CREATE TABLE IF NOT EXISTS public.lots_transitions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id          UUID NOT NULL REFERENCES pnlf.lots(id) ON DELETE CASCADE,
    ancien_statut   VARCHAR(20),
    nouveau_statut  VARCHAR(20) NOT NULL,
    mode            VARCHAR(20) NOT NULL,
    role_auteur     VARCHAR(30),
    auteur_id       UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    motif           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_lots_transitions_mode
        CHECK (mode IN ('AGENT', 'AUTO', 'PROPRIETAIRE', 'MIGRATION'))
);

CREATE INDEX IF NOT EXISTS idx_lots_transitions_lot
    ON public.lots_transitions (lot_id, created_at);

CREATE TABLE IF NOT EXISTS public.certifications_pieces (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certification_id  UUID NOT NULL REFERENCES pnlf.certifications(id) ON DELETE CASCADE,
    intitule          VARCHAR(150) NOT NULL,
    chemin            TEXT NOT NULL,
    nom_original      VARCHAR(255),
    type_mime         VARCHAR(60),
    taille_octets     INTEGER,
    depose_par_id     UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_certif_pieces_taille CHECK (taille_octets IS NULL OR taille_octets > 0)
);

CREATE INDEX IF NOT EXISTS idx_certifications_pieces_cert
    ON public.certifications_pieces (certification_id, created_at);

-- Migration des statuts abandonnés. L'ancien statut est conservé dans lots_transitions ;
-- les mouvements (inaltérables) ne sont pas touchés.
INSERT INTO public.lots_transitions (lot_id, ancien_statut, nouveau_statut, mode, motif)
SELECT l.id,
       l.statut::text,
       CASE l.statut::text
           WHEN 'DECLARE' THEN 'BROUILLON'
           WHEN 'TRANSFORME' THEN 'VALIDE'
           WHEN 'EN_TRANSIT' THEN 'VALIDE'
           ELSE 'BROUILLON'
       END,
       'MIGRATION',
       CASE
           WHEN l.statut::text IN ('ANNULE', 'ARCHIVE')
               THEN 'Passage au cycle à trois statuts : lot annulé ou archivé retiré des listes.'
           ELSE 'Passage au cycle à trois statuts (brouillon, validé, commercialisé).'
       END
  FROM pnlf.lots l
 WHERE l.statut::text IN ('DECLARE', 'TRANSFORME', 'EN_TRANSIT', 'ANNULE', 'ARCHIVE');

-- Date de validation estimée pour les lots validés avant l'existence du journal (calculée
-- avant les changements de statut, qui mettent à jour updated_at) : première étape
-- postérieure à la collecte, à défaut dernière mise à jour.
UPDATE pnlf.lots l
   SET valide_at = COALESCE(
           (SELECT MIN(m.date_mouvement) FROM pnlf.mouvements m
             WHERE m.lot_id = l.id AND m.type_mouvement::text <> 'COLLECTE'),
           l.updated_at)
 WHERE l.statut::text IN ('VALIDE', 'COMMERCIALISE', 'TRANSFORME', 'EN_TRANSIT') AND l.valide_at IS NULL;

UPDATE pnlf.lots SET statut = 'BROUILLON' WHERE statut::text = 'DECLARE';

UPDATE pnlf.lots SET statut = 'VALIDE' WHERE statut::text IN ('TRANSFORME', 'EN_TRANSIT');

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'pnlf' AND table_name = 'lots' AND column_name = 'deleted_at'
    ) THEN
        UPDATE pnlf.lots
           SET statut = 'BROUILLON', deleted_at = COALESCE(deleted_at, CURRENT_TIMESTAMP)
         WHERE statut::text IN ('ANNULE', 'ARCHIVE');
    ELSE
        UPDATE pnlf.lots SET statut = 'BROUILLON' WHERE statut::text IN ('ANNULE', 'ARCHIVE');
    END IF;
END;
$$;
