-- =============================================================================
-- PNLF-PFNL — Script d'initialisation PostgreSQL + PostGIS
-- Plateforme Numérique de Traçabilité des Produits Forestiers Non Ligneux
-- Version : 1.0 | Compatible PostgreSQL 14+
-- =============================================================================
-- PROCÉDURE pgAdmin (résumé) :
--   1. Créer la base "pnlf" (Encoding UTF8, Collation French_France ou C)
--   2. Se connecter à la base pnlf
--   3. Tools > Query Tool > coller ce script > Execute (F5)
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. EXTENSIONS
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";      -- gen_random_uuid(), cryptage
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID alternatif
CREATE EXTENSION IF NOT EXISTS "postgis";        -- géolocalisation
CREATE EXTENSION IF NOT EXISTS "citext";         -- e-mails insensibles à la casse
CREATE EXTENSION IF NOT EXISTS "unaccent";       -- recherche textuelle FR
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- recherche floue / index trigram

-- -----------------------------------------------------------------------------
-- 2. SCHÉMA APPLICATIF (isolement sécurité)
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS pnlf AUTHORIZATION CURRENT_USER;
COMMENT ON SCHEMA pnlf IS 'Schéma métier PNLF-PFNL';

SET search_path TO pnlf, public;

-- -----------------------------------------------------------------------------
-- 3. TYPES ÉNUMÉRÉS
-- -----------------------------------------------------------------------------
CREATE TYPE pnlf.role_utilisateur AS ENUM (
    'ADMINISTRATEUR',
    'AGENT_MINISTERE',
    'AGENT_FORESTIER',
    'PRODUCTEUR',
    'COOPERATIVE',
    'ACHETEUR'
);

CREATE TYPE pnlf.statut_compte AS ENUM (
    'ACTIF',
    'INACTIF',
    'SUSPENDU',
    'EN_ATTENTE'
);

CREATE TYPE pnlf.statut_producteur AS ENUM (
    'ACTIF',
    'INACTIF',
    'EN_VALIDATION',
    'REJETE'
);

CREATE TYPE pnlf.statut_lot AS ENUM (
    'BROUILLON',
    'DECLARE',
    'VALIDE',
    'EN_TRANSIT',
    'TRANSFORME',
    'COMMERCIALISE',
    'ARCHIVE',
    'ANNULE'
);

CREATE TYPE pnlf.type_mouvement AS ENUM (
    'COLLECTE',
    'RECEPTION_COOPERATIVE',
    'TRANSFERT',
    'TRANSFORMATION',
    'CONTROLE',
    'VENTE',
    'EXPORT',
    'AUTRE'
);

CREATE TYPE pnlf.statut_certification AS ENUM (
    'DEMANDEE',
    'EN_COURS',
    'OBTENUE',
    'EXPIREE',
    'REFUSEE',
    'REVOQUEE'
);

CREATE TYPE pnlf.unite_mesure AS ENUM (
    'KG',
    'G',
    'LITRE',
    'ML',
    'UNITE',
    'BOTTE',
    'SAC',
    'M3',
    'METRE'
);

CREATE TYPE pnlf.type_notification AS ENUM (
    'EMAIL',
    'SMS',
    'INTERNE'
);

CREATE TYPE pnlf.canal_notification AS ENUM (
    'EMAIL',
    'SMS',
    'LES_DEUX',
    'AUCUN'
);

CREATE TYPE pnlf.type_offre AS ENUM (
    'OFFRE',
    'DEMANDE'
);

CREATE TYPE pnlf.statut_offre AS ENUM (
    'EN_VALIDATION',
    'OUVERTE',
    'REJETEE',
    'CLOTUREE',
    'ANNULEE'
);

CREATE TYPE pnlf.statut_sync AS ENUM (
    'PENDING',
    'SYNCED',
    'CONFLICT',
    'ERROR'
);

-- -----------------------------------------------------------------------------
-- 4. FONCTIONS UTILITAIRES
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pnlf.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION pnlf.generer_code_lot()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.code_lot IS NULL OR NEW.code_lot = '' THEN
        NEW.code_lot := 'PNLF-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                        UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 10));
    END IF;
    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. RÉFÉRENTIEL GÉOGRAPHIQUE (Gabon)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.provinces (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(10)  NOT NULL,
    nom             VARCHAR(100) NOT NULL,
    geom            GEOMETRY(MultiPolygon, 4326),
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_provinces_code UNIQUE (code),
    CONSTRAINT uq_provinces_nom  UNIQUE (nom),
    CONSTRAINT ck_provinces_code CHECK (code ~ '^[A-Z0-9_]{2,10}$')
);

