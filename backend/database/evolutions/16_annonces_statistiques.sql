-- Annonces (détails complémentaires, trace de modération) et statistiques intégrées
-- (connexions, présence en temps réel, visites anonymes des pages publiques).
-- Tables dans le schéma public : le compte applicatif n'a pas le droit CREATE sur le schéma pnlf.

-- Détails d'une annonce absents de pnlf.offres_demandes (extension 1-1).
CREATE TABLE IF NOT EXISTS public.offres_details (
    offre_id             UUID PRIMARY KEY REFERENCES pnlf.offres_demandes(id) ON DELETE CASCADE,
    categorie_id         UUID REFERENCES pnlf.categories_produit(id) ON DELETE SET NULL,
    prix_total           NUMERIC(16, 2),
    negociable           BOOLEAN NOT NULL DEFAULT FALSE,
    conditionnement      VARCHAR(150),
    qualite              VARCHAR(200),
    localite             VARCHAR(150),
    disponible_du        DATE,
    mode_remise          VARCHAR(30),
    modalites_livraison  TEXT,
    moyens_paiement      VARCHAR(30)[] NOT NULL DEFAULT '{}',
    conditions_paiement  TEXT,
    afficher_telephone   BOOLEAN NOT NULL DEFAULT FALSE,
    afficher_email       BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_offres_details_prix_total CHECK (prix_total IS NULL OR prix_total >= 0),
    CONSTRAINT ck_offres_details_mode_remise
        CHECK (mode_remise IS NULL OR mode_remise IN ('LIVRAISON', 'RETRAIT', 'LIVRAISON_OU_RETRAIT'))
);

CREATE INDEX IF NOT EXISTS idx_offres_details_categorie ON public.offres_details (categorie_id);

-- Dernière décision de modération (validation ou rejet) : visible uniquement dans l'espace connecté.
CREATE TABLE IF NOT EXISTS public.offres_moderation (
    offre_id        UUID PRIMARY KEY REFERENCES pnlf.offres_demandes(id) ON DELETE CASCADE,
    decision        VARCHAR(20) NOT NULL,
    moderateur_id   UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    moderateur_nom  VARCHAR(260),
    motif           TEXT,
    decide_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_offres_moderation_decision CHECK (decision IN ('VALIDEE', 'REJETEE'))
);