CREATE TABLE pnlf.departements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    province_id     UUID NOT NULL REFERENCES pnlf.provinces(id) ON DELETE RESTRICT,
    code            VARCHAR(20)  NOT NULL,
    nom             VARCHAR(120) NOT NULL,
    geom            GEOMETRY(MultiPolygon, 4326),
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_departements_code UNIQUE (code),
    CONSTRAINT uq_departements_nom_province UNIQUE (province_id, nom)
);

CREATE TABLE pnlf.villages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    departement_id  UUID NOT NULL REFERENCES pnlf.departements(id) ON DELETE RESTRICT,
    nom             VARCHAR(150) NOT NULL,
    latitude        NUMERIC(10, 7),
    longitude       NUMERIC(10, 7),
    geom            GEOMETRY(Point, 4326),
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_villages_nom_dept UNIQUE (departement_id, nom),
    CONSTRAINT ck_villages_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_villages_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
);

CREATE INDEX idx_villages_geom ON pnlf.villages USING GIST (geom);
CREATE INDEX idx_provinces_geom ON pnlf.provinces USING GIST (geom);

-- -----------------------------------------------------------------------------
-- 6. UTILISATEURS & SÉCURITÉ D'ACCÈS
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.utilisateurs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               CITEXT NOT NULL,
    telephone           VARCHAR(30),
    mot_de_passe_hash   TEXT NOT NULL,          -- hash applicatif (argon2/bcrypt) — jamais en clair
    role                pnlf.role_utilisateur NOT NULL,
    statut              pnlf.statut_compte NOT NULL DEFAULT 'EN_ATTENTE',
    nom                 VARCHAR(100) NOT NULL,
    prenoms             VARCHAR(150) NOT NULL,
    double_auth_active  BOOLEAN NOT NULL DEFAULT FALSE,
    derniere_connexion  TIMESTAMPTZ,
    tentatives_echec    SMALLINT NOT NULL DEFAULT 0,
    verrouille_jusquau  TIMESTAMPTZ,
    doit_changer_mdp    BOOLEAN NOT NULL DEFAULT FALSE,
    preferences_notif   pnlf.canal_notification NOT NULL DEFAULT 'EMAIL',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,            -- soft delete
    CONSTRAINT uq_utilisateurs_email UNIQUE (email),
    CONSTRAINT ck_utilisateurs_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_utilisateurs_telephone CHECK (
        telephone IS NULL OR telephone ~ '^\+?[0-9]{8,20}$'
    ),
    CONSTRAINT ck_utilisateurs_tentatives CHECK (tentatives_echec >= 0 AND tentatives_echec <= 20),
    CONSTRAINT ck_utilisateurs_mdp_non_vide CHECK (length(mot_de_passe_hash) >= 20)
);

CREATE INDEX idx_utilisateurs_role ON pnlf.utilisateurs (role) WHERE deleted_at IS NULL;
CREATE INDEX idx_utilisateurs_statut ON pnlf.utilisateurs (statut) WHERE deleted_at IS NULL;

CREATE TABLE pnlf.sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id  UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    jti             VARCHAR(64) NOT NULL,       -- JWT ID
    refresh_token_hash TEXT NOT NULL,
    ip_adresse      INET,
    user_agent      TEXT,
    expire_at       TIMESTAMPTZ NOT NULL,
    revoquee_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sessions_jti UNIQUE (jti)
);

CREATE INDEX idx_sessions_user ON pnlf.sessions (utilisateur_id) WHERE revoquee_at IS NULL;

CREATE TABLE pnlf.reinitialisations_mdp (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id  UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    token_hash      TEXT NOT NULL,
    expire_at       TIMESTAMPTZ NOT NULL,
    utilise_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reset_token UNIQUE (token_hash)
);

-- -----------------------------------------------------------------------------
-- 7. COOPÉRATIVES
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.cooperatives (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(30)  NOT NULL,
    nom                 VARCHAR(200) NOT NULL,
    numero_agrement     VARCHAR(80),
    telephone           VARCHAR(30),
    email               CITEXT,
    adresse             TEXT,
    province_id         UUID REFERENCES pnlf.provinces(id) ON DELETE SET NULL,
    departement_id      UUID REFERENCES pnlf.departements(id) ON DELETE SET NULL,
    village_id          UUID REFERENCES pnlf.villages(id) ON DELETE SET NULL,
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    geom                GEOMETRY(Point, 4326),
    utilisateur_id      UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    actif               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cooperatives_code UNIQUE (code),
    CONSTRAINT uq_cooperatives_nom  UNIQUE (nom),
    CONSTRAINT ck_coop_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_coop_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
);

CREATE INDEX idx_cooperatives_geom ON pnlf.cooperatives USING GIST (geom);

-- -----------------------------------------------------------------------------
-- 8. PRODUCTEURS / COLLECTEURS
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.producteurs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_producteur     VARCHAR(30) NOT NULL,
    nom                 VARCHAR(100) NOT NULL,
    prenoms             VARCHAR(150) NOT NULL,
    date_naissance      DATE,
    type_piece_identite VARCHAR(50),
    numero_piece        VARCHAR(80),
    telephone           VARCHAR(30),
    email               CITEXT,
    communaute          VARCHAR(120),
    province_id         UUID NOT NULL REFERENCES pnlf.provinces(id) ON DELETE RESTRICT,
    departement_id      UUID REFERENCES pnlf.departements(id) ON DELETE SET NULL,
    village_id          UUID REFERENCES pnlf.villages(id) ON DELETE SET NULL,
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    geom                GEOMETRY(Point, 4326),
    cooperative_id      UUID REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL,
    utilisateur_id      UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    type_acteur         VARCHAR(20) NOT NULL DEFAULT 'PRODUCTEUR',
    statut              pnlf.statut_producteur NOT NULL DEFAULT 'EN_VALIDATION',
    valide_par          UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    valide_at           TIMESTAMPTZ,
    notes               TEXT,
    -- champs sync offline
    client_uuid         UUID,                   -- id généré côté tablette
    sync_statut         pnlf.statut_sync NOT NULL DEFAULT 'SYNCED',
    sync_version        BIGINT NOT NULL DEFAULT 1,
    last_synced_at      TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT uq_producteurs_code UNIQUE (code_producteur),
    CONSTRAINT uq_producteurs_piece UNIQUE (type_piece_identite, numero_piece),
    CONSTRAINT uq_producteurs_client_uuid UNIQUE (client_uuid),
    CONSTRAINT ck_prod_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_prod_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    CONSTRAINT ck_prod_naissance CHECK (date_naissance IS NULL OR date_naissance < CURRENT_DATE),
    CONSTRAINT ck_producteurs_type_acteur CHECK (type_acteur IN ('PRODUCTEUR', 'COLLECTEUR'))
);

CREATE INDEX idx_producteurs_province ON pnlf.producteurs (province_id);
CREATE INDEX idx_producteurs_coop ON pnlf.producteurs (cooperative_id);
CREATE INDEX idx_producteurs_geom ON pnlf.producteurs USING GIST (geom);
CREATE INDEX idx_producteurs_nom ON pnlf.producteurs USING GIN ((nom || ' ' || prenoms) gin_trgm_ops);

CREATE TABLE pnlf.cooperative_membres (
    cooperative_id  UUID NOT NULL REFERENCES pnlf.cooperatives(id) ON DELETE CASCADE,
    producteur_id   UUID NOT NULL REFERENCES pnlf.producteurs(id) ON DELETE CASCADE,
    date_adhesion   DATE NOT NULL DEFAULT CURRENT_DATE,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cooperative_id, producteur_id)
);

-- -----------------------------------------------------------------------------
-- 9. RÉFÉRENTIEL PRODUITS PFNL (extensible sans code)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.categories_produit (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(30)  NOT NULL,
    libelle         VARCHAR(150) NOT NULL,
    description     TEXT,
    parent_id       UUID REFERENCES pnlf.categories_produit(id) ON DELETE SET NULL,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_categories_code UNIQUE (code),
    CONSTRAINT uq_categories_libelle UNIQUE (libelle)
);