-- Tentatives de connexion (réussies ou non), avec analyse du navigateur faite côté serveur.
CREATE TABLE IF NOT EXISTS public.connexions (
    id                  BIGSERIAL PRIMARY KEY,
    utilisateur_id      UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    email_saisi         VARCHAR(254),
    role                VARCHAR(30),
    succes              BOOLEAN NOT NULL,
    motif_echec         VARCHAR(30),
    ip_adresse          INET,
    appareil            VARCHAR(20) NOT NULL DEFAULT 'INCONNU',
    systeme             VARCHAR(40),
    navigateur          VARCHAR(40),
    empreinte_appareil  VARCHAR(64),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_connexions_created_at ON public.connexions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_connexions_utilisateur ON public.connexions (utilisateur_id, created_at DESC);

-- Présence en temps réel : une ligne par utilisateur et par appareil, rafraîchie par le heartbeat.
CREATE TABLE IF NOT EXISTS public.presences (
    utilisateur_id      UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    empreinte_appareil  VARCHAR(64) NOT NULL,
    appareil            VARCHAR(20) NOT NULL DEFAULT 'INCONNU',
    systeme             VARCHAR(40),
    navigateur          VARCHAR(40),
    ip_adresse          INET,
    debut_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    derniere_activite   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (utilisateur_id, empreinte_appareil)
);

CREATE INDEX IF NOT EXISTS idx_presences_activite ON public.presences (derniere_activite DESC);

-- Visites des pages publiques : compteur agrégé anonyme (aucune donnée personnelle).
CREATE TABLE IF NOT EXISTS public.visites_publiques (
    jour      DATE NOT NULL,
    page      VARCHAR(120) NOT NULL,
    appareil  VARCHAR(20) NOT NULL,
    visites   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (jour, page, appareil)
);

-- Historique : les connexions réussies déjà tracées dans le journal d'audit alimentent les statistiques.
-- L'analyse du navigateur reprend les règles de accounts/appareils.py.
INSERT INTO public.connexions (
    utilisateur_id, email_saisi, role, succes, ip_adresse, appareil, systeme, navigateur,
    empreinte_appareil, created_at
)
SELECT u.id,
       LEFT(COALESCE(a.nouvelles_valeurs->>'email', u.email), 254),
       LEFT(COALESCE(a.nouvelles_valeurs->>'role', u.role::text), 30),
       TRUE,
       a.ip_adresse,
       CASE
           WHEN COALESCE(a.user_agent, '') = '' THEN 'INCONNU'
           WHEN a.user_agent ~* '(bot|crawler|spider|curl|wget|python-requests|httpclient)' THEN 'ROBOT'
           WHEN a.user_agent ~* '(ipad|tablet|kindle|silk)' THEN 'TABLETTE'
           WHEN a.user_agent ~* 'android' AND a.user_agent !~* 'mobile' THEN 'TABLETTE'
           WHEN a.user_agent ~* '(mobi|iphone|ipod|android|windows phone)' THEN 'MOBILE'
           ELSE 'ORDINATEUR'
       END,
       CASE
           WHEN a.user_agent ~* 'windows phone' THEN 'Windows Phone'
           WHEN a.user_agent ~* 'windows' THEN 'Windows'
           WHEN a.user_agent ~* 'android' THEN 'Android'
           WHEN a.user_agent ~* '(iphone|ipad|ipod)' THEN 'iOS'
           WHEN a.user_agent ~* 'cros' THEN 'ChromeOS'
           WHEN a.user_agent ~* '(mac os|macintosh)' THEN 'macOS'
           WHEN a.user_agent ~* 'linux' THEN 'Linux'
       END,
       CASE
           WHEN a.user_agent ~* 'edg(e|a|ios)?/' THEN 'Edge'
           WHEN a.user_agent ~* '(opr/|opera)' THEN 'Opera'
           WHEN a.user_agent ~* 'samsungbrowser' THEN 'Samsung Internet'
           WHEN a.user_agent ~* '(firefox|fxios)/' THEN 'Firefox'
           WHEN a.user_agent ~* '(chrome|crios|chromium)/' THEN 'Chrome'
           WHEN a.user_agent ~* 'safari/' THEN 'Safari'
       END,
       CASE WHEN COALESCE(a.user_agent, '') <> ''
            THEN LEFT(ENCODE(SHA256(CONVERT_TO(a.user_agent, 'UTF8')), 'hex'), 32) END,
       a.created_at
FROM pnlf.audit_logs a
LEFT JOIN pnlf.utilisateurs u ON u.id = a.utilisateur_id
WHERE a.action = 'LOGIN'
  AND NOT EXISTS (SELECT 1 FROM public.connexions);

-- Trace de modération des annonces déjà validées ou rejetées (d'après le journal d'audit).
INSERT INTO public.offres_moderation (offre_id, decision, moderateur_id, moderateur_nom, motif, decide_at)
SELECT DISTINCT ON (a.enregistrement_id)
       a.enregistrement_id,
       CASE a.action WHEN 'VALIDATE' THEN 'VALIDEE' ELSE 'REJETEE' END,
       u.id,
       NULLIF(TRIM(COALESCE(u.prenoms, '') || ' ' || COALESCE(u.nom, '')), ''),
       a.nouvelles_valeurs->>'motif',
       a.created_at
FROM pnlf.audit_logs a
JOIN pnlf.offres_demandes o ON o.id = a.enregistrement_id
LEFT JOIN pnlf.utilisateurs u ON u.id = a.utilisateur_id
WHERE a.table_cible = 'offres_demandes'
  AND a.action IN ('VALIDATE', 'REJECT')
ORDER BY a.enregistrement_id, a.created_at DESC
ON CONFLICT (offre_id) DO NOTHING;