CREATE TABLE pnlf.produits (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(40)  NOT NULL,
    nom                 VARCHAR(200) NOT NULL,
    nom_scientifique    VARCHAR(200),
    categorie_id        UUID NOT NULL REFERENCES pnlf.categories_produit(id) ON DELETE RESTRICT,
    description         TEXT,
    unite_defaut        pnlf.unite_mesure NOT NULL DEFAULT 'KG',
    soumis_cites        BOOLEAN NOT NULL DEFAULT FALSE,
    code_cites          VARCHAR(50),
    actif               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_produits_code UNIQUE (code),
    CONSTRAINT uq_produits_nom  UNIQUE (nom),
    CONSTRAINT ck_produits_cites CHECK (
        (soumis_cites = FALSE AND code_cites IS NULL)
        OR (soumis_cites = TRUE)
    )
);

CREATE INDEX idx_produits_categorie ON pnlf.produits (categorie_id);
CREATE INDEX idx_produits_nom_trgm ON pnlf.produits USING GIN (nom gin_trgm_ops);

CREATE TABLE pnlf.producteur_produits (
    producteur_id   UUID NOT NULL REFERENCES pnlf.producteurs(id) ON DELETE CASCADE,
    produit_id      UUID NOT NULL REFERENCES pnlf.produits(id) ON DELETE CASCADE,
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (producteur_id, produit_id)
);

-- -----------------------------------------------------------------------------
-- 10. ZONES DE COLLECTE
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.zones_collecte (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(40) NOT NULL,
    libelle         VARCHAR(200) NOT NULL,
    province_id     UUID NOT NULL REFERENCES pnlf.provinces(id) ON DELETE RESTRICT,
    description     TEXT,
    latitude        NUMERIC(10, 7),
    longitude       NUMERIC(10, 7),
    geom            GEOMETRY(Point, 4326),
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_zones_code UNIQUE (code),
    CONSTRAINT ck_zones_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_zones_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
);

CREATE INDEX idx_zones_geom ON pnlf.zones_collecte USING GIST (geom);

-- -----------------------------------------------------------------------------
-- 11. LOTS & TRAÇABILITÉ (cœur métier)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.lots (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_lot            VARCHAR(40) NOT NULL,
    uuid_public         UUID NOT NULL DEFAULT gen_random_uuid(), -- pour QR / vérification publique
    produit_id          UUID NOT NULL REFERENCES pnlf.produits(id) ON DELETE RESTRICT,
    producteur_id       UUID NOT NULL REFERENCES pnlf.producteurs(id) ON DELETE RESTRICT,
    cooperative_id      UUID REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL,
    zone_collecte_id    UUID REFERENCES pnlf.zones_collecte(id) ON DELETE SET NULL,
    date_collecte       DATE NOT NULL,
    quantite            NUMERIC(14, 3) NOT NULL,
    unite               pnlf.unite_mesure NOT NULL,
    qualite_indicateur  VARCHAR(100),
    prix_indicatif      NUMERIC(14, 2),
    devise              CHAR(3) NOT NULL DEFAULT 'XAF',
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    geom                GEOMETRY(Point, 4326),
    statut              pnlf.statut_lot NOT NULL DEFAULT 'DECLARE',
    qr_payload          TEXT,                   -- contenu encodé dans le QR
    qr_image_path       TEXT,                   -- chemin fichier généré
    declare_par         UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    valide_par          UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    valide_at           TIMESTAMPTZ,
    observations        TEXT,
    -- sync offline
    client_uuid         UUID,
    sync_statut         pnlf.statut_sync NOT NULL DEFAULT 'SYNCED',
    sync_version        BIGINT NOT NULL DEFAULT 1,
    last_synced_at      TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT uq_lots_code UNIQUE (code_lot),
    CONSTRAINT uq_lots_uuid_public UNIQUE (uuid_public),
    CONSTRAINT uq_lots_client_uuid UNIQUE (client_uuid),
    CONSTRAINT ck_lots_quantite CHECK (quantite > 0),
    CONSTRAINT ck_lots_prix CHECK (prix_indicatif IS NULL OR prix_indicatif >= 0),
    CONSTRAINT ck_lots_date CHECK (date_collecte <= CURRENT_DATE + INTERVAL '1 day'),
    CONSTRAINT ck_lots_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_lots_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    CONSTRAINT ck_lots_devise CHECK (devise ~ '^[A-Z]{3}$')
);

CREATE INDEX idx_lots_produit ON pnlf.lots (produit_id);
CREATE INDEX idx_lots_producteur ON pnlf.lots (producteur_id);
CREATE INDEX idx_lots_statut ON pnlf.lots (statut) WHERE deleted_at IS NULL;
CREATE INDEX idx_lots_date ON pnlf.lots (date_collecte DESC);
CREATE INDEX idx_lots_geom ON pnlf.lots USING GIST (geom);

CREATE TRIGGER trg_lots_code
    BEFORE INSERT ON pnlf.lots
    FOR EACH ROW
    EXECUTE FUNCTION pnlf.generer_code_lot();

-- Historique inaltérable des mouvements (append-only recommandé côté appli)
CREATE TABLE pnlf.mouvements (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id              UUID NOT NULL REFERENCES pnlf.lots(id) ON DELETE RESTRICT,
    type_mouvement      pnlf.type_mouvement NOT NULL,
    date_mouvement      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lieu_libelle        VARCHAR(200),
    latitude            NUMERIC(10, 7),
    longitude           NUMERIC(10, 7),
    geom                GEOMETRY(Point, 4326),
    quantite            NUMERIC(14, 3),
    unite               pnlf.unite_mesure,
    acteur_utilisateur_id UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    acteur_producteur_id  UUID REFERENCES pnlf.producteurs(id) ON DELETE SET NULL,
    acteur_cooperative_id UUID REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL,
    destinataire_libelle  VARCHAR(200),
    commentaire         TEXT,
    hash_precedent      CHAR(64),               -- chaînage optionnel (intégrité)
    hash_courant        CHAR(64),
    -- sync offline
    client_uuid         UUID,
    sync_statut         pnlf.statut_sync NOT NULL DEFAULT 'SYNCED',
    sync_version        BIGINT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_mouvements_client_uuid UNIQUE (client_uuid),
    CONSTRAINT ck_mvt_quantite CHECK (quantite IS NULL OR quantite > 0),
    CONSTRAINT ck_mvt_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    CONSTRAINT ck_mvt_lon CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    CONSTRAINT ck_mvt_acteur CHECK (
        acteur_utilisateur_id IS NOT NULL
        OR acteur_producteur_id IS NOT NULL
        OR acteur_cooperative_id IS NOT NULL
    )
);

CREATE INDEX idx_mouvements_lot ON pnlf.mouvements (lot_id, date_mouvement);
CREATE INDEX idx_mouvements_type ON pnlf.mouvements (type_mouvement);
CREATE INDEX idx_mouvements_geom ON pnlf.mouvements USING GIST (geom);

-- Empêcher UPDATE/DELETE des mouvements (inaltérabilité)
CREATE OR REPLACE FUNCTION pnlf.interdire_modif_mouvement()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Les mouvements de traçabilité sont inaltérables (UPDATE/DELETE interdits)';
END;
$$;

CREATE TRIGGER trg_mouvements_immutable_upd
    BEFORE UPDATE ON pnlf.mouvements
    FOR EACH ROW
    EXECUTE FUNCTION pnlf.interdire_modif_mouvement();

CREATE TRIGGER trg_mouvements_immutable_del
    BEFORE DELETE ON pnlf.mouvements
    FOR EACH ROW
    EXECUTE FUNCTION pnlf.interdire_modif_mouvement();

-- -----------------------------------------------------------------------------
-- 12. CERTIFICATIONS
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.types_certification (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(40) NOT NULL,
    libelle         VARCHAR(150) NOT NULL,
    organisme       VARCHAR(200),
    description     TEXT,
    duree_mois      INTEGER,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_types_cert_code UNIQUE (code),
    CONSTRAINT ck_types_cert_duree CHECK (duree_mois IS NULL OR duree_mois > 0)
);

CREATE TABLE pnlf.certifications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_certification_id UUID NOT NULL REFERENCES pnlf.types_certification(id) ON DELETE RESTRICT,
    lot_id              UUID REFERENCES pnlf.lots(id) ON DELETE CASCADE,
    producteur_id       UUID REFERENCES pnlf.producteurs(id) ON DELETE CASCADE,
    numero_certificat   VARCHAR(80),
    statut              pnlf.statut_certification NOT NULL DEFAULT 'DEMANDEE',
    date_demande        DATE NOT NULL DEFAULT CURRENT_DATE,
    date_obtention      DATE,
    date_expiration     DATE,
    document_path       TEXT,
    valide_par          UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    observations        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_cert_cible CHECK (lot_id IS NOT NULL OR producteur_id IS NOT NULL),
    CONSTRAINT ck_cert_dates CHECK (
        date_obtention IS NULL OR date_obtention >= date_demande
    ),
    CONSTRAINT ck_cert_exp CHECK (
        date_expiration IS NULL OR date_obtention IS NULL OR date_expiration >= date_obtention
    )
);

CREATE INDEX idx_certifications_lot ON pnlf.certifications (lot_id);
CREATE INDEX idx_certifications_statut ON pnlf.certifications (statut);

-- Documents administratifs joints à l'inscription (CNI, fiche circuit,
-- agrément CITES/Nagoya…) — voir database/12_documents_administratifs.sql.
-- Table créée dans public (pnlf_app n'a pas CREATE sur le schéma pnlf), comme
-- conversation_context / conversation_participant_meta (migration 11).
CREATE TABLE public.documents_inscription (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entite_type    VARCHAR(20) NOT NULL,
    entite_id      UUID NOT NULL,
    type_document  VARCHAR(30) NOT NULL,
    chemin         TEXT NOT NULL,
    nom_original   VARCHAR(255),
    depose_par_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_doc_entite_type CHECK (entite_type IN ('PRODUCTEUR', 'COOPERATIVE', 'UTILISATEUR')),
    CONSTRAINT ck_doc_type CHECK (type_document IN ('CNI', 'FICHE_CIRCUIT', 'AGREMENT_NAGOYA', 'AUTRE'))
);

CREATE INDEX idx_documents_inscription_entite ON public.documents_inscription (entite_type, entite_id);

-- -----------------------------------------------------------------------------
-- 13. MISE EN RELATION (annuaire / offres-demandes / messagerie)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.offres_demandes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_annonce        pnlf.type_offre NOT NULL,
    auteur_id           UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    produit_id          UUID NOT NULL REFERENCES pnlf.produits(id) ON DELETE RESTRICT,
    province_id         UUID REFERENCES pnlf.provinces(id) ON DELETE SET NULL,
    quantite            NUMERIC(14, 3),
    unite               pnlf.unite_mesure,
    prix_unitaire       NUMERIC(14, 2),
    devise              CHAR(3) NOT NULL DEFAULT 'XAF',
    titre               VARCHAR(200) NOT NULL,
    description         TEXT,
    certification_requise BOOLEAN NOT NULL DEFAULT FALSE,
    statut              pnlf.statut_offre NOT NULL DEFAULT 'EN_VALIDATION',
    expire_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_od_quantite CHECK (quantite IS NULL OR quantite > 0),
    CONSTRAINT ck_od_prix CHECK (prix_unitaire IS NULL OR prix_unitaire >= 0)
);

CREATE INDEX idx_od_produit ON pnlf.offres_demandes (produit_id, type_annonce, statut);

CREATE TABLE pnlf.conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sujet           VARCHAR(200),
    offre_id        UUID REFERENCES pnlf.offres_demandes(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pnlf.conversation_participants (
    conversation_id UUID NOT NULL REFERENCES pnlf.conversations(id) ON DELETE CASCADE,
    utilisateur_id  UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id, utilisateur_id)
);

CREATE TABLE pnlf.messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES pnlf.conversations(id) ON DELETE CASCADE,
    expediteur_id   UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    contenu         TEXT NOT NULL,
    lu_at           TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_messages_contenu CHECK (length(trim(contenu)) > 0)
);

CREATE INDEX idx_messages_conv ON pnlf.messages (conversation_id, created_at);

-- -----------------------------------------------------------------------------
-- 14. NOTIFICATIONS
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destinataire_id UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    type_notif      pnlf.type_notification NOT NULL DEFAULT 'INTERNE',
    titre           VARCHAR(200) NOT NULL,
    corps           TEXT NOT NULL,
    lue             BOOLEAN NOT NULL DEFAULT FALSE,
    envoyee_at      TIMESTAMPTZ,
    erreur_envoi    TEXT,
    metadata        JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_dest ON pnlf.notifications (destinataire_id, lue, created_at DESC);

-- -----------------------------------------------------------------------------
-- 15. JOURNAL D'AUDIT (sécurité / conformité)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    utilisateur_id  UUID REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL,
    action          VARCHAR(50) NOT NULL,      -- CREATE, UPDATE, DELETE, LOGIN, EXPORT...
    table_cible     VARCHAR(80),
    enregistrement_id UUID,
    ip_adresse      INET,
    user_agent      TEXT,
    anciennes_valeurs JSONB,
    nouvelles_valeurs JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON pnlf.audit_logs (utilisateur_id, created_at DESC);
CREATE INDEX idx_audit_table ON pnlf.audit_logs (table_cible, created_at DESC);

-- Inaltérabilité audit
CREATE OR REPLACE FUNCTION pnlf.interdire_modif_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Le journal d''audit est inaltérable';
END;
$$;

CREATE TRIGGER trg_audit_immutable_upd
    BEFORE UPDATE ON pnlf.audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION pnlf.interdire_modif_audit();

CREATE TRIGGER trg_audit_immutable_del
    BEFORE DELETE ON pnlf.audit_logs
    FOR EACH ROW
    EXECUTE FUNCTION pnlf.interdire_modif_audit();

-- -----------------------------------------------------------------------------
-- 16. SYNC OFFLINE (tablettes / PWA)
-- -----------------------------------------------------------------------------
CREATE TABLE pnlf.appareils_sync (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id  UUID NOT NULL REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE,
    device_id       VARCHAR(120) NOT NULL,
    libelle         VARCHAR(120),
    dernier_sync_at TIMESTAMPTZ,
    actif           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_appareils_device UNIQUE (utilisateur_id, device_id)
);

CREATE TABLE pnlf.sync_conflicts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appareil_id     UUID REFERENCES pnlf.appareils_sync(id) ON DELETE SET NULL,
    entite          VARCHAR(80) NOT NULL,
    client_uuid     UUID NOT NULL,
    payload_client  JSONB NOT NULL,
    payload_serveur JSONB,
    resolu          BOOLEAN NOT NULL DEFAULT FALSE,
    resolution      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at     TIMESTAMPTZ
);

CREATE INDEX idx_sync_conflicts_ouverts ON pnlf.sync_conflicts (resolu, created_at)
    WHERE resolu = FALSE;

-- -----------------------------------------------------------------------------
-- 17. TRIGGERS updated_at
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'provinces', 'departements', 'villages', 'utilisateurs', 'cooperatives',
        'producteurs', 'categories_produit', 'produits', 'zones_collecte',
        'lots', 'certifications', 'offres_demandes'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON pnlf.%I
             FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;

-- -----------------------------------------------------------------------------
-- 18. VUES MÉTIER (tableaux de bord)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW pnlf.v_stats_producteurs_par_province AS
SELECT
    p.id AS province_id,
    p.nom AS province,
    COUNT(pr.id) FILTER (WHERE pr.deleted_at IS NULL AND pr.statut = 'ACTIF') AS nb_producteurs_actifs
FROM pnlf.provinces p
LEFT JOIN pnlf.producteurs pr ON pr.province_id = p.id
GROUP BY p.id, p.nom;

CREATE OR REPLACE VIEW pnlf.v_stats_lots_par_produit AS
SELECT
    prod.id AS produit_id,
    prod.nom AS produit,
    COUNT(l.id) FILTER (WHERE l.deleted_at IS NULL) AS nb_lots,
    COALESCE(SUM(l.quantite) FILTER (WHERE l.deleted_at IS NULL), 0) AS quantite_totale
FROM pnlf.produits prod
LEFT JOIN pnlf.lots l ON l.produit_id = prod.id
GROUP BY prod.id, prod.nom;

CREATE OR REPLACE VIEW pnlf.v_tracabilite_lot AS
SELECT
    l.id AS lot_id,
    l.code_lot,
    l.uuid_public,
    l.statut,
    prod.nom AS produit,
    pr.nom || ' ' || pr.prenoms AS producteur,
    m.id AS mouvement_id,
    m.type_mouvement,
    m.date_mouvement,
    m.lieu_libelle,
    m.quantite,
    m.unite
FROM pnlf.lots l
JOIN pnlf.produits prod ON prod.id = l.produit_id
JOIN pnlf.producteurs pr ON pr.id = l.producteur_id
LEFT JOIN pnlf.mouvements m ON m.lot_id = l.id
WHERE l.deleted_at IS NULL
ORDER BY l.code_lot, m.date_mouvement;

-- -----------------------------------------------------------------------------
-- 19. DONNÉES DE RÉFÉRENCE MINIMALES (9 provinces du Gabon)
-- -----------------------------------------------------------------------------
INSERT INTO pnlf.provinces (code, nom) VALUES
    ('EST', 'Estuaire'),
    ('HAO', 'Haut-Ogooué'),
    ('MOY', 'Moyen-Ogooué'),
    ('NGO', 'Ngounié'),
    ('NYA', 'Nyanga'),
    ('OGO', 'Ogooué-Ivindo'),
    ('OLR', 'Ogooué-Lolo'),
    ('OMR', 'Ogooué-Maritime'),
    ('WOL', 'Woleu-Ntem');

INSERT INTO pnlf.categories_produit (code, libelle, description) VALUES
    ('MIEL', 'Miels et produits de la ruche', 'Miel sauvage et dérivés'),
    ('NOIX', 'Noix et graines', 'Moabi et autres noix forestières'),
    ('PLANTES', 'Plantes médicinales et aromatiques', NULL),
    ('ECORCES', 'Écorces', 'Usages pharmacologiques ou artisanaux'),
    ('FRUITS', 'Fruits sauvages', 'Mangue sauvage, safou, etc.'),
    ('CHAMP', 'Champignons', 'Champignons comestibles'),
    ('ROTIN', 'Rotin et bambou', NULL),
    ('FAUNE', 'Produits issus de la faune (CITES)', 'Conformément à la réglementation'),
    ('AUTRE', 'Autres PFNL', 'Catégorie extensible');

INSERT INTO pnlf.types_certification (code, libelle, organisme, duree_mois) VALUES
    ('BIO', 'Certification biologique', NULL, 12),
    ('ORIGINE', 'Certification d''origine', 'Ministère des Eaux et Forêts', 24),
    ('QUALITE', 'Certification qualité', NULL, 12),
    ('CITES', 'Permis / certificat CITES', 'Autorité CITES Gabon', 12);

-- Admin initial : mot de passe à REMPLACER immédiatement côté application
-- Hash placeholder (ne pas utiliser en production telle quelle)
INSERT INTO pnlf.utilisateurs (
    email, mot_de_passe_hash, role, statut, nom, prenoms, doit_changer_mdp
) VALUES (
    'admin@pnlf.ga',
    crypt('ChangeMe_PNLF_2026!', gen_salt('bf', 12)),
    'ADMINISTRATEUR',
    'ACTIF',
    'Administrateur',
    'Système',
    TRUE
);

-- -----------------------------------------------------------------------------
-- 20. RÔLES PostgreSQL & DROITS (sécurité)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pnlf_app') THEN
        CREATE ROLE pnlf_app LOGIN PASSWORD 'A_CHANGER_MotDePasseApp_2026';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pnlf_readonly') THEN
        CREATE ROLE pnlf_readonly LOGIN PASSWORD 'A_CHANGER_MotDePasseRO_2026';
    END IF;
END;
$$;

GRANT CONNECT ON DATABASE pnlf TO pnlf_app, pnlf_readonly;
GRANT USAGE ON SCHEMA pnlf TO pnlf_app, pnlf_readonly;
GRANT USAGE ON SCHEMA public TO pnlf_app, pnlf_readonly; -- PostGIS

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pnlf TO pnlf_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pnlf TO pnlf_app;
GRANT SELECT ON ALL TABLES IN SCHEMA pnlf TO pnlf_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA pnlf
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pnlf_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA pnlf
    GRANT USAGE, SELECT ON SEQUENCES TO pnlf_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA pnlf
    GRANT SELECT ON TABLES TO pnlf_readonly;

-- Révoquer l'accès public large
REVOKE ALL ON SCHEMA pnlf FROM PUBLIC;

COMMENT ON TABLE pnlf.lots IS 'Unité tracée PFNL — identifiant unique + QR Code';
COMMENT ON TABLE pnlf.mouvements IS 'Parcours chronologique inaltérable d''un lot';
COMMENT ON TABLE pnlf.audit_logs IS 'Journal d''audit de sécurité — append-only';

COMMIT;

-- =============================================================================
-- FIN DU SCRIPT
-- Vérifications utiles après exécution :
--   SELECT * FROM pnlf.provinces;
--   SELECT extname FROM pg_extension;
--   \dn pnlf
-- =============================================================================
