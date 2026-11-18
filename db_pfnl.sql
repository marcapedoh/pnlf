--
-- PostgreSQL database dump
--

\restrict 1hU877PMe8nP5rpwih8gHN3fbcA8xzVYs9zWk0pXDL1eOuXwjK63UGpxMf7HIhT

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-11-18 16:51:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 12 (class 2615 OID 69118)
-- Name: pnlf; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA pnlf;


ALTER SCHEMA pnlf OWNER TO postgres;

--
-- TOC entry 7018 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA pnlf; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA pnlf IS 'Schéma métier PNLF-PFNL';


--
-- TOC entry 5 (class 3079 OID 68925)
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- TOC entry 7021 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- TOC entry 7 (class 3079 OID 69037)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 7022 (class 0 OID 0)
-- Dependencies: 7
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 2 (class 3079 OID 67794)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 7023 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 4 (class 3079 OID 67843)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 7024 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 6 (class 3079 OID 69030)
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- TOC entry 7025 (class 0 OID 0)
-- Dependencies: 6
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- TOC entry 3 (class 3079 OID 67832)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 7026 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1873 (class 1247 OID 69232)
-- Name: canal_notification; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.canal_notification AS ENUM (
    'EMAIL',
    'SMS',
    'LES_DEUX',
    'AUCUN'
);


ALTER TYPE pnlf.canal_notification OWNER TO postgres;

--
-- TOC entry 1849 (class 1247 OID 69120)
-- Name: role_utilisateur; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.role_utilisateur AS ENUM (
    'ADMINISTRATEUR',
    'AGENT_MINISTERE',
    'AGENT_FORESTIER',
    'PRODUCTEUR',
    'COOPERATIVE',
    'ACHETEUR'
);


ALTER TYPE pnlf.role_utilisateur OWNER TO postgres;

--
-- TOC entry 1864 (class 1247 OID 69190)
-- Name: statut_certification; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.statut_certification AS ENUM (
    'DEMANDEE',
    'EN_COURS',
    'OBTENUE',
    'EXPIREE',
    'REFUSEE',
    'REVOQUEE'
);


ALTER TYPE pnlf.statut_certification OWNER TO postgres;

--
-- TOC entry 1852 (class 1247 OID 69134)
-- Name: statut_compte; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.statut_compte AS ENUM (
    'ACTIF',
    'INACTIF',
    'SUSPENDU',
    'EN_ATTENTE'
);


ALTER TYPE pnlf.statut_compte OWNER TO postgres;

--
-- TOC entry 1858 (class 1247 OID 69154)
-- Name: statut_lot; Type: TYPE; Schema: pnlf; Owner: postgres
--

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


ALTER TYPE pnlf.statut_lot OWNER TO postgres;

--
-- TOC entry 1879 (class 1247 OID 69248)
-- Name: statut_offre; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.statut_offre AS ENUM (
    'OUVERTE',
    'CLOTUREE',
    'ANNULEE',
    'EN_VALIDATION',
    'REJETEE'
);


ALTER TYPE pnlf.statut_offre OWNER TO postgres;

--
-- TOC entry 1855 (class 1247 OID 69144)
-- Name: statut_producteur; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.statut_producteur AS ENUM (
    'ACTIF',
    'INACTIF',
    'EN_VALIDATION',
    'REJETE'
);


ALTER TYPE pnlf.statut_producteur OWNER TO postgres;

--
-- TOC entry 1882 (class 1247 OID 69256)
-- Name: statut_sync; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.statut_sync AS ENUM (
    'PENDING',
    'SYNCED',
    'CONFLICT',
    'ERROR'
);


ALTER TYPE pnlf.statut_sync OWNER TO postgres;

--
-- TOC entry 1861 (class 1247 OID 69172)
-- Name: type_mouvement; Type: TYPE; Schema: pnlf; Owner: postgres
--

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


ALTER TYPE pnlf.type_mouvement OWNER TO postgres;

--
-- TOC entry 1870 (class 1247 OID 69224)
-- Name: type_notification; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.type_notification AS ENUM (
    'EMAIL',
    'SMS',
    'INTERNE'
);


ALTER TYPE pnlf.type_notification OWNER TO postgres;

--
-- TOC entry 1876 (class 1247 OID 69242)
-- Name: type_offre; Type: TYPE; Schema: pnlf; Owner: postgres
--

CREATE TYPE pnlf.type_offre AS ENUM (
    'OFFRE',
    'DEMANDE'
);


ALTER TYPE pnlf.type_offre OWNER TO postgres;

--
-- TOC entry 1867 (class 1247 OID 69204)
-- Name: unite_mesure; Type: TYPE; Schema: pnlf; Owner: postgres
--

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


ALTER TYPE pnlf.unite_mesure OWNER TO postgres;

--
-- TOC entry 504 (class 1255 OID 69266)
-- Name: generer_code_lot(); Type: FUNCTION; Schema: pnlf; Owner: postgres
--

CREATE FUNCTION pnlf.generer_code_lot() RETURNS trigger
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


ALTER FUNCTION pnlf.generer_code_lot() OWNER TO postgres;

--
-- TOC entry 981 (class 1255 OID 70001)
-- Name: interdire_modif_audit(); Type: FUNCTION; Schema: pnlf; Owner: postgres
--

CREATE FUNCTION pnlf.interdire_modif_audit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Le journal d''audit est inaltérable';
END;
$$;


ALTER FUNCTION pnlf.interdire_modif_audit() OWNER TO postgres;

--
-- TOC entry 421 (class 1255 OID 69791)
-- Name: interdire_modif_mouvement(); Type: FUNCTION; Schema: pnlf; Owner: postgres
--

CREATE FUNCTION pnlf.interdire_modif_mouvement() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Les mouvements de traçabilité sont inaltérables (UPDATE/DELETE interdits)';
END;
$$;


ALTER FUNCTION pnlf.interdire_modif_mouvement() OWNER TO postgres;

--
-- TOC entry 917 (class 1255 OID 69265)
-- Name: set_updated_at(); Type: FUNCTION; Schema: pnlf; Owner: postgres
--

CREATE FUNCTION pnlf.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION pnlf.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 255 (class 1259 OID 70004)
-- Name: appareils_sync; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.appareils_sync (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    utilisateur_id uuid NOT NULL,
    device_id character varying(120) NOT NULL,
    libelle character varying(120),
    dernier_sync_at timestamp with time zone,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.appareils_sync OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 69982)
-- Name: audit_logs; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.audit_logs (
    id bigint NOT NULL,
    utilisateur_id uuid,
    action character varying(50) NOT NULL,
    table_cible character varying(80),
    enregistrement_id uuid,
    ip_adresse inet,
    user_agent text,
    anciennes_valeurs jsonb,
    nouvelles_valeurs jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.audit_logs OWNER TO postgres;

--
-- TOC entry 7032 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE audit_logs; Type: COMMENT; Schema: pnlf; Owner: postgres
--

COMMENT ON TABLE pnlf.audit_logs IS 'Journal d''audit de sécurité — append-only';


--
-- TOC entry 253 (class 1259 OID 69981)
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: pnlf; Owner: postgres
--

CREATE SEQUENCE pnlf.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pnlf.audit_logs_id_seq OWNER TO postgres;

--
-- TOC entry 7034 (class 0 OID 0)
-- Dependencies: 253
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: pnlf; Owner: postgres
--

ALTER SEQUENCE pnlf.audit_logs_id_seq OWNED BY pnlf.audit_logs.id;


--
-- TOC entry 240 (class 1259 OID 69557)
-- Name: categories_produit; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.categories_produit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(30) NOT NULL,
    libelle character varying(150) NOT NULL,
    description text,
    parent_id uuid,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.categories_produit OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 69812)
-- Name: certifications; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.certifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type_certification_id uuid NOT NULL,
    lot_id uuid,
    producteur_id uuid,
    numero_certificat character varying(80),
    statut pnlf.statut_certification DEFAULT 'DEMANDEE'::pnlf.statut_certification NOT NULL,
    date_demande date DEFAULT CURRENT_DATE NOT NULL,
    date_obtention date,
    date_expiration date,
    document_path text,
    valide_par uuid,
    observations text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_cert_cible CHECK (((lot_id IS NOT NULL) OR (producteur_id IS NOT NULL))),
    CONSTRAINT ck_cert_dates CHECK (((date_obtention IS NULL) OR (date_obtention >= date_demande))),
    CONSTRAINT ck_cert_exp CHECK (((date_expiration IS NULL) OR (date_obtention IS NULL) OR (date_expiration >= date_obtention)))
);


ALTER TABLE pnlf.certifications OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 69910)
-- Name: conversation_participants; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.conversation_participants (
    conversation_id uuid NOT NULL,
    utilisateur_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.conversation_participants OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 69896)
-- Name: conversations; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sujet character varying(200),
    offre_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.conversations OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 69534)
-- Name: cooperative_membres; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.cooperative_membres (
    cooperative_id uuid NOT NULL,
    producteur_id uuid NOT NULL,
    date_adhesion date DEFAULT CURRENT_DATE NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.cooperative_membres OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 69424)
-- Name: cooperatives; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.cooperatives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(30) NOT NULL,
    nom character varying(200) NOT NULL,
    numero_agrement character varying(80),
    telephone character varying(30),
    email public.citext,
    adresse text,
    province_id uuid,
    departement_id uuid,
    village_id uuid,
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    utilisateur_id uuid,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    statut character varying(20) DEFAULT 'ACTIF'::character varying NOT NULL,
    CONSTRAINT ck_coop_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_coop_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))),
    CONSTRAINT ck_cooperatives_statut CHECK (((statut)::text = ANY ((ARRAY['EN_VALIDATION'::character varying, 'ACTIF'::character varying, 'INACTIF'::character varying, 'REJETE'::character varying])::text[])))
);


ALTER TABLE pnlf.cooperatives OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 69289)
-- Name: departements; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.departements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    province_id uuid NOT NULL,
    code character varying(20) NOT NULL,
    nom character varying(120) NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.departements OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 69666)
-- Name: lots; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.lots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code_lot character varying(40) NOT NULL,
    uuid_public uuid DEFAULT gen_random_uuid() NOT NULL,
    produit_id uuid NOT NULL,
    producteur_id uuid NOT NULL,
    cooperative_id uuid,
    zone_collecte_id uuid,
    date_collecte date NOT NULL,
    quantite numeric(14,3) NOT NULL,
    unite pnlf.unite_mesure NOT NULL,
    qualite_indicateur character varying(100),
    prix_indicatif numeric(14,2),
    devise character(3) DEFAULT 'XAF'::bpchar NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    statut pnlf.statut_lot DEFAULT 'DECLARE'::pnlf.statut_lot NOT NULL,
    qr_payload text,
    qr_image_path text,
    declare_par uuid,
    valide_par uuid,
    valide_at timestamp with time zone,
    observations text,
    client_uuid uuid,
    sync_statut pnlf.statut_sync DEFAULT 'SYNCED'::pnlf.statut_sync NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    last_synced_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT ck_lots_date CHECK ((date_collecte <= (CURRENT_DATE + '1 day'::interval))),
    CONSTRAINT ck_lots_devise CHECK ((devise ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT ck_lots_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_lots_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))),
    CONSTRAINT ck_lots_prix CHECK (((prix_indicatif IS NULL) OR (prix_indicatif >= (0)::numeric))),
    CONSTRAINT ck_lots_quantite CHECK ((quantite > (0)::numeric))
);


ALTER TABLE pnlf.lots OWNER TO postgres;

--
-- TOC entry 7043 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE lots; Type: COMMENT; Schema: pnlf; Owner: postgres
--

COMMENT ON TABLE pnlf.lots IS 'Unité tracée PFNL — identifiant unique + QR Code';


--
-- TOC entry 251 (class 1259 OID 69929)
-- Name: messages; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    expediteur_id uuid NOT NULL,
    contenu text NOT NULL,
    lu_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_messages_contenu CHECK ((length(TRIM(BOTH FROM contenu)) > 0))
);


ALTER TABLE pnlf.messages OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 70309)
-- Name: messages_publics; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.messages_publics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    producteur_id uuid NOT NULL,
    nom_visiteur character varying(150) NOT NULL,
    email_visiteur character varying(255) NOT NULL,
    telephone_visiteur character varying(30),
    message text NOT NULL,
    ip_adresse character varying(64),
    statut character varying(20) DEFAULT 'NOUVEAU'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    traite_at timestamp with time zone,
    CONSTRAINT ck_messages_publics_statut CHECK (((statut)::text = ANY ((ARRAY['NOUVEAU'::character varying, 'TRAITE'::character varying])::text[])))
);


ALTER TABLE pnlf.messages_publics OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 69743)
-- Name: mouvements; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.mouvements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid NOT NULL,
    type_mouvement pnlf.type_mouvement NOT NULL,
    date_mouvement timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    lieu_libelle character varying(200),
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    quantite numeric(14,3),
    unite pnlf.unite_mesure,
    acteur_utilisateur_id uuid,
    acteur_producteur_id uuid,
    acteur_cooperative_id uuid,
    destinataire_libelle character varying(200),
    commentaire text,
    hash_precedent character(64),
    hash_courant character(64),
    client_uuid uuid,
    sync_statut pnlf.statut_sync DEFAULT 'SYNCED'::pnlf.statut_sync NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_mvt_acteur CHECK (((acteur_utilisateur_id IS NOT NULL) OR (acteur_producteur_id IS NOT NULL) OR (acteur_cooperative_id IS NOT NULL))),
    CONSTRAINT ck_mvt_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_mvt_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))),
    CONSTRAINT ck_mvt_quantite CHECK (((quantite IS NULL) OR (quantite > (0)::numeric)))
);


ALTER TABLE pnlf.mouvements OWNER TO postgres;

--
-- TOC entry 7047 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE mouvements; Type: COMMENT; Schema: pnlf; Owner: postgres
--

COMMENT ON TABLE pnlf.mouvements IS 'Parcours chronologique inaltérable d''un lot';


--
-- TOC entry 252 (class 1259 OID 69955)
-- Name: notifications; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destinataire_id uuid NOT NULL,
    type_notif pnlf.type_notification DEFAULT 'INTERNE'::pnlf.type_notification NOT NULL,
    titre character varying(200) NOT NULL,
    corps text NOT NULL,
    lue boolean DEFAULT false NOT NULL,
    envoyee_at timestamp with time zone,
    erreur_envoi text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.notifications OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 69855)
-- Name: offres_demandes; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.offres_demandes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type_annonce pnlf.type_offre NOT NULL,
    auteur_id uuid NOT NULL,
    produit_id uuid NOT NULL,
    province_id uuid,
    quantite numeric(14,3),
    unite pnlf.unite_mesure,
    prix_unitaire numeric(14,2),
    devise character(3) DEFAULT 'XAF'::bpchar NOT NULL,
    titre character varying(200) NOT NULL,
    description text,
    certification_requise boolean DEFAULT false NOT NULL,
    statut pnlf.statut_offre DEFAULT 'OUVERTE'::pnlf.statut_offre NOT NULL,
    expire_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    uuid_public uuid,
    qr_payload text,
    qr_image_path text,
    CONSTRAINT ck_od_prix CHECK (((prix_unitaire IS NULL) OR (prix_unitaire >= (0)::numeric))),
    CONSTRAINT ck_od_quantite CHECK (((quantite IS NULL) OR (quantite > (0)::numeric)))
);


ALTER TABLE pnlf.offres_demandes OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 69617)
-- Name: producteur_produits; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.producteur_produits (
    producteur_id uuid NOT NULL,
    produit_id uuid NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.producteur_produits OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 69468)
-- Name: producteurs; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.producteurs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code_producteur character varying(30) NOT NULL,
    nom character varying(100) NOT NULL,
    prenoms character varying(150) NOT NULL,
    date_naissance date,
    type_piece_identite character varying(50),
    numero_piece character varying(80),
    telephone character varying(30),
    email public.citext,
    communaute character varying(120),
    province_id uuid NOT NULL,
    departement_id uuid,
    village_id uuid,
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    cooperative_id uuid,
    utilisateur_id uuid,
    statut pnlf.statut_producteur DEFAULT 'EN_VALIDATION'::pnlf.statut_producteur NOT NULL,
    valide_par uuid,
    valide_at timestamp with time zone,
    notes text,
    client_uuid uuid,
    sync_statut pnlf.statut_sync DEFAULT 'SYNCED'::pnlf.statut_sync NOT NULL,
    sync_version bigint DEFAULT 1 NOT NULL,
    last_synced_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    type_acteur character varying(20) DEFAULT 'PRODUCTEUR'::character varying NOT NULL,
    photo_path text,
    visible_public boolean DEFAULT true NOT NULL,
    CONSTRAINT ck_prod_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_prod_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))),
    CONSTRAINT ck_prod_naissance CHECK (((date_naissance IS NULL) OR (date_naissance < CURRENT_DATE))),
    CONSTRAINT ck_producteurs_type_acteur CHECK (((type_acteur)::text = ANY ((ARRAY['PRODUCTEUR'::character varying, 'COLLECTEUR'::character varying])::text[])))
);


ALTER TABLE pnlf.producteurs OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 69583)
-- Name: produits; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.produits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    nom character varying(200) NOT NULL,
    nom_scientifique character varying(200),
    categorie_id uuid NOT NULL,
    description text,
    unite_defaut pnlf.unite_mesure DEFAULT 'KG'::pnlf.unite_mesure NOT NULL,
    soumis_cites boolean DEFAULT false NOT NULL,
    code_cites character varying(50),
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    image_path text,
    CONSTRAINT ck_produits_cites CHECK ((((soumis_cites = false) AND (code_cites IS NULL)) OR (soumis_cites = true)))
);


ALTER TABLE pnlf.produits OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 69267)
-- Name: provinces; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.provinces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(10) NOT NULL,
    nom character varying(100) NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_provinces_code CHECK (((code)::text ~ '^[A-Z0-9_]{2,10}$'::text))
);


ALTER TABLE pnlf.provinces OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 69403)
-- Name: reinitialisations_mdp; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.reinitialisations_mdp (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    utilisateur_id uuid NOT NULL,
    token_hash text NOT NULL,
    expire_at timestamp with time zone NOT NULL,
    utilise_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.reinitialisations_mdp OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 69380)
-- Name: sessions; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    utilisateur_id uuid NOT NULL,
    jti character varying(64) NOT NULL,
    refresh_token_hash text NOT NULL,
    ip_adresse inet,
    user_agent text,
    expire_at timestamp with time zone NOT NULL,
    revoquee_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE pnlf.sessions OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 70024)
-- Name: sync_conflicts; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.sync_conflicts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appareil_id uuid,
    entite character varying(80) NOT NULL,
    client_uuid uuid NOT NULL,
    payload_client jsonb NOT NULL,
    payload_serveur jsonb,
    resolu boolean DEFAULT false NOT NULL,
    resolution text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    resolved_at timestamp with time zone
);


ALTER TABLE pnlf.sync_conflicts OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 69794)
-- Name: types_certification; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.types_certification (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    libelle character varying(150) NOT NULL,
    organisme character varying(200),
    description text,
    duree_mois integer,
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_types_cert_duree CHECK (((duree_mois IS NULL) OR (duree_mois > 0)))
);


ALTER TABLE pnlf.types_certification OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 69344)
-- Name: utilisateurs; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.utilisateurs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext NOT NULL,
    telephone character varying(30),
    mot_de_passe_hash text NOT NULL,
    role pnlf.role_utilisateur NOT NULL,
    statut pnlf.statut_compte DEFAULT 'EN_ATTENTE'::pnlf.statut_compte NOT NULL,
    nom character varying(100) NOT NULL,
    prenoms character varying(150) NOT NULL,
    double_auth_active boolean DEFAULT false NOT NULL,
    derniere_connexion timestamp with time zone,
    tentatives_echec smallint DEFAULT 0 NOT NULL,
    verrouille_jusquau timestamp with time zone,
    doit_changer_mdp boolean DEFAULT false NOT NULL,
    preferences_notif pnlf.canal_notification DEFAULT 'EMAIL'::pnlf.canal_notification NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT ck_utilisateurs_email CHECK ((email OPERATOR(public.~*) '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::public.citext)),
    CONSTRAINT ck_utilisateurs_mdp_non_vide CHECK ((length(mot_de_passe_hash) >= 20)),
    CONSTRAINT ck_utilisateurs_telephone CHECK (((telephone IS NULL) OR ((telephone)::text ~ '^\+?[0-9]{8,20}$'::text))),
    CONSTRAINT ck_utilisateurs_tentatives CHECK (((tentatives_echec >= 0) AND (tentatives_echec <= 20)))
);


ALTER TABLE pnlf.utilisateurs OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 70296)
-- Name: v_dashboard_lots; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_dashboard_lots AS
 SELECT pr.id AS province_id,
    pr.nom AS province_nom,
    prod.id AS produit_id,
    prod.nom AS produit_nom,
    l.statut,
    (date_trunc('month'::text, (l.date_collecte)::timestamp with time zone))::date AS periode_mois,
    count(*) AS nb_lots,
    COALESCE(sum(l.quantite), (0)::numeric) AS quantite_totale,
    l.unite
   FROM (((pnlf.lots l
     JOIN pnlf.produits prod ON ((prod.id = l.produit_id)))
     JOIN pnlf.producteurs p ON ((p.id = l.producteur_id)))
     JOIN pnlf.provinces pr ON ((pr.id = p.province_id)))
  WHERE (l.deleted_at IS NULL)
  GROUP BY pr.id, pr.nom, prod.id, prod.nom, l.statut, (date_trunc('month'::text, (l.date_collecte)::timestamp with time zone)), l.unite;


ALTER VIEW pnlf.v_dashboard_lots OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 70301)
-- Name: v_dashboard_mouvements; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_dashboard_mouvements AS
 SELECT m.type_mouvement,
    (date_trunc('month'::text, m.date_mouvement))::date AS periode_mois,
    count(*) AS nb_mouvements
   FROM (pnlf.mouvements m
     JOIN pnlf.lots l ON (((l.id = m.lot_id) AND (l.deleted_at IS NULL))))
  GROUP BY m.type_mouvement, (date_trunc('month'::text, m.date_mouvement));


ALTER VIEW pnlf.v_dashboard_mouvements OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 70291)
-- Name: v_dashboard_producteurs; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_dashboard_producteurs AS
 SELECT pr.id AS province_id,
    pr.nom AS province_nom,
    p.type_acteur,
    p.statut,
    count(*) AS nombre
   FROM (pnlf.producteurs p
     JOIN pnlf.provinces pr ON ((pr.id = p.province_id)))
  WHERE (p.deleted_at IS NULL)
  GROUP BY pr.id, pr.nom, p.type_acteur, p.statut;


ALTER VIEW pnlf.v_dashboard_producteurs OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 70063)
-- Name: v_stats_lots_par_produit; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_stats_lots_par_produit AS
 SELECT prod.id AS produit_id,
    prod.nom AS produit,
    count(l.id) FILTER (WHERE (l.deleted_at IS NULL)) AS nb_lots,
    COALESCE(sum(l.quantite) FILTER (WHERE (l.deleted_at IS NULL)), (0)::numeric) AS quantite_totale
   FROM (pnlf.produits prod
     LEFT JOIN pnlf.lots l ON ((l.produit_id = prod.id)))
  GROUP BY prod.id, prod.nom;


ALTER VIEW pnlf.v_stats_lots_par_produit OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 70058)
-- Name: v_stats_producteurs_par_province; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_stats_producteurs_par_province AS
 SELECT p.id AS province_id,
    p.nom AS province,
    count(pr.id) FILTER (WHERE ((pr.deleted_at IS NULL) AND (pr.statut = 'ACTIF'::pnlf.statut_producteur))) AS nb_producteurs_actifs
   FROM (pnlf.provinces p
     LEFT JOIN pnlf.producteurs pr ON ((pr.province_id = p.id)))
  GROUP BY p.id, p.nom;


ALTER VIEW pnlf.v_stats_producteurs_par_province OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 70068)
-- Name: v_tracabilite_lot; Type: VIEW; Schema: pnlf; Owner: postgres
--

CREATE VIEW pnlf.v_tracabilite_lot AS
 SELECT l.id AS lot_id,
    l.code_lot,
    l.uuid_public,
    l.statut,
    prod.nom AS produit,
    (((pr.nom)::text || ' '::text) || (pr.prenoms)::text) AS producteur,
    m.id AS mouvement_id,
    m.type_mouvement,
    m.date_mouvement,
    m.lieu_libelle,
    m.quantite,
    m.unite
   FROM (((pnlf.lots l
     JOIN pnlf.produits prod ON ((prod.id = l.produit_id)))
     JOIN pnlf.producteurs pr ON ((pr.id = l.producteur_id)))
     LEFT JOIN pnlf.mouvements m ON ((m.lot_id = l.id)))
  WHERE (l.deleted_at IS NULL)
  ORDER BY l.code_lot, m.date_mouvement;


ALTER VIEW pnlf.v_tracabilite_lot OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 69316)
-- Name: villages; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.villages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    departement_id uuid NOT NULL,
    nom character varying(150) NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_villages_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_villages_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric))))
);


ALTER TABLE pnlf.villages OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 69638)
-- Name: zones_collecte; Type: TABLE; Schema: pnlf; Owner: postgres
--

CREATE TABLE pnlf.zones_collecte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(40) NOT NULL,
    libelle character varying(200) NOT NULL,
    province_id uuid NOT NULL,
    description text,
    latitude numeric(10,7),
    longitude numeric(10,7),
    geom public.geometry(Point,4326),
    actif boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_zones_lat CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT ck_zones_lon CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric))))
);


ALTER TABLE pnlf.zones_collecte OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 86836)
-- Name: _data_ops; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public._data_ops (
    op_key character varying(100) NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


ALTER TABLE public._data_ops OWNER TO pnlf_app;

--
-- TOC entry 267 (class 1259 OID 70121)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO pnlf_app;

--
-- TOC entry 266 (class 1259 OID 70120)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 269 (class 1259 OID 70131)
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO pnlf_app;

--
-- TOC entry 268 (class 1259 OID 70130)
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 265 (class 1259 OID 70111)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO pnlf_app;

--
-- TOC entry 264 (class 1259 OID 70110)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 271 (class 1259 OID 70140)
-- Name: auth_user; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO pnlf_app;

--
-- TOC entry 273 (class 1259 OID 70159)
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO pnlf_app;

--
-- TOC entry 272 (class 1259 OID 70158)
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 270 (class 1259 OID 70139)
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 275 (class 1259 OID 70168)
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO pnlf_app;

--
-- TOC entry 274 (class 1259 OID 70167)
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.auth_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 296 (class 1259 OID 86926)
-- Name: certifications_pieces; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.certifications_pieces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    certification_id uuid NOT NULL,
    intitule character varying(150) NOT NULL,
    chemin text NOT NULL,
    nom_original character varying(255),
    type_mime character varying(60),
    taille_octets integer,
    depose_par_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_certif_pieces_taille CHECK (((taille_octets IS NULL) OR (taille_octets > 0)))
);


ALTER TABLE public.certifications_pieces OWNER TO pnlf_app;

--
-- TOC entry 300 (class 1259 OID 87006)
-- Name: connexions; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.connexions (
    id bigint NOT NULL,
    utilisateur_id uuid,
    email_saisi character varying(254),
    role character varying(30),
    succes boolean NOT NULL,
    motif_echec character varying(30),
    ip_adresse inet,
    appareil character varying(20) DEFAULT 'INCONNU'::character varying NOT NULL,
    systeme character varying(40),
    navigateur character varying(40),
    empreinte_appareil character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.connexions OWNER TO pnlf_app;

--
-- TOC entry 299 (class 1259 OID 87005)
-- Name: connexions_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

CREATE SEQUENCE public.connexions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.connexions_id_seq OWNER TO pnlf_app;

--
-- TOC entry 7068 (class 0 OID 0)
-- Dependencies: 299
-- Name: connexions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pnlf_app
--

ALTER SEQUENCE public.connexions_id_seq OWNED BY public.connexions.id;


--
-- TOC entry 284 (class 1259 OID 86665)
-- Name: conversation_context; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.conversation_context (
    conversation_id uuid NOT NULL,
    producteur_id uuid,
    cooperative_id uuid,
    est_groupe boolean DEFAULT false NOT NULL
);


ALTER TABLE public.conversation_context OWNER TO pnlf_app;

--
-- TOC entry 286 (class 1259 OID 86702)
-- Name: conversation_participant_meta; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.conversation_participant_meta (
    conversation_id uuid NOT NULL,
    utilisateur_id uuid NOT NULL,
    last_read_at timestamp with time zone,
    deleted_at timestamp with time zone
);


ALTER TABLE public.conversation_participant_meta OWNER TO pnlf_app;

--
-- TOC entry 277 (class 1259 OID 70229)
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO pnlf_app;

--
-- TOC entry 276 (class 1259 OID 70228)
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 263 (class 1259 OID 70099)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO pnlf_app;

--
-- TOC entry 262 (class 1259 OID 70098)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 261 (class 1259 OID 70087)
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


ALTER TABLE public.django_migrations OWNER TO pnlf_app;

--
-- TOC entry 260 (class 1259 OID 70086)
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 278 (class 1259 OID 70269)
-- Name: django_session; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO pnlf_app;

--
-- TOC entry 287 (class 1259 OID 86728)
-- Name: documents_inscription; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.documents_inscription (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entite_type character varying(20) NOT NULL,
    entite_id uuid NOT NULL,
    type_document character varying(30) NOT NULL,
    chemin text NOT NULL,
    nom_original character varying(255),
    depose_par_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_doc_entite_type CHECK (((entite_type)::text = ANY ((ARRAY['PRODUCTEUR'::character varying, 'COOPERATIVE'::character varying, 'UTILISATEUR'::character varying])::text[]))),
    CONSTRAINT ck_doc_type CHECK (((type_document)::text = ANY ((ARRAY['CNI'::character varying, 'FICHE_CIRCUIT'::character varying, 'AGREMENT_NAGOYA'::character varying, 'AUTRE'::character varying])::text[])))
);


ALTER TABLE public.documents_inscription OWNER TO pnlf_app;

--
-- TOC entry 294 (class 1259 OID 86862)
-- Name: invitations_cooperative; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.invitations_cooperative (
    id uuid NOT NULL,
    cooperative_id uuid NOT NULL,
    producteur_id uuid NOT NULL,
    statut character varying(20) DEFAULT 'EN_ATTENTE'::character varying NOT NULL,
    message text,
    invite_par_id uuid,
    repondu_par_id uuid,
    motif_reponse text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    repondu_at timestamp with time zone,
    CONSTRAINT ck_invitation_coop_statut CHECK (((statut)::text = ANY ((ARRAY['EN_ATTENTE'::character varying, 'ACCEPTEE'::character varying, 'REFUSEE'::character varying, 'ANNULEE'::character varying, 'CADUQUE'::character varying])::text[])))
);


ALTER TABLE public.invitations_cooperative OWNER TO pnlf_app;

--
-- TOC entry 295 (class 1259 OID 86900)
-- Name: lots_transitions; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.lots_transitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid NOT NULL,
    ancien_statut character varying(20),
    nouveau_statut character varying(20) NOT NULL,
    mode character varying(20) NOT NULL,
    role_auteur character varying(30),
    auteur_id uuid,
    motif text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_lots_transitions_mode CHECK (((mode)::text = ANY ((ARRAY['AGENT'::character varying, 'AUTO'::character varying, 'PROPRIETAIRE'::character varying, 'MIGRATION'::character varying])::text[])))
);


ALTER TABLE public.lots_transitions OWNER TO pnlf_app;

--
-- TOC entry 285 (class 1259 OID 86688)
-- Name: message_pieces; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.message_pieces (
    message_id uuid NOT NULL,
    piece_type character varying(10) NOT NULL,
    piece_path character varying(400) NOT NULL,
    CONSTRAINT message_pieces_piece_type_check CHECK (((piece_type)::text = ANY ((ARRAY['IMAGE'::character varying, 'AUDIO'::character varying])::text[])))
);


ALTER TABLE public.message_pieces OWNER TO pnlf_app;

--
-- TOC entry 303 (class 1259 OID 87067)
-- Name: moderation_images; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.moderation_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    chemin text NOT NULL,
    type_objet character varying(30) NOT NULL,
    objet_id uuid,
    envoye_par_id uuid,
    verdict character varying(20) DEFAULT 'DOUTEUX'::character varying NOT NULL,
    score_nsfw numeric(6,5),
    scores jsonb DEFAULT '{}'::jsonb NOT NULL,
    statut character varying(20) DEFAULT 'EN_ATTENTE'::character varying NOT NULL,
    motif text,
    traite_par_id uuid,
    traite_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_moderation_images_score CHECK (((score_nsfw IS NULL) OR ((score_nsfw >= (0)::numeric) AND (score_nsfw <= (1)::numeric)))),
    CONSTRAINT ck_moderation_images_statut CHECK (((statut)::text = ANY ((ARRAY['EN_ATTENTE'::character varying, 'APPROUVEE'::character varying, 'REJETEE'::character varying, 'REMPLACEE'::character varying])::text[]))),
    CONSTRAINT ck_moderation_images_traitement CHECK ((((statut)::text = 'EN_ATTENTE'::text) OR (traite_at IS NOT NULL))),
    CONSTRAINT ck_moderation_images_verdict CHECK (((verdict)::text = ANY ((ARRAY['DOUTEUX'::character varying, 'EXPLICITE'::character varying])::text[])))
);


ALTER TABLE public.moderation_images OWNER TO pnlf_app;

--
-- TOC entry 297 (class 1259 OID 86952)
-- Name: offres_details; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.offres_details (
    offre_id uuid NOT NULL,
    categorie_id uuid,
    prix_total numeric(16,2),
    negociable boolean DEFAULT false NOT NULL,
    conditionnement character varying(150),
    qualite character varying(200),
    localite character varying(150),
    disponible_du date,
    mode_remise character varying(30),
    modalites_livraison text,
    moyens_paiement character varying(30)[] DEFAULT '{}'::character varying[] NOT NULL,
    conditions_paiement text,
    afficher_telephone boolean DEFAULT false NOT NULL,
    afficher_email boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_offres_details_mode_remise CHECK (((mode_remise IS NULL) OR ((mode_remise)::text = ANY ((ARRAY['LIVRAISON'::character varying, 'RETRAIT'::character varying, 'LIVRAISON_OU_RETRAIT'::character varying])::text[])))),
    CONSTRAINT ck_offres_details_prix_total CHECK (((prix_total IS NULL) OR (prix_total >= (0)::numeric)))
);


ALTER TABLE public.offres_details OWNER TO pnlf_app;

--
-- TOC entry 298 (class 1259 OID 86983)
-- Name: offres_moderation; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.offres_moderation (
    offre_id uuid NOT NULL,
    decision character varying(20) NOT NULL,
    moderateur_id uuid,
    moderateur_nom character varying(260),
    motif text,
    decide_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_offres_moderation_decision CHECK (((decision)::text = ANY ((ARRAY['VALIDEE'::character varying, 'REJETEE'::character varying])::text[])))
);


ALTER TABLE public.offres_moderation OWNER TO pnlf_app;

--
-- TOC entry 283 (class 1259 OID 78480)
-- Name: offres_statut_workflow; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.offres_statut_workflow (
    offre_id uuid NOT NULL,
    statut character varying(20) NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.offres_statut_workflow OWNER TO pnlf_app;

--
-- TOC entry 293 (class 1259 OID 86854)
-- Name: pnlf_evolutions; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.pnlf_evolutions (
    nom character varying(200) NOT NULL,
    appliquee_le timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pnlf_evolutions OWNER TO pnlf_app;

--
-- TOC entry 301 (class 1259 OID 87027)
-- Name: presences; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.presences (
    utilisateur_id uuid NOT NULL,
    empreinte_appareil character varying(64) NOT NULL,
    appareil character varying(20) DEFAULT 'INCONNU'::character varying NOT NULL,
    systeme character varying(40),
    navigateur character varying(40),
    ip_adresse inet,
    debut_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    derniere_activite timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.presences OWNER TO pnlf_app;

--
-- TOC entry 289 (class 1259 OID 86752)
-- Name: token_blacklist_blacklistedtoken; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.token_blacklist_blacklistedtoken (
    id bigint NOT NULL,
    blacklisted_at timestamp with time zone NOT NULL,
    token_id bigint NOT NULL
);


ALTER TABLE public.token_blacklist_blacklistedtoken OWNER TO pnlf_app;

--
-- TOC entry 288 (class 1259 OID 86751)
-- Name: token_blacklist_blacklistedtoken_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.token_blacklist_blacklistedtoken ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.token_blacklist_blacklistedtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 291 (class 1259 OID 86760)
-- Name: token_blacklist_outstandingtoken; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.token_blacklist_outstandingtoken (
    id bigint NOT NULL,
    token text NOT NULL,
    created_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    user_id integer,
    jti character varying(255) CONSTRAINT token_blacklist_outstandingtoken_jti_hex_not_null NOT NULL
);


ALTER TABLE public.token_blacklist_outstandingtoken OWNER TO pnlf_app;

--
-- TOC entry 290 (class 1259 OID 86759)
-- Name: token_blacklist_outstandingtoken_id_seq; Type: SEQUENCE; Schema: public; Owner: pnlf_app
--

ALTER TABLE public.token_blacklist_outstandingtoken ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.token_blacklist_outstandingtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 302 (class 1259 OID 87048)
-- Name: visites_publiques; Type: TABLE; Schema: public; Owner: pnlf_app
--

CREATE TABLE public.visites_publiques (
    jour date NOT NULL,
    page character varying(120) NOT NULL,
    appareil character varying(20) NOT NULL,
    visites integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.visites_publiques OWNER TO pnlf_app;

--
-- TOC entry 6349 (class 2604 OID 69985)
-- Name: audit_logs id; Type: DEFAULT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.audit_logs ALTER COLUMN id SET DEFAULT nextval('pnlf.audit_logs_id_seq'::regclass);


--
-- TOC entry 6378 (class 2604 OID 87009)
-- Name: connexions id; Type: DEFAULT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.connexions ALTER COLUMN id SET DEFAULT nextval('public.connexions_id_seq'::regclass);


--
-- TOC entry 6970 (class 0 OID 70004)
-- Dependencies: 255
-- Data for Name: appareils_sync; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.appareils_sync (id, utilisateur_id, device_id, libelle, dernier_sync_at, actif, created_at) FROM stdin;
d5b914b0-b41f-4c09-ba0d-47bad37f5a0f	96c362a7-7215-490a-8443-371d2768cd2e	DEMO-TABLETTE-MAKOKOU-01	Tablette terrain, Makokou	2026-10-02 12:06:46.798241+02	t	2026-10-02 12:06:46.798241+02
\.


--
-- TOC entry 6969 (class 0 OID 69982)
-- Dependencies: 254
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.audit_logs (id, utilisateur_id, action, table_cible, enregistrement_id, ip_adresse, user_agent, anciennes_valeurs, nouvelles_valeurs, created_at) FROM stdin;
1	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N	\N	{"test": true}	2026-08-10 14:35:58.949512+02
2	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Python-urllib/3.14	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-10 14:36:18.922239+02
3	1051c839-763f-4a10-9f0e-7b64d301a393	LOGIN	utilisateurs	1051c839-763f-4a10-9f0e-7b64d301a393	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "test_admin@pnlf-test.local"}	2026-08-13 12:33:13.042601+02
4	1051c839-763f-4a10-9f0e-7b64d301a393	LOGIN	utilisateurs	1051c839-763f-4a10-9f0e-7b64d301a393	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "test_admin@pnlf-test.local"}	2026-08-13 12:33:13.63455+02
5	9f1ffdb2-b800-4e03-8587-2ebe210fe622	LOGIN	utilisateurs	9f1ffdb2-b800-4e03-8587-2ebe210fe622	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "test_acheteur@pnlf-test.local"}	2026-08-13 12:33:14.209953+02
6	505512be-a7e2-4291-b5cb-6f7f3bb54030	LOGIN	utilisateurs	505512be-a7e2-4291-b5cb-6f7f3bb54030	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test_producteur@pnlf-test.local"}	2026-08-13 12:33:14.821426+02
7	d2dd8717-64d9-47e9-a533-4fdce48ba54e	LOGIN	utilisateurs	d2dd8717-64d9-47e9-a533-4fdce48ba54e	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "test_agent_min@pnlf-test.local"}	2026-08-13 12:33:15.381331+02
8	d2dd8717-64d9-47e9-a533-4fdce48ba54e	CREATE	produits	14102286-f9a4-440e-bc84-916df15b9a2d	127.0.0.1	\N	\N	{"nom": "Produit agent", "code": "TST-AG-6dc84e"}	2026-08-13 12:33:15.399097+02
9	1051c839-763f-4a10-9f0e-7b64d301a393	LOGIN	utilisateurs	1051c839-763f-4a10-9f0e-7b64d301a393	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "test_admin@pnlf-test.local"}	2026-08-13 12:33:15.688391+02
10	1051c839-763f-4a10-9f0e-7b64d301a393	CREATE	lots	07fa0834-2dd8-47b1-a514-176f1f8091a9	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-E455264678", "uuid_public": "564d2fc5-834f-4eb8-9234-bf920aac1213"}	2026-08-13 12:33:15.728645+02
11	1051c839-763f-4a10-9f0e-7b64d301a393	SOFT_DELETE	lots	07fa0834-2dd8-47b1-a514-176f1f8091a9	127.0.0.1	\N	\N	\N	2026-08-13 12:33:15.758256+02
12	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N	\N	{"test": true}	2026-08-13 12:33:37.810183+02
13	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:50:55.112488+02
14	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:50:56.09132+02
15	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:50:57.049977+02
16	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:50:57.995741+02
17	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:50:58.983985+02
18	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:50:59.850043+02
19	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:51:00.841959+02
20	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	c251228a-fc87-4b0d-b6ee-e3c076ebda98	127.0.0.1	\N	\N	{"nom": "Test RBAC admin", "code": "RBAC-admin-0f8909"}	2026-08-13 14:51:01.177453+02
21	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	86a4d7fd-0461-4b95-a732-01aaff3f5714	127.0.0.1	\N	\N	{"nom": "Test RBAC agent_min", "code": "RBAC-agent_min-81e6e8"}	2026-08-13 14:51:01.208179+02
22	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	f8d8d141-99bf-40d4-a69b-f7ddd8bfaac7	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-db24f9"}	2026-08-13 14:51:01.258001+02
23	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	2be4fa4f-9e73-44a0-b604-70a9f59f0f77	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-beb4c3"}	2026-08-13 14:51:01.280457+02
24	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	27b9943d-2844-4ba1-811f-0e871fa1f0da	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-785e73"}	2026-08-13 14:51:01.30422+02
25	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	4604f83b-77bc-4758-a2cb-172f5f5e2772	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-b002a9"}	2026-08-13 14:51:01.325665+02
26	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	4930b891-237e-47a2-99d2-dfb3fe640157	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-7d2111"}	2026-08-13 14:51:01.347228+02
27	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	88f42de2-5646-4008-a283-2539f2e43e21	127.0.0.1	\N	\N	\N	2026-08-13 14:51:01.461598+02
28	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	6c36cf89-bf38-4585-9ed7-6105d09c6834	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-35B458D565", "uuid_public": "d1a34831-94f9-4d3e-87d6-fb7d08b0882a"}	2026-08-13 14:51:01.527455+02
29	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	f732e990-3a92-4436-bfbe-45dccd6412f3	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-C1CB86289D", "uuid_public": "175f3c7b-03fd-4bc8-beca-555c32d3cac9"}	2026-08-13 14:51:01.592518+02
30	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	eae7ddfb-aa9b-4a85-ad6f-3a1ba0cc1d80	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-4A0208551C", "uuid_public": "c193c470-72dc-4b6c-bde9-40c05754bc51"}	2026-08-13 14:51:01.654925+02
31	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	72bfcb0e-d964-43f7-ace3-9ec798fbc9b5	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-2CA72F7708", "uuid_public": "f98edae0-9989-4d78-a347-49a09bb2b7c5"}	2026-08-13 14:51:01.712563+02
32	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	67fe58b6-5032-43e3-87ec-e5288cec9cf4	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-77656B291A", "uuid_public": "68e09589-e99e-4309-ac2f-84fa8bb08bc8"}	2026-08-13 14:51:01.773139+02
33	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	242cb5f0-bf99-4a9e-a8ae-b8482cf56adb	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-9D37C4CD75", "uuid_public": "425489e3-0a73-4948-bb1a-94768aa6afd9"}	2026-08-13 14:51:01.999501+02
34	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	d25990de-abce-4a33-8532-370a252fe84e	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-3F6FFBE010", "uuid_public": "eb6d68ca-e47e-417a-bbc1-ee14765eec5a"}	2026-08-13 14:51:02.225909+02
35	867247ca-c7cd-4240-a26d-184312b3fcc8	SOFT_DELETE	lots	d25990de-abce-4a33-8532-370a252fe84e	127.0.0.1	\N	\N	\N	2026-08-13 14:51:02.256636+02
36	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	dbfaa73b-99d8-412e-b7d0-614d22408dca	127.0.0.1	\N	\N	{"code_producteur": "AGF-3b1820"}	2026-08-13 14:51:02.275755+02
37	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:51:54.564074+02
38	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:51:55.929453+02
39	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:51:57.327061+02
40	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:51:58.960424+02
41	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:52:00.330258+02
42	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:52:01.724752+02
43	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:53:06.570196+02
44	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:53:07.860873+02
45	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:53:09.124901+02
46	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:53:10.429882+02
47	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:53:11.731854+02
48	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:53:13.043263+02
49	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:53:13.943831+02
50	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	2488a860-dd07-4abb-8234-6039b075dcb0	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-27a73c"}	2026-08-13 14:53:14.293906+02
51	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	88f64df9-a902-4976-b73a-0385ba26cf10	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-f03464"}	2026-08-13 14:53:14.316804+02
52	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	eceb8e0f-bd08-43c8-bd38-e19dbbc0dedf	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-af5085"}	2026-08-13 14:53:14.338401+02
53	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	acde2b48-6a26-4371-8c0b-d6db6d774a76	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-17a12f"}	2026-08-13 14:53:14.35488+02
54	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	1a735b32-8bd9-45a7-ac2f-ba7be7c455cc	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-02ca15"}	2026-08-13 14:53:14.370247+02
55	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	97421cd2-24d5-4f37-af62-5bac7c43ac0f	127.0.0.1	\N	\N	\N	2026-08-13 14:53:14.46705+02
56	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	36d41a1a-17df-485a-8af8-ca1e89301c1f	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-AFE39655CA", "uuid_public": "a513eff5-9b0f-4d85-97cc-093611f23752"}	2026-08-13 14:53:14.506125+02
57	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	192b93a8-c496-43ef-8871-16b6c4d86f0c	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-7F9B008D08", "uuid_public": "207bde12-2de0-4bf8-a437-dc544332c920"}	2026-08-13 14:53:14.542075+02
58	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	680c23ed-0ad7-435c-93c2-0733a4312726	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-91E884D2DD", "uuid_public": "0e0462af-ea41-472f-ad1f-c0d5a7eb6a3d"}	2026-08-13 14:53:14.572167+02
59	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	e437c0f5-36ad-4a4b-b637-9ae63759035e	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-19A4A6699F", "uuid_public": "3512000d-e181-42fb-8486-a797b3b9007e"}	2026-08-13 14:53:14.603811+02
60	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	73e3c879-2b0a-4679-96f9-e14c889eaa7f	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-4F4253AC98", "uuid_public": "d9f2743c-5b5f-4042-9f20-654bd9470fd0"}	2026-08-13 14:53:14.644105+02
61	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	09cd3c9e-1a70-4ce1-a1d0-24468fb4ab1b	127.0.0.1	\N	\N	{"lot_id": "7103bd23-00dd-4ad8-9397-73280b333f3f", "type_mouvement": "CONTROLE"}	2026-08-13 14:53:14.807173+02
62	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	087eb98b-b513-48d0-89c4-b4d175be40ad	127.0.0.1	\N	\N	{"lot_id": "7103bd23-00dd-4ad8-9397-73280b333f3f", "type_mouvement": "CONTROLE"}	2026-08-13 14:53:14.8367+02
63	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	b8cc0dd9-79c0-40d0-8a24-a4d8255e8659	127.0.0.1	\N	\N	{"lot_id": "7103bd23-00dd-4ad8-9397-73280b333f3f", "type_mouvement": "CONTROLE"}	2026-08-13 14:53:14.860639+02
64	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	749e0d73-5539-438c-b82f-cf56e1478664	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-E80F876C38", "uuid_public": "e8eaa534-66be-456a-9dd8-102b3fb42473"}	2026-08-13 14:53:14.902469+02
65	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	cbba6520-d220-45aa-a8bc-52a8ac8d0025	127.0.0.1	\N	\N	{"lot_id": "749e0d73-5539-438c-b82f-cf56e1478664", "type_mouvement": "CONTROLE"}	2026-08-13 14:53:14.94323+02
66	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	08c2c56f-9b50-428a-ad22-08e0390ca59d	127.0.0.1	\N	\N	{"lot_id": "7103bd23-00dd-4ad8-9397-73280b333f3f", "type_mouvement": "CONTROLE"}	2026-08-13 14:53:14.968756+02
67	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	309a3c6f-8439-4583-be13-0318f7fcaecb	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-DCE6F1FA2C", "uuid_public": "e8652afe-9bb6-43ff-bb24-06012661a0aa"}	2026-08-13 14:53:15.155251+02
68	867247ca-c7cd-4240-a26d-184312b3fcc8	SOFT_DELETE	lots	309a3c6f-8439-4583-be13-0318f7fcaecb	127.0.0.1	\N	\N	\N	2026-08-13 14:53:15.186283+02
69	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	5e53e681-cb89-4fab-bd8b-ebf2d2133383	127.0.0.1	\N	\N	{"code_producteur": "AGF-63dfc4"}	2026-08-13 14:53:15.19866+02
70	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:55:02.311254+02
71	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:55:03.72794+02
72	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:55:05.076611+02
73	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:55:06.461824+02
74	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:55:07.860285+02
75	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:55:09.202796+02
76	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:55:10.151458+02
77	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	d399f5eb-2a9b-40e4-8375-ca21f1e35f7c	127.0.0.1	\N	\N	{"nom": "Test RBAC admin afe0e4", "code": "RBAC-admin-c73e50"}	2026-08-13 14:55:10.436899+02
78	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	ae1d54f6-f1e2-4af9-a622-2a4f9e190d02	127.0.0.1	\N	\N	{"nom": "Test RBAC agent_min 9fbb7d", "code": "RBAC-agent_min-c1bb69"}	2026-08-13 14:55:10.461341+02
79	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	e8ce4b5f-e8d7-4d93-9c79-88752bc5375b	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-aeaac5"}	2026-08-13 14:55:10.512802+02
80	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	e086eb62-bfca-44d3-b45a-7e010882b45a	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-4458e4"}	2026-08-13 14:55:10.535387+02
81	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	bbf05d0a-816e-466c-80da-3e1f402bcdce	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-52dd62"}	2026-08-13 14:55:10.548481+02
82	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	56c1a5ac-79d8-4881-bc1b-af37b1add5c0	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-d9298c"}	2026-08-13 14:55:10.567884+02
83	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	1d2d6de2-a62e-494e-96d3-10e33d01bca9	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-cc9bff"}	2026-08-13 14:55:10.590748+02
84	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	5226f554-ac72-4d29-ab0a-64d8be484a1c	127.0.0.1	\N	\N	\N	2026-08-13 14:55:10.696574+02
85	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	39514cfc-0c93-4fe9-b85a-ff3fd8c043d0	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-674AD5C40A", "uuid_public": "851ecbae-2ff7-4262-9dd0-befc2fcae46c"}	2026-08-13 14:55:10.73735+02
86	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	d25c710b-839a-49ec-a011-89b37ef436ec	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-5D74CF92FF", "uuid_public": "00201d44-30ec-41e0-acc1-005b7025f052"}	2026-08-13 14:55:10.83247+02
87	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	5c386e69-9870-4b6b-8e27-4d5bf9027da9	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-24AE6A5254", "uuid_public": "5e9d6bf7-4253-4f6c-8445-fe65052f421e"}	2026-08-13 14:55:10.92288+02
88	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	e4b7c78d-8663-4b2a-afb3-71c1c7f3554b	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-E7A7048191", "uuid_public": "59259fe9-9997-4f13-aaa3-7eec3bb37234"}	2026-08-13 14:55:10.974533+02
89	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	c3885f84-6a3e-491a-a07e-4e812836b66d	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-A59F9DC09C", "uuid_public": "2f07b2f9-577b-48e7-8b47-a890ea1892fb"}	2026-08-13 14:55:11.012637+02
90	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	97f0b912-772d-46e1-aaba-1baa833a9ebd	127.0.0.1	\N	\N	{"lot_id": "87e9b6b2-f1c7-4bec-a267-8b45e8753e25", "type_mouvement": "CONTROLE"}	2026-08-13 14:55:11.180185+02
91	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	143f6c6d-ab60-4913-ad5b-a12b9e5c00d8	127.0.0.1	\N	\N	{"lot_id": "87e9b6b2-f1c7-4bec-a267-8b45e8753e25", "type_mouvement": "CONTROLE"}	2026-08-13 14:55:11.205862+02
92	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	310f2dc1-60e6-4bd8-9eef-b92964b345c4	127.0.0.1	\N	\N	{"lot_id": "87e9b6b2-f1c7-4bec-a267-8b45e8753e25", "type_mouvement": "CONTROLE"}	2026-08-13 14:55:11.231889+02
93	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	4c7da43b-544d-42e4-ae01-70caa3905819	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-1CBE383800", "uuid_public": "abce6ebf-b059-4c24-a625-e679f61adadb"}	2026-08-13 14:55:11.270298+02
94	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	2573f924-f9df-4744-b163-dff303636d80	127.0.0.1	\N	\N	{"lot_id": "4c7da43b-544d-42e4-ae01-70caa3905819", "type_mouvement": "CONTROLE"}	2026-08-13 14:55:11.304952+02
95	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	f5e33e4f-2e89-457d-8e88-f6c143b36707	127.0.0.1	\N	\N	{"lot_id": "87e9b6b2-f1c7-4bec-a267-8b45e8753e25", "type_mouvement": "CONTROLE"}	2026-08-13 14:55:11.329265+02
96	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	16649b4b-0929-45d1-b830-ae486e38be3d	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-5F15762956", "uuid_public": "75ff3a12-c0ba-473e-a885-cf7da129c925"}	2026-08-13 14:55:11.562491+02
97	867247ca-c7cd-4240-a26d-184312b3fcc8	SOFT_DELETE	lots	16649b4b-0929-45d1-b830-ae486e38be3d	127.0.0.1	\N	\N	\N	2026-08-13 14:55:11.597741+02
98	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	af3540a1-9c75-4321-b421-81c070180808	127.0.0.1	\N	\N	{"code_producteur": "AGF-54ea72"}	2026-08-13 14:55:11.628439+02
99	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:56:10.447749+02
100	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:56:11.771872+02
101	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:56:13.035485+02
102	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:56:14.34154+02
103	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:56:15.612405+02
104	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:56:16.894565+02
105	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:56:17.79104+02
106	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	6d5be948-2e51-468a-9b31-888978f073ec	127.0.0.1	\N	\N	{"nom": "Test RBAC admin 2c2b70", "code": "RBAC-admin-851551"}	2026-08-13 14:56:18.172481+02
107	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	ae926c05-4142-47b7-9b08-4f8b089376b4	127.0.0.1	\N	\N	{"nom": "Test RBAC agent_min 1d8a36", "code": "RBAC-agent_min-b033ef"}	2026-08-13 14:56:18.198602+02
108	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	29f7f41f-4d3d-41e3-b9d4-150644bfc821	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-24e38e"}	2026-08-13 14:56:18.255456+02
109	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	b00d01a0-6541-4625-8432-ddf541860b02	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-484223"}	2026-08-13 14:56:18.278952+02
110	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	ba571c43-da0e-405b-8c6f-42eca0cbe2f6	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-8ef874"}	2026-08-13 14:56:18.30072+02
111	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	ca18a13c-f250-4298-a18f-121bc08ada2d	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-70df88"}	2026-08-13 14:56:18.334964+02
112	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	0a7a7327-882b-4d07-9931-7b5ede4330a2	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-26d961"}	2026-08-13 14:56:18.363306+02
113	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	3c82ea68-8f13-404d-85be-4333679fb1c2	127.0.0.1	\N	\N	\N	2026-08-13 14:56:18.511703+02
114	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	e9ba15d9-eea2-4474-90bb-3162bdf3674c	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-75AC4A70CA", "uuid_public": "e9193654-2fd3-4946-bbc5-20ecc3ba9835"}	2026-08-13 14:56:18.579046+02
115	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	cfeb7bb7-ccfb-48e3-839a-969001365b45	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-069BB2C6B4", "uuid_public": "de8c9d13-2b5e-4899-b440-f0fd23651ca4"}	2026-08-13 14:56:18.637439+02
116	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	c856c8fd-10cb-4128-86d2-a4517631f039	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-12CDD5CB96", "uuid_public": "414c5ff0-f6fa-40cb-af93-f6a128bfcbc8"}	2026-08-13 14:56:18.674884+02
117	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	abef08e3-bf40-451b-a860-45bd366eee32	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-84036B2550", "uuid_public": "ceb7c922-8c29-4ad3-9719-cb7e639fc1c0"}	2026-08-13 14:56:18.719455+02
118	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	ea1b6189-2a4d-42c6-9410-bc59b3357468	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-789DD5A2D7", "uuid_public": "8445f7cb-3438-4ff3-8abb-d1f776c2a976"}	2026-08-13 14:56:18.756337+02
119	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	fe45dfbf-b34f-4a23-9496-d479a20654ca	127.0.0.1	\N	\N	{"lot_id": "4f532bb7-3727-41c4-b823-f79d20943430", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:18.915129+02
120	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	eb3665f0-9a02-4a39-b872-6bdf104394ff	127.0.0.1	\N	\N	{"lot_id": "4f532bb7-3727-41c4-b823-f79d20943430", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:18.935982+02
121	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	eb344933-0e65-48fc-8e70-508030fb0528	127.0.0.1	\N	\N	{"lot_id": "4f532bb7-3727-41c4-b823-f79d20943430", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:18.961852+02
122	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	e77b0d44-e40f-47da-9436-338e24f4948a	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-16B8378CA2", "uuid_public": "4bb574e8-009f-4f1e-b718-1a5277054406"}	2026-08-13 14:56:18.997527+02
123	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	8a74a62c-bd8c-4992-9019-bbebad085d40	127.0.0.1	\N	\N	{"lot_id": "e77b0d44-e40f-47da-9436-338e24f4948a", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:19.031067+02
124	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	140439a6-5ec8-41a5-a8d1-a4560ca427f3	127.0.0.1	\N	\N	{"lot_id": "4f532bb7-3727-41c4-b823-f79d20943430", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:19.054277+02
125	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	78492e02-c603-48c0-a488-8579d43e616f	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-363B802237", "uuid_public": "3551fc2f-1038-43ac-8a38-c1b06f0a780d"}	2026-08-13 14:56:19.314683+02
126	867247ca-c7cd-4240-a26d-184312b3fcc8	SOFT_DELETE	lots	78492e02-c603-48c0-a488-8579d43e616f	127.0.0.1	\N	\N	\N	2026-08-13 14:56:19.34956+02
127	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	ace5e7b6-96ec-4f2b-9146-6d22fdde26ee	127.0.0.1	\N	\N	{"code_producteur": "AGF-0b09e6"}	2026-08-13 14:56:19.370174+02
128	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:56:23.378707+02
129	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 14:56:24.76411+02
130	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 14:56:26.128929+02
131	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 14:56:27.534683+02
132	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 14:56:28.914238+02
133	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 14:56:30.258319+02
134	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 14:56:31.250997+02
135	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	9ccad303-69e7-4d5f-adaa-78462be552ab	127.0.0.1	\N	\N	{"nom": "Test RBAC admin e4c81e", "code": "RBAC-admin-329bd0"}	2026-08-13 14:56:31.571876+02
136	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	84bd1b2d-fe96-44f4-b4dc-676280156bc1	127.0.0.1	\N	\N	{"nom": "Test RBAC agent_min e00a34", "code": "RBAC-agent_min-4819f3"}	2026-08-13 14:56:31.606604+02
137	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	bf48952c-998d-489c-9564-0d0a16a2b4d3	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-2aeb85"}	2026-08-13 14:56:31.654521+02
138	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	a4b13bf3-ba07-488f-b66f-5a6d043a656f	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-cdb75e"}	2026-08-13 14:56:31.676804+02
139	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	1d2b461a-8911-40e8-a14b-5edea911fb1c	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-b3e2a6"}	2026-08-13 14:56:31.699649+02
140	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	93f97b4a-14bf-402a-99ba-0739b16e6de4	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-e8dea8"}	2026-08-13 14:56:31.722699+02
141	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	b5f6b687-db90-4646-a7a9-cd09f12439f4	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-0c3cfc"}	2026-08-13 14:56:31.747799+02
142	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	143ffb3e-853a-41d9-9c65-ec683695769d	127.0.0.1	\N	\N	\N	2026-08-13 14:56:31.853515+02
143	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	ebf56ae8-e877-45ee-b444-620ca79df018	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-E6FDA11423", "uuid_public": "d3f2dce1-65d2-4370-b74d-2c07fd1b975e"}	2026-08-13 14:56:31.910968+02
144	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	5f2fc59a-b2d2-4d4e-9db6-3a36ea46c34c	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-CED0F419CA", "uuid_public": "4bb76c12-a75b-451c-b418-eb6f411d156b"}	2026-08-13 14:56:31.986121+02
145	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	6e99d951-70c9-46f1-8d40-388b6fbb8126	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-AA8F0654CE", "uuid_public": "99b5aeda-cec4-46f7-9a8e-a51181ff1b4d"}	2026-08-13 14:56:32.051728+02
146	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	5a335163-11c9-41ce-a66b-504d08c9f909	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-49BA2564D1", "uuid_public": "2dc753bc-0db9-4c84-9c2a-cf23e5543a9f"}	2026-08-13 14:56:32.119302+02
147	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	cf6f989a-98d0-4682-948c-5538447e4b4b	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-1D75AE7DB5", "uuid_public": "1898e388-7543-4ad8-885a-a673ed08a98e"}	2026-08-13 14:56:32.177785+02
148	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	a77cf50d-ecaf-4428-a9c4-a25736a01107	127.0.0.1	\N	\N	{"lot_id": "226d5a29-c768-4283-9510-c0ee09ab6ad0", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:32.374933+02
149	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	ea214649-adef-4838-ba89-ea9dcb22d738	127.0.0.1	\N	\N	{"lot_id": "226d5a29-c768-4283-9510-c0ee09ab6ad0", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:32.409293+02
150	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	7e9a1b0b-fc2a-490c-96fa-c27df74486be	127.0.0.1	\N	\N	{"lot_id": "226d5a29-c768-4283-9510-c0ee09ab6ad0", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:32.443561+02
151	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	3dd1ba95-ac23-4045-902a-95a261153c17	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-95634B801A", "uuid_public": "ab61f945-fc2b-414e-8c82-ed557c792d5d"}	2026-08-13 14:56:32.492506+02
152	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	3c378b20-bd67-4bdf-907f-ed7b0d55c7c3	127.0.0.1	\N	\N	{"lot_id": "3dd1ba95-ac23-4045-902a-95a261153c17", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:32.527387+02
153	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	aba4f61c-c11a-4bf0-baa1-4ad3476f5692	127.0.0.1	\N	\N	{"lot_id": "226d5a29-c768-4283-9510-c0ee09ab6ad0", "type_mouvement": "CONTROLE"}	2026-08-13 14:56:32.561378+02
154	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	23726099-ba5f-4900-8824-9d5ac5f2d8ee	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-D04051B6E9", "uuid_public": "ab55b4ed-426c-4572-95d5-99626f436d14"}	2026-08-13 14:56:32.776779+02
155	867247ca-c7cd-4240-a26d-184312b3fcc8	SOFT_DELETE	lots	23726099-ba5f-4900-8824-9d5ac5f2d8ee	127.0.0.1	\N	\N	\N	2026-08-13 14:56:32.81492+02
156	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	9563aec3-96d4-454d-920b-8fb2b2d8c206	127.0.0.1	\N	\N	{"code_producteur": "AGF-56f461"}	2026-08-13 14:56:32.830979+02
157	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 15:16:53.459263+02
158	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 15:16:54.92747+02
159	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 15:16:56.276576+02
160	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 15:16:57.600573+02
161	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 15:16:58.976385+02
162	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 15:17:00.292212+02
163	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 15:18:51.066708+02
164	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-13 15:18:52.430096+02
165	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-13 15:18:53.771688+02
166	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-13 15:18:55.157453+02
167	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-13 15:18:56.467513+02
168	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-13 15:18:57.771348+02
169	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-13 15:18:58.714504+02
170	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	d02aa82b-40df-4936-bc1c-5724ac6201f7	127.0.0.1	\N	\N	{"code": "RBAC-admin-e6d31c"}	2026-08-13 15:18:59.071686+02
171	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	31b414ae-fda4-4240-9083-0c763334d443	127.0.0.1	\N	\N	{"code": "RBAC-agent_min-5bbdf2"}	2026-08-13 15:18:59.091431+02
172	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	36f91375-1657-40f9-a4e1-60710579c8c6	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-08e1f2"}	2026-08-13 15:18:59.323164+02
173	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	a6c24293-7e48-4fe7-972a-8f87c7e972d7	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-ba0486"}	2026-08-13 15:18:59.348171+02
174	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	67bde694-e33e-4a28-a3b2-e47eb449a22d	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-609f09"}	2026-08-13 15:18:59.371013+02
175	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	d0737953-a582-4324-b172-0472b51b1ccc	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-05dea8"}	2026-08-13 15:18:59.394342+02
176	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	e98b1c02-19ae-4ba4-b473-9170ecd08da9	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-74a8db"}	2026-08-13 15:18:59.418534+02
177	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	cf858f2d-3082-4e46-9c17-daeeed5b03fa	127.0.0.1	\N	\N	\N	2026-08-13 15:18:59.570869+02
178	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	0c0106ee-1b58-4b85-8ddd-cea26904d0ff	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-22A8ADAF4B"}	2026-08-13 15:19:00.204086+02
179	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	88181504-eb0e-4036-a6ef-bc43be5beed6	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-0C335E627C"}	2026-08-13 15:19:00.275149+02
180	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	18a8c9f8-e0fb-4053-877f-023e68359da7	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-88AD218334"}	2026-08-13 15:19:00.358229+02
181	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	954bede4-567a-480a-a715-58c0b6a9828c	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-EAB63171B1"}	2026-08-13 15:19:00.424096+02
182	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	4af77ba1-b515-42e3-8156-d299733b266e	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-40AD218188"}	2026-08-13 15:19:00.480623+02
183	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	fcc27a16-1f00-4beb-a817-d1741cb93708	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-13 15:19:00.666045+02
184	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	abd43669-04be-4b20-aac7-3b03f9ca080a	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-13 15:19:00.684758+02
185	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	7bdfb5a6-6e30-4277-9344-6d5d174c1e5f	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-13 15:19:00.697142+02
186	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	81593e4f-57a1-451b-a030-c09baeb0a38e	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-1BCEC822B1"}	2026-08-13 15:19:00.733603+02
187	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	e1ade27d-4116-46b9-b395-4834c4c692e5	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-13 15:19:00.757958+02
188	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	965269ce-3ed4-4fa1-aec3-f4a872697425	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-13 15:19:00.777199+02
189	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	87057364-ce8b-4dc3-8c87-658c8b4de90e	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260813-77489FBEC8"}	2026-08-13 15:19:01.029311+02
190	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	f55f2bcb-6013-46fb-82d7-ffda39280ac9	127.0.0.1	\N	\N	{"code_producteur": "AGF-6e0c86"}	2026-08-13 15:19:01.095214+02
191	28685225-99bb-47f6-bee0-44618f80115d	LOGIN	utilisateurs	28685225-99bb-47f6-bee0-44618f80115d	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "cadrage_admin@pnlf-test.local"}	2026-08-13 15:19:35.8914+02
192	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:19:36.467886+02
193	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:19:37.130154+02
194	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:21:12.693883+02
195	2b4e609b-d46f-4187-b99a-e23d596d0334	EXPORT	lots	\N	127.0.0.1	\N	\N	{"format": "csv"}	2026-08-13 15:21:12.710769+02
196	28685225-99bb-47f6-bee0-44618f80115d	LOGIN	utilisateurs	28685225-99bb-47f6-bee0-44618f80115d	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "cadrage_admin@pnlf-test.local"}	2026-08-13 15:21:59.503948+02
197	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:22:00.089372+02
198	2b4e609b-d46f-4187-b99a-e23d596d0334	EXPORT	lots	\N	127.0.0.1	\N	\N	{"format": "csv"}	2026-08-13 15:22:00.227058+02
199	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:22:00.876692+02
200	28685225-99bb-47f6-bee0-44618f80115d	LOGIN	utilisateurs	28685225-99bb-47f6-bee0-44618f80115d	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "cadrage_admin@pnlf-test.local"}	2026-08-13 15:36:12.657945+02
201	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:36:12.963184+02
202	2b4e609b-d46f-4187-b99a-e23d596d0334	EXPORT	lots	\N	127.0.0.1	\N	\N	{"format": "csv"}	2026-08-13 15:36:12.990759+02
203	2b4e609b-d46f-4187-b99a-e23d596d0334	LOGIN	utilisateurs	2b4e609b-d46f-4187-b99a-e23d596d0334	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "cadrage_agent@pnlf-test.local"}	2026-08-13 15:36:13.274175+02
204	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:47:32.944046+02
205	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:48:17.492822+02
206	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:49:39.737375+02
207	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:50:39.205791+02
208	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:51:34.37616+02
209	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:52:28.260568+02
210	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:53:14.590688+02
211	2992fb5e-5580-483b-9462-98fe46cf7627	CREATE	lots	30907e00-b121-4760-a042-f7d351b0fbf9	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"code_lot": "PNLF-20260813-F0692843D4"}	2026-08-13 20:53:21.102439+02
212	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:54:18.156544+02
213	2992fb5e-5580-483b-9462-98fe46cf7627	CREATE	lots	efa5499c-ebdd-48a9-8771-748225ebc2c8	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"code_lot": "PNLF-20260813-C5DBA203CA"}	2026-08-13 20:54:21.263195+02
214	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:54:58.142406+02
215	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 20:55:20.210913+02
216	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 21:23:08.853653+02
217	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-13 21:33:46.287805+02
218	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-14 12:32:35.147232+02
219	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-14 12:41:37.099157+02
220	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-14 14:16:48.788081+02
221	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-14 14:27:13.024202+02
222	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "csv"}	2026-08-14 14:29:12.501895+02
223	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "xlsx"}	2026-08-14 14:29:27.753692+02
224	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-14 14:30:26.722767+02
225	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-14 15:29:57.475473+02
226	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "csv"}	2026-08-14 15:38:14.243139+02
227	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "xlsx"}	2026-08-14 15:38:31.558572+02
228	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-14 15:38:47.342008+02
229	\N	INSCRIPTION_PUBLIQUE	producteurs	1d29e123-c3fb-403b-a89c-62ad2fe7b6b0	127.0.0.1	\N	\N	{"email": "test.producteur.82ad1e59@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:21:50.822125+02
230	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	1d29e123-c3fb-403b-a89c-62ad2fe7b6b0	127.0.0.1	\N	\N	\N	2026-08-15 16:21:53.005377+02
231	\N	INSCRIPTION_PUBLIQUE	producteurs	ec85036a-5257-4af4-b23e-dddb05a58828	127.0.0.1	\N	\N	{"email": "test.producteur.ed721073@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:23:02.64989+02
232	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	ec85036a-5257-4af4-b23e-dddb05a58828	127.0.0.1	\N	\N	\N	2026-08-15 16:23:03.24432+02
233	98e2a59e-389d-4b72-ba98-0c3c026dcae1	LOGIN	utilisateurs	98e2a59e-389d-4b72-ba98-0c3c026dcae1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.ed721073@pnlf-test.local"}	2026-08-15 16:23:03.504398+02
234	\N	INSCRIPTION_PUBLIQUE	cooperatives	9bf7adc1-7c0b-41a5-984a-71e1f52eed9f	127.0.0.1	\N	\N	{"email": "test.coop.fe212e98@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:23:03.736321+02
235	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	REJECT	cooperatives	9bf7adc1-7c0b-41a5-984a-71e1f52eed9f	127.0.0.1	\N	\N	\N	2026-08-15 16:23:03.794088+02
236	\N	INSCRIPTION_PUBLIQUE	producteurs	3aa7a8f9-4825-4a1a-9adf-8c8ffa8ed694	127.0.0.1	\N	\N	{"email": "test.producteur.430ae164@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:24:13.353856+02
237	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	3aa7a8f9-4825-4a1a-9adf-8c8ffa8ed694	127.0.0.1	\N	\N	\N	2026-08-15 16:24:13.979107+02
238	79b78eee-a7f2-43b2-9bb7-ed8d0d790982	LOGIN	utilisateurs	79b78eee-a7f2-43b2-9bb7-ed8d0d790982	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.430ae164@pnlf-test.local"}	2026-08-15 16:24:14.257364+02
239	\N	INSCRIPTION_PUBLIQUE	producteurs	e82608fe-54fc-4668-b294-0eef9753295d	127.0.0.1	\N	\N	{"email": "test.producteur.115f9ba6@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:24:30.787902+02
240	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	e82608fe-54fc-4668-b294-0eef9753295d	127.0.0.1	\N	\N	\N	2026-08-15 16:24:31.392646+02
241	10c652a1-c147-4459-91ef-523fb13fc3ad	LOGIN	utilisateurs	10c652a1-c147-4459-91ef-523fb13fc3ad	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.115f9ba6@pnlf-test.local"}	2026-08-15 16:24:31.654055+02
242	\N	INSCRIPTION_PUBLIQUE	producteurs	bea68c6f-bab7-4ad6-8265-a2b0f7f5d3fa	127.0.0.1	\N	\N	{"email": "test.producteur.01fd83f3@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:26:18.155814+02
243	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	bea68c6f-bab7-4ad6-8265-a2b0f7f5d3fa	127.0.0.1	\N	\N	\N	2026-08-15 16:26:18.714331+02
244	edc9a5ef-e345-4601-b244-735904555ea8	LOGIN	utilisateurs	edc9a5ef-e345-4601-b244-735904555ea8	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.01fd83f3@pnlf-test.local"}	2026-08-15 16:26:18.957024+02
245	\N	INSCRIPTION_PUBLIQUE	cooperatives	c967d518-2f25-4793-b23d-092608f5d411	127.0.0.1	\N	\N	{"email": "test.coop.6a5db5f2@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:26:19.182575+02
246	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	REJECT	cooperatives	c967d518-2f25-4793-b23d-092608f5d411	127.0.0.1	\N	\N	\N	2026-08-15 16:26:19.271622+02
247	\N	INSCRIPTION_PUBLIQUE	cooperatives	de769c57-d4d6-47ac-8d2e-4e12ce9225f1	127.0.0.1	\N	\N	{"email": "test.coop.6a5db5f2@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:26:19.548833+02
248	\N	INSCRIPTION_PUBLIQUE	producteurs	e43b2adb-454b-437e-b1a7-9a066d7ebd48	127.0.0.1	\N	\N	{"email": "test.producteur.e17bba51@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:26:37.361019+02
249	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	e43b2adb-454b-437e-b1a7-9a066d7ebd48	127.0.0.1	\N	\N	\N	2026-08-15 16:26:37.938228+02
250	71b962d9-fdb9-4b61-a931-c6676b9225fd	LOGIN	utilisateurs	71b962d9-fdb9-4b61-a931-c6676b9225fd	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.e17bba51@pnlf-test.local"}	2026-08-15 16:26:38.20723+02
251	\N	INSCRIPTION_PUBLIQUE	cooperatives	557e685b-0e95-4500-b8bf-84f41515fa61	127.0.0.1	\N	\N	{"email": "test.coop.d6e20562@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:26:38.438007+02
252	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	REJECT	cooperatives	557e685b-0e95-4500-b8bf-84f41515fa61	127.0.0.1	\N	\N	\N	2026-08-15 16:26:38.507266+02
253	\N	INSCRIPTION_PUBLIQUE	cooperatives	958df223-00b9-481a-be09-1e4c98568ac9	127.0.0.1	\N	\N	{"email": "test.coop.d6e20562@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:26:38.747585+02
254	\N	INSCRIPTION_PUBLIQUE	producteurs	a9c6983b-f451-4cd8-b933-7be901935e5c	127.0.0.1	\N	\N	{"email": "test.producteur.19de46a7@pnlf-test.local", "type_demande": "PRODUCTEUR"}	2026-08-15 16:30:17.12127+02
255	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	VALIDATE	producteurs	a9c6983b-f451-4cd8-b933-7be901935e5c	127.0.0.1	\N	\N	\N	2026-08-15 16:30:17.768995+02
256	48577b92-7b4f-4356-a499-b8f88eff743d	LOGIN	utilisateurs	48577b92-7b4f-4356-a499-b8f88eff743d	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "test.producteur.19de46a7@pnlf-test.local"}	2026-08-15 16:30:18.037868+02
257	\N	INSCRIPTION_PUBLIQUE	cooperatives	6ea3bc43-8210-451a-9e38-b0dab1bc4a47	127.0.0.1	\N	\N	{"email": "test.coop.c442cf35@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:30:18.345453+02
258	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	REJECT	cooperatives	6ea3bc43-8210-451a-9e38-b0dab1bc4a47	127.0.0.1	\N	\N	\N	2026-08-15 16:30:18.450622+02
259	\N	INSCRIPTION_PUBLIQUE	cooperatives	6dd799fb-c468-4f97-9d8e-1cd7cbf02ae3	127.0.0.1	\N	\N	{"email": "test.coop.c442cf35@pnlf-test.local", "type_demande": "COOPERATIVE"}	2026-08-15 16:30:18.668179+02
260	\N	INSCRIPTION_PUBLIQUE	producteurs	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"email": "staeelbent16@gmail.com", "type_demande": "PRODUCTEUR"}	2026-08-15 16:41:36.53695+02
261	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 16:42:03.759256+02
262	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 16:42:24.687923+02
370	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 12:40:17.971874+02
263	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 16:46:19.608383+02
264	ec38d815-0579-448c-b7dd-1c54b8dce005	CREATE	lots	896264b6-573a-4c65-9b7e-c8ca34c2bd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"code_lot": "PNLF-20260815-2337EA4931"}	2026-08-15 16:48:13.753291+02
265	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 16:51:54.992263+02
266	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 16:55:33.192551+02
267	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	cooperatives	b65da288-ffb4-4104-ba87-02725720d7d5	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 16:58:02.330944+02
268	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 17:00:43.322999+02
269	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 17:03:43.089655+02
270	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 17:06:17.99932+02
271	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	CREATE	lots	bdc4005d-08ee-4a9f-be9f-cd666e715270	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260815-DD2EB5967E"}	2026-08-15 17:43:31.273273+02
272	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	bdc4005d-08ee-4a9f-be9f-cd666e715270	127.0.0.1	\N	\N	\N	2026-08-15 17:43:31.313302+02
273	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	DELETE_PHOTO	lots	bdc4005d-08ee-4a9f-be9f-cd666e715270	127.0.0.1	\N	\N	\N	2026-08-15 17:43:31.344783+02
274	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	bdc4005d-08ee-4a9f-be9f-cd666e715270	127.0.0.1	\N	\N	\N	2026-08-15 17:43:31.362737+02
275	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	CREATE	lots	c2367dcb-a765-4713-beb5-e5dafbfd8501	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260815-D82C5080CB"}	2026-08-15 17:44:01.367679+02
276	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	c2367dcb-a765-4713-beb5-e5dafbfd8501	127.0.0.1	\N	\N	\N	2026-08-15 17:44:01.402067+02
277	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	DELETE_PHOTO	lots	c2367dcb-a765-4713-beb5-e5dafbfd8501	127.0.0.1	\N	\N	\N	2026-08-15 17:44:01.426728+02
278	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	c2367dcb-a765-4713-beb5-e5dafbfd8501	127.0.0.1	\N	\N	\N	2026-08-15 17:44:01.444034+02
279	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	CREATE	lots	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260815-F89A15495C"}	2026-08-15 17:44:35.593268+02
280	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	127.0.0.1	\N	\N	\N	2026-08-15 17:44:35.627714+02
281	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	DELETE_PHOTO	lots	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	127.0.0.1	\N	\N	\N	2026-08-15 17:44:35.653949+02
282	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	UPDATE_PHOTO	lots	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	127.0.0.1	\N	\N	\N	2026-08-15 17:44:35.674966+02
283	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Python-urllib/3.14	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 17:51:52.610214+02
284	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 17:52:12.186218+02
285	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:00:08.897565+02
286	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 18:02:44.572262+02
287	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:05:12.967952+02
288	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:09:32.4115+02
289	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 18:11:03.039937+02
290	ec38d815-0579-448c-b7dd-1c54b8dce005	CREATE	lots	e16b7be4-1d09-426d-a064-9dc93c2b3c97	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"code_lot": "PNLF-20260815-3508F83C65"}	2026-08-15 18:11:58.990361+02
291	ec38d815-0579-448c-b7dd-1c54b8dce005	UPDATE_PHOTO	lots	e16b7be4-1d09-426d-a064-9dc93c2b3c97	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 18:11:59.399449+02
292	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-15 18:15:11.170854+02
293	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:17:42.893885+02
294	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	f55f2bcb-6013-46fb-82d7-ffda39280ac9	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 18:18:11.723381+02
295	\N	INSCRIPTION_PUBLIQUE	producteurs	fea18beb-ff84-406b-a45b-6edc5d1cc489	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"email": "sylviamano7@gmail.com", "type_demande": "COLLECTEUR"}	2026-08-15 18:25:48.624578+02
296	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:26:11.061329+02
297	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-15 18:26:45.094207+02
298	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	fea18beb-ff84-406b-a45b-6edc5d1cc489	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 18:26:56.864403+02
371	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:40:18.786747+02
299	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-15 18:27:29.409418+02
300	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	CREATE	lots	06dea582-3d6a-4dfa-8e38-8bd4ca7bf681	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"code_lot": "PNLF-20260815-7E741114F6"}	2026-08-15 18:29:27.744244+02
301	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	UPDATE_PHOTO	lots	06dea582-3d6a-4dfa-8e38-8bd4ca7bf681	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-15 18:29:28.270019+02
302	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Mobile Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-17 16:11:15.905331+02
303	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Mobile Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 16:12:10.233707+02
304	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:31:41.956896+02
305	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:33:52.975495+02
306	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:34:52.811736+02
307	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:41:19.503033+02
308	2992fb5e-5580-483b-9462-98fe46cf7627	DEACTIVATE	producteurs	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:41:37.832304+02
309	2992fb5e-5580-483b-9462-98fe46cf7627	REJECT	producteurs	a6c24293-7e48-4fe7-972a-8f87c7e972d7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:43:40.519294+02
310	2992fb5e-5580-483b-9462-98fe46cf7627	UPDATE	producteurs	a6c24293-7e48-4fe7-972a-8f87c7e972d7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:43:54.780358+02
311	2992fb5e-5580-483b-9462-98fe46cf7627	DEACTIVATE	cooperatives	b65da288-ffb4-4104-ba87-02725720d7d5	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:45:24.658515+02
312	2992fb5e-5580-483b-9462-98fe46cf7627	ACTIVATE	cooperatives	b65da288-ffb4-4104-ba87-02725720d7d5	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:45:28.540154+02
313	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-17 17:46:42.898526+02
314	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-17 17:48:11.70159+02
315	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:50:39.866049+02
316	2992fb5e-5580-483b-9462-98fe46cf7627	ACTIVATE	producteurs	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 17:50:45.625139+02
317	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 17:58:32.306755+02
318	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 18:14:09.830537+02
319	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 18:17:10.614163+02
320	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-17 18:18:12.78016+02
321	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-17 18:19:03.121047+02
322	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	36f91375-1657-40f9-a4e1-60710579c8c6	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 18:22:04.271069+02
323	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	67bde694-e33e-4a28-a3b2-e47eb449a22d	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 18:22:07.088128+02
324	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	d0737953-a582-4324-b172-0472b51b1ccc	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 18:22:08.71749+02
325	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	e98b1c02-19ae-4ba4-b473-9170ecd08da9	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-17 18:22:11.339075+02
326	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-17 18:37:00.594845+02
327	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-18 06:03:34.791052+02
328	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-18 15:28:03.422649+02
329	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 00:25:44.155075+02
330	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-13", "format": "pdf", "granularite": "jour"}	2026-08-19 00:27:32.767482+02
331	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-13", "format": "xlsx", "granularite": "jour"}	2026-08-19 00:27:49.556143+02
332	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-19 11:35:43.947664+02
333	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 11:40:00.402982+02
334	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 11:42:22.54992+02
335	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 11:45:33.412929+02
336	ec38d815-0579-448c-b7dd-1c54b8dce005	CREATE	lots	9a398c12-bf2f-4fcf-b6b4-1590d65708ff	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"code_lot": "PNLF-20260819-D60F530C5E"}	2026-08-19 11:48:00.114951+02
337	ec38d815-0579-448c-b7dd-1c54b8dce005	UPDATE_PHOTO	lots	9a398c12-bf2f-4fcf-b6b4-1590d65708ff	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 11:48:00.538191+02
338	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 11:49:12.164879+02
339	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 11:55:32.38369+02
340	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 12:20:14.405211+02
341	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 12:20:14.993301+02
342	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 12:20:15.524993+02
343	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:20:16.08517+02
344	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 12:20:16.670487+02
345	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 12:20:17.256618+02
346	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:20:18.309166+02
347	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	6fccaa8b-9bf4-4806-843d-8f86fe510c44	127.0.0.1	\N	\N	\N	2026-08-19 12:20:18.849684+02
348	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 12:21:06.353175+02
349	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 12:21:07.130338+02
350	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 12:21:08.046894+02
351	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:21:08.96259+02
352	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 12:21:09.900389+02
353	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 12:21:10.881857+02
354	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:21:11.880058+02
355	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	4d78a694-9a9f-4f06-9228-01c77f7c1d40	127.0.0.1	\N	\N	\N	2026-08-19 12:21:12.654631+02
356	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 12:21:42.787474+02
357	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 12:21:43.613254+02
358	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 12:21:44.403804+02
359	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:21:45.316209+02
360	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 12:21:46.218058+02
361	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 12:21:46.961492+02
362	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:21:47.627544+02
363	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	fb1331f1-5a67-497a-8e45-bd97cc2356b0	127.0.0.1	\N	\N	\N	2026-08-19 12:21:48.349997+02
364	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	lots	dfde6062-15c1-4238-b853-6e1e40969f74	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-D66B7303C8"}	2026-08-19 12:21:49.189234+02
365	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 12:40:13.574078+02
366	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 12:40:14.406822+02
367	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 12:40:15.440854+02
368	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 12:40:16.289895+02
369	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 12:40:17.145979+02
372	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	ad98e5a6-ee71-46e2-9305-8abe21de8401	127.0.0.1	\N	\N	\N	2026-08-19 12:40:19.444179+02
373	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	offres_demandes	74645428-6803-4c56-b9d2-e1a16581b664	127.0.0.1	\N	\N	\N	2026-08-19 12:40:20.000069+02
374	959c438c-ffd7-4a8c-8780-9fd321d60aee	VALIDATE	offres_demandes	74645428-6803-4c56-b9d2-e1a16581b664	127.0.0.1	\N	\N	\N	2026-08-19 12:40:20.035476+02
375	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	lots	b41386d7-ef39-4e9d-8854-f23c1a9137ac	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-48B25496C0"}	2026-08-19 12:40:20.45926+02
376	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-19 12:40:42.503252+02
377	c324981c-2d16-41ee-9121-e21aa9c93565	LOGIN	utilisateurs	c324981c-2d16-41ee-9121-e21aa9c93565	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "rbac_agentmin@pnlf-test.local"}	2026-08-19 12:40:43.348341+02
378	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	LOGIN	utilisateurs	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "rbac_agentfor@pnlf-test.local"}	2026-08-19 12:40:44.18837+02
379	41f20506-4b04-4203-900c-5c52ab3209bf	LOGIN	utilisateurs	41f20506-4b04-4203-900c-5c52ab3209bf	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "rbac_producteur@pnlf-test.local"}	2026-08-19 12:40:45.170932+02
380	24cddb38-0a57-4661-928b-f97aba310218	LOGIN	utilisateurs	24cddb38-0a57-4661-928b-f97aba310218	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "rbac_coop@pnlf-test.local"}	2026-08-19 12:40:46.146843+02
381	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	LOGIN	utilisateurs	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "rbac_acheteur@pnlf-test.local"}	2026-08-19 12:40:46.987143+02
382	867247ca-c7cd-4240-a26d-184312b3fcc8	LOGIN	utilisateurs	867247ca-c7cd-4240-a26d-184312b3fcc8	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "rbac_admin@pnlf-test.local"}	2026-08-19 12:40:47.562472+02
383	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	produits	e0c450dd-b3c7-47fa-b49f-fd6248fd972b	127.0.0.1	\N	\N	{"code": "RBAC-admin-72aa7d"}	2026-08-19 12:40:47.720826+02
384	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	produits	2ab0e878-f995-4108-acdd-7ce0a37c51d2	127.0.0.1	\N	\N	{"code": "RBAC-agent_min-16274b"}	2026-08-19 12:40:47.731486+02
385	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	producteurs	750619e4-d1fb-4a39-8eab-7ea17c63dd8f	127.0.0.1	\N	\N	{"code_producteur": "RBAC-admin-1bc545"}	2026-08-19 12:40:47.793898+02
386	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	producteurs	86429988-bb53-4e7a-9a08-a8c8b87deef9	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_min-90adf0"}	2026-08-19 12:40:47.808811+02
387	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	5ac13177-fed1-4965-914b-629d29a107bf	127.0.0.1	\N	\N	{"code_producteur": "RBAC-agent_for-331f90"}	2026-08-19 12:40:47.820855+02
388	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	producteurs	b08a2333-4e66-4098-b6bc-ee7047e6437f	127.0.0.1	\N	\N	{"code_producteur": "RBAC-producteur-a94a67"}	2026-08-19 12:40:47.833924+02
389	24cddb38-0a57-4661-928b-f97aba310218	CREATE	producteurs	88e9555f-c828-4b75-97eb-b9529cd93f2f	127.0.0.1	\N	\N	{"code_producteur": "RBAC-cooperative-0d6f2a"}	2026-08-19 12:40:47.855264+02
390	24cddb38-0a57-4661-928b-f97aba310218	UPDATE	producteurs	2b8c129b-fb77-4744-9ccf-a172c4e7431f	127.0.0.1	\N	\N	\N	2026-08-19 12:40:47.934396+02
391	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	2d43927b-1ef1-4179-802c-38e2ec495ae3	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-AF473D094A"}	2026-08-19 12:40:48.030891+02
392	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	lots	ca95422f-ebbe-43a4-b199-6a2075afe0af	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-2FD5A4D363"}	2026-08-19 12:40:48.063687+02
393	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	lots	2b3c8331-3445-44be-b861-a6df69c126a6	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-2B5601D872"}	2026-08-19 12:40:48.090012+02
394	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	fe29adac-04cb-47d3-bd9d-73f3ed3649d8	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-F9931175FC"}	2026-08-19 12:40:48.11619+02
395	24cddb38-0a57-4661-928b-f97aba310218	CREATE	lots	50fce242-90c5-4af3-8349-4907f9649a1c	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-3AEB32C562"}	2026-08-19 12:40:48.14696+02
396	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	mouvements	10bf0f46-24f2-4c43-992f-be42be715dbb	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-19 12:40:48.232449+02
397	c324981c-2d16-41ee-9121-e21aa9c93565	CREATE	mouvements	60ae3428-045f-48b8-8ec8-f7be78336489	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-19 12:40:48.23994+02
398	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	mouvements	00d8e30b-0795-4d8e-97b6-390f462c6661	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-19 12:40:48.246698+02
399	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	lots	e2c90d83-967e-41e4-ad3d-aebf4e922897	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-F9FCD0D5E7"}	2026-08-19 12:40:48.266662+02
400	41f20506-4b04-4203-900c-5c52ab3209bf	CREATE	mouvements	73606a7f-9919-4a3a-af19-87c4e15531be	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-19 12:40:48.28841+02
401	24cddb38-0a57-4661-928b-f97aba310218	CREATE	mouvements	a264e847-aa22-4d6b-8332-0e27ef5ecc2b	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-08-19 12:40:48.30037+02
402	867247ca-c7cd-4240-a26d-184312b3fcc8	CREATE	lots	53532fa4-2495-4bb7-ad57-c0b842d1d0ca	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-D08120E6D6"}	2026-08-19 12:40:48.405613+02
403	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	CREATE	producteurs	f8c0ce3d-7954-46c7-b757-41a997c5bdd7	127.0.0.1	\N	\N	{"code_producteur": "AGF-b481a1"}	2026-08-19 12:40:48.43397+02
404	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 12:46:01.13252+02
405	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 12:49:48.178088+02
406	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 12:55:00.564987+02
407	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 13:09:41.611573+02
408	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 13:09:42.282638+02
409	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 13:09:43.0396+02
410	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 13:09:43.891207+02
411	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 13:09:44.839326+02
412	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 13:09:45.984597+02
413	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 13:09:47.84505+02
414	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	zones_collecte	0577d95e-71be-4615-a95e-c05389d8e622	127.0.0.1	\N	\N	\N	2026-08-19 13:09:48.497493+02
415	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	8c42d565-26c3-4908-994b-2490b274ee37	127.0.0.1	\N	\N	\N	2026-08-19 13:09:48.505198+02
416	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	offres_demandes	85259450-734c-47fd-baf8-5343185b1282	127.0.0.1	\N	\N	\N	2026-08-19 13:09:48.902297+02
417	959c438c-ffd7-4a8c-8780-9fd321d60aee	VALIDATE	offres_demandes	85259450-734c-47fd-baf8-5343185b1282	127.0.0.1	\N	\N	\N	2026-08-19 13:09:49.132825+02
418	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	lots	61d7ebae-83cb-44fc-b34d-f3a484d95ff3	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-65999C3660"}	2026-08-19 13:09:49.383079+02
419	959c438c-ffd7-4a8c-8780-9fd321d60aee	LOGIN	utilisateurs	959c438c-ffd7-4a8c-8780-9fd321d60aee	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "parcours_admin@pnlf-test.local"}	2026-08-19 13:10:25.581217+02
420	3e879f22-30a5-4295-a730-24b3e6b67875	LOGIN	utilisateurs	3e879f22-30a5-4295-a730-24b3e6b67875	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "parcours_agentmin@pnlf-test.local"}	2026-08-19 13:10:26.388466+02
421	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	LOGIN	utilisateurs	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "parcours_agentfor@pnlf-test.local"}	2026-08-19 13:10:26.988362+02
422	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 13:10:27.708855+02
423	469a4ea8-2f2b-4d70-9514-4f96476dc47a	LOGIN	utilisateurs	469a4ea8-2f2b-4d70-9514-4f96476dc47a	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "parcours_coop@pnlf-test.local"}	2026-08-19 13:10:28.819695+02
424	27fb70b6-339d-4899-b1db-30c14de44778	LOGIN	utilisateurs	27fb70b6-339d-4899-b1db-30c14de44778	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "parcours_acheteur@pnlf-test.local"}	2026-08-19 13:10:29.970223+02
425	1a62a7d6-150a-4243-8056-3025dab6cbf7	LOGIN	utilisateurs	1a62a7d6-150a-4243-8056-3025dab6cbf7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "parcours_producteur@pnlf-test.local"}	2026-08-19 13:10:30.691348+02
426	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	zones_collecte	0e30f3a4-dd98-42e4-8f7e-f2cea8a89b41	127.0.0.1	\N	\N	\N	2026-08-19 13:10:31.25632+02
427	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	CREATE	zones_collecte	277683f1-6c6e-4c7b-a3cb-38faec341ce0	127.0.0.1	\N	\N	\N	2026-08-19 13:10:31.262916+02
428	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	offres_demandes	88a16c5c-f976-478d-9522-68e85310cefa	127.0.0.1	\N	\N	\N	2026-08-19 13:10:31.637657+02
429	959c438c-ffd7-4a8c-8780-9fd321d60aee	VALIDATE	offres_demandes	88a16c5c-f976-478d-9522-68e85310cefa	127.0.0.1	\N	\N	\N	2026-08-19 13:10:31.711997+02
430	1a62a7d6-150a-4243-8056-3025dab6cbf7	CREATE	lots	0db80fe5-1427-4a01-8be9-183de8232ae9	127.0.0.1	\N	\N	{"code_lot": "PNLF-20260819-43584676EA"}	2026-08-19 13:10:31.937548+02
431	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 13:57:21.686695+02
432	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 13:57:40.977625+02
433	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 14:00:58.442472+02
434	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 14:01:17.440254+02
435	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 15:35:30.130532+02
436	2992fb5e-5580-483b-9462-98fe46cf7627	REJECT	producteurs	f8c0ce3d-7954-46c7-b757-41a997c5bdd7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:02.770401+02
437	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	88e9555f-c828-4b75-97eb-b9529cd93f2f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:26.906712+02
438	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	750619e4-d1fb-4a39-8eab-7ea17c63dd8f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:29.062723+02
439	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	86429988-bb53-4e7a-9a08-a8c8b87deef9	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:30.631347+02
440	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	5ac13177-fed1-4965-914b-629d29a107bf	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:32.32454+02
441	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	b08a2333-4e66-4098-b6bc-ee7047e6437f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-19 15:37:33.984517+02
442	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 15:39:41.14807+02
443	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 15:39:52.21168+02
444	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-19 15:40:30.126448+02
445	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 15:42:01.664478+02
446	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-19 15:43:26.464927+02
447	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-19 15:43:45.929778+02
448	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-19 15:44:03.703179+02
449	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 15:55:46.381545+02
450	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-17", "format": "pdf", "granularite": "semaine"}	2026-08-19 15:56:00.349759+02
451	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 15:56:32.868173+02
452	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 15:56:40.514388+02
453	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-19 16:02:44.662811+02
454	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-19 16:02:51.939824+02
455	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-17", "format": "pdf", "granularite": "semaine"}	2026-08-19 16:03:08.016612+02
579	\N	INSCRIPTION_PUBLIQUE	utilisateurs	d86f7f2c-f363-4f5a-9e14-e8232893566e	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.fbd6df@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 20:07:12.12506+02
456	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-20 14:20:35.198709+02
457	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 11:50:05.470666+02
458	2992fb5e-5580-483b-9462-98fe46cf7627	CREATE	utilisateurs	e300b89e-c6bc-4576-878f-bcdef266555e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur@pnlf.ga"}	2026-08-21 11:52:05.03726+02
459	e300b89e-c6bc-4576-878f-bcdef266555e	LOGIN	utilisateurs	e300b89e-c6bc-4576-878f-bcdef266555e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur@pnlf.ga"}	2026-08-21 11:53:16.174034+02
460	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 11:55:41.064571+02
461	\N	INSCRIPTION_PUBLIQUE	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"email": "kaaki@pnlf.ga", "type_demande": "PRODUCTEUR"}	2026-08-21 11:58:36.863466+02
462	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 11:59:53.513052+02
463	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-21 12:00:46.026225+02
464	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 12:01:27.066883+02
465	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 12:24:54.123548+02
466	2992fb5e-5580-483b-9462-98fe46cf7627	DEACTIVATE	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-21 12:26:04.484021+02
467	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-21 12:42:34.863568+02
468	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 13:11:48.308445+02
469	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Python-urllib/3.14	\N	{"format": "pdf"}	2026-08-21 13:24:40.791561+02
470	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Python-urllib/3.14	\N	{"date": "2026-08-21", "format": "pdf", "granularite": "jour"}	2026-08-21 13:24:41.187551+02
471	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 13:26:29.182432+02
472	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-21 13:26:35.777206+02
473	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-21", "format": "pdf", "granularite": "jour"}	2026-08-21 13:26:49.026502+02
474	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Python-urllib/3.14	\N	{"format": "pdf"}	2026-08-21 13:32:05.479421+02
475	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 13:38:37.749772+02
476	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-08-21 13:38:41.261743+02
477	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-21", "format": "pdf", "granularite": "jour"}	2026-08-21 13:38:49.03039+02
478	\N	INSCRIPTION_PUBLIQUE	producteurs	55140168-b06c-471b-b68f-28db1317fab2	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"email": "yves@pnlf.ga", "type_demande": "COLLECTEUR"}	2026-08-21 18:30:34.691946+02
479	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 18:30:59.005133+02
480	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	55140168-b06c-471b-b68f-28db1317fab2	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-21 18:35:14.523664+02
481	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 18:41:52.532911+02
482	e7f43b56-b615-4214-9e26-e2b2e09d257e	LOGIN	utilisateurs	e7f43b56-b615-4214-9e26-e2b2e09d257e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "yves@pnlf.ga"}	2026-08-21 18:45:10.588062+02
483	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-21 18:49:52.16832+02
484	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-21 19:02:34.595707+02
485	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-21 19:03:15.490257+02
486	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-21 19:04:48.088056+02
487	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-21 19:05:03.424308+02
488	ec38d815-0579-448c-b7dd-1c54b8dce005	CREATE	mouvements	2904780d-af65-4970-acdd-8e6612cee71b	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"type_mouvement": "VENTE"}	2026-08-21 19:07:16.63735+02
489	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-21 19:07:51.409717+02
490	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	LOGIN	utilisateurs	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "sylviamano7@gmail.com"}	2026-08-21 19:08:16.851319+02
491	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	CREATE	mouvements	876c482d-4d68-4806-806f-ddbe234343ce	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"type_mouvement": "VENTE"}	2026-08-21 19:08:35.481412+02
492	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-23 17:46:03.950056+02
493	2992fb5e-5580-483b-9462-98fe46cf7627	ACTIVATE	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	\N	2026-08-23 17:47:01.383112+02
494	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 10:51:58.679806+02
495	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 12:25:18.110659+02
496	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"date": "2026-08-23", "format": "pdf", "granularite": "jour"}	2026-08-25 12:26:29.853129+02
497	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 12:33:45.077425+02
498	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 12:38:29.270516+02
499	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 12:38:53.112224+02
500	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-23", "format": "pdf", "granularite": "jour"}	2026-08-25 12:39:16.474384+02
501	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-08-25 12:39:39.084639+02
502	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "date": "2026-08-25", "format": "pdf", "granularite": "jour"}	2026-08-25 12:39:39.43528+02
503	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-21", "format": "pdf", "granularite": "jour"}	2026-08-25 12:40:11.119388+02
504	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-15", "format": "pdf", "granularite": "jour"}	2026-08-25 12:41:10.143003+02
505	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-08-25 12:41:44.260404+02
506	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-18", "format": "pdf", "granularite": "jour"}	2026-08-25 12:42:39.735744+02
507	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-23", "format": "pdf", "granularite": "jour"}	2026-08-25 12:47:13.527195+02
508	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "date": "2026-08-23", "format": "pdf", "granularite": "jour"}	2026-08-25 12:47:26.894486+02
509	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 22:06:21.409771+02
510	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-25 22:09:26.806791+02
543	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 00:00:37.337929+02
544	\N	INSCRIPTION_PUBLIQUE	utilisateurs	98240505-423c-4a4d-9118-f4e5fe0dce35	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.d50186@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 15:40:26.38797+02
545	\N	INSCRIPTION_PUBLIQUE	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"email": "mba@pnlf.ga", "type_demande": "ACHETEUR"}	2026-08-27 15:46:07.998908+02
546	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 15:46:20.885232+02
547	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 15:49:23.704381+02
548	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 15:50:52.335206+02
549	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 15:51:57.656852+02
550	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 15:52:23.293615+02
551	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 15:57:02.341763+02
552	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 16:00:01.379995+02
553	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-27 16:01:56.972246+02
554	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 16:05:53.564073+02
555	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 16:17:42.142343+02
556	\N	INSCRIPTION_PUBLIQUE	utilisateurs	96727eed-8f24-40ae-92bf-29469b0dde74	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.8a16a5@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 16:46:13.64033+02
557	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 16:46:45.293474+02
558	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-27 17:00:31.473859+02
559	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 17:02:57.417695+02
560	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 17:07:52.771484+02
561	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-27 17:09:43.990515+02
562	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 17:17:47.8647+02
563	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-08-27 17:18:28.274409+02
564	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 17:23:53.995556+02
565	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 17:28:02.354581+02
566	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 19:33:58.470848+02
567	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-08-27 19:35:46.117301+02
568	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 19:36:59.386694+02
569	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 19:38:16.10496+02
570	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 19:44:41.070708+02
571	2992fb5e-5580-483b-9462-98fe46cf7627	CREATE	utilisateurs	72bd473c-6010-4800-a9dd-2e3a247c2673	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "prod@pnlf.ga"}	2026-08-27 19:45:14.06995+02
572	72bd473c-6010-4800-a9dd-2e3a247c2673	LOGIN	utilisateurs	72bd473c-6010-4800-a9dd-2e3a247c2673	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "prod@pnlf.ga"}	2026-08-27 19:45:29.892301+02
573	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 19:46:20.396642+02
574	2992fb5e-5580-483b-9462-98fe46cf7627	CREATE	utilisateurs	363a526d-88d0-4dfc-931f-65ed184f8d14	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "prodcol@pnlf.ga"}	2026-08-27 19:46:58.932531+02
575	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 19:47:06.932089+02
576	363a526d-88d0-4dfc-931f-65ed184f8d14	LOGIN	utilisateurs	363a526d-88d0-4dfc-931f-65ed184f8d14	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "prodcol@pnlf.ga"}	2026-08-27 19:47:28.731722+02
577	\N	INSCRIPTION_PUBLIQUE	utilisateurs	e8326ec9-a630-4ed6-ad0d-4775f22f5343	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.461f8b@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 20:05:52.47178+02
578	\N	INSCRIPTION_PUBLIQUE	utilisateurs	e0dad95c-4ba9-4249-8a44-4cc78cd267db	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.64f02c@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 20:06:34.916083+02
580	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	LOGIN	utilisateurs	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ACHETEUR", "email": "mba@pnlf.ga"}	2026-08-27 20:09:35.388542+02
581	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 20:09:53.962457+02
582	72bd473c-6010-4800-a9dd-2e3a247c2673	LOGIN	utilisateurs	72bd473c-6010-4800-a9dd-2e3a247c2673	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "prod@pnlf.ga"}	2026-08-27 20:10:18.331998+02
583	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 20:10:53.222979+02
584	\N	INSCRIPTION_PUBLIQUE	utilisateurs	85e73743-f268-4751-b855-3b529e7d800b	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.5f8112@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-08-27 20:17:34.21232+02
585	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-08-27 20:26:10.766355+02
586	363a526d-88d0-4dfc-931f-65ed184f8d14	LOGIN	utilisateurs	363a526d-88d0-4dfc-931f-65ed184f8d14	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "prodcol@pnlf.ga"}	2026-09-06 20:08:31.030198+02
587	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-06 20:09:40.987597+02
588	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 12:51:03.492478+02
589	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 12:51:03.739188+02
590	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	ead7c0cb-3a14-4fd7-bfbd-386ee49f4191	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 12:51:03.919255+02
591	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 12:51:04.138835+02
592	\N	INSCRIPTION_PUBLIQUE	utilisateurs	f4287552-2689-4335-9fbc-ed2c03597d71	127.0.0.1	\N	\N	{"email": "chat.acheteur.insc.16483d@pnlf-test.local", "type_demande": "ACHETEUR"}	2026-09-21 13:00:04.441064+02
593	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:42:34.053151+02
594	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:42:34.448023+02
595	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	ead7c0cb-3a14-4fd7-bfbd-386ee49f4191	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:42:34.820727+02
596	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Python-urllib/3.14	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:42:35.158821+02
597	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 13:48:13.624227+02
598	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:48:51.444342+02
599	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:49:22.090241+02
600	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 13:54:20.674759+02
601	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:00:29.547315+02
602	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 14:00:32.250112+02
603	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:02:05.029042+02
604	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"via": "ticket", "format": "pdf"}	2026-09-21 14:02:08.095296+02
605	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:13:38.92446+02
606	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:13:48.849353+02
607	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:13:52.316212+02
608	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:15:12.548707+02
609	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:15:15.124073+02
610	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:15:43.810648+02
611	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:15:46.268599+02
612	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:16:18.826234+02
1238	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 18:09:57.072372+02
613	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:17:30.645838+02
614	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:17:32.964876+02
615	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:18:05.632373+02
616	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	98737ebe-a91f-4d04-9f3a-7a51f3fc4942	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:18:40.705309+02
617	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:19:41.543767+02
618	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:20:20.981309+02
619	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	ead7c0cb-3a14-4fd7-bfbd-386ee49f4191	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:20:24.114559+02
620	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:23:20.546718+02
621	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:24:20.8067+02
622	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:24:28.388884+02
623	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:25:45.253269+02
624	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:30:09.199653+02
625	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:36:32.914944+02
626	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:36:35.484044+02
627	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:37:09.899886+02
628	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:37:12.359918+02
629	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:37:46.874674+02
630	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:37:49.27986+02
631	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:38:24.222149+02
632	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:38:26.578457+02
633	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:38:37.218049+02
634	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:38:49.262418+02
635	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:39:01.94542+02
636	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:39:04.411746+02
637	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:40:45.530732+02
638	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:40:48.496002+02
639	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:41:27.45222+02
640	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:42:34.36024+02
641	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/3.18.9 Chrome/144.0.7559.236 Electron/40.10.3 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:44:23.368288+02
642	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/3.18.9 Chrome/144.0.7559.236 Electron/40.10.3 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:44:37.145045+02
643	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:45:39.556714+02
644	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:46:03.278317+02
645	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/3.18.9 Chrome/144.0.7559.236 Electron/40.10.3 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:46:17.052858+02
646	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:46:48.743594+02
647	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:47:26.967511+02
648	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:52:32.740412+02
649	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:54:57.327786+02
650	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:55:02.897768+02
651	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:55:11.67993+02
652	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:56:33.355228+02
653	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:56:45.246855+02
654	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:56:53.953791+02
655	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:57:03.135211+02
656	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 14:57:53.845445+02
657	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:57:56.130892+02
658	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 14:59:41.202525+02
659	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/3.18.9 Chrome/144.0.7559.236 Electron/40.10.3 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 15:52:34.363645+02
660	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 15:53:44.154082+02
661	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 15:53:54.010368+02
662	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	cooperatives	ead7c0cb-3a14-4fd7-bfbd-386ee49f4191	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 15:54:46.832582+02
663	ec38d815-0579-448c-b7dd-1c54b8dce005	LOGIN	utilisateurs	ec38d815-0579-448c-b7dd-1c54b8dce005	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "staeelbent16@gmail.com"}	2026-09-21 15:56:33.865676+02
664	ec38d815-0579-448c-b7dd-1c54b8dce005	EXPORT	producteurs	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-21 15:57:00.656646+02
665	ec38d815-0579-448c-b7dd-1c54b8dce005	CREATE	offres_demandes	b0350371-7264-4096-a2ba-03e7bcd9a384	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	\N	2026-09-21 15:58:49.871095+02
666	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-21 15:59:05.961296+02
667	\N	INSCRIPTION_PUBLIQUE	producteurs	c660c2be-c52d-4fa6-8273-0f754efc497f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"email": "prod2@outlook.com", "type_demande": "PRODUCTEUR"}	2026-09-23 11:19:23.219749+02
668	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 11:21:19.723658+02
669	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	c660c2be-c52d-4fa6-8273-0f754efc497f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-23 11:22:11.722914+02
670	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	producteurs	c660c2be-c52d-4fa6-8273-0f754efc497f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	\N	2026-09-23 11:22:52.380745+02
671	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 11:44:37.468681+02
672	2992fb5e-5580-483b-9462-98fe46cf7627	VALIDATE	offres_demandes	b0350371-7264-4096-a2ba-03e7bcd9a384	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	\N	2026-09-23 11:44:52.080844+02
673	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 11:45:22.491652+02
674	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"date": "2026-08-01", "format": "pdf", "granularite": "mois"}	2026-09-23 11:46:25.513721+02
1567	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:13:57.72157+02
675	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"q": null, "date": "2024-09-23", "action": null, "format": "pdf", "date_fin": "2026-09-23", "date_debut": "2024-09-23", "granularite": "jour", "utilisateur_id": "ec38d815-0579-448c-b7dd-1c54b8dce005"}	2026-09-23 12:07:12.216282+02
676	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	audit_logs	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"q": "systèm", "date": "2026-09-21", "action": null, "format": "pdf", "date_fin": null, "date_debut": null, "granularite": "jour", "utilisateur_id": null}	2026-09-23 12:12:56.612208+02
677	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 12:54:38.307175+02
678	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 13:28:28.532312+02
679	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-09-23 22:55:09.861756+02
680	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	lots	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-09-23 22:55:50.538244+02
1568	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:13:58.077091+02
1569	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:13:58.367252+02
1570	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:13:59.043445+02
1571	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:14:00.020126+02
1572	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:14:00.479802+02
1573	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:14:01.66635+02
1574	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:14:02.047221+02
1575	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:14:02.326692+02
1576	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:14:02.623858+02
1577	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:14:03.976796+02
1578	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:14:04.391332+02
2828	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:23:50.169173+02
2829	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:23:50.470158+02
1579	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:16:20.197732+02
1580	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:16:20.49663+02
1581	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:16:20.736044+02
1582	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:16:20.951026+02
1583	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:16:21.437788+02
1584	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:16:21.689842+02
1585	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:16:22.522045+02
1586	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:16:22.832874+02
1587	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:16:23.047844+02
1588	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:16:23.270526+02
1589	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:16:24.089536+02
1590	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:16:24.337854+02
2595	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:16:01.584596+02
2596	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:16:01.960867+02
2597	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:16:02.308323+02
2598	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:16:02.626396+02
2599	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:16:03.298607+02
2600	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:16:03.704968+02
2601	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:16:04.646364+02
2602	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:16:05.008282+02
2603	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:16:05.363475+02
2604	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:16:05.709453+02
2605	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:16:06.949369+02
2606	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:16:07.309211+02
1061	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:11:10.218351+02
1064	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:13:26.149841+02
1067	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 12:14:26.586915+02
1071	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:17:51.233579+02
1074	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 12:18:50.053394+02
1077	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:24:57.761449+02
1080	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 15:34:38.647226+02
1083	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 15:36:10.298932+02
1097	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 18:03:11.284022+02
1098	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 18:03:11.550157+02
1099	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 18:03:11.777011+02
1100	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 18:03:12.007387+02
967	70dd1a0a-1111-47f4-9a12-efd092fbc67a	CREATE	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 12:06:24.799502+02
968	70dd1a0a-1111-47f4-9a12-efd092fbc67a	CREATE	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 12:06:24.799502+02
969	70dd1a0a-1111-47f4-9a12-efd092fbc67a	CREATE	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 12:06:24.799502+02
970	70dd1a0a-1111-47f4-9a12-efd092fbc67a	CREATE	utilisateurs	baa3d8fc-73a1-4ea7-bea2-61addb73958c	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.suspendu@demo.pfnl.ga"}	2026-10-02 12:06:24.799502+02
971	70dd1a0a-1111-47f4-9a12-efd092fbc67a	CREATE	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 12:06:24.799502+02
972	\N	INSCRIPTION_PUBLIQUE	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"email": "producteur.miel@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
973	\N	INSCRIPTION_PUBLIQUE	producteurs	efddd969-6c0b-49f0-9204-5c846f4f7bba	127.0.0.1	\N	\N	{"email": "producteur.kola@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
974	\N	INSCRIPTION_PUBLIQUE	producteurs	32b71cac-11e7-4f9e-a7e9-b909b42a7154	127.0.0.1	\N	\N	{"email": "collecteur.ogooue@demo.pfnl.ga", "type_demande": "COLLECTEUR"}	2026-10-02 12:06:24.799502+02
975	\N	INSCRIPTION_PUBLIQUE	producteurs	34cc9c4d-801a-4e72-9ff8-2e673be01804	127.0.0.1	\N	\N	{"email": "producteur.independant@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
976	\N	INSCRIPTION_PUBLIQUE	producteurs	8d14134e-2de3-49e6-bc73-9e18699258a1	127.0.0.1	\N	\N	{"email": "producteur.inactif@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
977	\N	INSCRIPTION_PUBLIQUE	producteurs	5acc6d02-db6c-4886-80f7-2344e223ec3f	127.0.0.1	\N	\N	{"email": "producteur.rejete@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
978	\N	INSCRIPTION_PUBLIQUE	producteurs	47d0baea-0308-4618-ac9a-dcb5319e4d26	127.0.0.1	\N	\N	{"email": "collecteur.attente@demo.pfnl.ga", "type_demande": "COLLECTEUR"}	2026-10-02 12:06:24.799502+02
979	\N	INSCRIPTION_PUBLIQUE	producteurs	c6c3eee1-a671-4e21-8c35-b792af24efc6	127.0.0.1	\N	\N	{"email": "producteur.attente@demo.pfnl.ga", "type_demande": "PRODUCTEUR"}	2026-10-02 12:06:24.799502+02
980	\N	INSCRIPTION_PUBLIQUE	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"email": "coop.ivindo@demo.pfnl.ga", "type_demande": "COOPERATIVE"}	2026-10-02 12:06:24.799502+02
981	\N	INSCRIPTION_PUBLIQUE	cooperatives	e5326de4-90ed-4b3b-acab-5c847db8bf0a	127.0.0.1	\N	\N	{"email": "coop.ngounie@demo.pfnl.ga", "type_demande": "COOPERATIVE"}	2026-10-02 12:06:24.799502+02
982	\N	INSCRIPTION_PUBLIQUE	cooperatives	06b7bec2-85a3-4b42-9844-fc9a927efcf7	127.0.0.1	\N	\N	{"email": "coop.inactive@demo.pfnl.ga", "type_demande": "COOPERATIVE"}	2026-10-02 12:06:24.799502+02
983	\N	INSCRIPTION_PUBLIQUE	cooperatives	291e43ee-c88b-45a1-a5b1-b69e94b723af	127.0.0.1	\N	\N	{"email": "coop.rejetee@demo.pfnl.ga", "type_demande": "COOPERATIVE"}	2026-10-02 12:06:24.799502+02
984	\N	INSCRIPTION_PUBLIQUE	cooperatives	1b1aaec8-b1bc-4228-8b1b-278466538418	127.0.0.1	\N	\N	{"email": "coop.attente@demo.pfnl.ga", "type_demande": "COOPERATIVE"}	2026-10-02 12:06:24.799502+02
985	\N	INSCRIPTION_PUBLIQUE	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"email": "acheteur.export@demo.pfnl.ga", "type_demande": "ACHETEUR"}	2026-10-02 12:06:24.799502+02
986	\N	INSCRIPTION_PUBLIQUE	utilisateurs	1a7015dd-2f54-424e-9b92-620a4cedabaa	127.0.0.1	\N	\N	{"email": "acheteur.attente@demo.pfnl.ga", "type_demande": "ACHETEUR"}	2026-10-02 12:06:24.799502+02
987	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
988	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	efddd969-6c0b-49f0-9204-5c846f4f7bba	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
989	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	34cc9c4d-801a-4e72-9ff8-2e673be01804	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
990	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	8d14134e-2de3-49e6-bc73-9e18699258a1	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
991	96c362a7-7215-490a-8443-371d2768cd2e	VALIDATE	producteurs	32b71cac-11e7-4f9e-a7e9-b909b42a7154	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
992	70dd1a0a-1111-47f4-9a12-efd092fbc67a	REJECT	producteurs	5acc6d02-db6c-4886-80f7-2344e223ec3f	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
993	70dd1a0a-1111-47f4-9a12-efd092fbc67a	DEACTIVATE	producteurs	8d14134e-2de3-49e6-bc73-9e18699258a1	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
994	70dd1a0a-1111-47f4-9a12-efd092fbc67a	VALIDATE	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
995	70dd1a0a-1111-47f4-9a12-efd092fbc67a	VALIDATE	cooperatives	e5326de4-90ed-4b3b-acab-5c847db8bf0a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
996	70dd1a0a-1111-47f4-9a12-efd092fbc67a	VALIDATE	cooperatives	06b7bec2-85a3-4b42-9844-fc9a927efcf7	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
997	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	REJECT	cooperatives	291e43ee-c88b-45a1-a5b1-b69e94b723af	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
998	70dd1a0a-1111-47f4-9a12-efd092fbc67a	DEACTIVATE	cooperatives	06b7bec2-85a3-4b42-9844-fc9a927efcf7	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
999	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	zones_collecte	8b79f5b9-a549-4942-9069-93850ce5d12f	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1000	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	zones_collecte	cf91171c-fc2d-44d3-870b-5618fc796032	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1001	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	zones_collecte	12d53253-f473-41ef-82a8-04778bcff530	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1002	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	CREATE	zones_collecte	3fc8509c-9db1-4587-bbe5-0cb4914b418e	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1003	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	zones_collecte	ec28c59a-9434-4f66-b272-368859a8b7fd	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1004	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	producteurs	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	127.0.0.1	\N	\N	{"code_producteur": "DEMO-PRD-T01"}	2026-10-02 12:06:24.799502+02
1005	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	producteurs	b8515540-29f1-4ccc-97d5-a08be4e598af	127.0.0.1	\N	\N	{"code_producteur": "DEMO-PRD-T02"}	2026-10-02 12:06:24.799502+02
1006	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	producteurs	d085f4ac-9b58-447e-ab11-fbcc26bb5163	127.0.0.1	\N	\N	{"code_producteur": "DEMO-PRD-T03"}	2026-10-02 12:06:24.799502+02
1007	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	producteurs	ffd2f32f-0ed0-48ec-a502-f250ca779820	127.0.0.1	\N	\N	{"code_producteur": "DEMO-PRD-C01"}	2026-10-02 12:06:24.799502+02
1008	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1009	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	b8515540-29f1-4ccc-97d5-a08be4e598af	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1010	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	producteurs	ffd2f32f-0ed0-48ec-a502-f250ca779820	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1011	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	lots	fd945c4c-725a-4f72-af41-ff2d89df112d	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-EA6C9C8D5E"}	2026-10-02 12:06:24.799502+02
1012	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	lots	18e903a7-62a8-4f15-95ac-613f516a3013	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-2937F51224"}	2026-10-02 12:06:24.799502+02
1013	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	lots	9c409482-8669-4389-a5ef-5b1fad45e2f5	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-3667AA23F8"}	2026-10-02 12:06:24.799502+02
1014	b64ff13b-0617-456b-9589-257f95ae4fb7	CREATE	lots	2c9fe26c-95eb-4b84-80eb-93bc10b3d187	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-C99C0C5972"}	2026-10-02 12:06:24.799502+02
1015	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	lots	8242374c-f334-4e11-afd4-e5504950b786	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-DF1ADB827E"}	2026-10-02 12:06:24.799502+02
1016	97a54b08-c1ef-46eb-8505-1f31b5cadb80	CREATE	lots	a1aa93bc-20b7-457b-b07f-59c3b4655558	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-1E9B73FBE4"}	2026-10-02 12:06:24.799502+02
1017	5dfd8155-3222-4e05-9702-06e9cc47cca1	CREATE	lots	ff635715-df72-42e1-ada5-496a2f16d668	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-29EDFB74D1"}	2026-10-02 12:06:24.799502+02
1018	5dfd8155-3222-4e05-9702-06e9cc47cca1	CREATE	lots	b76576f5-5a0c-4adc-941d-8f5d584033e7	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-A04BB16BD3"}	2026-10-02 12:06:24.799502+02
1019	b64ff13b-0617-456b-9589-257f95ae4fb7	CREATE	lots	67381035-8c17-475b-a555-6a929aca6db1	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-05AB5441EC"}	2026-10-02 12:06:24.799502+02
1068	\N	LOGIN	utilisateurs	\N	127.0.0.1	\N	\N	{"role": null, "email": null}	2026-10-02 12:15:49.489916+02
1020	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	lots	134f6a3d-20da-4ae3-b853-002795421487	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-3B1D5EAEF3"}	2026-10-02 12:06:24.799502+02
1021	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	lots	eb80791e-3f0c-4ba9-a30b-c0176a9c2aec	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-5545324569"}	2026-10-02 12:06:24.799502+02
1022	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	lots	08480520-7787-45e4-afbd-db51aff36d80	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-7D25F17DDB"}	2026-10-02 12:06:24.799502+02
1023	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	lots	12b57849-fa7e-42ed-8fb7-cb5004a3ec2d	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-4C2F067A57"}	2026-10-02 12:06:24.799502+02
1024	97a54b08-c1ef-46eb-8505-1f31b5cadb80	CREATE	lots	f455fe71-7ef8-44e9-bdc8-e8a8d790e336	127.0.0.1	\N	\N	{"code_lot": "PNLF-20261002-124E2F8C82"}	2026-10-02 12:06:24.799502+02
1025	1f279d86-485b-4a3b-b0c5-3bfc813473b6	CREATE	mouvements	b6673d26-2356-4d59-97fc-ae83803bc1db	127.0.0.1	\N	\N	{"type_mouvement": "RECEPTION_COOPERATIVE"}	2026-10-02 12:06:24.799502+02
1026	1f279d86-485b-4a3b-b0c5-3bfc813473b6	CREATE	mouvements	43fa8e04-0f4f-4f63-b270-444fb30a06f9	127.0.0.1	\N	\N	{"type_mouvement": "TRANSFERT"}	2026-10-02 12:06:24.799502+02
1027	1f279d86-485b-4a3b-b0c5-3bfc813473b6	CREATE	mouvements	1acafd37-153f-42ec-b153-84c47bd81e8a	127.0.0.1	\N	\N	{"type_mouvement": "VENTE"}	2026-10-02 12:06:24.799502+02
1028	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	mouvements	165b994b-44f4-4afc-a27a-bbb9a87dbe6b	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-10-02 12:06:24.799502+02
1029	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	mouvements	8c57da53-d411-4560-be98-629e8c4b1503	127.0.0.1	\N	\N	{"type_mouvement": "RECEPTION_COOPERATIVE"}	2026-10-02 12:06:24.799502+02
1030	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	mouvements	d7d97573-5e23-4356-89be-6f5397873264	127.0.0.1	\N	\N	{"type_mouvement": "TRANSFORMATION"}	2026-10-02 12:06:24.799502+02
1031	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	mouvements	3f2e4511-041a-4bf2-bd7f-b9bfe01d86a5	127.0.0.1	\N	\N	{"type_mouvement": "TRANSFERT"}	2026-10-02 12:06:24.799502+02
1032	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	mouvements	60f3c543-c9eb-4475-a3d7-486c99be5934	127.0.0.1	\N	\N	{"type_mouvement": "EXPORT"}	2026-10-02 12:06:24.799502+02
1033	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	mouvements	633e7423-4f76-4f16-8b0d-caa0b88c410d	127.0.0.1	\N	\N	{"type_mouvement": "CONTROLE"}	2026-10-02 12:06:24.799502+02
1034	96c362a7-7215-490a-8443-371d2768cd2e	CREATE	mouvements	7b55de83-259e-4219-9da2-2dad02a67ca1	127.0.0.1	\N	\N	{"type_mouvement": "TRANSFERT"}	2026-10-02 12:06:24.799502+02
1035	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	mouvements	026709c9-b6c7-4a4a-8fb5-f92b8d1da10e	127.0.0.1	\N	\N	{"type_mouvement": "RECEPTION_COOPERATIVE"}	2026-10-02 12:06:24.799502+02
1036	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	CREATE	offres_demandes	2378a2d4-443f-450f-b63b-a63c6789c82a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1037	ec677a07-a583-40fd-9a61-370807755ac1	CREATE	offres_demandes	34d135f3-82bd-46fa-8817-c7a9bc40e62f	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1038	eaf22c78-d48d-431f-a7ae-660650279c0e	CREATE	offres_demandes	f8cbdbeb-f57c-497e-baa1-3610a8e939ee	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1039	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	CREATE	offres_demandes	d41cc54f-ed02-46d8-b259-2dc8ed763527	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1040	97a54b08-c1ef-46eb-8505-1f31b5cadb80	CREATE	offres_demandes	efd1c8b5-a4ee-4d50-af79-e5124c71a23a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1041	5dfd8155-3222-4e05-9702-06e9cc47cca1	CREATE	offres_demandes	1e5154fd-a8a7-4ca2-9e57-610654f1f521	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1042	b64ff13b-0617-456b-9589-257f95ae4fb7	CREATE	offres_demandes	ac5f5311-20f7-4b40-a159-52c28402e13f	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1043	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	offres_demandes	2378a2d4-443f-450f-b63b-a63c6789c82a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1044	70dd1a0a-1111-47f4-9a12-efd092fbc67a	VALIDATE	offres_demandes	34d135f3-82bd-46fa-8817-c7a9bc40e62f	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1045	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	VALIDATE	offres_demandes	f8cbdbeb-f57c-497e-baa1-3610a8e939ee	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1046	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	REJECT	offres_demandes	efd1c8b5-a4ee-4d50-af79-e5124c71a23a	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1047	70dd1a0a-1111-47f4-9a12-efd092fbc67a	VALIDATE	offres_demandes	1e5154fd-a8a7-4ca2-9e57-610654f1f521	127.0.0.1	\N	\N	\N	2026-10-02 12:06:24.799502+02
1048	5dfd8155-3222-4e05-9702-06e9cc47cca1	UPDATE	offres_demandes	1e5154fd-a8a7-4ca2-9e57-610654f1f521	127.0.0.1	\N	\N	{"statut": "CLOTUREE"}	2026-10-02 12:06:24.799502+02
1062	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:11:24.233261+02
1065	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:13:39.956846+02
1069	\N	LOGIN	utilisateurs	\N	127.0.0.1	\N	\N	{"role": null, "email": null}	2026-10-02 12:16:04.698215+02
1072	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:18:03.986882+02
1075	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:21:41.753874+02
1078	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 12:25:14.40354+02
1081	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 15:34:58.105634+02
1084	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	Python-urllib/3.14	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 15:38:06.564635+02
1101	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 18:03:12.231177+02
1102	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 18:03:12.465859+02
1103	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 18:03:12.694576+02
1104	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 18:03:12.960374+02
1105	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 18:03:13.240925+02
1106	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 18:03:13.540762+02
1107	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 18:03:13.815607+02
1108	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 18:03:14.118367+02
1109	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 18:03:16.553438+02
3626	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:39:19.158726+02
1049	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:07:39.158216+02
1050	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 12:07:39.529504+02
1051	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 12:07:39.841575+02
1052	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 12:07:40.155559+02
1053	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 12:07:40.922909+02
1054	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 12:07:41.409548+02
1055	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:07:42.59143+02
1056	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 12:07:42.973255+02
1057	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 12:07:43.347942+02
1058	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 12:07:43.704361+02
1059	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 12:07:44.899301+02
1060	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 12:07:45.234825+02
1063	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 12:11:38.111588+02
1066	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 12:13:53.537106+02
1070	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 12:16:52.096663+02
1073	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 12:18:17.217581+02
1076	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 12:24:42.856645+02
1079	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 12:25:48.302101+02
1082	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/151.0.7922.34 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 15:35:18.063946+02
1085	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 15:38:22.350825+02
1086	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 15:38:22.700003+02
1087	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 15:38:22.958877+02
1088	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 15:38:23.258415+02
1089	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 15:38:23.976911+02
1090	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 15:38:24.404295+02
1091	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 15:38:25.387586+02
1092	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 15:38:25.757291+02
1093	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 15:38:26.16241+02
1094	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 15:38:26.434362+02
1095	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 15:38:27.333191+02
1096	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 15:38:27.584805+02
3638	2992fb5e-5580-483b-9462-98fe46cf7627	EXPORT	producteurs	5acc6d02-db6c-4886-80f7-2344e223ec3f	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36	\N	{"format": "pdf"}	2026-10-03 14:51:11.865102+02
1112	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 18:03:36.009674+02
3627	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:40:12.259219+02
3878	1051c839-763f-4a10-9f0e-7b64d301a393	EXPORT	rapport_inscriptions	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"format": "pdf", "filtres": {"q": "MOUNGUENGUI", "date_fin": "2026-10-06", "date_debut": "2026-09-07"}}	2026-10-06 12:57:03.032948+02
3628	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:41:07.755393+02
1413	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 18:50:06.853381+02
1414	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 18:50:07.119601+02
1415	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 18:50:07.353459+02
1416	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 18:50:07.572417+02
1417	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 18:50:08.00602+02
1418	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 18:50:08.239671+02
1419	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 18:50:08.958129+02
1420	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 18:50:09.248193+02
1421	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 18:50:09.556359+02
1422	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 18:50:09.972043+02
1423	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 18:50:11.386805+02
1424	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 18:50:11.739621+02
3629	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:41:54.830916+02
2224	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:03:11.026427+02
2225	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:03:11.33449+02
2226	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:03:11.581348+02
2227	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:03:11.815818+02
2228	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:03:12.265889+02
1714	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:18:08.987354+02
1715	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:18:09.250333+02
1716	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:18:09.500733+02
1717	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:18:09.719699+02
1718	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:18:10.166318+02
1719	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:18:10.420326+02
1720	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:18:11.058676+02
1721	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:18:11.275397+02
1722	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:18:11.49807+02
1723	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:18:11.744512+02
1442	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 18:51:47.97074+02
1443	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 18:51:48.242227+02
1444	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 18:51:48.494247+02
1445	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 18:51:48.738156+02
1446	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 18:51:49.191948+02
1447	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 18:51:49.437884+02
1448	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 18:51:50.200126+02
1449	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 18:51:50.479625+02
1450	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 18:51:50.893567+02
1451	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 18:51:51.244157+02
1452	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 18:51:52.329622+02
1453	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 18:51:52.619184+02
1724	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:18:12.877368+02
1725	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:18:13.293239+02
2229	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:03:12.533992+02
2230	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:03:13.205451+02
2231	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:03:13.450506+02
2232	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:03:13.677911+02
2233	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:03:13.905608+02
2234	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:03:14.79621+02
2235	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:03:15.046984+02
3630	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:42:37.793927+02
1772	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:19:51.826381+02
1773	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:19:52.139175+02
1774	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:19:52.398248+02
1775	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:19:52.611641+02
1776	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:19:53.054123+02
1777	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:19:53.304331+02
1778	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:19:54.148799+02
1779	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:19:54.525525+02
1780	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:19:54.805802+02
1781	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:19:55.02448+02
1782	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:19:55.870311+02
1783	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:19:56.158711+02
1784	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:20:13.244374+02
1785	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:20:13.508541+02
1786	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:20:13.827471+02
1787	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:20:14.150147+02
1788	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:20:14.669973+02
1789	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:20:14.907857+02
1790	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:20:15.779989+02
1791	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:20:16.084047+02
1792	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:20:16.414082+02
1793	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:20:16.701574+02
1794	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:20:17.760069+02
1795	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:20:18.077376+02
1796	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:21:45.271681+02
1797	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:21:45.540469+02
1798	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:21:45.771834+02
1799	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:21:46.029699+02
1800	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:21:46.80301+02
1801	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-02 19:21:47.288296+02
1802	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:21:48.269429+02
1803	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-02 19:21:48.502881+02
1804	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:21:48.736152+02
1805	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-02 19:21:48.970365+02
1806	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-02 19:21:49.816302+02
1807	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:21:50.056339+02
1808	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:26:04.231333+02
1809	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:26:50.186015+02
1810	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:27:32.102497+02
1811	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:28:13.397045+02
1812	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:28:54.792054+02
1813	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:29:23.00475+02
1814	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:31:06.094363+02
1815	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:33:19.411421+02
1816	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 19:34:54.741738+02
1817	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-02 19:35:44.046728+02
1818	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-02 19:36:33.738999+02
1819	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 19:37:19.609773+02
1820	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 19:38:00.623148+02
1821	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-02 19:38:43.100518+02
1822	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 19:39:24.960364+02
1823	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-02 19:39:53.366882+02
1824	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-02 20:10:47.698714+02
1825	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 20:11:28.734081+02
1826	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-02 20:15:22.712592+02
1827	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-02 20:15:57.822443+02
1828	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-02 20:16:27.363348+02
3631	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:43:19.549001+02
1835	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 13:52:37.316128+02
1836	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 13:52:37.726575+02
1837	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 13:52:38.312791+02
1838	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 13:52:38.621473+02
1839	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 13:52:39.299138+02
1840	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 13:52:39.707484+02
1841	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 13:52:40.576461+02
1842	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 13:52:40.956886+02
1843	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 13:52:41.315263+02
1844	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 13:52:41.612272+02
1845	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 13:52:42.831949+02
1846	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 13:52:43.131542+02
1847	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 13:52:57.855637+02
1848	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 13:58:51.641682+02
1849	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:52.2126+02
1850	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:52.448661+02
1851	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	producteurs	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:52.557772+02
1852	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	cooperatives	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:52.640697+02
1853	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 13:58:52.902887+02
1854	96c362a7-7215-490a-8443-371d2768cd2e	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:53.028239+02
1855	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 13:58:53.437855+02
1856	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:53.658526+02
1857	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	producteurs	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:53.790135+02
1858	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	cooperatives	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:53.861089+02
1859	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 13:58:54.237541+02
1860	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:58:54.486273+02
1861	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 13:58:54.884086+02
1862	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 13:58:55.159657+02
1863	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 13:59:51.391106+02
1864	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:51.828724+02
1865	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:52.166735+02
1866	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	producteurs	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:52.3381+02
1867	70dd1a0a-1111-47f4-9a12-efd092fbc67a	EXPORT	cooperatives	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:52.464451+02
1868	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 13:59:52.862087+02
1869	96c362a7-7215-490a-8443-371d2768cd2e	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:53.180576+02
1870	96c362a7-7215-490a-8443-371d2768cd2e	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:53.796159+02
1871	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 13:59:54.719749+02
1872	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:54.919064+02
1873	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	producteurs	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:55.133181+02
1874	ec677a07-a583-40fd-9a61-370807755ac1	EXPORT	cooperatives	\N	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:55.396297+02
1875	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 13:59:56.037948+02
1876	1f279d86-485b-4a3b-b0c5-3bfc813473b6	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:56.200727+02
1877	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 13:59:56.543549+02
1878	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:56.703093+02
1879	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:56.917293+02
1880	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 13:59:57.333862+02
1881	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	EXPORT	producteurs	ad0c1500-c241-4d87-90c6-ac3ec914f53a	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:57.478857+02
1882	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:57.749425+02
1883	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 13:59:58.121654+02
1884	b64ff13b-0617-456b-9589-257f95ae4fb7	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:58.290057+02
1885	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 13:59:58.667165+02
1886	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	EXPORT	cooperatives	17c571aa-c973-4da4-abe2-59fc08b7ded2	127.0.0.1	\N	\N	{"format": "pdf"}	2026-10-03 13:59:58.846665+02
3632	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:44:01.795668+02
3633	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:44:29.723603+02
2824	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:23:48.862458+02
2502	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:13:48.907799+02
2503	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:13:49.424+02
2504	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:13:49.921238+02
2505	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:13:50.464103+02
2506	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:13:51.351817+02
2507	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:13:51.887103+02
2508	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:13:53.287127+02
2509	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:13:53.813998+02
2510	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:13:54.294334+02
2511	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:13:54.741644+02
2512	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:13:56.461191+02
2513	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:13:56.943312+02
3634	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:44:57.96694+02
2825	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:23:49.192496+02
3479	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:30:01.137084+02
3480	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:30:01.591912+02
3481	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:30:01.952879+02
3482	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:30:02.296881+02
3483	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:30:03.008889+02
3484	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:30:03.409949+02
3485	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:30:04.43264+02
3486	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:30:04.782745+02
3487	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:30:05.134276+02
3488	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:30:05.492074+02
3489	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:30:06.920803+02
3490	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:30:07.314746+02
3635	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:45:15.981297+02
3746	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 16:48:37.074146+02
3747	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 16:48:37.547607+02
3748	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 16:48:38.00549+02
3749	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 16:48:38.615751+02
3750	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 16:48:39.533333+02
3751	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 16:48:39.999591+02
3752	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 16:48:41.225215+02
3753	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 16:48:41.632335+02
3754	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 16:48:42.040171+02
3755	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 16:48:42.415358+02
3756	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 16:48:43.924577+02
3757	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 16:48:44.352894+02
2826	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:23:49.455836+02
2827	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:23:49.695676+02
2830	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:23:51.285167+02
2831	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:23:51.840447+02
2832	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:23:52.384419+02
2833	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:23:52.923797+02
2834	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:23:54.130972+02
2835	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:23:54.628067+02
3491	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	\N	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:33:15.634178+02
3492	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	LOGIN	utilisateurs	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.demo@demo.pfnl.ga"}	2026-10-03 14:33:16.786059+02
3493	f2d88f9a-597f-4c0f-88a8-13e670a28a58	LOGIN	utilisateurs	f2d88f9a-597f-4c0f-88a8-13e670a28a58	127.0.0.1	\N	\N	{"role": "AGENT_MINISTERE", "email": "ministere.nouveau@demo.pfnl.ga"}	2026-10-03 14:33:17.796624+02
3494	96c362a7-7215-490a-8443-371d2768cd2e	LOGIN	utilisateurs	96c362a7-7215-490a-8443-371d2768cd2e	127.0.0.1	\N	\N	{"role": "AGENT_FORESTIER", "email": "forestier.demo@demo.pfnl.ga"}	2026-10-03 14:33:18.59071+02
3495	ec677a07-a583-40fd-9a61-370807755ac1	LOGIN	utilisateurs	ec677a07-a583-40fd-9a61-370807755ac1	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ivindo@demo.pfnl.ga"}	2026-10-03 14:33:20.23148+02
3496	1f279d86-485b-4a3b-b0c5-3bfc813473b6	LOGIN	utilisateurs	1f279d86-485b-4a3b-b0c5-3bfc813473b6	127.0.0.1	\N	\N	{"role": "COOPERATIVE", "email": "coop.ngounie@demo.pfnl.ga"}	2026-10-03 14:33:21.225103+02
3497	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	LOGIN	utilisateurs	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.miel@demo.pfnl.ga"}	2026-10-03 14:33:23.346159+02
3498	b64ff13b-0617-456b-9589-257f95ae4fb7	LOGIN	utilisateurs	b64ff13b-0617-456b-9589-257f95ae4fb7	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.kola@demo.pfnl.ga"}	2026-10-03 14:33:23.982021+02
3499	97a54b08-c1ef-46eb-8505-1f31b5cadb80	LOGIN	utilisateurs	97a54b08-c1ef-46eb-8505-1f31b5cadb80	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "collecteur.ogooue@demo.pfnl.ga"}	2026-10-03 14:33:24.688278+02
3500	5dfd8155-3222-4e05-9702-06e9cc47cca1	LOGIN	utilisateurs	5dfd8155-3222-4e05-9702-06e9cc47cca1	127.0.0.1	\N	\N	{"role": "PRODUCTEUR", "email": "producteur.independant@demo.pfnl.ga"}	2026-10-03 14:33:25.411206+02
3501	eaf22c78-d48d-431f-a7ae-660650279c0e	LOGIN	utilisateurs	eaf22c78-d48d-431f-a7ae-660650279c0e	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.export@demo.pfnl.ga"}	2026-10-03 14:33:27.929431+02
3502	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	LOGIN	utilisateurs	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	127.0.0.1	\N	\N	{"role": "ACHETEUR", "email": "acheteur.local@demo.pfnl.ga"}	2026-10-03 14:33:28.602035+02
3636	70dd1a0a-1111-47f4-9a12-efd092fbc67a	LOGIN	utilisateurs	70dd1a0a-1111-47f4-9a12-efd092fbc67a	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin.demo@demo.pfnl.ga"}	2026-10-03 14:46:31.806609+02
3883	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-10-06 13:57:23.75482+02
3637	2992fb5e-5580-483b-9462-98fe46cf7627	LOGIN	utilisateurs	2992fb5e-5580-483b-9462-98fe46cf7627	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36	\N	{"role": "ADMINISTRATEUR", "email": "admin@pnlf.ga"}	2026-10-03 14:46:39.527548+02
3877	1051c839-763f-4a10-9f0e-7b64d301a393	EXPORT	rapport_dernieres_connexions	\N	127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36	\N	{"format": "pdf", "filtres": {"date_fin": "2026-10-06", "date_debut": "2026-09-07"}}	2026-10-06 12:56:52.510411+02
\.


--
-- TOC entry 6955 (class 0 OID 69557)
-- Dependencies: 240
-- Data for Name: categories_produit; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.categories_produit (id, code, libelle, description, parent_id, actif, created_at, updated_at) FROM stdin;
e4e07e44-216b-456b-90b8-2845de865057	MIEL	Miels et produits de la ruche	Miel sauvage et dérivés	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
943a01d8-e052-415b-ad56-ac9be3c5cc42	NOIX	Noix et graines	Moabi et autres noix forestières	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
13f789df-f0c4-4fb0-975a-cd0b0c4c657b	PLANTES	Plantes médicinales et aromatiques	\N	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
6d59205c-75c6-449b-b8d5-c0a5d894ff61	ECORCES	Écorces	Usages pharmacologiques ou artisanaux	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
ca039312-f99b-420c-ad60-15f78eae03f1	FRUITS	Fruits sauvages	Mangue sauvage, safou, etc.	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
4148fb8a-9bdb-4359-b5bc-ea49c9234009	CHAMP	Champignons	Champignons comestibles	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
b4fdb694-b4e2-485a-8037-2f3c9792062b	ROTIN	Rotin et bambou	\N	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
f87fb134-0856-47c3-9b2d-35f0b9fe2837	FAUNE	Produits issus de la faune (CITES)	Conformément à la réglementation	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
153d9f97-d3bc-4daf-ac7b-55bc6cef22a3	AUTRE	Autres PFNL	Catégorie extensible	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
\.


--
-- TOC entry 6962 (class 0 OID 69812)
-- Dependencies: 247
-- Data for Name: certifications; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.certifications (id, type_certification_id, lot_id, producteur_id, numero_certificat, statut, date_demande, date_obtention, date_expiration, document_path, valide_par, observations, created_at, updated_at) FROM stdin;
81a5865b-0ca0-45e3-9325-a67bad9bcacb	dc77ac1e-27ba-4f83-b809-203f34d35933	134f6a3d-20da-4ae3-b853-002795421487	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	CITES-GA-2026-0007	OBTENUE	2026-10-02	2026-10-02	2027-03-31	\N	70dd1a0a-1111-47f4-9a12-efd092fbc67a	Iboga : permis requis avant toute commercialisation.	2026-10-02 12:06:38.443536+02	2026-10-02 12:06:24.799502+02
be87efb2-8b8f-4cbf-b858-45cf10d0e5fc	e5a74b63-1870-45b3-bdcf-45e4d5ecc763	\N	ad0c1500-c241-4d87-90c6-ac3ec914f53a	QUA-GA-2025-0031	EXPIREE	2025-07-29	2025-08-08	2026-08-08	\N	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Certificat arrivé à échéance : renouvellement à demander.	2026-10-02 12:06:39.90463+02	2026-10-02 12:06:24.799502+02
3cbabc4e-c544-4942-872d-a9fa2822542c	d167f4d2-337e-4752-b78a-e6ab3d31a4d5	\N	ad0c1500-c241-4d87-90c6-ac3ec914f53a	BIO-GA-2026-0142	OBTENUE	2026-10-02	2026-10-02	2027-10-02	\N	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Ruchers situés hors zone agricole.	2026-10-02 12:06:38.155516+02	2026-10-02 12:06:24.799502+02
50b68b86-54b3-4bb8-97b0-79007e7d1e9d	d397d40b-41f3-4b13-829f-ed968f38e24a	\N	efddd969-6c0b-49f0-9204-5c846f4f7bba	\N	DEMANDEE	2026-10-02	\N	\N	\N	\N	Demande d’indication d’origine « Kola de l’Ivindo ».	2026-10-02 12:06:38.250887+02	2026-10-02 12:06:38.250887+02
40a89d43-9245-4210-be6f-60f284d22e62	e5a74b63-1870-45b3-bdcf-45e4d5ecc763	\N	32b71cac-11e7-4f9e-a7e9-b909b42a7154	\N	EN_COURS	2026-10-02	\N	\N	\N	\N	Demande portée par la coopérative. Instruction en cours : visite terrain programmée.	2026-10-02 12:06:38.307706+02	2026-10-02 12:06:24.799502+02
dd3f8911-1d43-4113-a79d-a2d9a34e2a69	d167f4d2-337e-4752-b78a-e6ab3d31a4d5	\N	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	REFUSEE	2026-10-02	\N	\N	\N	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Refus : Plan de gestion durable de la ressource non fourni.	2026-10-02 12:06:38.356892+02	2026-10-02 12:06:24.799502+02
\.


--
-- TOC entry 6965 (class 0 OID 69910)
-- Dependencies: 250
-- Data for Name: conversation_participants; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.conversation_participants (conversation_id, utilisateur_id, joined_at) FROM stdin;
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	2992fb5e-5580-483b-9462-98fe46cf7627	2026-10-03 14:52:33.55394+02
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	5dfd8155-3222-4e05-9702-06e9cc47cca1	2026-10-03 14:52:33.55394+02
11a76a97-5e8f-4eb4-9500-c4fcee8fd636	eaf22c78-d48d-431f-a7ae-660650279c0e	2026-10-02 12:06:44.667776+02
11a76a97-5e8f-4eb4-9500-c4fcee8fd636	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	2026-10-02 12:06:44.667776+02
15453ebc-6eba-4ada-90cf-8817007331b8	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	2026-10-02 12:06:45.271912+02
15453ebc-6eba-4ada-90cf-8817007331b8	ec677a07-a583-40fd-9a61-370807755ac1	2026-10-02 12:06:45.271912+02
6aec5643-73f5-4767-9cd0-a7d990a50152	eaf22c78-d48d-431f-a7ae-660650279c0e	2026-10-02 12:06:45.525426+02
6aec5643-73f5-4767-9cd0-a7d990a50152	b64ff13b-0617-456b-9589-257f95ae4fb7	2026-10-02 12:06:45.525426+02
75cc426b-35bf-4b82-bf2a-582c16e92e93	ec677a07-a583-40fd-9a61-370807755ac1	2026-10-02 12:06:45.734946+02
75cc426b-35bf-4b82-bf2a-582c16e92e93	97a54b08-c1ef-46eb-8505-1f31b5cadb80	2026-10-02 12:06:45.734946+02
75cc426b-35bf-4b82-bf2a-582c16e92e93	b64ff13b-0617-456b-9589-257f95ae4fb7	2026-10-02 12:06:45.734946+02
732a763f-ae05-499c-834f-5f785d39f339	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:46.151181+02
732a763f-ae05-499c-834f-5f785d39f339	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	2026-10-02 12:06:46.151181+02
840b065a-bd81-4aaf-b799-da196446caf3	96c362a7-7215-490a-8443-371d2768cd2e	2026-10-02 12:06:46.479876+02
840b065a-bd81-4aaf-b799-da196446caf3	1f279d86-485b-4a3b-b0c5-3bfc813473b6	2026-10-02 12:06:46.479876+02
\.


--
-- TOC entry 6964 (class 0 OID 69896)
-- Dependencies: 249
-- Data for Name: conversations; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.conversations (id, sujet, offre_id, created_at) FROM stdin;
11a76a97-5e8f-4eb4-9500-c4fcee8fd636	Miel sauvage de la Ngounié, 100 kg disponibles	2378a2d4-443f-450f-b63b-a63c6789c82a	2026-10-02 12:06:44.667776+02
15453ebc-6eba-4ada-90cf-8817007331b8	Discussion avec Coopérative des Saveurs de l’Ivindo	\N	2026-10-02 12:06:45.271912+02
6aec5643-73f5-4767-9cd0-a7d990a50152	Discussion avec Marie-Claire MOUSSAVOU	\N	2026-10-02 12:06:45.525426+02
75cc426b-35bf-4b82-bf2a-582c16e92e93	Groupe des membres, Saveurs de l’Ivindo	\N	2026-10-02 12:06:45.734946+02
732a763f-ae05-499c-834f-5f785d39f339	Discussion avec Jean-Baptiste NDONG	\N	2026-10-02 12:06:46.151181+02
840b065a-bd81-4aaf-b799-da196446caf3	Discussion avec Coopérative Coopérative Miel et Forêt de la Ngounié	\N	2026-10-02 12:06:46.479876+02
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	Discussion avec Sylvie MBOUMBA	\N	2026-10-03 14:52:33.55394+02
\.


--
-- TOC entry 6954 (class 0 OID 69534)
-- Dependencies: 239
-- Data for Name: cooperative_membres; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.cooperative_membres (cooperative_id, producteur_id, date_adhesion, actif, created_at) FROM stdin;
17c571aa-c973-4da4-abe2-59fc08b7ded2	efddd969-6c0b-49f0-9204-5c846f4f7bba	2026-03-06	t	2026-10-02 12:06:36.342641+02
17c571aa-c973-4da4-abe2-59fc08b7ded2	32b71cac-11e7-4f9e-a7e9-b909b42a7154	2026-05-05	t	2026-10-02 12:06:36.372979+02
17c571aa-c973-4da4-abe2-59fc08b7ded2	ffd2f32f-0ed0-48ec-a502-f250ca779820	2026-07-04	t	2026-10-02 12:06:36.398865+02
e5326de4-90ed-4b3b-acab-5c847db8bf0a	ad0c1500-c241-4d87-90c6-ac3ec914f53a	2025-08-28	t	2026-10-02 12:06:36.423993+02
\.


--
-- TOC entry 6952 (class 0 OID 69424)
-- Dependencies: 237
-- Data for Name: cooperatives; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.cooperatives (id, code, nom, numero_agrement, telephone, email, adresse, province_id, departement_id, village_id, latitude, longitude, geom, utilisateur_id, actif, created_at, updated_at, statut) FROM stdin;
1b1aaec8-b1bc-4228-8b1b-278466538418	COOP-1B1AAEC8	Coopérative des Femmes Productrices du Woleu-Ntem	AGR-WOL-2026-002	+241077000305	coop.attente@demo.pfnl.ga	Bitam, quartier Mbéba	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	\N	\N	\N	\N	\N	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	f	2026-10-02 12:06:33.665253+02	2026-10-02 12:06:33.665253+02	EN_VALIDATION
17c571aa-c973-4da4-abe2-59fc08b7ded2	COOP-17C571AA	Coopérative des Saveurs de l’Ivindo	AGR-OGO-2024-017	+241077000301	coop.ivindo@demo.pfnl.ga	Quartier Zoatab, Makokou	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	\N	\N	\N	\N	\N	ec677a07-a583-40fd-9a61-370807755ac1	t	2026-10-02 12:06:30.204846+02	2026-10-02 12:06:24.799502+02	ACTIF
e5326de4-90ed-4b3b-acab-5c847db8bf0a	COOP-E5326DE4	Coopérative Miel et Forêt de la Ngounié	AGR-NGO-2023-009	+241077000302	coop.ngounie@demo.pfnl.ga	Route de Fougamou, Mouila	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	\N	\N	\N	\N	\N	1f279d86-485b-4a3b-b0c5-3bfc813473b6	t	2026-10-02 12:06:30.908028+02	2026-10-02 12:06:24.799502+02	ACTIF
291e43ee-c88b-45a1-a5b1-b69e94b723af	COOP-291E43EE	Groupement des Cueilleurs de Port-Gentil [REJETÉ 20261002100635]	\N	+241077000304	coop.rejetee@demo.pfnl.ga	Port-Gentil, quartier Balise	5bac0569-7d48-4e2d-bcd3-d2701bb6f3fe	\N	\N	\N	\N	\N	\N	f	2026-10-02 12:06:32.723715+02	2026-10-02 12:06:24.799502+02	REJETE
06b7bec2-85a3-4b42-9844-fc9a927efcf7	COOP-06B7BEC2	Coopérative Rotin et Raphia de l’Estuaire	AGR-EST-2022-004	+241077000303	coop.inactive@demo.pfnl.ga	Kango centre	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	b894dc88-5275-4bba-9feb-13a700171cf3	f	2026-10-02 12:06:31.753698+02	2026-10-02 12:06:24.799502+02	INACTIF
\.


--
-- TOC entry 6947 (class 0 OID 69289)
-- Dependencies: 232
-- Data for Name: departements; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.departements (id, province_id, code, nom, geom, actif, created_at, updated_at) FROM stdin;
cf38827b-8288-4146-a599-bba708382b1d	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	GAB001001	Komo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
7bb72885-b409-4a09-a0e3-de885874e010	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	GAB001002	Komo-Mondah	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
06d2e9f5-8615-422f-ba7a-54af8047c7f5	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	GAB001003	Noya	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
8e640ef4-cc64-4b9d-ad40-29c7506bc205	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	GAB001004	Libreville	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
e0b34d63-b611-498d-b75e-e714d54a677f	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002001	Djoué	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
1699b7ec-f36d-411a-a50c-07bf3509eceb	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002002	Djouori-Agnili	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
e5e965fc-819a-483d-a6a9-b455a2344f57	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002003	Lébombi-Léyou	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
6c7cba9f-402f-4826-96d6-201102f0a723	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002004	Lékabi-Léwolo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
9dd6b61b-bd21-4ef1-b6ee-8b1edacf4283	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002005	Lékoko	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
5e81b436-7183-4b2d-8b09-b7eaf2ddfc94	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002006	Lékoni-Lékori	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
cc3d5e68-9614-4d21-bb36-b3c36612b37b	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002007	Ogooué-Létili	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
8d665c3a-0905-4d3e-b6ac-518abd7e3048	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002008	Mpassa	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
5f6aa474-01a7-4631-b516-e8fcd3d6f154	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002009	Plateaux	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
8c6cac3a-f9ae-4db2-974c-bf12613a5cd3	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002010	Sébé-Brikolo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d595baea-82f0-4e05-a141-f650a012ee28	cb1698dc-1a3a-4f23-ae61-0672d2e579db	GAB002011	Bayi-Brikolo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
3e7fe5b2-697f-44d4-80a0-0ff2ebd195b7	395a5ce3-066b-4a05-a931-fc5848038cde	GAB003001	Abanga-Bigné	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
083ec496-43bc-4b74-8514-e63b86559ca1	395a5ce3-066b-4a05-a931-fc5848038cde	GAB003002	Ogooué et des Lacs	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d13daecd-deef-44a6-ba6a-7bdfe8ac3ac2	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004001	Boumi-Louetsi	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
118a620f-fb2d-4613-8333-c7dec4c0a80f	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004002	Dola	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
56943c85-7c1c-47f9-a595-38dbe982e3bc	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004003	Douya-Onoye	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
faaa99cc-dcfc-4acb-bc0f-f92973ff91c1	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004004	Louetsi-Bibaka	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
f844caac-39e7-492c-a9ed-982e341a34be	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004005	Louetsi-Wano	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
4da04750-0971-42b5-821f-6afbe8e0f4fa	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004006	Ndolou	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
02c616fa-e4a3-4f68-b3b3-de992c98a42a	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004007	Ogoulou	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
13de8477-071b-4375-9aec-b8f14f351ce1	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004008	Tsamba-Magotsi	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
366aa27f-7e8a-412b-985a-b999d7c03b18	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	GAB004009	Mougalaba	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0967f0c8-f287-4f32-abf3-7856e34dc2a3	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005001	Basse-Banio	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
5bd885ef-a736-45e6-b566-c2ed9f2ee1d2	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005002	Douigny	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
8c56dc91-ef41-4222-8111-f85a3227b700	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005003	Doutsila	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
b3ac6e70-4401-4770-9cc1-7f11087eb36d	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005004	Haute-Banio	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0e039faf-0a05-4d7c-9fe2-df6f483a00f3	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005005	Mougoutsi	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
5d266a70-f635-4447-bf48-40539a88d97b	86a5e90b-c713-4ccc-affe-2480b77fbbf0	GAB005006	Mongo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
e4d7dea5-9056-4c46-b905-74aae292e4dd	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	GAB006001	Ivindo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d96eb2c5-ec95-4691-82c0-bfa19680f78f	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	GAB006002	Lopé	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
214d5429-953b-4600-b136-15793bbdf6ab	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	GAB006003	Mvoung	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
c58572ba-7298-408e-b523-ee2be28bce45	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	GAB006004	Zadié	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
3a51074b-871e-495f-a135-1d7028b67916	b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	GAB007001	Lolo-Bouenguidi	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0bcf799b-fe5e-4538-8c03-d0f97ea126ad	b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	GAB007002	Lombo-Bouenguidi	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
856fbac1-89d6-481b-a874-6ef4b66dbd5f	b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	GAB007003	Mulundu	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
dbdafef5-6aca-4088-8cfe-92fd3a663009	b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	GAB007004	Offoué-Onoye	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
2f28fef3-c55d-4d24-a86f-5c4bb85a9f71	5bac0569-7d48-4e2d-bcd3-d2701bb6f3fe	GAB008001	Bendjé	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
2e2e99be-9b7e-4894-8026-380f526c98d4	5bac0569-7d48-4e2d-bcd3-d2701bb6f3fe	GAB008002	Etimboué	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
a13613de-fe11-479c-8bf7-4842009652cf	5bac0569-7d48-4e2d-bcd3-d2701bb6f3fe	GAB008003	Ndougou	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
f4bae033-8914-4808-baca-cd59c094bd6f	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	GAB009001	Haut-Komo	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
bb465088-18fe-4a45-a826-127be2ebd83e	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	GAB009002	Haut-Ntem	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
816670eb-a0e7-40f7-a413-4ebe534c31ec	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	GAB009003	Ntem	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0549ba65-547a-4f79-b451-06c48f9bffe4	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	GAB009004	Okano	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
adb16100-f503-4a39-8e41-27732f8dddd5	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	GAB009005	Woleu	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
\.


--
-- TOC entry 6959 (class 0 OID 69666)
-- Dependencies: 244
-- Data for Name: lots; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.lots (id, code_lot, uuid_public, produit_id, producteur_id, cooperative_id, zone_collecte_id, date_collecte, quantite, unite, qualite_indicateur, prix_indicatif, devise, latitude, longitude, geom, statut, qr_payload, qr_image_path, declare_par, valide_par, valide_at, observations, client_uuid, sync_statut, sync_version, last_synced_at, created_at, updated_at, deleted_at) FROM stdin;
cbab41ae-0e5a-4b8e-a556-f0d173ef9f90	PNLF-20260810-A1CDF1785E	373ff778-12e2-4f5d-a580-8dc80d7c5c47	23a50256-8c19-4052-9107-b5af0c971952	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	2026-08-10	12.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:373ff778-12e2-4f5d-a580-8dc80d7c5c47	\N	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N	\N	\N	SYNCED	1	\N	2026-08-10 14:35:58.85693+02	2026-10-03 13:53:59.538256+02	2026-08-10 14:35:58.957573+02
242cb5f0-bf99-4a9e-a8ae-b8482cf56adb	PNLF-20260813-9D37C4CD75	425489e3-0a73-4948-bb1a-94768aa6afd9	5f306e08-3b87-4cb9-95e7-7ff7020e0425	87e98748-a24e-4ae5-98cc-8b028986a11a	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:425489e3-0a73-4948-bb1a-94768aa6afd9	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.937136+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
67fe58b6-5032-43e3-87ec-e5288cec9cf4	PNLF-20260813-77656B291A	68e09589-e99e-4309-ac2f-84fa8bb08bc8	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:68e09589-e99e-4309-ac2f-84fa8bb08bc8	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.748277+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
07fa0834-2dd8-47b1-a514-176f1f8091a9	PNLF-20260813-E455264678	564d2fc5-834f-4eb8-9234-bf920aac1213	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5ac66f77-ef10-49e4-962f-9670667460f6	\N	\N	2026-08-13	15.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:564d2fc5-834f-4eb8-9234-bf920aac1213	\N	1051c839-763f-4a10-9f0e-7b64d301a393	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:33:15.700519+02	2026-10-03 13:53:59.538256+02	2026-08-13 12:33:15.760121+02
cfeb7bb7-ccfb-48e3-839a-969001365b45	PNLF-20260813-069BB2C6B4	de8c9d13-2b5e-4899-b440-f0fd23651ca4	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:de8c9d13-2b5e-4899-b440-f0fd23651ca4	\N	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.617641+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
74ce72a3-51ce-4843-965e-6aaa68792a32	PNLF-20260813-CB465D0244	727e5ce0-ee5d-4f82-a105-50a7d59c574a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	36f91375-1657-40f9-a4e1-60710579c8c6	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:22:00.361022+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
c3885f84-6a3e-491a-a07e-4e812836b66d	PNLF-20260813-A59F9DC09C	2f07b2f9-577b-48e7-8b47-a890ea1892fb	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:2f07b2f9-577b-48e7-8b47-a890ea1892fb	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.996717+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
30907e00-b121-4760-a042-f7d351b0fbf9	PNLF-20260813-F0692843D4	ecc1dbb6-d6b3-4d44-b188-229cf69ef0eb	5f306e08-3b87-4cb9-95e7-7ff7020e0425	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	2026-08-13	25.000	KG		\N	XAF	\N	\N	\N	BROUILLON	PNLF:ecc1dbb6-d6b3-4d44-b188-229cf69ef0eb	qr/ecc1dbb6-d6b3-4d44-b188-229cf69ef0eb.png	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N		\N	SYNCED	1	\N	2026-08-13 20:53:18.572138+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
6e99d951-70c9-46f1-8d40-388b6fbb8126	PNLF-20260813-AA8F0654CE	99b5aeda-cec4-46f7-9a8e-a51181ff1b4d	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:99b5aeda-cec4-46f7-9a8e-a51181ff1b4d	\N	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.02866+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
c2367dcb-a765-4713-beb5-e5dafbfd8501	PNLF-20260815-D82C5080CB	9c900d74-79a4-4752-a1fb-78acaf55991b	acbeb789-ea63-4010-808b-c1967da0ef3f	c72db6b0-beec-4785-82c0-c5d84e40dc7e	\N	\N	2026-08-15	12.500	KG	1er choix	2500.00	XAF	\N	\N	\N	BROUILLON	PNLF:9c900d74-79a4-4752-a1fb-78acaf55991b	qr/9c900d74-79a4-4752-a1fb-78acaf55991b.png	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	\N	\N	Récolte fraîche, séchage naturel.	\N	SYNCED	1	\N	2026-08-15 17:44:01.285136+02	2026-10-03 13:53:59.538256+02	2026-08-15 17:48:02.675364+02
5a335163-11c9-41ce-a66b-504d08c9f909	PNLF-20260813-49BA2564D1	2dc753bc-0db9-4c84-9c2a-cf23e5543a9f	5f306e08-3b87-4cb9-95e7-7ff7020e0425	1c012791-98f7-4b5e-81b7-5e553492aedf	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:2dc753bc-0db9-4c84-9c2a-cf23e5543a9f	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.085475+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
87e9b6b2-f1c7-4bec-a267-8b45e8753e25	PNLF-RBAC-M-4b6d09	b82710f3-8ba8-4aeb-a0a4-b900a36b699e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:09.221805+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
a6ecae99-b5d9-42a5-8371-bb48e8f26c86	PNLF-20260815-F89A15495C	46e4cea9-7e72-4f32-b2df-accca057638f	acbeb789-ea63-4010-808b-c1967da0ef3f	117d4a3b-7814-452a-b8f8-f55a483b1cd4	\N	\N	2026-08-15	12.500	KG	1er choix	2500.00	XAF	\N	\N	\N	BROUILLON	PNLF:46e4cea9-7e72-4f32-b2df-accca057638f	qr/46e4cea9-7e72-4f32-b2df-accca057638f.png	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	\N	\N	Récolte fraîche, séchage naturel.	\N	SYNCED	1	\N	2026-08-15 17:44:35.468468+02	2026-10-03 13:53:59.538256+02	2026-08-15 17:44:35.771342+02
bdc4005d-08ee-4a9f-be9f-cd666e715270	PNLF-20260815-DD2EB5967E	a655366a-38eb-43fd-815c-b2b2222a8ca2	acbeb789-ea63-4010-808b-c1967da0ef3f	9027c481-fbc6-4681-8612-1800eb5d6bf0	\N	\N	2026-08-15	12.500	KG	1er choix	2500.00	XAF	\N	\N	\N	BROUILLON	PNLF:a655366a-38eb-43fd-815c-b2b2222a8ca2	qr/a655366a-38eb-43fd-815c-b2b2222a8ca2.png	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	\N	\N	Récolte fraîche, séchage naturel.	\N	SYNCED	1	\N	2026-08-15 17:43:31.186964+02	2026-10-03 13:53:59.538256+02	2026-08-15 17:48:02.675364+02
4af77ba1-b515-42e3-8156-d299733b266e	PNLF-20260813-40AD218188	57fcbdc9-4303-40ed-8a13-e06bc3ee71b9	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:57fcbdc9-4303-40ed-8a13-e06bc3ee71b9	qr/57fcbdc9-4303-40ed-8a13-e06bc3ee71b9.png	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.447724+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
58237198-493a-412c-b06f-5a9dd504e426	PNLF-PAR-X-d21c0e	7d357664-75d4-48ec-8635-c88364b49338	5f306e08-3b87-4cb9-95e7-7ff7020e0425	0c883635-2daa-4b9e-9240-c726c9c0ec84	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:47.016115+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:21:49.217458+02
87057364-ce8b-4dc3-8c87-658c8b4de90e	PNLF-20260813-77489FBEC8	905572c5-6acc-445c-a1f7-4c2c6d1bc375	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:905572c5-6acc-445c-a1f7-4c2c6d1bc375	qr/905572c5-6acc-445c-a1f7-4c2c6d1bc375.png	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.977958+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.063087+02
0c0106ee-1b58-4b85-8ddd-cea26904d0ff	PNLF-20260813-22A8ADAF4B	ce4b41d7-97cd-413c-8736-6604cf2c63b7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:ce4b41d7-97cd-413c-8736-6604cf2c63b7	qr/ce4b41d7-97cd-413c-8736-6604cf2c63b7.png	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:18:59.588489+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
88181504-eb0e-4036-a6ef-bc43be5beed6	PNLF-20260813-0C335E627C	2f283e08-fe90-4ce4-a3f4-1a437e49bb9a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:2f283e08-fe90-4ce4-a3f4-1a437e49bb9a	qr/2f283e08-fe90-4ce4-a3f4-1a437e49bb9a.png	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.241698+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
18a8c9f8-e0fb-4053-877f-023e68359da7	PNLF-20260813-88AD218334	9f88ff67-3afe-4bb0-8780-c39835175a51	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:9f88ff67-3afe-4bb0-8780-c39835175a51	qr/9f88ff67-3afe-4bb0-8780-c39835175a51.png	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.309502+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
954bede4-567a-480a-a715-58c0b6a9828c	PNLF-20260813-EAB63171B1	e974d6ba-20cf-4649-a64b-f75694922f16	5f306e08-3b87-4cb9-95e7-7ff7020e0425	21780bdf-be5a-4eb5-866b-eb89d96ccdf1	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:e974d6ba-20cf-4649-a64b-f75694922f16	qr/e974d6ba-20cf-4649-a64b-f75694922f16.png	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.39057+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
06787104-09da-485e-897f-ec09c69ebca0	PNLF-PAR-X-edea48	e1501b16-a2ba-435c-8d41-fc74c1740939	5f306e08-3b87-4cb9-95e7-7ff7020e0425	c49db566-245a-4200-a4b6-632a35db8d67	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:20:17.3473+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:20:18.985927+02
09508320-8436-41a6-ac38-bad3927786de	PNLF-PAR-X-15b2ff	1136ecd1-ae53-40ef-9845-d315de2c7c7e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	b972746b-10e7-42aa-ae2e-7b4eb7866bdb	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:10.978194+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:21:12.750623+02
dfde6062-15c1-4238-b853-6e1e40969f74	PNLF-20260819-D66B7303C8	3abcef53-d722-4bf5-bc44-753b392f9d61	5f306e08-3b87-4cb9-95e7-7ff7020e0425	6fbdace5-2e31-4c07-b980-9fb13a618ea5	\N	\N	2026-08-19	1.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:3abcef53-d722-4bf5-bc44-753b392f9d61	qr/3abcef53-d722-4bf5-bc44-753b392f9d61.png	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:49.096465+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:21:49.217458+02
b5b08992-60f8-4936-aa89-10c2904df08d	PNLF-PAR-X-63dfe3	757b8446-ef64-450d-bf54-71851a0fb3d1	5f306e08-3b87-4cb9-95e7-7ff7020e0425	8a6a7d24-b821-400a-b0f7-7d93ca76ff3f	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:18.038551+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:20.494359+02
8ec32c4a-4ad4-4840-a4f4-eb8dde3d158b	PNLF-PAR-X-3d97ef	8e783f1d-d889-4890-befb-38dc7f229b54	5f306e08-3b87-4cb9-95e7-7ff7020e0425	c7d4b9fd-5548-4f18-84a2-884f01126fdf	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:09:47.201463+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:09:49.414913+02
53532fa4-2495-4bb7-ad57-c0b842d1d0ca	PNLF-20260819-D08120E6D6	334c35db-1b7d-451e-a3cb-f1042418033e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:334c35db-1b7d-451e-a3cb-f1042418033e	qr/334c35db-1b7d-451e-a3cb-f1042418033e.png	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.387675+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.421879+02
31e28129-f299-44ef-8bc4-2cabb1dd7ffc	PNLF-PAR-X-a43c98	1feb9fb8-8897-49c7-a470-b2abb039569b	5f306e08-3b87-4cb9-95e7-7ff7020e0425	0440e25f-1a0c-491a-86b3-a1c5bee2f26a	\N	\N	2026-08-19	9.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:10:30.011947+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:10:31.973516+02
fe29adac-04cb-47d3-bd9d-73f3ed3649d8	PNLF-20260819-F9931175FC	2db3550b-0645-49e3-8654-33daf2736ccf	5f306e08-3b87-4cb9-95e7-7ff7020e0425	05829c24-382b-4e30-9633-12241b7f2f97	\N	\N	2026-08-19	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:2db3550b-0645-49e3-8654-33daf2736ccf	qr/2db3550b-0645-49e3-8654-33daf2736ccf.png	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.10244+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
50fce242-90c5-4af3-8349-4907f9649a1c	PNLF-20260819-3AEB32C562	9b7222f7-e143-4440-aa2c-e6889d086375	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:9b7222f7-e143-4440-aa2c-e6889d086375	qr/9b7222f7-e143-4440-aa2c-e6889d086375.png	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.130987+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
e96f14dd-1165-4db8-b979-a60b2141f830	PNLF-PAR-O-236c97	a34feb51-a813-40eb-a8a6-e731600d71f7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	bde9fe4e-d2cf-49b5-b40e-eff49b384b72	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:09:47.171767+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:09:49.414913+02
61d7ebae-83cb-44fc-b34d-f3a484d95ff3	PNLF-20260819-65999C3660	c0342402-496c-4961-9f14-650ed1bad517	5f306e08-3b87-4cb9-95e7-7ff7020e0425	bde9fe4e-d2cf-49b5-b40e-eff49b384b72	\N	\N	2026-08-19	1.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:c0342402-496c-4961-9f14-650ed1bad517	qr/c0342402-496c-4961-9f14-650ed1bad517.png	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:09:49.354664+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:09:49.414913+02
cd7faaa4-8d83-4e01-aa9b-9804a80b396f	PNLF-PAR-O-a5462d	e8ef5e82-1289-4dd3-80c0-a12a222651d2	5f306e08-3b87-4cb9-95e7-7ff7020e0425	4f34afb3-9c20-4e22-b443-ce5b4d50f7df	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:10:30.002209+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:10:31.973516+02
0db80fe5-1427-4a01-8be9-183de8232ae9	PNLF-20260819-43584676EA	b0ef3b05-7d46-4507-8afb-d679b82159a7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	4f34afb3-9c20-4e22-b443-ce5b4d50f7df	\N	\N	2026-08-19	1.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:b0ef3b05-7d46-4507-8afb-d679b82159a7	qr/b0ef3b05-7d46-4507-8afb-d679b82159a7.png	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:10:31.919272+02	2026-10-03 13:53:59.538256+02	2026-08-19 13:10:31.973516+02
e2c90d83-967e-41e4-ad3d-aebf4e922897	PNLF-20260819-F9FCD0D5E7	d0ad8d01-494c-455c-91f8-ccfe3e76236d	5f306e08-3b87-4cb9-95e7-7ff7020e0425	05829c24-382b-4e30-9633-12241b7f2f97	\N	\N	2026-08-19	2.000	KG	\N	\N	XAF	\N	\N	\N	VALIDE	PNLF:d0ad8d01-494c-455c-91f8-ccfe3e76236d	qr/d0ad8d01-494c-455c-91f8-ccfe3e76236d.png	41f20506-4b04-4203-900c-5c52ab3209bf	\N	2026-08-19 12:40:48.277451+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.253178+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
e16b7be4-1d09-426d-a064-9dc93c2b3c97	PNLF-20260815-3508F83C65	457b31d1-0bb4-4651-add6-53bfc31202e7	f3bac528-2d07-4b1a-a300-dd2d5fd327ac	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	2026-08-15	2.000	LITRE	frais	14973.00	XAF	\N	\N	\N	BROUILLON	PNLF:457b31d1-0bb4-4651-add6-53bfc31202e7	qr/457b31d1-0bb4-4651-add6-53bfc31202e7.png	ec38d815-0579-448c-b7dd-1c54b8dce005	\N	\N		\N	SYNCED	1	\N	2026-08-15 18:11:58.555353+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
f0e40537-ecf1-4242-94d1-65339dde604f	PNLF-PAR-O-7d9eda	77284646-753a-45d1-a9ef-492e20898935	5f306e08-3b87-4cb9-95e7-7ff7020e0425	06efa363-7347-4d12-b162-e932a0425b60	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:18.017359+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:20.494359+02
b41386d7-ef39-4e9d-8854-f23c1a9137ac	PNLF-20260819-48B25496C0	6eb03b1b-0197-4b5a-96af-d517fa824392	5f306e08-3b87-4cb9-95e7-7ff7020e0425	06efa363-7347-4d12-b162-e932a0425b60	\N	\N	2026-08-19	1.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:6eb03b1b-0197-4b5a-96af-d517fa824392	qr/6eb03b1b-0197-4b5a-96af-d517fa824392.png	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:20.344974+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:20.494359+02
ca95422f-ebbe-43a4-b199-6a2075afe0af	PNLF-20260819-2FD5A4D363	7c8b2c98-c18c-4600-9244-34b707903a17	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:7c8b2c98-c18c-4600-9244-34b707903a17	qr/7c8b2c98-c18c-4600-9244-34b707903a17.png	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.047763+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
2b3c8331-3445-44be-b861-a6df69c126a6	PNLF-20260819-2B5601D872	681ba8da-6354-4cda-97c7-cff181399810	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:681ba8da-6354-4cda-97c7-cff181399810	qr/681ba8da-6354-4cda-97c7-cff181399810.png	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:48.073652+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
2d43927b-1ef1-4179-802c-38e2ec495ae3	PNLF-20260819-AF473D094A	d4c85d3b-22e6-46e3-b677-b9af3db19263	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:d4c85d3b-22e6-46e3-b677-b9af3db19263	qr/d4c85d3b-22e6-46e3-b677-b9af3db19263.png	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.944568+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
2bdbbed9-9ebf-4e94-8c3d-f857cfcee8bc	PNLF-PAR-O-aad5f1	95a79edf-a1c0-4256-846e-0085b64b0cab	5f306e08-3b87-4cb9-95e7-7ff7020e0425	528c3915-6d2e-43f7-9bc0-788c6bcbf8d8	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:20:17.337232+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:20:18.985927+02
92f2903a-395a-4daf-a693-fcbf85494663	PNLF-PAR-O-731d64	eb009fbd-7735-44c8-bdd7-3c8936ba06f4	5f306e08-3b87-4cb9-95e7-7ff7020e0425	d8c58101-a2c7-4e35-a49d-a8a8476af4e1	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:10.944666+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:21:12.750623+02
08480520-7787-45e4-afbd-db51aff36d80	PNLF-20261002-7D25F17DDB	2b91d219-652a-4e37-880b-76fd1acea288	4537cff5-7a87-4bb8-8a3e-dc9586dab36b	ffd2f32f-0ed0-48ec-a502-f250ca779820	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-09-24	60.000	KG	Feuilles fraîches	2000.00	XAF	0.6100000	12.7300000	\N	BROUILLON	PNLF:2b91d219-652a-4e37-880b-76fd1acea288	qr/2b91d219-652a-4e37-880b-76fd1acea288.png	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	Lot de démonstration L12.	fe60ba5d-b2b7-5aed-812d-0efe7b3bc95f	SYNCED	1	\N	2026-10-02 12:06:37.265857+02	2026-10-03 13:53:59.538256+02	\N
12b57849-fa7e-42ed-8fb7-cb5004a3ec2d	PNLF-20261002-4C2F067A57	51f8a13e-de01-4402-93ff-4abb2449cc72	9b81e198-8133-4aab-b8e2-c06c8781589d	ad0c1500-c241-4d87-90c6-ac3ec914f53a	e5326de4-90ed-4b3b-acab-5c847db8bf0a	12d53253-f473-41ef-82a8-04778bcff530	2026-09-27	150.000	BOTTE	\N	500.00	XAF	-1.7500000	11.1500000	\N	BROUILLON	PNLF:51f8a13e-de01-4402-93ff-4abb2449cc72	qr/51f8a13e-de01-4402-93ff-4abb2449cc72.png	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	\N	\N	Lot de démonstration L13.	fce48b06-b1bc-5e4b-9c44-56bb43970538	SYNCED	1	\N	2026-10-02 12:06:37.365217+02	2026-10-03 13:53:59.538256+02	\N
b76576f5-5a0c-4adc-941d-8f5d584033e7	PNLF-20261002-A04BB16BD3	bdd9af9c-214a-4f91-beff-2be158179064	03e2ea27-7d14-4024-a157-b0fa4e2ccb13	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	\N	2026-07-04	50.000	KG	\N	3500.00	XAF	\N	\N	\N	BROUILLON	PNLF:bdd9af9c-214a-4f91-beff-2be158179064	qr/bdd9af9c-214a-4f91-beff-2be158179064.png	5dfd8155-3222-4e05-9702-06e9cc47cca1	\N	\N	Lot de démonstration L08.	98a7fcd9-f1a9-5d44-873c-ab2516cccec3	SYNCED	1	\N	2026-10-02 12:06:36.942521+02	2026-10-03 13:53:59.538256+02	2026-10-03 13:53:59.538256+02
67381035-8c17-475b-a555-6a929aca6db1	PNLF-20261002-05AB5441EC	0df45241-a322-4322-8407-23c7cc14076b	cbc6ebe5-a267-413c-8848-7e5e26ce2c09	efddd969-6c0b-49f0-9204-5c846f4f7bba	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-06-04	10.000	KG	Frais	5000.00	XAF	0.6100000	12.7300000	\N	BROUILLON	PNLF:0df45241-a322-4322-8407-23c7cc14076b	qr/0df45241-a322-4322-8407-23c7cc14076b.png	b64ff13b-0617-456b-9589-257f95ae4fb7	\N	\N	Lot de démonstration L09.	1dfcc26c-9e1b-5d7c-b9c5-ce97d1c217c3	SYNCED	1	\N	2026-10-02 12:06:37.021469+02	2026-10-03 13:53:59.538256+02	2026-10-03 13:53:59.538256+02
9c409482-8669-4389-a5ef-5b1fad45e2f5	PNLF-20261002-3667AA23F8	8bb30a93-cb0f-4150-91ed-fd54b0d79441	ba78f0de-2b31-4349-9f1f-8ea2607bfe3d	ad0c1500-c241-4d87-90c6-ac3ec914f53a	e5326de4-90ed-4b3b-acab-5c847db8bf0a	ec28c59a-9434-4f66-b272-368859a8b7fd	2026-09-29	2.500	KG	\N	\N	XAF	-1.2100000	10.6000000	\N	BROUILLON	PNLF:8bb30a93-cb0f-4150-91ed-fd54b0d79441	qr/8bb30a93-cb0f-4150-91ed-fd54b0d79441.png	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	\N	\N	Lot de démonstration L03.	61820f53-5e30-5d03-9ccd-831cd81329d5	SYNCED	1	\N	2026-10-02 12:06:36.649353+02	2026-10-02 12:06:24.799502+02	\N
4761a2cc-ed5d-495c-99b0-370a8abdfc2d	PNLF-RBAC-M-9ffe69	ffb1c3b4-0f18-4443-9aec-41267bd5d99f	5f306e08-3b87-4cb9-95e7-7ff7020e0425	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	VALIDE	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	2026-08-13 15:19:00.623133+02	\N	\N	SYNCED	1	\N	2026-08-13 15:18:57.823743+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
179de271-fbbf-497b-92f5-427374f71075	PNLF-RBAC-M-42642a	db2ebd11-61c6-4737-b6bf-87ac517e09da	5f306e08-3b87-4cb9-95e7-7ff7020e0425	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	2026-08-19	10.000	KG	\N	\N	XAF	\N	\N	\N	VALIDE	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	2026-08-19 12:40:48.227346+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:46.996598+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
896264b6-573a-4c65-9b7e-c8ca34c2bd2e	PNLF-20260815-2337EA4931	193c0929-0f58-40f3-8480-37f1e5c3ccc1	38d243ac-a8f6-4024-a33e-4b4e9c46e27a	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	2026-08-15	200.000	SAC	Seché	12000.00	XAF	\N	\N	\N	COMMERCIALISE	PNLF:193c0929-0f58-40f3-8480-37f1e5c3ccc1	qr/193c0929-0f58-40f3-8480-37f1e5c3ccc1.png	ec38d815-0579-448c-b7dd-1c54b8dce005	\N	2026-08-21 17:06:00+02	produit impécable	\N	SYNCED	1	\N	2026-08-15 16:48:13.264106+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
81593e4f-57a1-451b-a030-c09baeb0a38e	PNLF-20260813-1BCEC822B1	26ec8e87-e147-4059-897e-9798dc1e95ac	5f306e08-3b87-4cb9-95e7-7ff7020e0425	21780bdf-be5a-4eb5-866b-eb89d96ccdf1	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	VALIDE	PNLF:26ec8e87-e147-4059-897e-9798dc1e95ac	qr/26ec8e87-e147-4059-897e-9798dc1e95ac.png	41f20506-4b04-4203-900c-5c52ab3209bf	\N	2026-08-13 15:19:00.751805+02	\N	\N	SYNCED	1	\N	2026-08-13 15:19:00.707977+02	2026-10-03 13:53:59.538256+02	2026-08-13 15:19:01.107229+02
06dea582-3d6a-4dfa-8e38-8bd4ca7bf681	PNLF-20260815-7E741114F6	089488c7-2455-4304-b2bb-460fb538b861	4537cff5-7a87-4bb8-8a3e-dc9586dab36b	fea18beb-ff84-406b-a45b-6edc5d1cc489	\N	\N	2026-08-15	266.000	KG	fraif	500000.00	XAF	-0.5546000	11.6642000	\N	COMMERCIALISE	PNLF:089488c7-2455-4304-b2bb-460fb538b861	qr/089488c7-2455-4304-b2bb-460fb538b861.png	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	\N	2026-08-21 17:08:00+02	nkumu frais	\N	SYNCED	1	\N	2026-08-15 18:29:27.664695+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
9a398c12-bf2f-4fcf-b6b4-1590d65708ff	PNLF-20260819-D60F530C5E	fab7b6cb-5bfc-4196-a42f-18cab1d940f1	dafedd72-af4f-410b-b81b-e55d238c9280	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	2026-08-19	1.000	KG	Sec	945.00	XAF	0.5500000	11.6600000	\N	COMMERCIALISE	PNLF:fab7b6cb-5bfc-4196-a42f-18cab1d940f1	qr/fab7b6cb-5bfc-4196-a42f-18cab1d940f1.png	ec38d815-0579-448c-b7dd-1c54b8dce005	\N	2026-09-23 17:12:46.065062+02	bon	\N	SYNCED	1	\N	2026-08-19 11:47:57.282583+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
2c9fe26c-95eb-4b84-80eb-93bc10b3d187	PNLF-20261002-C99C0C5972	bb39b993-8880-4023-aeee-034c48b4a5d0	a0a0d114-3cf6-400f-8dd7-4cdddd0792f8	efddd969-6c0b-49f0-9204-5c846f4f7bba	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-08-03	300.000	KG	Noix fraîches	1800.00	XAF	0.6100000	12.7300000	\N	VALIDE	PNLF:bb39b993-8880-4023-aeee-034c48b4a5d0	qr/bb39b993-8880-4023-aeee-034c48b4a5d0.png	b64ff13b-0617-456b-9589-257f95ae4fb7	\N	2026-10-02 12:06:37.731589+02	Lot de démonstration L04.	3d1de5b1-2d80-50c7-a8e5-04d2a00dc5be	SYNCED	1	\N	2026-10-02 12:06:36.692982+02	2026-10-03 13:53:59.538256+02	\N
a53361f0-d36f-4224-ac8b-b16f89e2ac3e	PNLF-20260813-7D4BC658A2	61d38303-b991-4833-a64a-79e5b662d044	23a50256-8c19-4052-9107-b5af0c971952	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	2026-08-13	12.500	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:61d38303-b991-4833-a64a-79e5b662d044	\N	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:33:37.734286+02	2026-10-03 13:53:59.538256+02	2026-08-13 12:33:37.815383+02
c856c8fd-10cb-4128-86d2-a4517631f039	PNLF-20260813-12CDD5CB96	414c5ff0-f6fa-40cb-af93-f6a128bfcbc8	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:414c5ff0-f6fa-40cb-af93-f6a128bfcbc8	\N	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.658387+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
abef08e3-bf40-451b-a860-45bd366eee32	PNLF-20260813-84036B2550	ceb7c922-8c29-4ad3-9719-cb7e639fc1c0	5f306e08-3b87-4cb9-95e7-7ff7020e0425	ceef2c73-0866-4ade-b4e5-40029ee9236d	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:ceb7c922-8c29-4ad3-9719-cb7e639fc1c0	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.702077+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
7426e125-300b-4c0d-a1d6-5c6f9ba45f33	PNLF-RBAC-M-e0aefa	08fd2fe6-5fd9-4920-854d-14544ae22800	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:50:59.894145+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
e77b0d44-e40f-47da-9436-338e24f4948a	PNLF-20260813-16B8378CA2	4bb574e8-009f-4f1e-b718-1a5277054406	5f306e08-3b87-4cb9-95e7-7ff7020e0425	ceef2c73-0866-4ade-b4e5-40029ee9236d	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:4bb574e8-009f-4f1e-b718-1a5277054406	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.978088+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
04f37203-6c70-438c-8898-0ef5fbea5650	PNLF-RBAC-O-3dd6b9	14a34c63-9253-42ca-8958-6d72e4e634e7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	fed1ccfc-0904-4704-85b9-4d8bd8a3af98	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:16.958917+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
421c9eb8-2612-4025-b2ff-8b71c8c250b0	PNLF-RBAC-O-d95c11	fb3082ef-0e4d-4188-b889-038d3298eff8	5f306e08-3b87-4cb9-95e7-7ff7020e0425	c934672b-25c6-4846-b9ef-7ffbd30aeb36	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:50:59.913166+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
54b091df-1b94-42b1-956e-9ec210b70bee	PNLF-RBAC-O-8f0672	008880e3-0933-4f2d-a5bc-53a9c3e388c5	5f306e08-3b87-4cb9-95e7-7ff7020e0425	62f06868-08de-448f-a8cd-9db6e81b28bd	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:18:57.858217+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
309a3c6f-8439-4583-be13-0318f7fcaecb	PNLF-20260813-DCE6F1FA2C	e8652afe-9bb6-43ff-bb24-06012661a0aa	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:e8652afe-9bb6-43ff-bb24-06012661a0aa	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:15.140429+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.181977+02
78492e02-c603-48c0-a488-8579d43e616f	PNLF-20260813-363B802237	3551fc2f-1038-43ac-8a38-c1b06f0a780d	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:3551fc2f-1038-43ac-8a38-c1b06f0a780d	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:19.256217+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.344531+02
e9ba15d9-eea2-4474-90bb-3162bdf3674c	PNLF-20260813-75AC4A70CA	e9193654-2fd3-4946-bbc5-20ecc3ba9835	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:e9193654-2fd3-4946-bbc5-20ecc3ba9835	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.532632+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
d25990de-abce-4a33-8532-370a252fe84e	PNLF-20260813-3F6FFBE010	eb6d68ca-e47e-417a-bbc1-ee14765eec5a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:eb6d68ca-e47e-417a-bbc1-ee14765eec5a	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:02.17298+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.250748+02
6c36cf89-bf38-4585-9ed7-6105d09c6834	PNLF-20260813-35B458D565	d1a34831-94f9-4d3e-87d6-fb7d08b0882a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:d1a34831-94f9-4d3e-87d6-fb7d08b0882a	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.475111+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
f732e990-3a92-4436-bfbe-45dccd6412f3	PNLF-20260813-C1CB86289D	175f3c7b-03fd-4bc8-beca-555c32d3cac9	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:175f3c7b-03fd-4bc8-beca-555c32d3cac9	\N	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.568843+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
eae7ddfb-aa9b-4a85-ad6f-3a1ba0cc1d80	PNLF-20260813-4A0208551C	c193c470-72dc-4b6c-bde9-40c05754bc51	5f306e08-3b87-4cb9-95e7-7ff7020e0425	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:c193c470-72dc-4b6c-bde9-40c05754bc51	\N	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.62335+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
72bfcb0e-d964-43f7-ace3-9ec798fbc9b5	PNLF-20260813-2CA72F7708	f98edae0-9989-4d78-a347-49a09bb2b7c5	5f306e08-3b87-4cb9-95e7-7ff7020e0425	87e98748-a24e-4ae5-98cc-8b028986a11a	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:f98edae0-9989-4d78-a347-49a09bb2b7c5	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.689083+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:51:02.284338+02
36d41a1a-17df-485a-8af8-ca1e89301c1f	PNLF-20260813-AFE39655CA	a513eff5-9b0f-4d85-97cc-093611f23752	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:a513eff5-9b0f-4d85-97cc-093611f23752	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.48187+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
192b93a8-c496-43ef-8871-16b6c4d86f0c	PNLF-20260813-7F9B008D08	207bde12-2de0-4bf8-a437-dc544332c920	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:207bde12-2de0-4bf8-a437-dc544332c920	\N	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.531932+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
680c23ed-0ad7-435c-93c2-0733a4312726	PNLF-20260813-91E884D2DD	0e0462af-ea41-472f-ad1f-c0d5a7eb6a3d	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:0e0462af-ea41-472f-ad1f-c0d5a7eb6a3d	\N	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.558254+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
e437c0f5-36ad-4a4b-b637-9ae63759035e	PNLF-20260813-19A4A6699F	3512000d-e181-42fb-8486-a797b3b9007e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	0535f8f6-d738-495c-8ecc-896c1c442a63	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:3512000d-e181-42fb-8486-a797b3b9007e	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.588787+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
749e0d73-5539-438c-b82f-cf56e1478664	PNLF-20260813-E80F876C38	e8eaa534-66be-456a-9dd8-102b3fb42473	5f306e08-3b87-4cb9-95e7-7ff7020e0425	0535f8f6-d738-495c-8ecc-896c1c442a63	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:e8eaa534-66be-456a-9dd8-102b3fb42473	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.881968+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
73e3c879-2b0a-4679-96f9-e14c889eaa7f	PNLF-20260813-4F4253AC98	d9f2743c-5b5f-4042-9f20-654bd9470fd0	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:d9f2743c-5b5f-4042-9f20-654bd9470fd0	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.626964+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:53:15.204602+02
ea1b6189-2a4d-42c6-9410-bc59b3357468	PNLF-20260813-789DD5A2D7	8445f7cb-3438-4ff3-8abb-d1f776c2a976	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:8445f7cb-3438-4ff3-8abb-d1f776c2a976	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.743023+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:19.377897+02
cf6f989a-98d0-4682-948c-5538447e4b4b	PNLF-20260813-1D75AE7DB5	1898e388-7543-4ad8-885a-a673ed08a98e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:1898e388-7543-4ad8-885a-a673ed08a98e	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.154129+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
16649b4b-0929-45d1-b830-ae486e38be3d	PNLF-20260813-5F15762956	75ff3a12-c0ba-473e-a885-cf7da129c925	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:75ff3a12-c0ba-473e-a885-cf7da129c925	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:11.506018+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.59365+02
39514cfc-0c93-4fe9-b85a-ff3fd8c043d0	PNLF-20260813-674AD5C40A	851ecbae-2ff7-4262-9dd0-befc2fcae46c	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:851ecbae-2ff7-4262-9dd0-befc2fcae46c	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.711928+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
d25c710b-839a-49ec-a011-89b37ef436ec	PNLF-20260813-5D74CF92FF	00201d44-30ec-41e0-acc1-005b7025f052	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:00201d44-30ec-41e0-acc1-005b7025f052	\N	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.774994+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
5c386e69-9870-4b6b-8e27-4d5bf9027da9	PNLF-20260813-24AE6A5254	5e9d6bf7-4253-4f6c-8445-fe65052f421e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:5e9d6bf7-4253-4f6c-8445-fe65052f421e	\N	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.889901+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
e4b7c78d-8663-4b2a-afb3-71c1c7f3554b	PNLF-20260813-E7A7048191	59259fe9-9997-4f13-aaa3-7eec3bb37234	5f306e08-3b87-4cb9-95e7-7ff7020e0425	d8f1ea56-6a02-4de3-9730-47e39a0a1df8	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:59259fe9-9997-4f13-aaa3-7eec3bb37234	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.962316+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
4c7da43b-544d-42e4-ae01-70caa3905819	PNLF-20260813-1CBE383800	abce6ebf-b059-4c24-a625-e679f61adadb	5f306e08-3b87-4cb9-95e7-7ff7020e0425	d8f1ea56-6a02-4de3-9730-47e39a0a1df8	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:abce6ebf-b059-4c24-a625-e679f61adadb	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:11.25138+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:55:11.634658+02
7103bd23-00dd-4ad8-9397-73280b333f3f	PNLF-RBAC-M-1b4f28	657ad222-1c73-4e7f-8069-84b6956c768a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:13.067971+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
4f532bb7-3727-41c4-b823-f79d20943430	PNLF-RBAC-M-c7002a	69cb9a83-07b4-4cc2-b26f-77234557d61a	5f306e08-3b87-4cb9-95e7-7ff7020e0425	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:16.931094+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
226d5a29-c768-4283-9510-c0ee09ab6ad0	PNLF-RBAC-M-40c753	18eef4e8-8a40-42a7-83fb-6abca8d236c7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	10.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:30.2807+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
23726099-ba5f-4900-8824-9d5ac5f2d8ee	PNLF-20260813-D04051B6E9	ab55b4ed-426c-4572-95d5-99626f436d14	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	1.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:ab55b4ed-426c-4572-95d5-99626f436d14	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.730838+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.805574+02
2805594d-f18f-47b4-aff1-d1263143f8a3	PNLF-RBAC-O-20b6dd	16aa9e31-dbb7-4b7b-a9d4-a11ab55fa0bf	5f306e08-3b87-4cb9-95e7-7ff7020e0425	9fd66383-703c-42ad-8b9d-81fce34da52a	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:13.074087+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
ebf56ae8-e877-45ee-b444-620ca79df018	PNLF-20260813-E6FDA11423	d3f2dce1-65d2-4370-b74d-2c07fd1b975e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:d3f2dce1-65d2-4370-b74d-2c07fd1b975e	\N	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.868661+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
5f2fc59a-b2d2-4d4e-9db6-3a36ea46c34c	PNLF-20260813-CED0F419CA	4bb76c12-a75b-451c-b418-eb6f411d156b	5f306e08-3b87-4cb9-95e7-7ff7020e0425	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	2026-08-13	3.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:4bb76c12-a75b-451c-b418-eb6f411d156b	\N	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.961356+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
3dd1ba95-ac23-4045-902a-95a261153c17	PNLF-20260813-95634B801A	ab61f945-fc2b-414e-8c82-ed557c792d5d	5f306e08-3b87-4cb9-95e7-7ff7020e0425	1c012791-98f7-4b5e-81b7-5e553492aedf	\N	\N	2026-08-13	2.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	PNLF:ab61f945-fc2b-414e-8c82-ed557c792d5d	\N	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.466068+02	2026-10-03 13:53:59.538256+02	2026-08-13 14:56:32.838371+02
907fb82c-92f8-4545-8175-f2936c9561bb	PNLF-RBAC-O-14bce7	60c2e148-6926-483a-a25d-0b42d5ff9869	5f306e08-3b87-4cb9-95e7-7ff7020e0425	a10ef888-85b6-46f9-8591-d3da6eba4b5c	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:09.23139+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
7a948d05-8a65-4fd5-8a20-52fca42aff5d	PNLF-RBAC-O-bdb22b	4e2e1f58-ebf6-4243-85d3-b0df1db185b7	5f306e08-3b87-4cb9-95e7-7ff7020e0425	28658b55-e711-4ca0-bd25-e2d71b74d960	\N	\N	2026-08-13	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:30.286337+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:41.390084+02
87dd0477-1172-4893-9dac-1aac9c934792	PNLF-RBAC-O-04bf93	069edf67-b7cc-4c64-9dd0-527c1c04a1f4	5f306e08-3b87-4cb9-95e7-7ff7020e0425	d550bc5e-077b-47f9-8214-6f92b994a641	\N	\N	2026-08-19	5.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:46.998682+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:40:48.439047+02
efa5499c-ebdd-48a9-8771-748225ebc2c8	PNLF-20260813-C5DBA203CA	d2c7dfb2-0b3c-44af-b9db-1d9c0528485e	5f306e08-3b87-4cb9-95e7-7ff7020e0425	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	2026-08-13	25.000	KG		\N	XAF	\N	\N	\N	BROUILLON	PNLF:d2c7dfb2-0b3c-44af-b9db-1d9c0528485e	qr/d2c7dfb2-0b3c-44af-b9db-1d9c0528485e.png	2992fb5e-5580-483b-9462-98fe46cf7627	\N	\N		\N	SYNCED	1	\N	2026-08-13 20:54:21.231584+02	2026-10-03 13:53:59.538256+02	2026-09-23 17:12:46.065062+02
7890cc23-a774-4768-b9fc-fa31d63e675c	PNLF-PAR-O-49e6f8	6100f149-7ebb-40eb-8ac0-c140c2034291	5f306e08-3b87-4cb9-95e7-7ff7020e0425	6fbdace5-2e31-4c07-b980-9fb13a618ea5	\N	\N	2026-08-19	4.000	KG	\N	\N	XAF	\N	\N	\N	BROUILLON	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:46.99805+02	2026-10-03 13:53:59.538256+02	2026-08-19 12:21:49.217458+02
8242374c-f334-4e11-afd4-e5504950b786	PNLF-20261002-DF1ADB827E	8a802c64-65cb-4e55-8d5d-ed9eabd90cc8	dafedd72-af4f-410b-b81b-e55d238c9280	32b71cac-11e7-4f9e-a7e9-b909b42a7154	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-09-12	80.000	KG	Calibre moyen	2500.00	XAF	0.6100000	12.7300000	\N	BROUILLON	PNLF:8a802c64-65cb-4e55-8d5d-ed9eabd90cc8	qr/8a802c64-65cb-4e55-8d5d-ed9eabd90cc8.png	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	Lot de démonstration L05.	c1e5768a-5779-572d-9525-d25f39b64290	SYNCED	1	\N	2026-10-02 12:06:36.744773+02	2026-10-03 13:53:59.538256+02	\N
134f6a3d-20da-4ae3-b853-002795421487	PNLF-20261002-3B1D5EAEF3	0f4420f8-3db5-4bf0-94d4-fed82a82cc1d	ec06371d-e297-438b-8d26-bb2b6d21804e	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	\N	cf91171c-fc2d-44d3-870b-5618fc796032	2026-09-02	25.000	KG	Écorce de racine séchée	\N	XAF	-0.2000000	11.6000000	\N	BROUILLON	PNLF:0f4420f8-3db5-4bf0-94d4-fed82a82cc1d	qr/0f4420f8-3db5-4bf0-94d4-fed82a82cc1d.png	96c362a7-7215-490a-8443-371d2768cd2e	\N	\N	Lot de démonstration L10.	62af55de-ac16-5909-bf6f-2ff7d8db7ab2	SYNCED	1	\N	2026-10-02 12:06:37.090166+02	2026-10-03 13:53:59.538256+02	\N
eb80791e-3f0c-4ba9-a30b-c0176a9c2aec	PNLF-20261002-5545324569	337cc313-652a-4806-a543-6dd9b109f39c	05fcfa33-5ec2-43e3-98d7-1b50cb29a91a	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	\N	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-08-28	60.000	LITRE	Pressage artisanal	7000.00	XAF	0.6100000	12.7300000	\N	VALIDE	PNLF:337cc313-652a-4806-a543-6dd9b109f39c	qr/337cc313-652a-4806-a543-6dd9b109f39c.png	96c362a7-7215-490a-8443-371d2768cd2e	\N	2026-10-02 12:06:37.932745+02	Lot de démonstration L11.	23d464c8-a49a-5060-b7a4-3c836152002f	SYNCED	1	\N	2026-10-02 12:06:37.175468+02	2026-10-03 13:53:59.538256+02	\N
fd945c4c-725a-4f72-af41-ff2d89df112d	PNLF-20261002-EA6C9C8D5E	0d88bd6f-50cb-49e4-89d0-e898c4805a7b	22cd568c-3fa9-4518-871b-fe9f3d658b97	ad0c1500-c241-4d87-90c6-ac3ec914f53a	e5326de4-90ed-4b3b-acab-5c847db8bf0a	ec28c59a-9434-4f66-b272-368859a8b7fd	2026-07-19	120.000	KG	Premier choix	6500.00	XAF	-1.2100000	10.6000000	\N	COMMERCIALISE	PNLF:0d88bd6f-50cb-49e4-89d0-e898c4805a7b	qr/0d88bd6f-50cb-49e4-89d0-e898c4805a7b.png	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	\N	2026-10-02 12:06:37.570275+02	Lot de démonstration L01.	78f5f2a6-fdc3-543e-9d82-ee8e53239a72	SYNCED	1	\N	2026-10-02 12:06:36.504492+02	2026-10-03 13:53:59.538256+02	\N
18e903a7-62a8-4f15-95ac-613f516a3013	PNLF-20261002-2937F51224	1db63bb1-f76c-4dce-a07c-528c1e51df33	f3bac528-2d07-4b1a-a300-dd2d5fd327ac	ad0c1500-c241-4d87-90c6-ac3ec914f53a	e5326de4-90ed-4b3b-acab-5c847db8bf0a	12d53253-f473-41ef-82a8-04778bcff530	2026-08-23	15.000	KG	Cire brute filtrée	4000.00	XAF	-1.7500000	11.1500000	\N	VALIDE	PNLF:1db63bb1-f76c-4dce-a07c-528c1e51df33	qr/1db63bb1-f76c-4dce-a07c-528c1e51df33.png	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	\N	2026-10-02 12:06:37.690658+02	Lot de démonstration L02.	27ef7f63-3c74-5ba5-a62e-32b73ebca531	SYNCED	1	\N	2026-10-02 12:06:36.594816+02	2026-10-03 13:53:59.538256+02	\N
a1aa93bc-20b7-457b-b07f-59c3b4655558	PNLF-20261002-1E9B73FBE4	245a9568-c176-4f1e-b2c1-03adc6e9e169	df527935-1b53-4d8f-be5d-4e24ae8b7ab2	32b71cac-11e7-4f9e-a7e9-b909b42a7154	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-08-13	40.000	KG	Séchées au feu de bois	9000.00	XAF	0.6100000	12.7300000	\N	COMMERCIALISE	PNLF:245a9568-c176-4f1e-b2c1-03adc6e9e169	qr/245a9568-c176-4f1e-b2c1-03adc6e9e169.png	97a54b08-c1ef-46eb-8505-1f31b5cadb80	\N	2026-10-02 12:06:37.815436+02	Lot de démonstration L06.	6d7f39ac-298c-5cc6-98e2-36e55b250101	SYNCED	1	\N	2026-10-02 12:06:36.806655+02	2026-10-03 13:53:59.538256+02	\N
ff635715-df72-42e1-ada5-496a2f16d668	PNLF-20261002-29EDFB74D1	53438f74-5acc-4700-984b-5e0d5708c0c9	20c3ba11-7016-4166-8e92-f53e482a181e	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	\N	2026-09-20	200.000	KG	Fruits mûrs	1200.00	XAF	\N	\N	\N	VALIDE	PNLF:53438f74-5acc-4700-984b-5e0d5708c0c9	qr/53438f74-5acc-4700-984b-5e0d5708c0c9.png	5dfd8155-3222-4e05-9702-06e9cc47cca1	\N	2026-10-02 12:06:37.894097+02	Lot de démonstration L07.	b8854a63-9224-5cb2-a2c9-b85dd502f124	SYNCED	1	\N	2026-10-02 12:06:36.875413+02	2026-10-03 13:53:59.538256+02	\N
f455fe71-7ef8-44e9-bdc8-e8a8d790e336	PNLF-20261002-124E2F8C82	c326d72a-7c86-4ca2-9204-ea0e203ddd22	16f0cac4-9798-42fa-b08c-43941ea9a87f	32b71cac-11e7-4f9e-a7e9-b909b42a7154	17c571aa-c973-4da4-abe2-59fc08b7ded2	8b79f5b9-a549-4942-9069-93850ce5d12f	2026-09-07	18.000	KG	Graines sèches	6000.00	XAF	0.6100000	12.7300000	\N	VALIDE	PNLF:c326d72a-7c86-4ca2-9204-ea0e203ddd22	qr/c326d72a-7c86-4ca2-9204-ea0e203ddd22.png	97a54b08-c1ef-46eb-8505-1f31b5cadb80	\N	2026-10-02 12:06:37.974936+02	Lot de démonstration L14.	04c84180-3957-5557-b655-afa6f67ee848	SYNCED	1	\N	2026-10-02 12:06:37.454799+02	2026-10-03 13:53:59.538256+02	\N
\.


--
-- TOC entry 6966 (class 0 OID 69929)
-- Dependencies: 251
-- Data for Name: messages; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.messages (id, conversation_id, expediteur_id, contenu, lu_at, created_at) FROM stdin;
6b7aa7f6-080c-452d-a8ee-563fe0a4b158	15453ebc-6eba-4ada-90cf-8817007331b8	ec677a07-a583-40fd-9a61-370807755ac1	Bonjour Madame, oui : une livraison groupée chaque premier lundi du mois.	2026-10-02 19:29:04.036405+02	2026-10-02 12:06:45.450143+02
1248c071-3306-4e08-8bc4-49cb20b974f0	732a763f-ae05-499c-834f-5f785d39f339	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	Merci beaucoup, je le dépose dès cette semaine.	2026-10-02 19:36:08.665313+02	2026-10-02 12:06:46.40075+02
b933e868-670b-4103-8bf5-0b0469941325	11a76a97-5e8f-4eb4-9500-c4fcee8fd636	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	Bonjour, oui. Les 100 kg sont prêts et la récolte est certifiée biologique.	2026-10-02 12:06:45.05915+02	2026-10-02 12:06:44.946097+02
5c62ecb7-5c52-4208-aaab-908c182a96ed	11a76a97-5e8f-4eb4-9500-c4fcee8fd636	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	Bien sûr : lot PNLF-20261002-EA6C9C8D5E. Vous pouvez le vérifier sur la page publique.	\N	2026-10-02 12:06:45.167084+02
c7eb6641-a016-466b-8fb5-ecc300f92e5f	11a76a97-5e8f-4eb4-9500-c4fcee8fd636	eaf22c78-d48d-431f-a7ae-660650279c0e	Parfait. Pouvez-vous m’indiquer le code du lot pour une vérification par QR code ?	2026-10-02 12:06:45.183539+02	2026-10-02 12:06:45.041349+02
c771080c-c52d-4a4e-b032-795db0464df8	15453ebc-6eba-4ada-90cf-8817007331b8	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	Bonjour, livrez-vous des noix de kola à Libreville ?	2026-10-02 12:06:45.460934+02	2026-10-02 12:06:45.380723+02
c3686d8f-75ee-4012-8a5d-f34391110e29	6aec5643-73f5-4767-9cd0-a7d990a50152	eaf22c78-d48d-431f-a7ae-660650279c0e	Bonjour, seriez-vous intéressée par un contrat annuel pour la kola ?	\N	2026-10-02 12:06:45.642961+02
46119ffb-7c30-448f-bd30-a8028ff7d91e	11a76a97-5e8f-4eb4-9500-c4fcee8fd636	eaf22c78-d48d-431f-a7ae-660650279c0e	Bonjour, votre miel est-il disponible pour un enlèvement à Mouila en fin de mois ?	2026-10-02 12:06:44.962032+02	2026-10-02 12:06:44.835497+02
d005191b-1e4c-4cf4-a152-44e7c9d861a7	75cc426b-35bf-4b82-bf2a-582c16e92e93	ec677a07-a583-40fd-9a61-370807755ac1	Bonjour à tous : collecte groupée samedi au magasin de Makokou.	2026-10-02 12:06:45.985652+02	2026-10-02 12:06:45.876304+02
2a017820-c102-4383-b1fc-ebe4baf9f846	75cc426b-35bf-4b82-bf2a-582c16e92e93	b64ff13b-0617-456b-9589-257f95ae4fb7	Bien noté, j’apporte environ 80 kg de kola.	2026-10-02 12:06:46.077446+02	2026-10-02 12:06:45.967497+02
a48f3d98-6ed6-4b71-929c-05703e29bf33	732a763f-ae05-499c-834f-5f785d39f339	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Bonjour, votre certification biologique a été validée. Pensez à joindre le certificat signé.	2026-10-02 12:06:46.413566+02	2026-10-02 12:06:46.315411+02
44aba508-aebf-4f9e-9ea2-d92d296d2f61	840b065a-bd81-4aaf-b799-da196446caf3	96c362a7-7215-490a-8443-371d2768cd2e	Bonjour, contrôle de routine prévu à votre magasin de Mouila mardi prochain.	\N	2026-10-02 12:06:46.61506+02
5637ff96-27c7-47be-ac14-dbf5a339d43f	75cc426b-35bf-4b82-bf2a-582c16e92e93	97a54b08-c1ef-46eb-8505-1f31b5cadb80	Je serai présent avec les noisettes de Minkébé.	2026-10-02 12:11:43.429875+02	2026-10-02 12:06:46.057011+02
\.


--
-- TOC entry 6991 (class 0 OID 70309)
-- Dependencies: 282
-- Data for Name: messages_publics; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.messages_publics (id, producteur_id, nom_visiteur, email_visiteur, telephone_visiteur, message, ip_adresse, statut, created_at, traite_at) FROM stdin;
ddd4152a-34ac-48c6-adfc-d35c036d14b2	ad0c1500-c241-4d87-90c6-ac3ec914f53a	Hôtel Le Méridien Libreville (démo)	visiteur.hotel@demo.pfnl.ga	+241011000001	[Annonce Miel sauvage de la Ngounié, 100 kg disponibles] Bonjour, nous souhaitons commander 20 kg de miel par mois. Pouvez-vous nous rappeler ?	\N	NOUVEAU	2026-10-02 12:06:44.39175+02	\N
0c78077e-c7d1-4806-92f4-3b7b7782003b	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	Association Tradipraticiens (démo)	visiteur.asso@demo.pfnl.ga	+241011000002	Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	127.0.0.1	NOUVEAU	2026-10-02 12:06:44.451298+02	\N
cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4	ad0c1500-c241-4d87-90c6-ac3ec914f53a	Épicerie fine Akanda (démo)	visiteur.epicerie@demo.pfnl.ga	\N	Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	127.0.0.1	TRAITE	2026-10-02 12:06:44.547605+02	2026-10-02 12:06:44.626293+02
\.


--
-- TOC entry 6960 (class 0 OID 69743)
-- Dependencies: 245
-- Data for Name: mouvements; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.mouvements (id, lot_id, type_mouvement, date_mouvement, lieu_libelle, latitude, longitude, geom, quantite, unite, acteur_utilisateur_id, acteur_producteur_id, acteur_cooperative_id, destinataire_libelle, commentaire, hash_precedent, hash_courant, client_uuid, sync_statut, sync_version, created_at) FROM stdin;
cdbde0b6-b24d-4e2d-92dc-7118dfc1f21d	cbab41ae-0e5a-4b8e-a556-f0d173ef9f90	COLLECTE	2026-08-10 14:35:58.85693+02	Test	\N	\N	\N	12.500	KG	2992fb5e-5580-483b-9462-98fe46cf7627	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-10 14:35:58.85693+02
7b3e8444-934b-46a8-8d6e-172e6272a08f	07fa0834-2dd8-47b1-a514-176f1f8091a9	COLLECTE	2026-08-13 12:33:15.700519+02	Déclaration initiale	\N	\N	\N	15.000	KG	1051c839-763f-4a10-9f0e-7b64d301a393	5ac66f77-ef10-49e4-962f-9670667460f6	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 12:33:15.700519+02
ebf1caec-ee07-439e-8f15-fe83c117f6dc	a53361f0-d36f-4224-ac8b-b16f89e2ac3e	COLLECTE	2026-08-13 12:33:37.734286+02	Test	\N	\N	\N	12.500	KG	2992fb5e-5580-483b-9462-98fe46cf7627	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 12:33:37.734286+02
0a5037a9-181a-4467-afea-285a5e2ab58d	6c36cf89-bf38-4585-9ed7-6105d09c6834	COLLECTE	2026-08-13 14:51:01.475111+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.475111+02
9314d1d7-f3c0-4ecc-8b82-ceee18bbb65f	f732e990-3a92-4436-bfbe-45dccd6412f3	COLLECTE	2026-08-13 14:51:01.568843+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.568843+02
f4657b9a-8657-43bb-a7fd-0e301ee0052d	eae7ddfb-aa9b-4a85-ad6f-3a1ba0cc1d80	COLLECTE	2026-08-13 14:51:01.62335+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.62335+02
c2ba4bda-834f-42b9-8336-6fb7675f9be0	72bfcb0e-d964-43f7-ace3-9ec798fbc9b5	COLLECTE	2026-08-13 14:51:01.689083+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	87e98748-a24e-4ae5-98cc-8b028986a11a	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.689083+02
71a4ca1f-e50b-4bac-8763-4f75a87f294e	67fe58b6-5032-43e3-87ec-e5288cec9cf4	COLLECTE	2026-08-13 14:51:01.748277+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.748277+02
da6e2790-b967-49a0-bb7a-2153a97c5767	242cb5f0-bf99-4a9e-a8ae-b8482cf56adb	COLLECTE	2026-08-13 14:51:01.937136+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	87e98748-a24e-4ae5-98cc-8b028986a11a	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:01.937136+02
b09d30f0-c97f-4ae3-8c77-cc91b338b514	d25990de-abce-4a33-8532-370a252fe84e	COLLECTE	2026-08-13 14:51:02.17298+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	88f42de2-5646-4008-a283-2539f2e43e21	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:51:02.17298+02
08a18719-4f39-4727-921e-480209ab6f81	36d41a1a-17df-485a-8af8-ca1e89301c1f	COLLECTE	2026-08-13 14:53:14.48187+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.48187+02
0ce076d5-7cf5-4d9e-bbd2-c67a0be53cc2	192b93a8-c496-43ef-8871-16b6c4d86f0c	COLLECTE	2026-08-13 14:53:14.531932+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.531932+02
1d40739e-4b10-48fe-82ac-7e01bfa9217c	680c23ed-0ad7-435c-93c2-0733a4312726	COLLECTE	2026-08-13 14:53:14.558254+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.558254+02
cd86116c-4fad-42bb-9fda-f8b588e5f5b6	e437c0f5-36ad-4a4b-b637-9ae63759035e	COLLECTE	2026-08-13 14:53:14.588787+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	0535f8f6-d738-495c-8ecc-896c1c442a63	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.588787+02
6e08297a-0a75-41f5-a372-d0db9310aca6	73e3c879-2b0a-4679-96f9-e14c889eaa7f	COLLECTE	2026-08-13 14:53:14.626964+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.626964+02
09cd3c9e-1a70-4ce1-a1d0-24468fb4ab1b	7103bd23-00dd-4ad8-9397-73280b333f3f	CONTROLE	2026-08-13 14:53:14.764878+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.764878+02
087eb98b-b513-48d0-89c4-b4d175be40ad	7103bd23-00dd-4ad8-9397-73280b333f3f	CONTROLE	2026-08-13 14:53:14.828898+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.828898+02
b8cc0dd9-79c0-40d0-8a24-a4d8255e8659	7103bd23-00dd-4ad8-9397-73280b333f3f	CONTROLE	2026-08-13 14:53:14.855459+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.855459+02
c0fcd5f8-f5e9-4630-9c0d-333aba834d0a	749e0d73-5539-438c-b82f-cf56e1478664	COLLECTE	2026-08-13 14:53:14.881968+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	0535f8f6-d738-495c-8ecc-896c1c442a63	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.881968+02
cbba6520-d220-45aa-a8bc-52a8ac8d0025	749e0d73-5539-438c-b82f-cf56e1478664	CONTROLE	2026-08-13 14:53:14.936542+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.936542+02
08c2c56f-9b50-428a-ad22-08e0390ca59d	7103bd23-00dd-4ad8-9397-73280b333f3f	CONTROLE	2026-08-13 14:53:14.96274+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:14.96274+02
47c65c4b-6589-4f76-ac1e-ef0d52626135	309a3c6f-8439-4583-be13-0318f7fcaecb	COLLECTE	2026-08-13 14:53:15.140429+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	97421cd2-24d5-4f37-af62-5bac7c43ac0f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:53:15.140429+02
0420e1d3-100b-45cf-a67b-28568a232d3c	39514cfc-0c93-4fe9-b85a-ff3fd8c043d0	COLLECTE	2026-08-13 14:55:10.711928+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:10.711928+02
6b9545d5-ac3e-4857-bbaa-ece65da6bb32	d25c710b-839a-49ec-a011-89b37ef436ec	COLLECTE	2026-08-13 14:55:10.774994+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:10.774994+02
18aaa851-1b96-4d96-a3c2-f91e6b69012c	5c386e69-9870-4b6b-8e27-4d5bf9027da9	COLLECTE	2026-08-13 14:55:10.889901+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:10.889901+02
1acb0fd3-e929-44ce-8ffa-04392d735890	e4b7c78d-8663-4b2a-afb3-71c1c7f3554b	COLLECTE	2026-08-13 14:55:10.962316+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	d8f1ea56-6a02-4de3-9730-47e39a0a1df8	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:10.962316+02
a16cb9e2-5336-4e77-8562-fdc0dd73f494	c3885f84-6a3e-491a-a07e-4e812836b66d	COLLECTE	2026-08-13 14:55:10.996717+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:10.996717+02
97f0b912-772d-46e1-aaba-1baa833a9ebd	87e9b6b2-f1c7-4bec-a267-8b45e8753e25	CONTROLE	2026-08-13 14:55:11.139027+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.139027+02
143f6c6d-ab60-4913-ad5b-a12b9e5c00d8	87e9b6b2-f1c7-4bec-a267-8b45e8753e25	CONTROLE	2026-08-13 14:55:11.199483+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.199483+02
310f2dc1-60e6-4bd8-9eef-b92964b345c4	87e9b6b2-f1c7-4bec-a267-8b45e8753e25	CONTROLE	2026-08-13 14:55:11.225438+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.225438+02
78d25974-52c2-47a3-98aa-d8538ba812af	4c7da43b-544d-42e4-ae01-70caa3905819	COLLECTE	2026-08-13 14:55:11.25138+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	d8f1ea56-6a02-4de3-9730-47e39a0a1df8	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.25138+02
2573f924-f9df-4744-b163-dff303636d80	4c7da43b-544d-42e4-ae01-70caa3905819	CONTROLE	2026-08-13 14:55:11.299997+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.299997+02
f5e33e4f-2e89-457d-8e88-f6c143b36707	87e9b6b2-f1c7-4bec-a267-8b45e8753e25	CONTROLE	2026-08-13 14:55:11.321965+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.321965+02
75703c59-01ba-4d5f-86d4-680982042c13	16649b4b-0929-45d1-b830-ae486e38be3d	COLLECTE	2026-08-13 14:55:11.506018+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	5226f554-ac72-4d29-ab0a-64d8be484a1c	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:55:11.506018+02
cd5d9c72-7afe-4a03-98b4-221dfc8a7576	e9ba15d9-eea2-4474-90bb-3162bdf3674c	COLLECTE	2026-08-13 14:56:18.532632+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.532632+02
5fa046bb-b004-4107-8ca2-4df0ea5e27a8	cfeb7bb7-ccfb-48e3-839a-969001365b45	COLLECTE	2026-08-13 14:56:18.617641+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.617641+02
90a8e92a-dd33-4869-885c-7b018aaf66a0	c856c8fd-10cb-4128-86d2-a4517631f039	COLLECTE	2026-08-13 14:56:18.658387+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.658387+02
a70ed359-25d2-405a-b994-9bab38043c0a	abef08e3-bf40-451b-a860-45bd366eee32	COLLECTE	2026-08-13 14:56:18.702077+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	ceef2c73-0866-4ade-b4e5-40029ee9236d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.702077+02
94b3b14d-32cb-4fb5-a5ea-a417b405aeba	ea1b6189-2a4d-42c6-9410-bc59b3357468	COLLECTE	2026-08-13 14:56:18.743023+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.743023+02
fe45dfbf-b34f-4a23-9496-d479a20654ca	4f532bb7-3727-41c4-b823-f79d20943430	CONTROLE	2026-08-13 14:56:18.909193+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.909193+02
eb3665f0-9a02-4a39-b872-6bdf104394ff	4f532bb7-3727-41c4-b823-f79d20943430	CONTROLE	2026-08-13 14:56:18.930117+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.930117+02
eb344933-0e65-48fc-8e70-508030fb0528	4f532bb7-3727-41c4-b823-f79d20943430	CONTROLE	2026-08-13 14:56:18.955483+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.955483+02
d6e8d6a4-01e6-4152-b77a-6bfe4ce34405	e77b0d44-e40f-47da-9436-338e24f4948a	COLLECTE	2026-08-13 14:56:18.978088+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	ceef2c73-0866-4ade-b4e5-40029ee9236d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:18.978088+02
8a74a62c-bd8c-4992-9019-bbebad085d40	e77b0d44-e40f-47da-9436-338e24f4948a	CONTROLE	2026-08-13 14:56:19.025888+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:19.025888+02
140439a6-5ec8-41a5-a8d1-a4560ca427f3	4f532bb7-3727-41c4-b823-f79d20943430	CONTROLE	2026-08-13 14:56:19.048394+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:19.048394+02
6db7ea73-940b-415f-a47a-a84dde320f1d	78492e02-c603-48c0-a488-8579d43e616f	COLLECTE	2026-08-13 14:56:19.256217+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	3c82ea68-8f13-404d-85be-4333679fb1c2	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:19.256217+02
525b68c5-94ed-4bfd-bf18-2efff9fce975	ebf56ae8-e877-45ee-b444-620ca79df018	COLLECTE	2026-08-13 14:56:31.868661+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:31.868661+02
ada48d48-f1b0-479d-934e-8dc31d401206	5f2fc59a-b2d2-4d4e-9db6-3a36ea46c34c	COLLECTE	2026-08-13 14:56:31.961356+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:31.961356+02
60cf8ad4-1177-45ce-aa4d-9fe46232f2f0	6e99d951-70c9-46f1-8d40-388b6fbb8126	COLLECTE	2026-08-13 14:56:32.02866+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.02866+02
905eab16-dff6-42aa-b52b-343c756fb785	5a335163-11c9-41ce-a66b-504d08c9f909	COLLECTE	2026-08-13 14:56:32.085475+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	1c012791-98f7-4b5e-81b7-5e553492aedf	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.085475+02
0ceabd61-45a2-483c-983a-f5b469e61093	cf6f989a-98d0-4682-948c-5538447e4b4b	COLLECTE	2026-08-13 14:56:32.154129+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.154129+02
a77cf50d-ecaf-4428-a9c4-a25736a01107	226d5a29-c768-4283-9510-c0ee09ab6ad0	CONTROLE	2026-08-13 14:56:32.334085+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.334085+02
ea214649-adef-4838-ba89-ea9dcb22d738	226d5a29-c768-4283-9510-c0ee09ab6ad0	CONTROLE	2026-08-13 14:56:32.394393+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.394393+02
7e9a1b0b-fc2a-490c-96fa-c27df74486be	226d5a29-c768-4283-9510-c0ee09ab6ad0	CONTROLE	2026-08-13 14:56:32.430242+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.430242+02
c2521278-932f-4291-b2e9-8b7f41c68e23	3dd1ba95-ac23-4045-902a-95a261153c17	COLLECTE	2026-08-13 14:56:32.466068+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	1c012791-98f7-4b5e-81b7-5e553492aedf	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.466068+02
3c378b20-bd67-4bdf-907f-ed7b0d55c7c3	3dd1ba95-ac23-4045-902a-95a261153c17	CONTROLE	2026-08-13 14:56:32.519964+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.519964+02
aba4f61c-c11a-4bf0-baa1-4ad3476f5692	226d5a29-c768-4283-9510-c0ee09ab6ad0	CONTROLE	2026-08-13 14:56:32.542053+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.542053+02
adaa7164-a9c5-4a1c-9e8b-49d6f736d85e	23726099-ba5f-4900-8824-9d5ac5f2d8ee	COLLECTE	2026-08-13 14:56:32.730838+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	143ffb3e-853a-41d9-9c65-ec683695769d	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 14:56:32.730838+02
9ab05227-ad0a-47ee-88ac-8b04f91476bc	0c0106ee-1b58-4b85-8ddd-cea26904d0ff	COLLECTE	2026-08-13 15:18:59.588489+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:18:59.588489+02
b7f8d0c8-9843-486b-8f8a-5a8bc8db316d	88181504-eb0e-4036-a6ef-bc43be5beed6	COLLECTE	2026-08-13 15:19:00.241698+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.241698+02
97686e44-53e0-476b-87d7-23e8a88f19e8	18a8c9f8-e0fb-4053-877f-023e68359da7	COLLECTE	2026-08-13 15:19:00.309502+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.309502+02
acc969e0-a242-442d-9719-6f8bcbfa526b	954bede4-567a-480a-a715-58c0b6a9828c	COLLECTE	2026-08-13 15:19:00.39057+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	21780bdf-be5a-4eb5-866b-eb89d96ccdf1	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.39057+02
57108792-368c-492c-b531-4c245bba9653	4af77ba1-b515-42e3-8156-d299733b266e	COLLECTE	2026-08-13 15:19:00.447724+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.447724+02
fcc27a16-1f00-4beb-a817-d1741cb93708	4761a2cc-ed5d-495c-99b0-370a8abdfc2d	CONTROLE	2026-08-13 15:19:00.623133+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.623133+02
abd43669-04be-4b20-aac7-3b03f9ca080a	4761a2cc-ed5d-495c-99b0-370a8abdfc2d	CONTROLE	2026-08-13 15:19:00.677244+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.677244+02
7bdfb5a6-6e30-4277-9344-6d5d174c1e5f	4761a2cc-ed5d-495c-99b0-370a8abdfc2d	CONTROLE	2026-08-13 15:19:00.69408+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.69408+02
4bfdc60f-47a9-42d2-8626-9b14bacc9211	81593e4f-57a1-451b-a030-c09baeb0a38e	COLLECTE	2026-08-13 15:19:00.707977+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	21780bdf-be5a-4eb5-866b-eb89d96ccdf1	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.707977+02
e1ade27d-4116-46b9-b395-4834c4c692e5	81593e4f-57a1-451b-a030-c09baeb0a38e	CONTROLE	2026-08-13 15:19:00.751805+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.751805+02
965269ce-3ed4-4fa1-aec3-f4a872697425	4761a2cc-ed5d-495c-99b0-370a8abdfc2d	CONTROLE	2026-08-13 15:19:00.770128+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.770128+02
1faf61a9-b587-43db-9d3b-a815f8598b80	87057364-ce8b-4dc3-8c87-658c8b4de90e	COLLECTE	2026-08-13 15:19:00.977958+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	cf858f2d-3082-4e46-9c17-daeeed5b03fa	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 15:19:00.977958+02
f4d66ec3-61dc-4fbc-9595-5676f0803954	30907e00-b121-4760-a042-f7d351b0fbf9	COLLECTE	2026-08-13 20:53:18.572138+02	Déclaration initiale	\N	\N	\N	25.000	KG	2992fb5e-5580-483b-9462-98fe46cf7627	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 20:53:18.572138+02
2c73cd65-aeed-4e78-acc9-16c06f68d2df	efa5499c-ebdd-48a9-8771-748225ebc2c8	COLLECTE	2026-08-13 20:54:21.231584+02	Déclaration initiale	\N	\N	\N	25.000	KG	2992fb5e-5580-483b-9462-98fe46cf7627	30670990-06f1-4b0e-9990-de341ba5cf42	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-13 20:54:21.231584+02
bc9e0d57-c297-4269-a61b-1d6f104e23a4	896264b6-573a-4c65-9b7e-c8ca34c2bd2e	COLLECTE	2026-08-15 16:48:13.264106+02	Déclaration initiale	\N	\N	\N	200.000	SAC	ec38d815-0579-448c-b7dd-1c54b8dce005	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 16:48:13.264106+02
008c785d-54fd-4e73-bcc6-872bee7a3edf	bdc4005d-08ee-4a9f-be9f-cd666e715270	COLLECTE	2026-08-15 17:43:31.186964+02	Déclaration initiale	\N	\N	\N	12.500	KG	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	9027c481-fbc6-4681-8612-1800eb5d6bf0	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 17:43:31.186964+02
739c22a9-3a80-4b93-86f2-6e3fd73be398	c2367dcb-a765-4713-beb5-e5dafbfd8501	COLLECTE	2026-08-15 17:44:01.285136+02	Déclaration initiale	\N	\N	\N	12.500	KG	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	c72db6b0-beec-4785-82c0-c5d84e40dc7e	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 17:44:01.285136+02
488bd79c-7179-4789-8693-28a217315beb	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	COLLECTE	2026-08-15 17:44:35.468468+02	Déclaration initiale	\N	\N	\N	12.500	KG	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	117d4a3b-7814-452a-b8f8-f55a483b1cd4	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 17:44:35.468468+02
615a71d9-d0cf-4a7d-9d03-266edbd5d7d1	e16b7be4-1d09-426d-a064-9dc93c2b3c97	COLLECTE	2026-08-15 18:11:58.555353+02	Déclaration initiale	\N	\N	\N	2.000	LITRE	ec38d815-0579-448c-b7dd-1c54b8dce005	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 18:11:58.555353+02
254488c4-bbc6-49fe-a920-e192136bd06a	06dea582-3d6a-4dfa-8e38-8bd4ca7bf681	COLLECTE	2026-08-15 18:29:27.664695+02	Déclaration initiale	\N	\N	\N	266.000	KG	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	fea18beb-ff84-406b-a45b-6edc5d1cc489	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-15 18:29:27.664695+02
a2a13a32-18ac-4a54-aaf8-c543c0eeccd2	9a398c12-bf2f-4fcf-b6b4-1590d65708ff	COLLECTE	2026-08-19 11:47:57.282583+02	Déclaration initiale	0.5500000	11.6600000	\N	1.000	KG	ec38d815-0579-448c-b7dd-1c54b8dce005	eb2c74d5-1101-4af8-8797-9bbaaf3b8043	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 11:47:57.282583+02
ab6c3e62-b349-42dc-94f3-c47ea71fe506	dfde6062-15c1-4238-b853-6e1e40969f74	COLLECTE	2026-08-19 12:21:49.096465+02	Déclaration initiale	\N	\N	\N	1.500	KG	1a62a7d6-150a-4243-8056-3025dab6cbf7	6fbdace5-2e31-4c07-b980-9fb13a618ea5	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:21:49.096465+02
a38d6b98-15f9-4ea3-9b2d-0d0efb048621	b41386d7-ef39-4e9d-8854-f23c1a9137ac	COLLECTE	2026-08-19 12:40:20.344974+02	Déclaration initiale	\N	\N	\N	1.500	KG	1a62a7d6-150a-4243-8056-3025dab6cbf7	06efa363-7347-4d12-b162-e932a0425b60	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:20.344974+02
7ab0bd79-a4d7-4e16-953b-039f98f1582c	2d43927b-1ef1-4179-802c-38e2ec495ae3	COLLECTE	2026-08-19 12:40:47.944568+02	Déclaration initiale	\N	\N	\N	3.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:47.944568+02
acb80b4d-ea12-45ad-9e94-fe5e91846ec3	ca95422f-ebbe-43a4-b199-6a2075afe0af	COLLECTE	2026-08-19 12:40:48.047763+02	Déclaration initiale	\N	\N	\N	3.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.047763+02
cf263150-57e5-48a0-9137-471df5fd0005	2b3c8331-3445-44be-b861-a6df69c126a6	COLLECTE	2026-08-19 12:40:48.073652+02	Déclaration initiale	\N	\N	\N	3.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.073652+02
0eaf9661-ee4f-45ca-a8f2-9e13032df9ac	fe29adac-04cb-47d3-bd9d-73f3ed3649d8	COLLECTE	2026-08-19 12:40:48.10244+02	Déclaration initiale	\N	\N	\N	3.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	05829c24-382b-4e30-9633-12241b7f2f97	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.10244+02
c54c4ec6-6316-4e13-ad53-838a4a87e10a	50fce242-90c5-4af3-8349-4907f9649a1c	COLLECTE	2026-08-19 12:40:48.130987+02	Déclaration initiale	\N	\N	\N	3.000	KG	24cddb38-0a57-4661-928b-f97aba310218	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.130987+02
10bf0f46-24f2-4c43-992f-be42be715dbb	179de271-fbbf-497b-92f5-427374f71075	CONTROLE	2026-08-19 12:40:48.227346+02	Test admin	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.227346+02
60ae3428-045f-48b8-8ec8-f7be78336489	179de271-fbbf-497b-92f5-427374f71075	CONTROLE	2026-08-19 12:40:48.238804+02	Test agent_min	\N	\N	\N	1.000	KG	c324981c-2d16-41ee-9121-e21aa9c93565	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.238804+02
00d8e30b-0795-4d8e-97b6-390f462c6661	179de271-fbbf-497b-92f5-427374f71075	CONTROLE	2026-08-19 12:40:48.245558+02	Test agent_for	\N	\N	\N	1.000	KG	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.245558+02
95f4cd40-4a8b-4b32-9472-5c3ae6aa568d	e2c90d83-967e-41e4-ad3d-aebf4e922897	COLLECTE	2026-08-19 12:40:48.253178+02	Déclaration initiale	\N	\N	\N	2.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	05829c24-382b-4e30-9633-12241b7f2f97	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.253178+02
73606a7f-9919-4a3a-af19-87c4e15531be	e2c90d83-967e-41e4-ad3d-aebf4e922897	CONTROLE	2026-08-19 12:40:48.277451+02	Test producteur	\N	\N	\N	1.000	KG	41f20506-4b04-4203-900c-5c52ab3209bf	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.277451+02
a264e847-aa22-4d6b-8332-0e27ef5ecc2b	179de271-fbbf-497b-92f5-427374f71075	CONTROLE	2026-08-19 12:40:48.298416+02	Test cooperative	\N	\N	\N	1.000	KG	24cddb38-0a57-4661-928b-f97aba310218	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.298416+02
18fb5600-d0e0-4975-aed8-06125cce3b38	53532fa4-2495-4bb7-ad57-c0b842d1d0ca	COLLECTE	2026-08-19 12:40:48.387675+02	Déclaration initiale	\N	\N	\N	1.000	KG	867247ca-c7cd-4240-a26d-184312b3fcc8	2b8c129b-fb77-4744-9ccf-a172c4e7431f	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 12:40:48.387675+02
ca024ca2-7e41-4369-b8af-66cc9dc598a4	61d7ebae-83cb-44fc-b34d-f3a484d95ff3	COLLECTE	2026-08-19 13:09:49.354664+02	Déclaration initiale	\N	\N	\N	1.500	KG	1a62a7d6-150a-4243-8056-3025dab6cbf7	bde9fe4e-d2cf-49b5-b40e-eff49b384b72	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 13:09:49.354664+02
311ab20c-a728-4f84-930b-6f117a514418	0db80fe5-1427-4a01-8be9-183de8232ae9	COLLECTE	2026-08-19 13:10:31.919272+02	Déclaration initiale	\N	\N	\N	1.500	KG	1a62a7d6-150a-4243-8056-3025dab6cbf7	4f34afb3-9c20-4e22-b443-ce5b4d50f7df	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-19 13:10:31.919272+02
2904780d-af65-4970-acdd-8e6612cee71b	896264b6-573a-4c65-9b7e-c8ca34c2bd2e	VENTE	2026-08-21 17:06:00+02	\N	\N	\N	\N	\N	\N	ec38d815-0579-448c-b7dd-1c54b8dce005	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-21 19:07:16.522562+02
876c482d-4d68-4806-806f-ddbe234343ce	06dea582-3d6a-4dfa-8e38-8bd4ca7bf681	VENTE	2026-08-21 17:08:00+02	\N	\N	\N	\N	\N	\N	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-08-21 19:08:35.411781+02
4f30f89c-610a-456e-b23e-7e0fa928b2ff	fd945c4c-725a-4f72-af41-ff2d89df112d	COLLECTE	2026-10-02 12:06:36.504492+02	Ruchers forestiers de Fougamou	-1.2100000	10.6000000	\N	120.000	KG	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	ad0c1500-c241-4d87-90c6-ac3ec914f53a	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.504492+02
d5e168f7-6598-4324-89c2-5a166ac82bc3	18e903a7-62a8-4f15-95ac-613f516a3013	COLLECTE	2026-10-02 12:06:36.594816+02	Massif de Waka, abords de Mouila	-1.7500000	11.1500000	\N	15.000	KG	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	ad0c1500-c241-4d87-90c6-ac3ec914f53a	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.594816+02
0665fe31-a3fe-49c0-8ee2-5f6c03babd4d	2c9fe26c-95eb-4b84-80eb-93bc10b3d187	COLLECTE	2026-10-02 12:06:36.692982+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	300.000	KG	b64ff13b-0617-456b-9589-257f95ae4fb7	efddd969-6c0b-49f0-9204-5c846f4f7bba	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.692982+02
d25fcde1-9e54-4f3c-a3de-58684e84ab04	8242374c-f334-4e11-afd4-e5504950b786	COLLECTE	2026-10-02 12:06:36.744773+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	80.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	32b71cac-11e7-4f9e-a7e9-b909b42a7154	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.744773+02
65aac613-d100-479b-b6e0-c2fcaa447215	a1aa93bc-20b7-457b-b07f-59c3b4655558	COLLECTE	2026-10-02 12:06:36.806655+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	40.000	KG	97a54b08-c1ef-46eb-8505-1f31b5cadb80	32b71cac-11e7-4f9e-a7e9-b909b42a7154	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.806655+02
69aa5e90-ccb1-4914-9107-169fb6b0102c	ff635715-df72-42e1-ada5-496a2f16d668	COLLECTE	2026-10-02 12:06:36.875413+02	Déclaration initiale	\N	\N	\N	200.000	KG	5dfd8155-3222-4e05-9702-06e9cc47cca1	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.875413+02
d3eadb8d-9974-4bda-9517-ca677d05ac9e	b76576f5-5a0c-4adc-941d-8f5d584033e7	COLLECTE	2026-10-02 12:06:36.942521+02	Déclaration initiale	\N	\N	\N	50.000	KG	5dfd8155-3222-4e05-9702-06e9cc47cca1	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:36.942521+02
41c54d5a-a57d-4787-be47-6e646581ca30	67381035-8c17-475b-a555-6a929aca6db1	COLLECTE	2026-10-02 12:06:37.021469+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	10.000	KG	b64ff13b-0617-456b-9589-257f95ae4fb7	efddd969-6c0b-49f0-9204-5c846f4f7bba	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.021469+02
275be496-ef80-43af-a810-ac58b5214283	134f6a3d-20da-4ae3-b853-002795421487	COLLECTE	2026-10-02 12:06:37.090166+02	Lopé, lisière forêt-savane	-0.2000000	11.6000000	\N	25.000	KG	96c362a7-7215-490a-8443-371d2768cd2e	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.090166+02
88d84455-9660-4ef2-95ee-68998e25f7ac	eb80791e-3f0c-4ba9-a30b-c0176a9c2aec	COLLECTE	2026-10-02 12:06:37.175468+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	60.000	LITRE	96c362a7-7215-490a-8443-371d2768cd2e	b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.175468+02
c2f67843-84c8-4cab-83d2-57445a9727e2	08480520-7787-45e4-afbd-db51aff36d80	COLLECTE	2026-10-02 12:06:37.265857+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	60.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	ffd2f32f-0ed0-48ec-a502-f250ca779820	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.265857+02
cce36abb-1113-4a3f-a3a4-04eec650a462	12b57849-fa7e-42ed-8fb7-cb5004a3ec2d	COLLECTE	2026-10-02 12:06:37.365217+02	Massif de Waka, abords de Mouila	-1.7500000	11.1500000	\N	150.000	BOTTE	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	ad0c1500-c241-4d87-90c6-ac3ec914f53a	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.365217+02
fbb999f6-313d-4eca-90fe-d5596b4c764c	f455fe71-7ef8-44e9-bdc8-e8a8d790e336	COLLECTE	2026-10-02 12:06:37.454799+02	Forêt de Minkébé, secteur de Makokou	0.6100000	12.7300000	\N	18.000	KG	97a54b08-c1ef-46eb-8505-1f31b5cadb80	32b71cac-11e7-4f9e-a7e9-b909b42a7154	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.454799+02
b6673d26-2356-4d59-97fc-ae83803bc1db	fd945c4c-725a-4f72-af41-ff2d89df112d	RECEPTION_COOPERATIVE	2026-10-02 12:06:37.570275+02	Magasin de la coopérative, Mouila	\N	\N	\N	120.000	KG	1f279d86-485b-4a3b-b0c5-3bfc813473b6	\N	\N	\N	Pesée et contrôle visuel conformes.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.570275+02
43fa8e04-0f4f-4f63-b270-444fb30a06f9	fd945c4c-725a-4f72-af41-ff2d89df112d	TRANSFERT	2026-10-02 12:06:37.611033+02	Mouila vers Owendo (RN1)	\N	\N	\N	120.000	KG	1f279d86-485b-4a3b-b0c5-3bfc813473b6	\N	\N	Entrepôt Gabon Export Bio, Owendo	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.611033+02
1acafd37-153f-42ec-b153-84c47bd81e8a	fd945c4c-725a-4f72-af41-ff2d89df112d	VENTE	2026-10-02 12:06:37.652931+02	Owendo	\N	\N	\N	120.000	KG	1f279d86-485b-4a3b-b0c5-3bfc813473b6	\N	\N	Société Gabon Export Bio	Facture DEMO-FV-0012.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.652931+02
165b994b-44f4-4afc-a27a-bbb9a87dbe6b	18e903a7-62a8-4f15-95ac-613f516a3013	CONTROLE	2026-10-02 12:06:37.690658+02	Poste forestier de Mouila	\N	\N	\N	15.000	KG	96c362a7-7215-490a-8443-371d2768cd2e	\N	\N	\N	Contrôle de conformité : RAS.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.690658+02
8c57da53-d411-4560-be98-629e8c4b1503	2c9fe26c-95eb-4b84-80eb-93bc10b3d187	RECEPTION_COOPERATIVE	2026-10-02 12:06:37.731589+02	Magasin de la coopérative, Makokou	\N	\N	\N	300.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.731589+02
d7d97573-5e23-4356-89be-6f5397873264	2c9fe26c-95eb-4b84-80eb-93bc10b3d187	TRANSFORMATION	2026-10-02 12:06:37.771262+02	Atelier de séchage, Makokou	\N	\N	\N	300.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	\N	Séchage, tri et calibrage.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.771262+02
3f2e4511-041a-4bf2-bd7f-b9bfe01d86a5	a1aa93bc-20b7-457b-b07f-59c3b4655558	TRANSFERT	2026-10-02 12:06:37.815436+02	Makokou vers Libreville	\N	\N	\N	40.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	Transitaire agréé, Libreville	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.815436+02
60f3c543-c9eb-4475-a3d7-486c99be5934	a1aa93bc-20b7-457b-b07f-59c3b4655558	EXPORT	2026-10-02 12:06:37.857586+02	Port d’Owendo	\N	\N	\N	40.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	Client export, Douala (Cameroun)	Certificat phytosanitaire DEMO-PHY-221.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.857586+02
633e7423-4f76-4f16-8b0d-caa0b88c410d	ff635715-df72-42e1-ada5-496a2f16d668	CONTROLE	2026-10-02 12:06:37.894097+02	Brigade forestière d’Oyem	\N	\N	\N	200.000	KG	96c362a7-7215-490a-8443-371d2768cd2e	\N	\N	\N	Contrôle qualité et origine validés.	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.894097+02
7b55de83-259e-4219-9da2-2dad02a67ca1	eb80791e-3f0c-4ba9-a30b-c0176a9c2aec	TRANSFERT	2026-10-02 12:06:37.932745+02	Makokou vers Franceville	\N	\N	\N	60.000	LITRE	96c362a7-7215-490a-8443-371d2768cd2e	\N	\N	Huilerie artisanale, Franceville	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.932745+02
026709c9-b6c7-4a4a-8fb5-f92b8d1da10e	f455fe71-7ef8-44e9-bdc8-e8a8d790e336	RECEPTION_COOPERATIVE	2026-10-02 12:06:37.974936+02	Magasin de la coopérative, Makokou	\N	\N	\N	18.000	KG	ec677a07-a583-40fd-9a61-370807755ac1	\N	\N	\N	\N	\N	\N	\N	SYNCED	1	2026-10-02 12:06:37.974936+02
\.


--
-- TOC entry 6967 (class 0 OID 69955)
-- Dependencies: 252
-- Data for Name: notifications; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.notifications (id, destinataire_id, type_notif, titre, corps, lue, envoyee_at, erreur_envoi, metadata, created_at) FROM stdin;
c20f56c6-c203-4ed6-9b23-bc3b334dfd9e	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.78397+02
7796026d-7554-4575-b855-65d2e56fcf33	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Jean-Baptiste NDONG,\n\nNous avons bien reçu votre demande d'inscription en tant que producteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:27.097582+02	\N	{}	2026-10-02 12:06:27.097591+02
1307206d-9c06-4831-b41a-33019daf2cb2	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:27.109633+02
0bb6fab3-5e28-4d1a-b92e-e98ef584cf84	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.112531+02
2cb8c667-ece3-4fd7-bdb5-db136a683d34	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.113469+02
73116873-cf1a-42fd-9abb-a8d596133cb3	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.115763+02
e0e8b5d1-e091-4d91-ab9f-240a5838ef6b	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.11632+02
574d4b02-e2f7-43c0-9c8f-34ae2c0316fc	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.116761+02
dd5af9fb-b015-4d0b-b77f-33d7d4631e80	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.117131+02
bb03c35c-c00a-42f9-9167-c314033d9570	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.117454+02
c6d55ba1-450c-4269-b655-c1f4b35fe8a9	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Jean-Baptiste NDONG (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a"}	2026-10-02 12:06:27.117845+02
b0cef0b5-baad-4b63-aa85-36478c444f5a	b64ff13b-0617-456b-9589-257f95ae4fb7	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Marie-Claire MOUSSAVOU,\n\nNous avons bien reçu votre demande d'inscription en tant que producteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:27.419474+02	\N	{}	2026-10-02 12:06:27.419475+02
deaa6777-0f22-40d0-9780-ef5c13d04efa	b64ff13b-0617-456b-9589-257f95ae4fb7	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:27.420681+02
c731bd05-32de-4443-b80d-e4f717f0e1e7	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.42321+02
5c3b16bd-9013-461a-88ea-477067ca12f0	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.423667+02
7c969f06-d64a-4f46-8e8a-2c73ad5b79b7	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.424071+02
6774408e-f108-4af7-8513-5d789b50cb59	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.424389+02
a6f38477-eb77-4d6a-a300-2a2fcf4ad91c	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.424678+02
127bc7b9-f365-4331-9e74-a4b7717daa8b	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.424957+02
56a5f10e-f3b0-4c21-b9e6-c850eb27f13f	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.425233+02
6dd5f1b6-8469-42eb-8a62-ff0b8e325eaf	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Marie-Claire MOUSSAVOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "efddd969-6c0b-49f0-9204-5c846f4f7bba"}	2026-10-02 12:06:27.425525+02
ae204ab0-d36c-46a7-abb2-51303cd8162e	97a54b08-c1ef-46eb-8505-1f31b5cadb80	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Paul OBIANG,\n\nNous avons bien reçu votre demande d'inscription en tant que collecteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:27.779328+02	\N	{}	2026-10-02 12:06:27.779332+02
b6b7db1c-23ae-47e8-825f-7e4bd675aaac	97a54b08-c1ef-46eb-8505-1f31b5cadb80	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:27.780762+02
71b2d385-a6ad-4a4f-b30a-aed04f58fb1a	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.782975+02
2b3884a6-8a91-459b-8b4f-ee4b28a074c7	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.783514+02
047a856b-3dfb-45cb-83e0-45d8b85ebfc8	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.784401+02
104f0351-f712-46b1-a8ef-88665f278595	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.78487+02
32350400-0a14-4246-9c42-453a189c992c	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.785202+02
e08a0a24-a4c3-4e41-b109-f41e1ebb884a	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.785516+02
1a4ed9bd-9d46-46de-bf37-46eebd172ec0	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Paul OBIANG (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "32b71cac-11e7-4f9e-a7e9-b909b42a7154"}	2026-10-02 12:06:27.78639+02
8752f03f-9d63-47fa-ac6f-e9b70845ae19	5dfd8155-3222-4e05-9702-06e9cc47cca1	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Sylvie MBOUMBA,\n\nNous avons bien reçu votre demande d'inscription en tant que producteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:28.13564+02	\N	{}	2026-10-02 12:06:28.135641+02
3a40b894-af72-4f61-95d7-892fe8ed0c3a	5dfd8155-3222-4e05-9702-06e9cc47cca1	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:28.136254+02
23ad0ebd-699c-4e6a-977a-6aaeb64037c0	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.139345+02
bd838fe6-8873-415f-87b1-4d4d548d1728	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.140019+02
c8ec7207-47c7-4b0e-ae53-911736ea32c8	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.140521+02
81b552d2-db81-4490-8da1-23b198024d1f	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.140968+02
aeafbfe0-05d2-436c-b12c-d04447faf3df	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.141303+02
d3013e4a-2fd1-4ed6-ac74-76015a4fffd9	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.141611+02
5088c215-0e3b-4757-9b8d-ba0dd44ec740	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.141899+02
a9e1317f-0037-4b77-8d05-948fdf1817a8	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Sylvie MBOUMBA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "34cc9c4d-801a-4e72-9ff8-2e673be01804"}	2026-10-02 12:06:28.142172+02
614c4034-2f4f-49bd-8efb-8bd6e37ace26	1d6791e9-3b17-4369-9041-924118ba2d22	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Fabrice NGUEMA,\n\nNous avons bien reçu votre demande d'inscription en tant que producteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:28.481539+02	\N	{}	2026-10-02 12:06:28.481542+02
908024fe-a087-472e-9af3-7d82ce84c876	1d6791e9-3b17-4369-9041-924118ba2d22	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:28.482545+02
c91d2291-a0b9-4e37-8094-4156837f194f	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.48438+02
5c98c2aa-c290-4b13-a7ea-0df380728114	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.484997+02
a24eb799-e6e8-4c1d-abfc-26002d255d55	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.485488+02
8b5616ee-7125-4a22-ad70-50c36dfa3787	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.48606+02
b09cea4a-fd8c-4b27-bddf-36ccc228c870	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.486568+02
400bb0a1-81af-4c4e-bba9-6d250be56cf6	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.487303+02
2d05e37b-f7d2-4b43-950c-82596bbec128	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.488104+02
2676d0fe-96c9-43c0-b025-db13b1fa6c4e	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Fabrice NGUEMA (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "8d14134e-2de3-49e6-bc73-9e18699258a1"}	2026-10-02 12:06:28.488633+02
30658633-2339-4367-9c94-4c7a22a0e98e	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.925322+02
59de0636-5999-4ad2-a948-b3ba16dff963	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.92627+02
fc8d6a67-d75f-42c7-99fe-5ead8f0de322	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.926708+02
8893ba8a-af29-4a1f-acbe-0e6c061caa48	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.927127+02
d3bdfa73-f1ad-48b5-9c59-2e6eef6a487a	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.92761+02
6867aea8-bf3a-438c-8fa9-687881270647	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.928241+02
aba30f11-08ee-4a45-bb54-005fa282d4a8	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.929163+02
07335ee2-ae47-45d2-933d-793660e3cb6f	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Arnaud BOUSSOUGOU (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "5acc6d02-db6c-4886-80f7-2344e223ec3f"}	2026-10-02 12:06:28.93022+02
d2dd45b7-f56b-4860-ad5c-9ff36c30a167	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Christelle MAPANGOU,\n\nNous avons bien reçu votre demande d'inscription en tant que collecteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:29.491035+02	\N	{}	2026-10-02 12:06:29.491037+02
2cc4f720-6e3d-41cf-9a78-597b851a6304	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:29.492109+02
2090b239-ae79-4b0b-b837-a6c5432c946b	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.494103+02
da8b24e4-9487-4097-a20a-88cd32048b27	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.494585+02
5198a456-3552-449a-8a1d-a8dbdb3fdbb9	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.495771+02
f4a6d6b8-deaf-4590-8ed4-d96d23ee1324	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.496643+02
4f53bde2-9c13-4a36-81db-eb60d16b2f19	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.497478+02
384e6c38-bb2b-4eca-8e51-d70b072a831b	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.498202+02
c56e7e32-386d-402b-aa4b-fa44c43ba6b1	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.498792+02
645ecf7e-1af2-42db-8314-c826f0d36541	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Christelle MAPANGOU (collecteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "47d0baea-0308-4618-ac9a-dcb5319e4d26"}	2026-10-02 12:06:29.499381+02
1ebe6a59-3aa9-49d0-bde8-cc45611f08ad	aac56367-b288-4ac9-8b81-d1c202be4ef8	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Ghislain IKAPI,\n\nNous avons bien reçu votre demande d'inscription en tant que producteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:30.062671+02	\N	{}	2026-10-02 12:06:30.062674+02
61f10eee-4cc0-4367-8c0f-92d2c13e86ad	aac56367-b288-4ac9-8b81-d1c202be4ef8	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:30.064655+02
5c502729-e1ff-4ad1-9813-c11dd446592d	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.068019+02
75140bc0-442a-4d3e-9fd3-78082627f2ac	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.068646+02
cd1d455f-13df-418d-9a42-e9f0a1a247e1	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.069291+02
645c900c-13e9-4061-a39c-7b1f8b30f31b	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.069794+02
3d596a95-6926-4b91-ad8f-f78c586688b7	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.070541+02
3d63eac3-20e3-44b5-8c06-cfb050acd2ed	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.071212+02
80f56068-e9b0-474f-8307-ea88b96839a3	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.072072+02
f7ea35f3-64a6-49af-917d-1e279397d2b9	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Ghislain IKAPI (producteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "producteurs", "enregistrement_id": "c6c3eee1-a671-4e21-8c35-b792af24efc6"}	2026-10-02 12:06:30.073007+02
50e320a4-2fcf-4c2c-9170-5d1bc19474ec	ec677a07-a583-40fd-9a61-370807755ac1	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Coopérative Coopérative des Saveurs de l’Ivindo,\n\nNous avons bien reçu votre demande d'inscription en tant que coopérative sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:30.770734+02	\N	{}	2026-10-02 12:06:30.770741+02
df11ac22-bd1b-4806-822e-b4cebafdafb3	ec677a07-a583-40fd-9a61-370807755ac1	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:30.774455+02
2eded4b8-6c16-4df5-9100-754d9017ff68	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.781134+02
0a27476b-a43c-4641-925e-d16b88941c8e	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.783685+02
8542365d-91eb-416f-b812-b4abdd21200d	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.785274+02
1591978a-a081-46d9-875b-463fd0882fc1	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.786381+02
76809507-9bfc-4b5f-85fa-46be4c8040c9	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.791827+02
6c80448a-a4c8-438d-916e-4a47bc063278	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.793937+02
0d7d93f9-f29c-4297-bbeb-0cd989a68926	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.795509+02
40ee7b64-4781-418c-b6b5-67e9d535d8c4	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Saveurs de l’Ivindo (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "17c571aa-c973-4da4-abe2-59fc08b7ded2"}	2026-10-02 12:06:30.797224+02
13664afe-939a-4c3a-a18a-b60c6e371bb9	1f279d86-485b-4a3b-b0c5-3bfc813473b6	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Coopérative Coopérative Miel et Forêt de la Ngounié,\n\nNous avons bien reçu votre demande d'inscription en tant que coopérative sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:31.577103+02	\N	{}	2026-10-02 12:06:31.577107+02
9ff9f508-2c93-4d36-b838-dc88122833e7	1f279d86-485b-4a3b-b0c5-3bfc813473b6	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:31.579693+02
ee52f713-79e3-45c8-b993-8d1f8e2f3c71	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.586583+02
3df3f454-98c3-42ef-878f-d1db3511a73c	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.589614+02
610a6f8b-6904-44c7-92a3-49f564978c4e	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.591872+02
6d4acb07-006e-49aa-bba1-6925df48367a	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.956285+02
daceb924-b03c-4501-b811-b7170f56e26c	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.593593+02
0de351bd-0747-42ec-9e0e-6bc22632d442	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.595749+02
c6b301b4-ff25-418d-8743-0445f5f142c5	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.597879+02
bfd226eb-13ff-4646-be2f-6a4338c3ec44	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.599694+02
3acc7667-48d1-4b83-b2f0-443bf2e57b85	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Miel et Forêt de la Ngounié (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "e5326de4-90ed-4b3b-acab-5c847db8bf0a"}	2026-10-02 12:06:31.601184+02
130cd956-9ca0-48c1-a6f5-92b4c5350cea	b894dc88-5275-4bba-9feb-13a700171cf3	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Coopérative Coopérative Rotin et Raphia de l’Estuaire,\n\nNous avons bien reçu votre demande d'inscription en tant que coopérative sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:32.552764+02	\N	{}	2026-10-02 12:06:32.552767+02
944cdc08-132f-4d5d-8ba4-f8687eacec32	b894dc88-5275-4bba-9feb-13a700171cf3	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:32.555331+02
bb7052c1-3247-493c-9b91-017d829a71fc	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.561667+02
5ce37a57-1b6c-4aed-ad8b-c970b860be71	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.564048+02
07255d1d-d9e4-468d-bfb4-3cb6ba049bfc	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.565604+02
58ace0b2-e128-4344-9fc3-2cb868ba26a4	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.567413+02
8ab940b7-f2e5-4713-9519-fa90d3fa278c	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.568996+02
ba445076-7b26-4554-b729-61b1889117cf	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.570923+02
f5e6ca06-57d9-4ba0-9865-97b85464b4c1	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.572966+02
5a911de1-af59-457b-9129-c95330c0ebbd	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative Rotin et Raphia de l’Estuaire (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "06b7bec2-85a3-4b42-9844-fc9a927efcf7"}	2026-10-02 12:06:32.57489+02
d6406d43-325a-495c-b70b-16b7547ff896	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.472659+02
7f85da74-0ded-4eca-a390-a8f005efaf3e	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.474492+02
5432123c-9b59-4ab4-8c59-1da0a4ec9ae6	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.475505+02
6344ef3d-5651-48e7-8e9c-2a4500744c02	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.476756+02
91325e0a-5b6f-4a22-93c7-2e74b630d524	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.478298+02
2e8721c8-dc8c-4561-b981-c50f7ff29f5d	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.480689+02
dd44ad32-c5b3-4d19-ae00-53aa85940b7a	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.48287+02
17f8765d-54e7-4671-b5c6-cd573a83d9dc	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Coopérative Groupement des Cueilleurs de Port-Gentil (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "291e43ee-c88b-45a1-a5b1-b69e94b723af"}	2026-10-02 12:06:33.484446+02
bffd94bb-76be-46d3-9cf4-72ab8adae5bf	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Coopérative Coopérative des Femmes Productrices du Woleu-Ntem,\n\nNous avons bien reçu votre demande d'inscription en tant que coopérative sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:34.362349+02	\N	{}	2026-10-02 12:06:34.362352+02
4be0cc4b-a2d2-4b92-9729-75812f1a1682	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:34.364928+02
45a0e7f4-6531-4d81-ba67-08c34e935b25	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.368741+02
f15d70af-1cf0-4c7b-b34f-3709d4915803	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.369669+02
ed41138f-d8a3-4d62-bb1f-7afe345fc2c1	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.3707+02
dc1e352a-346c-4f9e-9730-27b4561fe062	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.372167+02
c6c32567-9869-4cb9-8738-ad7c7e362a86	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.373483+02
e3cdff4d-abb7-4d41-b3d1-717ed02ec535	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.37484+02
0de34bf9-9a5e-4b88-abf9-d82822603d87	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.375933+02
fbdccc64-1f8a-4bae-8d33-b6bfe11cdb17	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Coopérative Coopérative des Femmes Productrices du Woleu-Ntem (coopérative) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "cooperatives", "enregistrement_id": "1b1aaec8-b1bc-4228-8b1b-278466538418"}	2026-10-02 12:06:34.377262+02
61ed4802-0b8f-402e-a03e-e530b4cf054e	eaf22c78-d48d-431f-a7ae-660650279c0e	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Laurent DIBANGA,\n\nNous avons bien reçu votre demande d'inscription en tant que acheteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:34.946761+02	\N	{}	2026-10-02 12:06:34.946763+02
bd4a99b5-020c-4bb4-8088-4ca9960b6043	eaf22c78-d48d-431f-a7ae-660650279c0e	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:34.948723+02
d0cdbd71-f653-48ef-9f8d-1726571db0d9	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.951628+02
a0e53f9f-d5fc-42d8-87e8-6f2a7ba2af77	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.952365+02
2f07d2aa-53c5-4371-84c1-4ef497e50b77	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.953137+02
2829f195-17e1-42ef-bf31-9f537a233c05	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.953811+02
b9b48f4e-4e20-4446-8dab-609ec3e9b86d	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.954527+02
400193c2-414e-4b18-8f41-cec874d2d72f	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.95544+02
c5592499-fbdb-4156-91e3-0ea7001944dc	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Laurent DIBANGA (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "eaf22c78-d48d-431f-a7ae-660650279c0e"}	2026-10-02 12:06:34.957761+02
1bed4272-4c30-40f0-b5b1-1d464b3909b2	1a7015dd-2f54-424e-9b92-620a4cedabaa	EMAIL	PFNL — Accusé de réception de votre inscription	Bonjour Estelle MOUNGUENGUI,\n\nNous avons bien reçu votre demande d'inscription en tant que acheteur sur la plateforme PFNL (École Nationale des Eaux et Forêts).\nUn administrateur va examiner votre dossier. Vous recevrez un email et un SMS de confirmation dès que votre compte sera validé et activé.\n\nCordialement,\nL'équipe PFNL	f	2026-10-02 12:06:35.477986+02	\N	{}	2026-10-02 12:06:35.477989+02
691398eb-ba47-4a44-ac5a-01a2e444057a	1a7015dd-2f54-424e-9b92-620a4cedabaa	SMS	SMS	PFNL : votre demande d'inscription a ete recue et est en cours d'examen.	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.479133+02
9f48b8bb-8017-4e3c-8822-4c930d773108	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.482405+02
508700a0-55bd-4276-9c98-868a39f230a4	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.483559+02
8039bad1-877f-444f-a40b-a080a4634eb5	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.484455+02
56c90a91-36ec-4213-9f7d-64c84d942619	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.485012+02
b8e3e3dd-0acf-4eb9-9f35-655b5e26ef6d	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.485781+02
8c133e7e-a40c-41f9-8e9f-d6b991a6a1a6	70dd1a0a-1111-47f4-9a12-efd092fbc67a	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.487123+02
11604cf3-092c-4170-8ef8-942e9fc23d40	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.488408+02
f92d7e2b-2242-41e7-b02c-622034e6cd89	f2d88f9a-597f-4c0f-88a8-13e670a28a58	INTERNE	Nouvelle demande d'inscription	Estelle MOUNGUENGUI (acheteur) a soumis une demande d'inscription. Ouvrez sa fiche pour la valider ou la rejeter.	f	\N	\N	{"table_cible": "utilisateurs", "enregistrement_id": "1a7015dd-2f54-424e-9b92-620a4cedabaa"}	2026-10-02 12:06:35.490011+02
2532abe5-617b-430f-bc36-c4ff0af5775a	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	EMAIL	PFNL — Votre inscription a été validée	Bonjour Jean-Baptiste NDONG,\n\nVotre inscription en tant que producteur/collecteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.519993+02	\N	{}	2026-10-02 12:06:35.519996+02
5448291b-5675-4c78-9d17-7e5ec99e4b2b	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.522633+02
817dba8d-21c7-4467-b7f4-57dfe46a2360	b64ff13b-0617-456b-9589-257f95ae4fb7	EMAIL	PFNL — Votre inscription a été validée	Bonjour Marie-Claire MOUSSAVOU,\n\nVotre inscription en tant que producteur/collecteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.561505+02	\N	{}	2026-10-02 12:06:35.561508+02
5ebb196a-6eac-4c4e-9474-fdefb45abdd0	b64ff13b-0617-456b-9589-257f95ae4fb7	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.563512+02
f4dcff5a-4a6e-4b7b-972c-69bba9c017d0	5dfd8155-3222-4e05-9702-06e9cc47cca1	EMAIL	PFNL — Votre inscription a été validée	Bonjour Sylvie MBOUMBA,\n\nVotre inscription en tant que producteur/collecteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.59674+02	\N	{}	2026-10-02 12:06:35.596745+02
0c6cab06-ea53-45b2-badd-4a464551b72b	5dfd8155-3222-4e05-9702-06e9cc47cca1	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.599805+02
572f98c8-83ff-45c3-aa94-a1ed18b2cded	1d6791e9-3b17-4369-9041-924118ba2d22	EMAIL	PFNL — Votre inscription a été validée	Bonjour Fabrice NGUEMA,\n\nVotre inscription en tant que producteur/collecteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.629457+02	\N	{}	2026-10-02 12:06:35.629459+02
3cce49eb-f6e0-4dd1-b492-48098c3b22fa	1d6791e9-3b17-4369-9041-924118ba2d22	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.631127+02
08082a07-651d-47fb-b876-b7a826ba4adb	97a54b08-c1ef-46eb-8505-1f31b5cadb80	EMAIL	PFNL — Votre inscription a été validée	Bonjour Paul OBIANG,\n\nVotre inscription en tant que producteur/collecteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.664126+02	\N	{}	2026-10-02 12:06:35.664131+02
28dd9349-d095-4061-818d-dc052483ee5c	97a54b08-c1ef-46eb-8505-1f31b5cadb80	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.666564+02
a3a9e991-1152-4b5d-ba63-9d7157269876	ec677a07-a583-40fd-9a61-370807755ac1	EMAIL	PFNL — Votre inscription a été validée	Bonjour Coopérative Coopérative des Saveurs de l’Ivindo,\n\nVotre inscription en tant que coopérative sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.898968+02	\N	{}	2026-10-02 12:06:35.89897+02
dd60255d-75b9-401c-8b4d-ff83180506a7	ec677a07-a583-40fd-9a61-370807755ac1	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.900217+02
4c8f9265-f802-467b-8934-68f0dfe28fc4	1f279d86-485b-4a3b-b0c5-3bfc813473b6	EMAIL	PFNL — Votre inscription a été validée	Bonjour Coopérative Coopérative Miel et Forêt de la Ngounié,\n\nVotre inscription en tant que coopérative sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.92499+02	\N	{}	2026-10-02 12:06:35.924992+02
3c3ebfce-6e61-4dbe-a87b-7e559627656b	1f279d86-485b-4a3b-b0c5-3bfc813473b6	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.926165+02
30402d94-e48e-4355-81f4-7b41c3e00b91	b894dc88-5275-4bba-9feb-13a700171cf3	EMAIL	PFNL — Votre inscription a été validée	Bonjour Coopérative Coopérative Rotin et Raphia de l’Estuaire,\n\nVotre inscription en tant que coopérative sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:35.951143+02	\N	{}	2026-10-02 12:06:35.951145+02
3126dd9e-7aa3-4ea7-80b6-bbea23d09717	b894dc88-5275-4bba-9feb-13a700171cf3	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:35.952206+02
8e0c4ca6-1798-43ca-a772-7d9a00bff230	eaf22c78-d48d-431f-a7ae-660650279c0e	EMAIL	PFNL — Votre inscription a été validée	Bonjour Laurent DIBANGA,\n\nVotre inscription en tant que acheteur sur la plateforme PFNL a été validée par un administrateur.\nVous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi lors de votre inscription :\nhttp://localhost:4200/connexion\n\nCordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts	f	2026-10-02 12:06:36.028548+02	\N	{}	2026-10-02 12:06:36.02855+02
1528dc27-e8aa-4a27-acd8-f3035f3790b1	eaf22c78-d48d-431f-a7ae-660650279c0e	SMS	SMS	PFNL : votre inscription a ete validee. Connectez-vous sur http://localhost:4200/connexion	f	\N	Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).	{}	2026-10-02 12:06:36.029838+02
11cca69e-c2e0-45a6-be6d-b7bebe556976	ec677a07-a583-40fd-9a61-370807755ac1	INTERNE	Demande d’adhésion	Sylvie MBOUMBA (PRD-34CC9C4D) souhaite rejoindre Coopérative des Saveurs de l’Ivindo.	f	\N	\N	{}	2026-10-02 12:06:36.446921+02
3fe00a13-304f-4e6f-9d47-c2f963b435b6	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Annonce validée	Votre annonce « Miel sauvage de la Ngounié, 100 kg disponibles » a été validée et publiée dans l'annuaire public.	f	\N	\N	{"table_cible": "offres_demandes", "enregistrement_id": "2378a2d4-443f-450f-b63b-a63c6789c82a"}	2026-10-02 12:06:43.800975+02
e5814aae-94d1-4026-beb7-33fe0fc19265	ec677a07-a583-40fd-9a61-370807755ac1	INTERNE	Annonce validée	Votre annonce « Noix de kola calibrées, 250 kg » a été validée et publiée dans l'annuaire public.	f	\N	\N	{"table_cible": "offres_demandes", "enregistrement_id": "34d135f3-82bd-46fa-8817-c7a9bc40e62f"}	2026-10-02 12:06:43.904669+02
0cca8341-9c31-4ffd-ba5c-35c7f884cb31	eaf22c78-d48d-431f-a7ae-660650279c0e	INTERNE	Annonce validée	Votre annonce « Recherche 500 kg de noisettes owala certifiées » a été validée et publiée dans l'annuaire public.	f	\N	\N	{"table_cible": "offres_demandes", "enregistrement_id": "f8cbdbeb-f57c-497e-baa1-3610a8e939ee"}	2026-10-02 12:06:44.022535+02
c270a2e7-b258-41ec-8ff6-cada15ac5cd7	97a54b08-c1ef-46eb-8505-1f31b5cadb80	INTERNE	Annonce rejetée	Votre annonce « Champignons forestiers frais » a été rejetée. Motif : Produit périssable : précisez le conditionnement et la date de récolte.	f	\N	\N	{"table_cible": "offres_demandes", "enregistrement_id": "efd1c8b5-a4ee-4d50-af79-e5124c71a23a"}	2026-10-02 12:06:44.088624+02
29899405-e4f7-416f-903e-a4a743196695	5dfd8155-3222-4e05-9702-06e9cc47cca1	INTERNE	Annonce validée	Votre annonce « Safou d’Oyem, récolte de saison » a été validée et publiée dans l'annuaire public.	f	\N	\N	{"table_cible": "offres_demandes", "enregistrement_id": "1e5154fd-a8a7-4ca2-9e57-610654f1f521"}	2026-10-02 12:06:44.221682+02
094d67a4-b733-4a37-ba3e-43479eb07e28	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Message sur votre annonce	Hôtel Le Méridien Libreville (démo) (visiteur.hotel@demo.pfnl.ga · +241011000001) à propos de « Miel sauvage de la Ngounié, 100 kg disponibles » : Bonjour, nous souhaitons commander 20 kg de miel par mois. Pouvez-vous nous rappeler ?	f	\N	\N	{}	2026-10-02 12:06:44.374142+02
58a5ef52-fbe6-490b-8285-34cdac773262	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouveau message public	Association Tradipraticiens (démo) souhaite contacter Célestin ONDO MBA : Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	f	\N	\N	{"producteur_id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46", "message_public_id": "0c78077e-c7d1-4806-92f4-3b7b7782003b"}	2026-10-02 12:06:44.463385+02
e6afa338-9daa-40b8-8769-b919bad6cb4a	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouveau message public	Association Tradipraticiens (démo) souhaite contacter Célestin ONDO MBA : Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	f	\N	\N	{"producteur_id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46", "message_public_id": "0c78077e-c7d1-4806-92f4-3b7b7782003b"}	2026-10-02 12:06:44.463385+02
ef4327b8-454d-465c-b901-88f59490711c	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouveau message public	Association Tradipraticiens (démo) souhaite contacter Célestin ONDO MBA : Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	f	\N	\N	{"producteur_id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46", "message_public_id": "0c78077e-c7d1-4806-92f4-3b7b7782003b"}	2026-10-02 12:06:44.463385+02
f50bcfde-7ca9-494d-a49f-cdf8d086fcf9	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouveau message public	Association Tradipraticiens (démo) souhaite contacter Célestin ONDO MBA : Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	f	\N	\N	{"producteur_id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46", "message_public_id": "0c78077e-c7d1-4806-92f4-3b7b7782003b"}	2026-10-02 12:06:44.463385+02
95a4b0b4-60e0-41d2-989e-d07d95466beb	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouveau message public	Association Tradipraticiens (démo) souhaite contacter Célestin ONDO MBA : Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.	f	\N	\N	{"producteur_id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46", "message_public_id": "0c78077e-c7d1-4806-92f4-3b7b7782003b"}	2026-10-02 12:06:44.463385+02
24163bf5-9571-4747-95af-cb7389bfb80c	5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
2c33d7ef-120c-48df-911f-2ee4898fe24c	1051c839-763f-4a10-9f0e-7b64d301a393	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
d5d8720c-5a78-475b-97f0-fd52c4d5eb53	2992fb5e-5580-483b-9462-98fe46cf7627	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
a5bd2b00-85f7-44de-83ea-468910bd8ce0	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
96b6ec89-2cb7-445b-86f2-69811d28e112	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
7ad8c332-9045-48e2-b51d-a3ef74e72a92	28685225-99bb-47f6-bee0-44618f80115d	INTERNE	Nouveau message public	Épicerie fine Akanda (démo) souhaite contacter Jean-Baptiste NDONG : Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.	f	\N	\N	{"producteur_id": "ad0c1500-c241-4d87-90c6-ac3ec914f53a", "message_public_id": "cc3c3561-4de9-449f-9ef1-b6a3dd5e26c4"}	2026-10-02 12:06:44.560086+02
07603320-4fcc-4320-aa4d-6372a3e8b0d2	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Message: Miel sauvage de la Ngounié, 100 kg disponibles	Bonjour, votre miel est-il disponible pour un enlèvement à Mouila en fin de mois ?	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "11a76a97-5e8f-4eb4-9500-c4fcee8fd636"}	2026-10-02 12:06:44.856891+02
080d9ab1-8142-4eca-a46b-4206a66cfa14	eaf22c78-d48d-431f-a7ae-660650279c0e	INTERNE	Message: Miel sauvage de la Ngounié, 100 kg disponibles	Bonjour, oui. Les 100 kg sont prêts et la récolte est certifiée biologique.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "11a76a97-5e8f-4eb4-9500-c4fcee8fd636"}	2026-10-02 12:06:44.959581+02
984cda81-3700-4dce-a0a8-9767a1aa3059	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Message: Miel sauvage de la Ngounié, 100 kg disponibles	Parfait. Pouvez-vous m’indiquer le code du lot pour une vérification par QR code ?	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "11a76a97-5e8f-4eb4-9500-c4fcee8fd636"}	2026-10-02 12:06:45.056529+02
54a19d1d-a0c2-4fd8-a276-a7f5ff221e24	eaf22c78-d48d-431f-a7ae-660650279c0e	INTERNE	Message: Miel sauvage de la Ngounié, 100 kg disponibles	Bien sûr : lot PNLF-20261002-EA6C9C8D5E. Vous pouvez le vérifier sur la page publique.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "11a76a97-5e8f-4eb4-9500-c4fcee8fd636"}	2026-10-02 12:06:45.181278+02
20dd88fb-ccc5-4c80-bd97-7f3c3c83e591	ec677a07-a583-40fd-9a61-370807755ac1	INTERNE	Message: Discussion avec Coopérative des Saveurs de l’Ivindo	Bonjour, livrez-vous des noix de kola à Libreville ?	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "15453ebc-6eba-4ada-90cf-8817007331b8"}	2026-10-02 12:06:45.389771+02
678adca3-9db8-49eb-affb-14a8a247dc09	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	INTERNE	Message: Discussion avec Coopérative des Saveurs de l’Ivindo	Bonjour Madame, oui : une livraison groupée chaque premier lundi du mois.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "15453ebc-6eba-4ada-90cf-8817007331b8"}	2026-10-02 12:06:45.459252+02
ea2da928-aaaf-4fea-a321-5cd7c1087bdf	b64ff13b-0617-456b-9589-257f95ae4fb7	INTERNE	Message: Discussion avec Marie-Claire MOUSSAVOU	Bonjour, seriez-vous intéressée par un contrat annuel pour la kola ?	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "6aec5643-73f5-4767-9cd0-a7d990a50152"}	2026-10-02 12:06:45.652464+02
45dd51ce-13b1-4156-8883-00331eae3edb	97a54b08-c1ef-46eb-8505-1f31b5cadb80	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Bonjour à tous : collecte groupée samedi au magasin de Makokou.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:45.887014+02
e1ca9550-0736-45ce-a9a1-ccde8ad06092	b64ff13b-0617-456b-9589-257f95ae4fb7	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Bonjour à tous : collecte groupée samedi au magasin de Makokou.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:45.892613+02
17543146-5dd8-4e5c-8e0d-65dd07b6614a	ec677a07-a583-40fd-9a61-370807755ac1	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Bien noté, j’apporte environ 80 kg de kola.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:45.978154+02
47392354-433b-46b6-8c74-47735063eced	97a54b08-c1ef-46eb-8505-1f31b5cadb80	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Bien noté, j’apporte environ 80 kg de kola.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:45.983869+02
be9fa955-f8f0-42ec-b525-aa7b835511bc	ec677a07-a583-40fd-9a61-370807755ac1	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Je serai présent avec les noisettes de Minkébé.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:46.0683+02
4d5db4ff-b506-4a0c-963b-2c29e04486f2	b64ff13b-0617-456b-9589-257f95ae4fb7	INTERNE	Message: Groupe des membres, Saveurs de l’Ivindo	Je serai présent avec les noisettes de Minkébé.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "75cc426b-35bf-4b82-bf2a-582c16e92e93"}	2026-10-02 12:06:46.075515+02
0d3af4f8-185b-4b41-901e-efbf43387124	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	INTERNE	Message: Discussion avec Jean-Baptiste NDONG	Bonjour, votre certification biologique a été validée. Pensez à joindre le certificat signé.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "732a763f-ae05-499c-834f-5f785d39f339"}	2026-10-02 12:06:46.327166+02
a06e4fd4-db9a-4578-833f-1131baa6664a	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	INTERNE	Message: Discussion avec Jean-Baptiste NDONG	Merci beaucoup, je le dépose dès cette semaine.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "732a763f-ae05-499c-834f-5f785d39f339"}	2026-10-02 12:06:46.411694+02
a678bfe1-ccf1-4564-8271-03996b7724f5	1f279d86-485b-4a3b-b0c5-3bfc813473b6	INTERNE	Message: Discussion avec Coopérative Coopérative Miel et Forêt de la Ngounié	Bonjour, contrôle de routine prévu à votre magasin de Mouila mardi prochain.	f	\N	\N	{"table_cible": "conversations", "enregistrement_id": "840b065a-bd81-4aaf-b799-da196446caf3"}	2026-10-02 12:06:46.626133+02
\.


--
-- TOC entry 6963 (class 0 OID 69855)
-- Dependencies: 248
-- Data for Name: offres_demandes; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.offres_demandes (id, type_annonce, auteur_id, produit_id, province_id, quantite, unite, prix_unitaire, devise, titre, description, certification_requise, statut, expire_at, created_at, updated_at, uuid_public, qr_payload, qr_image_path) FROM stdin;
34d135f3-82bd-46fa-8817-c7a9bc40e62f	OFFRE	ec677a07-a583-40fd-9a61-370807755ac1	a0a0d114-3cf6-400f-8dd7-4cdddd0792f8	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	250.000	KG	1800.00	XAF	Noix de kola calibrées, 250 kg	Noix séchées et triées par la coopérative. Enlèvement possible à Makokou.	f	OUVERTE	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:41.206562+02	2026-10-02 12:06:24.799502+02	57bd8368-1534-4fc8-a9b1-dedbf7b18322	PNLF-OD:57bd8368-1534-4fc8-a9b1-dedbf7b18322	qr/od-57bd8368-1534-4fc8-a9b1-dedbf7b18322.png
d41cc54f-ed02-46d8-b259-2dc8ed763527	DEMANDE	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	df527935-1b53-4d8f-be5d-4e24ae8b7ab2	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	30.000	KG	9000.00	XAF	Achat de chenilles séchées pour restauration	Livraison souhaitée à Libreville, 10 kg par mois.	f	EN_VALIDATION	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:42.850175+02	2026-10-02 12:06:24.799502+02	\N	\N	\N
ac5f5311-20f7-4b40-a159-52c28402e13f	OFFRE	b64ff13b-0617-456b-9589-257f95ae4fb7	16f0cac4-9798-42fa-b08c-43941ea9a87f	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	20.000	KG	6000.00	XAF	Poivre de Guinée séché	Graines séchées au soleil, sacs de 5 kg.	f	EN_VALIDATION	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:43.528632+02	2026-10-02 12:06:24.799502+02	\N	\N	\N
2378a2d4-443f-450f-b63b-a63c6789c82a	OFFRE	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	22cd568c-3fa9-4518-871b-fe9f3d658b97	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	100.000	KG	6500.00	XAF	Miel sauvage de la Ngounié, 100 kg disponibles	Miel de forêt récolté de façon traditionnelle, filtré à froid, conditionné en seaux de 25 kg.	f	OUVERTE	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:40.494357+02	2026-10-02 12:06:24.799502+02	60e4826a-3174-418c-9c34-ed2564fe76d5	PNLF-OD:60e4826a-3174-418c-9c34-ed2564fe76d5	qr/od-60e4826a-3174-418c-9c34-ed2564fe76d5.png
f8cbdbeb-f57c-497e-baa1-3610a8e939ee	DEMANDE	eaf22c78-d48d-431f-a7ae-660650279c0e	dafedd72-af4f-410b-b81b-e55d238c9280	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	500.000	KG	2500.00	XAF	Recherche 500 kg de noisettes owala certifiées	Achat régulier pour l’export. Certification exigée, paiement à la livraison.	t	OUVERTE	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:42.282569+02	2026-10-02 12:06:24.799502+02	25259aeb-6fe3-48f2-8503-76b7a0a74f48	PNLF-OD:25259aeb-6fe3-48f2-8503-76b7a0a74f48	qr/od-25259aeb-6fe3-48f2-8503-76b7a0a74f48.png
efd1c8b5-a4ee-4d50-af79-e5124c71a23a	OFFRE	97a54b08-c1ef-46eb-8505-1f31b5cadb80	cbc6ebe5-a267-413c-8848-7e5e26ce2c09	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	15.000	KG	5000.00	XAF	Champignons forestiers frais	Récolte du jour.	f	REJETEE	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:43.050712+02	2026-10-02 12:06:24.799502+02	\N	\N	\N
1e5154fd-a8a7-4ca2-9e57-610654f1f521	OFFRE	5dfd8155-3222-4e05-9702-06e9cc47cca1	20c3ba11-7016-4166-8e92-f53e482a181e	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	200.000	KG	1200.00	XAF	Safou d’Oyem, récolte de saison	Fruits mûrs, cagettes de 20 kg.	f	CLOTUREE	2026-12-01 11:06:40.035537+01	2026-10-02 12:06:43.279672+02	2026-10-02 12:06:24.799502+02	f76e0bae-8604-4b79-9a7e-6ee8b17c63d5	PNLF-OD:f76e0bae-8604-4b79-9a7e-6ee8b17c63d5	qr/od-f76e0bae-8604-4b79-9a7e-6ee8b17c63d5.png
\.


--
-- TOC entry 6957 (class 0 OID 69617)
-- Dependencies: 242
-- Data for Name: producteur_produits; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.producteur_produits (producteur_id, produit_id, principal, created_at) FROM stdin;
\.


--
-- TOC entry 6953 (class 0 OID 69468)
-- Dependencies: 238
-- Data for Name: producteurs; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.producteurs (id, code_producteur, nom, prenoms, date_naissance, type_piece_identite, numero_piece, telephone, email, communaute, province_id, departement_id, village_id, latitude, longitude, geom, cooperative_id, utilisateur_id, statut, valide_par, valide_at, notes, client_uuid, sync_statut, sync_version, last_synced_at, created_at, updated_at, deleted_at, type_acteur, photo_path, visible_public) FROM stdin;
35ae1bd4-659d-4652-8af1-5873bd4cb687	OWN-0dbee9	Moi	Prod	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	505512be-a7e2-4291-b5cb-6f7f3bb54030	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:31:37.324786+02	2026-08-13 12:31:39.048533+02	2026-08-13 12:31:39.048201+02	PRODUCTEUR	\N	t
82c183df-216e-47fb-9140-8b79f25af6c7	OTH-242451	Autre	Prod	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:31:38.669299+02	2026-08-13 12:31:39.110641+02	2026-08-13 12:31:39.109467+02	PRODUCTEUR	\N	t
7075587b-caaa-4797-bf46-9267e26088db	LOT-4a6588	Lot	Test	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:31:39.007767+02	2026-08-13 12:31:39.112472+02	2026-08-13 12:31:39.11201+02	PRODUCTEUR	\N	t
165a6892-aea0-4369-b8f4-8fad5d806930	OWN-d479cb	Moi	Prod	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	505512be-a7e2-4291-b5cb-6f7f3bb54030	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:33:14.518822+02	2026-08-13 12:33:15.761454+02	2026-08-13 12:33:15.761203+02	PRODUCTEUR	\N	t
443a564d-3db3-4b42-917a-e7d7e25379dc	OTH-a14920	Autre	Prod	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:33:14.532854+02	2026-08-13 12:33:15.762291+02	2026-08-13 12:33:15.76209+02	PRODUCTEUR	\N	t
5ac66f77-ef10-49e4-962f-9670667460f6	LOT-cdbfb9	Lot	Test	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 12:33:15.689881+02	2026-08-13 12:33:15.76293+02	2026-08-13 12:33:15.762758+02	PRODUCTEUR	\N	t
c7d4b9fd-5548-4f18-84a2-884f01126fdf	PRD-EXT-603e4a	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:09:47.169247+02	2026-08-19 13:09:49.419428+02	2026-08-19 13:09:49.414913+02	PRODUCTEUR	\N	t
30670990-06f1-4b0e-9990-de341ba5cf42	PROD-TEST-01	Test	Producteur	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	2992fb5e-5580-483b-9462-98fe46cf7627	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-10 14:35:57.446617+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
55140168-b06c-471b-b68f-28db1317fab2	PRD-55140168	yves	alain	\N	\N	\N	+24174054314	yves@pnlf.ga	\N	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	d96eb2c5-ec95-4691-82c0-bfa19680f78f	dbe850af-595e-4f81-97b1-056abca7c9d4	\N	\N	\N	\N	e7f43b56-b615-4214-9e26-e2b2e09d257e	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-21 18:35:14.407994+02	Inscription publique le 21/08/2026 16:30 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-08-21 18:30:33.871995+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	COLLECTEUR	\N	t
e82608fe-54fc-4668-b294-0eef9753295d	PRD-E82608FE	Ondo	Jean	\N	\N	\N	074123456	test.producteur.115f9ba6@pnlf-test.local	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	10c652a1-c147-4459-91ef-523fb13fc3ad	ACTIF	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	2026-08-15 16:24:31.382295+02	Inscription publique le 15/08/2026 14:24 (IP 127.0.0.1). Message du demandeur : Je collecte du moabi et du kola.	\N	SYNCED	1	\N	2026-08-15 16:24:30.567096+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
1d29e123-c3fb-403b-a89c-62ad2fe7b6b0	PRD-1D29E123	Ondo	Jean	\N	\N	\N	074123456	test.producteur.82ad1e59@pnlf-test.local	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	499dde3f-543c-48da-aa30-55e4110c8fa9	ACTIF	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	2026-08-15 16:21:52.996891+02	Inscription publique le 15/08/2026 14:21 (IP 127.0.0.1). Message du demandeur : Je collecte du moabi et du kola.	\N	SYNCED	1	\N	2026-08-15 16:21:50.598297+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
06efa363-7347-4d12-b162-e932a0425b60	PRD-PAR-aae274	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:18.005314+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:40:20.494359+02	PRODUCTEUR	\N	t
bde9fe4e-d2cf-49b5-b40e-eff49b384b72	PRD-PAR-a1ed17	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:09:47.091335+02	2026-09-23 17:12:46.065062+02	2026-08-19 13:09:49.414913+02	PRODUCTEUR	\N	t
528c3915-6d2e-43f7-9bc0-788c6bcbf8d8	PRD-PAR-375c19	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:20:17.288156+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:20:18.985927+02	PRODUCTEUR	\N	t
29f7f41f-4d3d-41e3-b9d4-150644bfc821	RBAC-admin-24e38e	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.248222+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
c72db6b0-beec-4785-82c0-c5d84e40dc7e	PROD-PHOTO-D68E60	Ondimba	Alice	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	Test photos lot	\N	SYNCED	1	\N	2026-08-15 17:44:01.193495+02	2026-08-15 17:48:02.695583+02	2026-08-15 17:48:02.695088+02	PRODUCTEUR	\N	t
c49db566-245a-4200-a4b6-632a35db8d67	PRD-EXT-7584fd	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:20:17.335225+02	2026-08-19 12:20:18.995578+02	2026-08-19 12:20:18.985927+02	PRODUCTEUR	\N	t
8a6a7d24-b821-400a-b0f7-7d93ca76ff3f	PRD-EXT-3f2075	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:18.015553+02	2026-08-19 12:40:20.501222+02	2026-08-19 12:40:20.494359+02	PRODUCTEUR	\N	t
b00d01a0-6541-4625-8432-ddf541860b02	RBAC-agent_min-484223	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.273368+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
ba571c43-da0e-405b-8c6f-42eca0cbe2f6	RBAC-agent_for-8ef874	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.295071+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
ca18a13c-f250-4298-a18f-121bc08ada2d	RBAC-producteur-70df88	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.318629+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
0a7a7327-882b-4d07-9931-7b5ede4330a2	RBAC-cooperative-26d961	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:18.356446+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
f8d8d141-99bf-40d4-a69b-f7ddd8bfaac7	RBAC-admin-db24f9	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.252212+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
2be4fa4f-9e73-44a0-b604-70a9f59f0f77	RBAC-agent_min-beb4c3	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.274668+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
27b9943d-2844-4ba1-811f-0e871fa1f0da	RBAC-agent_for-785e73	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.297824+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
4604f83b-77bc-4758-a2cb-172f5f5e2772	RBAC-producteur-b002a9	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.32039+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
4930b891-237e-47a2-99d2-dfb3fe640157	RBAC-cooperative-7d2111	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:01.341207+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
f55f2bcb-6013-46fb-82d7-ffda39280ac9	AGF-6e0c86	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-15 18:18:11.697462+02	\N	\N	SYNCED	1	\N	2026-08-13 15:19:01.088835+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
62f06868-08de-448f-a8cd-9db6e81b28bd	PRD-OTH-88b528	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:18:57.819979+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
a6c24293-7e48-4fe7-972a-8f87c7e972d7	RBAC-agent_min-ba0486	N	P	\N	\N	\N				c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	REJETE	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-17 17:43:40.491206+02		\N	SYNCED	1	\N	2026-08-13 15:18:59.34218+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
36f91375-1657-40f9-a4e1-60710579c8c6	RBAC-admin-08e1f2	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-17 18:22:04.145357+02	\N	\N	SYNCED	1	\N	2026-08-13 15:18:59.130976+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
67bde694-e33e-4a28-a3b2-e47eb449a22d	RBAC-agent_for-609f09	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-17 18:22:07.063889+02	\N	\N	SYNCED	1	\N	2026-08-13 15:18:59.365792+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
c934672b-25c6-4846-b9ef-7ffbd30aeb36	PRD-OTH-6e1891	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:50:59.891361+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
2488a860-dd07-4abb-8234-6039b075dcb0	RBAC-admin-27a73c	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.252579+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
f8c0ce3d-7954-46c7-b757-41a997c5bdd7	AGF-b481a1	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	REJETE	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:02.628537+02	information incomplete	\N	SYNCED	1	\N	2026-08-19 12:40:48.430449+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
88e9555f-c828-4b75-97eb-b9529cd93f2f	RBAC-cooperative-0d6f2a	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:26.885027+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.845377+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
750619e4-d1fb-4a39-8eab-7ea17c63dd8f	RBAC-admin-1bc545	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:29.044778+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.750434+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
86429988-bb53-4e7a-9a08-a8c8b87deef9	RBAC-agent_min-90adf0	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:30.612231+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.802087+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
5ac13177-fed1-4965-914b-629d29a107bf	RBAC-agent_for-331f90	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:32.302052+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.817421+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
88f64df9-a902-4976-b73a-0385ba26cf10	RBAC-agent_min-f03464	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.310983+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
eceb8e0f-bd08-43c8-bd38-e19dbbc0dedf	RBAC-agent_for-af5085	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.332537+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
117d4a3b-7814-452a-b8f8-f55a483b1cd4	PROD-PHOTO-1804A6	Ondimba	Alice	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	Test photos lot	\N	SYNCED	1	\N	2026-08-15 17:44:35.321887+02	2026-08-15 17:44:35.776321+02	2026-08-15 17:44:35.775788+02	PRODUCTEUR	\N	t
b972746b-10e7-42aa-ae2e-7b4eb7866bdb	PRD-EXT-65af4c	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:10.940106+02	2026-08-19 12:21:12.757583+02	2026-08-19 12:21:12.750623+02	PRODUCTEUR	\N	t
21780bdf-be5a-4eb5-866b-eb89d96ccdf1	PRD-OWN-794520	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 15:18:57.778345+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
cf858f2d-3082-4e46-9c17-daeeed5b03fa	PRD-MEM-dcbe54	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 15:18:57.816438+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
d0737953-a582-4324-b172-0472b51b1ccc	RBAC-producteur-05dea8	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-17 18:22:08.695024+02	\N	\N	SYNCED	1	\N	2026-08-13 15:18:59.387672+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
e98b1c02-19ae-4ba4-b473-9170ecd08da9	RBAC-cooperative-74a8db	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-17 18:22:11.319769+02	\N	\N	SYNCED	1	\N	2026-08-13 15:18:59.412632+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
acde2b48-6a26-4371-8c0b-d6db6d774a76	RBAC-producteur-17a12f	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.349629+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
1a735b32-8bd9-45a7-ac2f-ba7be7c455cc	RBAC-cooperative-02ca15	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:14.364864+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
5e53e681-cb89-4fab-bd8b-ebf2d2133383	AGF-63dfc4	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:15.196121+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
9fd66383-703c-42ad-8b9d-81fce34da52a	PRD-OTH-6f3ac3	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:13.063487+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
e8ce4b5f-e8d7-4d93-9c79-88752bc5375b	RBAC-admin-aeaac5	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.506519+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
e086eb62-bfca-44d3-b45a-7e010882b45a	RBAC-agent_min-4458e4	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.530116+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
bbf05d0a-816e-466c-80da-3e1f402bcdce	RBAC-agent_for-52dd62	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.545448+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
bf48952c-998d-489c-9564-0d0a16a2b4d3	RBAC-admin-2aeb85	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.648619+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
a4b13bf3-ba07-488f-b66f-5a6d043a656f	RBAC-agent_min-cdb75e	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.670147+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
1d2b461a-8911-40e8-a14b-5edea911fb1c	RBAC-agent_for-b3e2a6	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.691614+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
93f97b4a-14bf-402a-99ba-0739b16e6de4	RBAC-producteur-e8dea8	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.716175+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
0535f8f6-d738-495c-8ecc-896c1c442a63	PRD-OWN-ed38cb	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:53:13.050288+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
97421cd2-24d5-4f37-af62-5bac7c43ac0f	PRD-MEM-2926b0	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 14:53:13.059563+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
d550bc5e-077b-47f9-8214-6f92b994a641	PRD-OTH-3f98c6	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:46.995024+02	2026-08-19 12:40:48.452371+02	2026-08-19 12:40:48.439047+02	PRODUCTEUR	\N	t
98737ebe-a91f-4d04-9f3a-7a51f3fc4942	PRD-98737EBE	kaaki	d	\N	\N	\N	+24174054314	kaaki@pnlf.ga	Mbigou	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	d13daecd-deef-44a6-ba6a-7bdfe8ac3ac2	a4ffe8c8-8260-490e-ad1a-663ffc3384a5	\N	\N	\N	\N	0cc7031d-9c14-4521-8394-a4bca39ffa4e	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-21 12:00:45.969111+02	Inscription publique le 21/08/2026 09:58 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-08-21 11:58:36.054656+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
3aa7a8f9-4825-4a1a-9adf-8c8ffa8ed694	PRD-3AA7A8F9	Ondo	Jean	\N	\N	\N	074123456	test.producteur.430ae164@pnlf-test.local	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	79b78eee-a7f2-43b2-9bb7-ed8d0d790982	ACTIF	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	2026-08-15 16:24:13.967198+02	Inscription publique le 15/08/2026 14:24 (IP 127.0.0.1). Message du demandeur : Je collecte du moabi et du kola.	\N	SYNCED	1	\N	2026-08-15 16:24:13.135663+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
6fbdace5-2e31-4c07-b980-9fb13a618ea5	PRD-PAR-0f8a5c	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:46.97676+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:21:49.217458+02	PRODUCTEUR	\N	t
fea18beb-ff84-406b-a45b-6edc5d1cc489	PRD-FEA18BEB	manomba	sylvie	\N	\N	\N	066139853	sylviamano7@gmail.com	1	86a5e90b-c713-4ccc-affe-2480b77fbbf0	0967f0c8-f287-4f32-abf3-7856e34dc2a3	97af34fb-69e1-4382-b96b-126390762621	\N	\N	\N	\N	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-15 18:26:56.830485+02	Inscription publique le 15/08/2026 16:25 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-08-15 18:25:48.056524+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	COLLECTEUR	\N	t
0c883635-2daa-4b9e-9240-c726c9c0ec84	PRD-EXT-2a6cff	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:46.995282+02	2026-08-19 12:21:49.229019+02	2026-08-19 12:21:49.217458+02	PRODUCTEUR	\N	t
9027c481-fbc6-4681-8612-1800eb5d6bf0	PROD-PHOTO-D3CA32	Ondimba	Alice	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	Test photos lot	\N	SYNCED	1	\N	2026-08-15 17:43:31.080871+02	2026-08-15 17:48:02.695583+02	2026-08-15 17:48:02.695088+02	PRODUCTEUR	\N	t
ace5e7b6-96ec-4f2b-9146-6d22fdde26ee	AGF-0b09e6	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:19.359612+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
fed1ccfc-0904-4704-85b9-4d8bd8a3af98	PRD-OTH-7dc5e4	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:16.926718+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
dbfaa73b-99d8-412e-b7d0-614d22408dca	AGF-3b1820	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:51:02.269832+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
87e98748-a24e-4ae5-98cc-8b028986a11a	PRD-OWN-4988d1	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:50:59.880731+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
88f42de2-5646-4008-a283-2539f2e43e21	PRD-MEM-fa90f7	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 14:50:59.88693+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
b5f6b687-db90-4646-a7a9-cd09f12439f4	RBAC-cooperative-0c3cfc	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:31.737939+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
9563aec3-96d4-454d-920b-8fb2b2d8c206	AGF-56f461	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:32.825912+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
28658b55-e711-4ca0-bd25-e2d71b74d960	PRD-OTH-6e029c	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:30.277369+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
56c1a5ac-79d8-4881-bc1b-af37b1add5c0	RBAC-producteur-d9298c	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.562278+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
1d2d6de2-a62e-494e-96d3-10e33d01bca9	RBAC-cooperative-cc9bff	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:10.579805+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
af3540a1-9c75-4321-b421-81c070180808	AGF-54ea72	Terrain	Agent	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:11.611154+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
a10ef888-85b6-46f9-8591-d3da6eba4b5c	PRD-OTH-f1fb7e	Autre	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:09.219097+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
d8f1ea56-6a02-4de3-9730-47e39a0a1df8	PRD-OWN-2cf74f	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:55:09.210028+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
5226f554-ac72-4d29-ab0a-64d8be484a1c	PRD-MEM-9e4c8c	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 14:55:09.21547+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
ceef2c73-0866-4ade-b4e5-40029ee9236d	PRD-OWN-a1ba40	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:16.903117+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
3c82ea68-8f13-404d-85be-4333679fb1c2	PRD-MEM-a7902d	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 14:56:16.921947+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
1c012791-98f7-4b5e-81b7-5e553492aedf	PRD-OWN-512576	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-13 14:56:30.266828+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
143ffb3e-853a-41d9-9c65-ec683695769d	PRD-MEM-7cc668	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-13 14:56:30.274196+02	2026-08-19 12:40:41.506247+02	2026-08-19 12:40:41.390084+02	PRODUCTEUR	\N	t
b08a2333-4e66-4098-b6bc-ee7047e6437f	RBAC-producteur-a94a67	N	P	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-19 15:37:33.960426+02	\N	\N	SYNCED	1	\N	2026-08-19 12:40:47.828602+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
c660c2be-c52d-4fa6-8273-0f754efc497f	PRD-C660C2BE	prod2	2	2000-06-23	\N	\N	+24174054315	prod2@outlook.com	bakoko	cb1698dc-1a3a-4f23-ae61-0672d2e579db	9dd6b61b-bd21-4ef1-b6ee-8b1edacf4283	6559b9af-f6a9-4570-9028-12973b6b8b56	0.3684810	9.4828480	\N	\N	601c6616-d69f-4019-b949-0d5e84cf694b	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-09-23 11:22:52.296631+02	Inscription publique le 23/09/2026 09:19 (IP 127.0.0.1). Message du demandeur : je vends	\N	SYNCED	1	\N	2026-09-23 11:19:22.534568+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
ec85036a-5257-4af4-b23e-dddb05a58828	PRD-EC85036A	Ondo	Jean	\N	\N	\N	074123456	test.producteur.ed721073@pnlf-test.local	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	98e2a59e-389d-4b72-ba98-0c3c026dcae1	ACTIF	cd88d15c-2bc8-466f-a9cd-46598dbe61dd	2026-08-15 16:23:03.234143+02	Inscription publique le 15/08/2026 14:23 (IP 127.0.0.1). Message du demandeur : Je collecte du moabi et du kola.	\N	SYNCED	1	\N	2026-08-15 16:23:02.427509+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
05829c24-382b-4e30-9633-12241b7f2f97	PRD-OWN-7c438f	Producteur	Propre	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	41f20506-4b04-4203-900c-5c52ab3209bf	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:40:46.990428+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:40:48.439047+02	PRODUCTEUR	\N	t
2b8c129b-fb77-4744-9ccf-a172c4e7431f	PRD-MEM-49b508	Membre	Coop	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	coop ok	\N	SYNCED	1	\N	2026-08-19 12:40:46.993073+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:40:48.439047+02	PRODUCTEUR	\N	t
eb2c74d5-1101-4af8-8797-9bbaaf3b8043	PRD-EB2C74D5	MPAMBOU	Wadrice	\N	\N	\N	+24174054314	staeelbent16@gmail.com	nzeng ayong	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	8e640ef4-cc64-4b9d-ad40-29c7506bc205	16d0886d-942b-4a2a-a36b-54594d9a232e	\N	\N	\N	\N	ec38d815-0579-448c-b7dd-1c54b8dce005	ACTIF	2992fb5e-5580-483b-9462-98fe46cf7627	2026-08-15 16:42:24.636151+02	Inscription publique le 15/08/2026 14:41 (IP 127.0.0.1). Message du demandeur : je suis un producteur désireux de vendre mes produit	\N	SYNCED	1	\N	2026-08-15 16:41:35.979927+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02	PRODUCTEUR	\N	t
4f34afb3-9c20-4e22-b443-ce5b4d50f7df	PRD-PAR-1728a6	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:10:29.994577+02	2026-09-23 17:12:46.065062+02	2026-08-19 13:10:31.973516+02	PRODUCTEUR	\N	t
0440e25f-1a0c-491a-86b3-a1c5bee2f26a	PRD-EXT-898daa	Parcours	Externe	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	\N	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 13:10:30.000113+02	2026-09-23 17:12:46.065062+02	2026-08-19 13:10:31.973516+02	PRODUCTEUR	\N	t
d8c58101-a2c7-4e35-a49d-a8a8476af4e1	PRD-PAR-3ad7a5	Parcours	Own	\N	\N	\N	\N	\N	\N	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	\N	\N	1a62a7d6-150a-4243-8056-3025dab6cbf7	ACTIF	\N	\N	\N	\N	SYNCED	1	\N	2026-08-19 12:21:10.911216+02	2026-09-23 17:12:46.065062+02	2026-08-19 12:21:12.750623+02	PRODUCTEUR	\N	t
c6c3eee1-a671-4e21-8c35-b792af24efc6	PRD-C6C3EEE1	IKAPI	Ghislain	1982-12-01	\N	\N	+241077000208	producteur.attente@demo.pfnl.ga	Koulamoutou	b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	3a51074b-871e-495f-a135-1d7028b67916	ebb8b1cb-485b-47a9-8ce0-cd9ca339879d	\N	\N	\N	\N	aac56367-b288-4ac9-8b81-d1c202be4ef8	EN_VALIDATION	\N	\N	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-10-02 12:06:29.568347+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
34cc9c4d-801a-4e72-9ff8-2e673be01804	PRD-34CC9C4D	MBOUMBA	Sylvie	1988-06-30	\N	\N	+241077000204	producteur.independant@demo.pfnl.ga	Oyem	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	f4bae033-8914-4808-baca-cd59c094bd6f	173062b5-4dab-4964-99bc-dfad03972d2b	1.5995000	11.5793000	\N	\N	5dfd8155-3222-4e05-9702-06e9cc47cca1	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:35.589152+02	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-10-02 12:06:27.842081+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
5acc6d02-db6c-4886-80f7-2344e223ec3f	PRD-5ACC6D02	BOUSSOUGOU	Arnaud	1993-02-14	\N	\N	+241077000206	producteur.rejete@demo.pfnl.ga	Tchibanga	86a5e90b-c713-4ccc-affe-2480b77fbbf0	0967f0c8-f287-4f32-abf3-7856e34dc2a3	97af34fb-69e1-4382-b96b-126390762621	\N	\N	\N	\N	\N	REJETE	70dd1a0a-1111-47f4-9a12-efd092fbc67a	2026-10-02 12:06:35.695314+02	Pièce d’identité illisible et zone de collecte non renseignée.	\N	SYNCED	1	\N	2026-10-02 12:06:28.543403+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
8d14134e-2de3-49e6-bc73-9e18699258a1	PRD-8D14134E	NGUEMA	Fabrice	1975-11-08	\N	\N	+241077000205	producteur.inactif@demo.pfnl.ga	Lambaréné	395a5ce3-066b-4a05-a931-fc5848038cde	3e7fe5b2-697f-44d4-80a0-0ff2ebd195b7	f926c47f-bcfb-410b-bb15-912e261e194d	\N	\N	\N	\N	1d6791e9-3b17-4369-9041-924118ba2d22	INACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:35.623444+02	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-10-02 12:06:28.191553+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
d085f4ac-9b58-447e-ab11-fbcc26bb5163	DEMO-PRD-T03	MAGANGA	Rosine	1980-05-09	PASSEPORT	DEMO-PP-T03	+241066000503	\N	Ndendé	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	d13daecd-deef-44a6-ba6a-7bdfe8ac3ac2	a4ffe8c8-8260-490e-ad1a-663ffc3384a5	\N	\N	\N	\N	\N	EN_VALIDATION	\N	\N	Dossier en attente de la copie du passeport.	45e76e3b-b74f-5aab-846c-cb3bedcc01f7	SYNCED	1	\N	2026-10-02 12:06:36.218461+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
b8515540-29f1-4ccc-97d5-a08be4e598af	DEMO-PRD-T02	NZÉ	Bertrand	1972-08-17	CNI	DEMO-CNI-T02	+241066000502	\N	Mitzic	3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	f4bae033-8914-4808-baca-cd59c094bd6f	173062b5-4dab-4964-99bc-dfad03972d2b	\N	\N	\N	\N	\N	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:36.289641+02	Collecteur itinérant, fiche masquée de l’annuaire public à sa demande.	beb6725a-cae9-5f0a-951d-cd586edaad33	SYNCED	1	\N	2026-10-02 12:06:36.186544+02	2026-10-02 12:06:24.799502+02	\N	COLLECTEUR	\N	f
efddd969-6c0b-49f0-9204-5c846f4f7bba	PRD-EFDDD969	MOUSSAVOU	Marie-Claire	1985-09-03	\N	\N	+241077000202	producteur.kola@demo.pfnl.ga	Makokou	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	e4d7dea5-9056-4c46-b905-74aae292e4dd	bf148f8d-5f09-4d82-850d-a48aec703c8b	0.5736000	12.8642000	\N	17c571aa-c973-4da4-abe2-59fc08b7ded2	b64ff13b-0617-456b-9589-257f95ae4fb7	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:35.553124+02	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-10-02 12:06:27.159983+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
32b71cac-11e7-4f9e-a7e9-b909b42a7154	PRD-32B71CAC	OBIANG	Paul	1990-01-21	\N	\N	+241077000203	collecteur.ogooue@demo.pfnl.ga	Booué	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	e4d7dea5-9056-4c46-b905-74aae292e4dd	bf148f8d-5f09-4d82-850d-a48aec703c8b	\N	\N	\N	17c571aa-c973-4da4-abe2-59fc08b7ded2	97a54b08-c1ef-46eb-8505-1f31b5cadb80	ACTIF	96c362a7-7215-490a-8443-371d2768cd2e	2026-10-02 12:06:35.657002+02	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1).	\N	SYNCED	1	\N	2026-10-02 12:06:27.49062+02	2026-10-02 12:06:24.799502+02	\N	COLLECTEUR	\N	t
ffd2f32f-0ed0-48ec-a502-f250ca779820	DEMO-PRD-C01	MINKO	Odette	1987-10-02	CNI	DEMO-CNI-C01	+241066000504	\N	Mékambo	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	e4d7dea5-9056-4c46-b905-74aae292e4dd	bf148f8d-5f09-4d82-850d-a48aec703c8b	\N	\N	\N	17c571aa-c973-4da4-abe2-59fc08b7ded2	\N	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:36.310217+02	Membre enregistrée par la coopérative.	9e717f56-b29b-5226-845f-0421fe96e26f	SYNCED	1	\N	2026-10-02 12:06:36.248978+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
ad0c1500-c241-4d87-90c6-ac3ec914f53a	PRD-AD0C1500	NDONG	Jean-Baptiste	1979-04-12	\N	\N	+241077000201	producteur.miel@demo.pfnl.ga	Fougamou	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	d13daecd-deef-44a6-ba6a-7bdfe8ac3ac2	a4ffe8c8-8260-490e-ad1a-663ffc3384a5	-1.2167000	10.5833000	\N	e5326de4-90ed-4b3b-acab-5c847db8bf0a	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:35.51275+02	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1). Message du demandeur : Apiculteur traditionnel, 40 ruches en forêt.	\N	SYNCED	1	\N	2026-10-02 12:06:26.295807+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
b3d30962-b5cb-45b7-8abc-f1c7a83f9a46	DEMO-PRD-T01	ONDO MBA	Célestin	1968-03-25	CNI	DEMO-CNI-T01	+241066000501	\N	Village Ntsiété	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	e4d7dea5-9056-4c46-b905-74aae292e4dd	bf148f8d-5f09-4d82-850d-a48aec703c8b	0.5500000	12.7000000	\N	\N	\N	ACTIF	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-02 12:06:36.270057+02	Recensé lors de la tournée terrain de mars ; ne dispose pas de smartphone.	03cafc6b-0c02-547b-9421-3c4d7cdfaa3d	SYNCED	1	\N	2026-10-02 12:06:36.154009+02	2026-10-02 12:06:24.799502+02	\N	PRODUCTEUR	\N	t
47d0baea-0308-4618-ac9a-dcb5319e4d26	PRD-47D0BAEA	MAPANGOU	Christelle	1991-07-19	\N	\N	+241077000207	collecteur.attente@demo.pfnl.ga	Franceville	cb1698dc-1a3a-4f23-ae61-0672d2e579db	d595baea-82f0-4e05-a141-f650a012ee28	b06dbedb-3ff0-4209-bf85-179520537822	\N	\N	\N	\N	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	EN_VALIDATION	\N	\N	Inscription publique le 02/10/2026 10:06 (IP 127.0.0.1). Message du demandeur : Collectrice de champignons et de safou sur l’axe Franceville - Moanda.	\N	SYNCED	1	\N	2026-10-02 12:06:29.035607+02	2026-10-02 12:06:24.799502+02	\N	COLLECTEUR	\N	t
\.


--
-- TOC entry 6956 (class 0 OID 69583)
-- Dependencies: 241
-- Data for Name: produits; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.produits (id, code, nom, nom_scientifique, categorie_id, description, unite_defaut, soumis_cites, code_cites, actif, created_at, updated_at, image_path) FROM stdin;
22cd568c-3fa9-4518-871b-fe9f3d658b97	PFNL-MIEL-SAUV	Miel sauvage / miel de forêt	Apis mellifera adansonii	e4e07e44-216b-456b-90b8-2845de865057	Miel issu de la forêt équatoriale gabonaise	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
f3bac528-2d07-4b1a-a300-dd2d5fd327ac	PFNL-CIRE	Cire d'abeille	\N	e4e07e44-216b-456b-90b8-2845de865057	Sous-produit apicole	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
ba78f0de-2b31-4349-9f1f-8ea2607bfe3d	PFNL-PROPOLIS	Propolis	\N	e4e07e44-216b-456b-90b8-2845de865057	Résine apicole	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
e97a4f94-ef6d-4988-b3d1-319fa87de3c5	PFNL-MOABI-NOIX	Noix / amandes de moabi	Baillonella toxisperma	943a01d8-e052-415b-ad56-ac9be3c5cc42	Amandes pour huile comestible — espèce emblématique du Gabon	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
05fcfa33-5ec2-43e3-98d7-1b50cb29a91a	PFNL-MOABI-HUILE	Huile de moabi	Baillonella toxisperma	943a01d8-e052-415b-ad56-ac9be3c5cc42	Huile extraite des amandes de moabi	LITRE	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
dafedd72-af4f-410b-b81b-e55d238c9280	PFNL-COULA	Noisettes d'Afrique (owala)	Coula edulis	943a01d8-e052-415b-ad56-ac9be3c5cc42	Noisettes forestières	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
a0a0d114-3cf6-400f-8dd7-4cdddd0792f8	PFNL-KOLA	Noix de kola	Cola nitida / Cola acuminata	943a01d8-e052-415b-ad56-ac9be3c5cc42	Stimulant traditionnel	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
03e2ea27-7d14-4024-a157-b0fa4e2ccb13	PFNL-ODIKA	Odika / mangue sauvage	Irvingia gabonensis	ca039312-f99b-420c-ad60-15f78eae03f1	Fruits et amandes (andok)	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
20c3ba11-7016-4166-8e92-f53e482a181e	PFNL-SAFOU	Safou	Dacryodes edulis	ca039312-f99b-420c-ad60-15f78eae03f1	Fruit oléagineux très consommé	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
5f306e08-3b87-4cb9-95e7-7ff7020e0425	PFNL-ATANGA	Atanga	Pachylobus edulis	ca039312-f99b-420c-ad60-15f78eae03f1	Fruit forestier / agroforestier	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
4537cff5-7a87-4bb8-8a3e-dc9586dab36b	PFNL-NKUMU	Nkumu (feuilles)	Gnetum africanum	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Légume-feuille forestier	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
ec06371d-e297-438b-8d26-bb2b6d21804e	PFNL-IBOGA	Iboga (racine / écorce)	Tabernanthe iboga	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Plante médicinale réglementée — usage contrôlé	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
ba844800-8b27-48f4-a3b9-0dc73c8edfd0	PFNL-GARCIA-KOLA	Bois amer (Garcinia)	Garcinia kola	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Graines / écorces médicinales	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
16f0cac4-9798-42fa-b08c-43941ea9a87f	PFNL-POIVRE-G	Poivre de Guinée	Piper guineense	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Épice forestière	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
612f77eb-9cea-4dc0-a103-9419d8b82830	PFNL-AFRAMOMUM	Maniguette / Aframomum	Aframomum spp.	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Fruits aromatiques	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
9b81e198-8133-4aab-b8e2-c06c8781589d	PFNL-MARANTACEES	Feuilles d'emballage (Marantacées)	Megaphrynium / Marantochloa spp.	13f789df-f0c4-4fb0-975a-cd0b0c4c657b	Feuilles pour emballage alimentaire	BOTTE	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
298383cc-96f4-486d-b8aa-d3d5948a67de	PFNL-ECORCE-MED	Écorces médicinales diverses	\N	6d59205c-75c6-449b-b8d5-c0a5d894ff61	Écorces à usage pharmacopée traditionnelle	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
38d243ac-a8f6-4024-a33e-4b4e9c46e27a	PFNL-ALSTONIA	Écorce d'Alstonia	Alstonia boonei	6d59205c-75c6-449b-b8d5-c0a5d894ff61	Usage médicinal	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
ce48779e-f16b-4148-9eb9-e26636c7baaf	PFNL-ROTIN	Rotin	Laccosperma / Eremospatha spp.	b4fdb694-b4e2-485a-8037-2f3c9792062b	Lianes pour artisanat et construction	METRE	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
54afbc25-3ba9-459a-87e7-dac1926367c5	PFNL-BAMBOU	Bambou	Bambusa / Oxytenanthera spp.	b4fdb694-b4e2-485a-8037-2f3c9792062b	Tiges pour construction et artisanat	METRE	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
6968151a-6f96-46bc-84da-c56eb7b484a9	PFNL-RAPHIA	Raphia	Raphia spp.	b4fdb694-b4e2-485a-8037-2f3c9792062b	Fibres, feuilles, vin de palme	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
cbc6ebe5-a267-413c-8848-7e5e26ce2c09	PFNL-CHAMP	Champignons comestibles forestiers	\N	4148fb8a-9bdb-4359-b5bc-ea49c9234009	Champignons saisonniers de sous-bois	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
df527935-1b53-4d8f-be5d-4e24ae8b7ab2	PFNL-CHENILLES	Chenilles comestibles	\N	f87fb134-0856-47c3-9b2d-35f0b9fe2837	Protéines forestières — conformité réglementaire requise	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
a596ea63-f021-4066-8dc3-3b8c096686ef	PFNL-ESCARGOTS	Escargots de forêt	Archachatina spp.	f87fb134-0856-47c3-9b2d-35f0b9fe2837	Mollusques comestibles	KG	f	\N	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02	\N
23a50256-8c19-4052-9107-b5af0c971952	TST-MIEL-01	Miel test PNLF	\N	153d9f97-d3bc-4daf-ac7b-55bc6cef22a3	\N	KG	f	\N	f	2026-08-10 14:35:57.36064+02	2026-08-10 14:49:06.017096+02	\N
14102286-f9a4-440e-bc84-916df15b9a2d	TST-AG-6dc84e	Produit agent	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 12:33:15.39556+02	2026-08-13 12:33:15.763722+02	\N
c251228a-fc87-4b0d-b6ee-e3c076ebda98	X9ca61c	Archivé 9ca61c	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:51:01.136433+02	2026-08-13 14:56:08.878375+02	\N
ae1d54f6-f1e2-4af9-a622-2a4f9e190d02	Xf3999e	Archivé f3999e	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:55:10.453512+02	2026-08-13 14:56:08.881186+02	\N
86a4d7fd-0461-4b95-a732-01aaff3f5714	X3b745e	Archivé 3b745e	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:51:01.200331+02	2026-08-13 14:56:08.884882+02	\N
d399f5eb-2a9b-40e4-8375-ca21f1e35f7c	X5f1a20	Archivé 5f1a20	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:55:10.412421+02	2026-08-13 14:56:08.872883+02	\N
6d5be948-2e51-468a-9b31-888978f073ec	Xaa43c9	Archivé aa43c9	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:56:18.129948+02	2026-08-13 14:56:21.685705+02	\N
ae926c05-4142-47b7-9b08-4f8b089376b4	Xdd9fc7	Archivé dd9fc7	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:56:18.192777+02	2026-08-13 14:56:21.693798+02	\N
acbeb789-ea63-4010-808b-c1967da0ef3f	TST-LOTPHOTO-01	Kola test photos	\N	153d9f97-d3bc-4daf-ac7b-55bc6cef22a3	\N	KG	f	\N	t	2026-08-15 17:43:31.080871+02	2026-08-15 17:43:31.080871+02	\N
d02aa82b-40df-4936-bc1c-5724ac6201f7	X11e389	Archivé 11e389	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 15:18:59.030481+02	2026-08-19 12:40:41.551263+02	\N
9ccad303-69e7-4d5f-adaa-78462be552ab	X9527a2	Archivé 9527a2	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:56:31.531453+02	2026-08-13 15:16:51.882447+02	\N
84bd1b2d-fe96-44f4-b4dc-676280156bc1	X5cf82f	Archivé 5cf82f	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 14:56:31.596119+02	2026-08-13 15:16:51.904087+02	\N
31b414ae-fda4-4240-9083-0c763334d443	X06f9d0	Archivé 06f9d0	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-13 15:18:59.086265+02	2026-08-19 12:40:41.561979+02	\N
e0c450dd-b3c7-47fa-b49f-fd6248fd972b	RBAC-admin-72aa7d	Test RBAC admin 748cbc	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-19 12:40:47.716637+02	2026-08-19 12:40:48.454249+02	\N
2ab0e878-f995-4108-acdd-7ce0a37c51d2	RBAC-agent_min-16274b	Test RBAC agent_min f6c11d	\N	ca039312-f99b-420c-ad60-15f78eae03f1	\N	KG	f	\N	f	2026-08-19 12:40:47.728862+02	2026-08-19 12:40:48.456126+02	\N
\.


--
-- TOC entry 6946 (class 0 OID 69267)
-- Dependencies: 231
-- Data for Name: provinces; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.provinces (id, code, nom, geom, actif, created_at, updated_at) FROM stdin;
c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	EST	Estuaire	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
cb1698dc-1a3a-4f23-ae61-0672d2e579db	HAO	Haut-Ogooué	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
395a5ce3-066b-4a05-a931-fc5848038cde	MOY	Moyen-Ogooué	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	NGO	Ngounié	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
86a5e90b-c713-4ccc-affe-2480b77fbbf0	NYA	Nyanga	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
e1b4f519-6b38-40e4-af34-e66a2b43d2c5	OGO	Ogooué-Ivindo	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
b9cbce9f-1f1c-450e-8cf2-f32d93f7c395	OLR	Ogooué-Lolo	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
5bac0569-7d48-4e2d-bcd3-d2701bb6f3fe	OMR	Ogooué-Maritime	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
3a6cfa1f-7f77-4981-99d5-a5ea9297e4c8	WOL	Woleu-Ntem	\N	t	2026-08-10 13:35:41.270016+02	2026-08-10 13:35:41.270016+02
\.


--
-- TOC entry 6951 (class 0 OID 69403)
-- Dependencies: 236
-- Data for Name: reinitialisations_mdp; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.reinitialisations_mdp (id, utilisateur_id, token_hash, expire_at, utilise_at, created_at) FROM stdin;
\.


--
-- TOC entry 6950 (class 0 OID 69380)
-- Dependencies: 235
-- Data for Name: sessions; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.sessions (id, utilisateur_id, jti, refresh_token_hash, ip_adresse, user_agent, expire_at, revoquee_at, created_at) FROM stdin;
\.


--
-- TOC entry 6971 (class 0 OID 70024)
-- Dependencies: 256
-- Data for Name: sync_conflicts; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.sync_conflicts (id, appareil_id, entite, client_uuid, payload_client, payload_serveur, resolu, resolution, created_at, resolved_at) FROM stdin;
b9e97460-bb30-4a48-8791-cb97276aace3	d5b914b0-b41f-4c09-ba0d-47bad37f5a0f	producteurs	03cafc6b-0c02-547b-9421-3c4d7cdfaa3d	{"nom": "ONDO MBA", "client_uuid": "03cafc6b-0c02-547b-9421-3c4d7cdfaa3d", "sync_version": 0}	{"id": "b3d30962-b5cb-45b7-8abc-f1c7a83f9a46"}	f	\N	2026-10-02 12:06:46.715745+02	\N
a92f63cf-c8cf-47c5-b842-fe35aafc7336	d5b914b0-b41f-4c09-ba0d-47bad37f5a0f	producteurs	beb6725a-cae9-5f0a-951d-cd586edaad33	{"nom": "NZÉ", "client_uuid": "beb6725a-cae9-5f0a-951d-cd586edaad33", "sync_version": 0}	{"id": "b8515540-29f1-4ccc-97d5-a08be4e598af"}	t	Version serveur conservée : fiche validée plus récente que la saisie hors ligne.	2026-10-02 12:06:46.758298+02	2026-10-02 12:06:46.903745+02
\.


--
-- TOC entry 6961 (class 0 OID 69794)
-- Dependencies: 246
-- Data for Name: types_certification; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.types_certification (id, code, libelle, organisme, description, duree_mois, actif, created_at) FROM stdin;
d167f4d2-337e-4752-b78a-e6ab3d31a4d5	BIO	Certification biologique	\N	\N	12	t	2026-08-10 13:35:41.270016+02
d397d40b-41f3-4b13-829f-ed968f38e24a	ORIGINE	Certification d'origine	Ministère des Eaux et Forêts	\N	24	t	2026-08-10 13:35:41.270016+02
e5a74b63-1870-45b3-bdcf-45e4d5ecc763	QUALITE	Certification qualité	\N	\N	12	t	2026-08-10 13:35:41.270016+02
dc77ac1e-27ba-4f83-b809-203f34d35933	CITES	Permis / certificat CITES	Autorité CITES Gabon	\N	12	t	2026-08-10 13:35:41.270016+02
\.


--
-- TOC entry 6949 (class 0 OID 69344)
-- Dependencies: 234
-- Data for Name: utilisateurs; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.utilisateurs (id, email, telephone, mot_de_passe_hash, role, statut, nom, prenoms, double_auth_active, derniere_connexion, tentatives_echec, verrouille_jusquau, doit_changer_mdp, preferences_notif, created_at, updated_at, deleted_at) FROM stdin;
85e73743-f268-4751-b855-3b529e7d800b	chat.acheteur.insc.5f8112@pnlf-test.local	074999111	$2b$12$AvGvGBRZ11MKG7bwImjh2Ovq4IbRVRRheOhjGqFN09ckX6JktklbO	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 20:17:33.996418+02	2026-08-27 20:17:34.719827+02	2026-08-27 20:17:34.719436+02
b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	\N	$2b$12$IuzllWbg3KNcuuO4jUcr9OVD0xuR6c4Mdlp3h2yuG7gG/5nCGRDqW	ACHETEUR	INACTIF	Test	acheteur	f	2026-08-19 12:40:46.946861+02	0	\N	f	EMAIL	2026-08-13 14:50:59.414288+02	2026-08-19 12:40:48.464319+02	2026-08-19 12:40:48.439047+02
1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	\N	$2b$12$unY8fte4EAM5qsocv6N9GuZ8s29a/04FouwmH2XeuUZzLWkrp5fmy	PRODUCTEUR	INACTIF	Parcours	producteur	f	2026-08-19 13:10:30.688251+02	0	\N	f	EMAIL	2026-08-19 12:20:15.785598+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
6f7dcede-2c55-4090-b71b-394d41e6fbac	parcours_attente_ac43475c@pnlf-test.local	\N	$2b$12$Dr28ZQ577qkxRe7r6sEuBuAFLHh/DKuSdOVHmcfDpPZ5a06Ovai4y	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 13:10:30.915892+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	+241077000301	$2b$12$i6.ipB2o9tB4q5yVC.ZGweaAkBH102FXed2ydw4i45/oYKEeiwveW	COOPERATIVE	ACTIF	Coopérative des Saveurs de l’Ivindo		f	2026-10-03 16:48:39.524734+02	0	\N	f	EMAIL	2026-10-02 12:06:30.204846+02	2026-10-03 16:48:39.525316+02	\N
1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	+241077000302	$2b$12$mAmaY3OuSFP2bn0YaQvYC.AYsYkjKegtMHPiqL81ELTsFvSE/sE9y	COOPERATIVE	ACTIF	Coopérative Miel et Forêt de la Ngounié		f	2026-10-03 16:48:39.993954+02	0	\N	f	EMAIL	2026-10-02 12:06:30.908028+02	2026-10-03 16:48:39.994663+02	\N
1051c839-763f-4a10-9f0e-7b64d301a393	test_admin@pnlf-test.local	\N	$2b$12$0CbxedviFRq.n2cqvPCv3.Zjud0.TR5b2Yk3v/HpN/6bSURipcBsu	ADMINISTRATEUR	ACTIF	Test	admin	f	2026-08-13 12:33:15.648723+02	0	\N	f	EMAIL	2026-08-13 12:31:36.42479+02	2026-08-19 12:40:41.564497+02	\N
f4287552-2689-4335-9fbc-ed2c03597d71	chat.acheteur.insc.16483d@pnlf-test.local	074999111	$2b$12$JRriiMl73PYhYa1TKGKjxOq/IQ0jfhxDOw0P8qw8H8dO.FTY2JwUu	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-09-21 13:00:04.221207+02	2026-09-21 13:00:04.909504+02	2026-09-21 13:00:04.909044+02
97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	+241077000203	$2b$12$WatM8AaWW9x7Ey9zX1EWa.FRbRPCuQOV15pwgArGOts/E7wMqQnTW	PRODUCTEUR	ACTIF	OBIANG	Paul	f	2026-10-03 16:48:42.031486+02	0	\N	f	EMAIL	2026-10-02 12:06:27.49062+02	2026-10-03 16:48:42.031943+02	\N
b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	+241077000303	$2b$12$23H2PpyjY79ev5fJezCvMe5Xw.td9ZSrxTehz3nbf5uKktpoKBX/C	COOPERATIVE	INACTIF	Coopérative Rotin et Raphia de l’Estuaire		f	\N	0	\N	f	EMAIL	2026-10-02 12:06:31.753698+02	2026-10-02 18:22:27.091825+02	\N
eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	+241077000401	$2b$12$qr3ouimAW/Hh12LuEAXDcuPfPHoby5.ofQSZizKW5NtHuiDgng.2W	ACHETEUR	ACTIF	DIBANGA	Laurent	f	2026-10-03 16:48:43.918613+02	0	\N	f	EMAIL	2026-10-02 12:06:34.397978+02	2026-10-03 16:48:43.919283+02	\N
2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	\N	$2b$12$Kn.prkOe5NMDgE8UvxMaIe/45m6tn71fmmP2MPKW8DX1wu4kQyU6y	ADMINISTRATEUR	ACTIF	Administrateur	Système	f	2026-10-06 13:57:23.736695+02	0	\N	f	EMAIL	2026-08-10 13:35:41.270016+02	2026-10-06 13:57:23.737297+02	\N
cd88d15c-2bc8-466f-a9cd-46598dbe61dd	inscription_test_admin@pnlf-test.local	074000000	$2b$12$oT/bYsOv/SBu3FU1QhRynuROUmAqOlR6cVNFEvVKkLLzkJ6aUzHmO	ADMINISTRATEUR	ACTIF	Test	Admin	f	\N	0	\N	f	EMAIL	2026-08-15 16:21:15.383023+02	2026-08-19 12:40:41.564497+02	\N
1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	+241077000205	$2b$12$aXRy.XfKQSVgWFHpAH76PebeDMsuC/xZ7fNIflK0cqL0ePQ4b8W0S	PRODUCTEUR	INACTIF	NGUEMA	Fabrice	f	\N	0	\N	f	EMAIL	2026-10-02 12:06:28.191553+02	2026-10-02 12:06:24.799502+02	\N
d86f7f2c-f363-4f5a-9e14-e8232893566e	chat.acheteur.insc.fbd6df@pnlf-test.local	074999111	$2b$12$hTDD2SgUpZXo9kJws33sXect08XiMwHiSiObWxKoSR0ii/IDMSUYu	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 20:07:11.912819+02	2026-08-27 20:07:12.851447+02	2026-08-27 20:07:12.850145+02
28685225-99bb-47f6-bee0-44618f80115d	cadrage_admin@pnlf-test.local	\N	$2b$12$R8WTVZ4attleblQ.ID/p.eEDwpGthZvYgNNC3gRW83.5dbZNFgFP.	ADMINISTRATEUR	ACTIF	T	U	f	2026-08-13 15:36:12.632002+02	0	\N	f	EMAIL	2026-08-13 15:19:34.642268+02	2026-08-19 12:40:41.564497+02	\N
d2dd8717-64d9-47e9-a533-4fdce48ba54e	test_agent_min@pnlf-test.local	\N	$2b$12$JCGG1aQQMqzbb158vUg3wuu3oRmdPuMDOMPJ3HOTM90eshPm2jxVC	AGENT_MINISTERE	INACTIF	Test	agent_min	f	2026-08-13 12:33:15.34204+02	0	\N	f	EMAIL	2026-08-13 12:31:38.958176+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
71b962d9-fdb9-4b61-a931-c6676b9225fd	test.producteur.e17bba51@pnlf-test.local	074123456	$2b$12$Wzd6EY5Zwua3LFTJ4ZlAResTfyIT4wv3nBY1xHa/MLfJLSWOEgGa.	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:26:38.186058+02	0	\N	f	EMAIL	2026-08-15 16:26:37.130024+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
96727eed-8f24-40ae-92bf-29469b0dde74	chat.acheteur.insc.8a16a5@pnlf-test.local	074999111	$2b$12$XL1lqdTJX6igBd7DJaqhqOGgFgr7/0/lBmmOiMmJY68E9F3q6IG/i	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 16:46:13.133656+02	2026-08-27 16:46:14.710365+02	2026-08-27 16:46:14.708766+02
ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	+24174054314	$2b$12$qTxttwzVtXmAwOwQBi0nUecbbVj/dkXWD1a2Qq4u5Grmxgpt09YMe	PRODUCTEUR	INACTIF	MPAMBOU	Wadrice	f	2026-09-21 15:56:33.848506+02	0	\N	f	EMAIL	2026-08-15 16:41:35.979927+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	066139853	$2b$12$xdycAEgcn7.6/ChsQMgMu.L8Y0mZfUq.1SSfddN8mK5nEs5DzJIg2	PRODUCTEUR	INACTIF	manomba	sylvie	f	2026-08-21 19:08:16.799175+02	2	\N	f	EMAIL	2026-08-15 18:25:48.056524+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
ab1d8bde-21c5-4301-97a9-e531c968d890	parcours_attente_e8f55a10@pnlf-test.local	\N	$2b$12$RzXz6wiVPM1rUMGnsYVk5ORyGzcTKHFbX0CLhomR4kbofpmivcKH2	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 12:40:19.043312+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
c2339e87-f4ef-4ea5-9e8b-7ae816c1aeed	test.coop.6a5db5f2@pnlf-test.local	074987654	$2b$12$Y4YvLquVuZK1Whpbhc/Jm.rbnXMWUzPG7JFtLtdRgdN6eIN8q.Rju	COOPERATIVE	INACTIF	Coopérative Test Moabi		f	\N	0	\N	f	EMAIL	2026-08-15 16:26:19.282422+02	2026-10-02 18:22:27.091825+02	2026-09-23 17:12:46.065062+02
5a25c729-bbbb-4a4a-bcc2-c95a4362f2d7	lot_photo_test_admin@pnlf-test.local	074000001	$2b$12$BtEmQUYRk9KZ6uNiZ/YU4.JhdomFmdOZkwm5qmcBs5i8p26fD2rLa	ADMINISTRATEUR	ACTIF	Test	Admin	f	\N	0	\N	f	EMAIL	2026-08-15 17:43:30.855289+02	2026-08-19 12:40:41.564497+02	\N
0a9685ee-5251-430e-96d0-3557d3935fd0	test.coop.c442cf35@pnlf-test.local	074987654	$2b$12$lPHT/Eq38TnjyGC7MPllr.sSgYIlghclyzlU1aTsOnxPq146Yq1OG	COOPERATIVE	INACTIF	Coopérative Test Moabi		f	\N	0	\N	f	EMAIL	2026-08-15 16:30:18.457542+02	2026-10-02 18:22:27.091825+02	2026-09-23 17:12:46.065062+02
3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	\N	$2b$12$Y9N5LetuYjYswnxHLWY6o.Hgq/xtFCLo9DbqeU1N7E3N8jlrcmBCa	AGENT_MINISTERE	INACTIF	Parcours	agent_min	f	2026-08-19 13:10:26.386178+02	0	\N	f	EMAIL	2026-08-19 12:20:14.657059+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	\N	$2b$12$FiD4tDydjlb5RC5pIhmogOELJjERxwJjCRqIKQN6ooMKE9r3..AI2	AGENT_FORESTIER	INACTIF	Parcours	agent_for	f	2026-08-19 13:10:26.986273+02	0	\N	f	EMAIL	2026-08-19 12:20:15.258226+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	\N	$2b$12$Tk0nzM6U8IzbFvshDZ2I8uM9QKsKgFZU3l6sAppQXB0XAqfjs.zKm	COOPERATIVE	INACTIF	Parcours	cooperative	f	2026-08-19 13:10:28.816767+02	0	\N	f	EMAIL	2026-08-19 12:20:16.342538+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	\N	$2b$12$7gPgQ1iu/8yogb9rFCwfK.e5s6RFWDuhwrUYXpkclpbn93Lw9t/wC	ACHETEUR	INACTIF	Parcours	acheteur	f	2026-08-19 13:10:29.967428+02	0	\N	f	EMAIL	2026-08-19 12:20:16.920277+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	\N	$2b$12$NqEh1IdqiQOBYFiqec3j8OzpgDMANCXJaK6NfndRW24M.Qu5kH/DO	ADMINISTRATEUR	INACTIF	Parcours	admin	f	2026-08-19 13:10:25.554334+02	1	\N	f	EMAIL	2026-08-19 12:20:13.851726+02	2026-08-19 13:10:31.982264+02	2026-08-19 13:10:31.973516+02
24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	\N	$2b$12$/f8w6mywwffh8bPydqbEPOZ0nDazWqd8ASlhPYrGeUlUeaHIyHWSW	COOPERATIVE	INACTIF	Test	cooperative	f	2026-08-19 12:40:46.107231+02	0	\N	f	EMAIL	2026-08-13 14:50:58.44548+02	2026-08-19 12:40:48.463312+02	2026-08-19 12:40:48.439047+02
dd6edb17-997f-4ab3-965d-4549466a367b	chat_admin@pnlf-test.local	074000001	$2b$12$j/e6TV/3J6ZEzYP5SEf03eNHXlDTDGyFd1MOjq1M169WfLe/U6u.q	ADMINISTRATEUR	ACTIF	Chat	Admin	f	\N	0	\N	f	EMAIL	2026-08-27 15:37:09.602475+02	2026-09-21 13:00:04.909504+02	2026-09-21 13:00:04.909044+02
08a93740-0af2-4149-87e6-a5c88b06da6c	chat_prod@pnlf-test.local	074000001	$2b$12$tiz3xyEuUqcPiOyW6q4/sOrMMOPin.QVIIr263VN.kL.rAZ/BoI.6	PRODUCTEUR	ACTIF	Chat	Producteur	f	\N	0	\N	f	EMAIL	2026-08-27 15:37:09.892554+02	2026-09-21 13:00:04.909504+02	2026-09-21 13:00:04.909044+02
23ac7257-0250-4686-88e8-8519f68444a2	chat_acheteur_a@pnlf-test.local	074000001	$2b$12$O23aHtPxBwVCokpwchVctuKGgJBbeSlsJnqNrfEbYDSKdJSe5ZUiu	ACHETEUR	ACTIF	Chat	AcheteurA	f	\N	0	\N	f	EMAIL	2026-08-27 15:37:10.121831+02	2026-09-21 13:00:04.909504+02	2026-09-21 13:00:04.909044+02
51ea8ae4-698a-45ad-9b70-e05de5586ff1	chat_acheteur_b@pnlf-test.local	074000001	$2b$12$aagaWBzekFoK0H8XVIL9L.9KfpoHH/90Xf/zXI2AdisgDof7q75B.	ACHETEUR	ACTIF	Chat	AcheteurB	f	\N	0	\N	f	EMAIL	2026-08-27 15:37:10.344345+02	2026-09-21 13:00:04.909504+02	2026-09-21 13:00:04.909044+02
867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	\N	$2b$12$eS18iqLu95iXls.fCn5aj.Gf0d23EHX7DLCZD8f56zb2OCyUyMJeC	ADMINISTRATEUR	INACTIF	Test	admin	f	2026-08-19 12:40:47.52287+02	0	\N	f	EMAIL	2026-08-13 14:50:54.36135+02	2026-08-19 12:40:48.457376+02	2026-08-19 12:40:48.439047+02
c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	\N	$2b$12$LEvoMYQkSAmJv4Yr70KNLORIsvLTUpFsZ/Cnu/kdpiFc1Gj/JKnoG	AGENT_MINISTERE	INACTIF	Test	agent_min	f	2026-08-19 12:40:43.309719+02	0	\N	f	EMAIL	2026-08-13 14:50:55.519551+02	2026-08-19 12:40:48.459288+02	2026-08-19 12:40:48.439047+02
f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	\N	$2b$12$usI1qrxUhOUQLhpcduO/mOdtBaAFl2Q8MpJ9HNwAMprZJXey.p3Ra	AGENT_FORESTIER	INACTIF	Test	agent_for	f	2026-08-19 12:40:44.182848+02	0	\N	f	EMAIL	2026-08-13 14:50:56.514994+02	2026-08-19 12:40:48.460618+02	2026-08-19 12:40:48.439047+02
41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	\N	$2b$12$7kOfCbA0SD/RnPg8buh7/uTgJ6qeP5QWrsdCr.v62hfUdAm2/jul.	PRODUCTEUR	INACTIF	Test	producteur	f	2026-08-19 12:40:45.130301+02	0	\N	f	EMAIL	2026-08-13 14:50:57.469311+02	2026-08-19 12:40:48.461944+02	2026-08-19 12:40:48.439047+02
48577b92-7b4f-4356-a499-b8f88eff743d	test.producteur.19de46a7@pnlf-test.local	074123456	$2b$12$1pdgGWHnpvnEpmDldaB4d.fNf5FS6h/f7VQVYPoeei.FDB6GZGEDy	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:30:18.024389+02	0	\N	f	EMAIL	2026-08-15 16:30:16.830895+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
e300b89e-c6bc-4576-878f-bcdef266555e	acheteur@pnlf.ga	074054314	$2b$12$5FpqJ6V1DbK6Yi2XMBe8KuQdLGRVZFKWuwMlPXkKwpRKqD5TW3Gfu	ACHETEUR	INACTIF	Bent	Staeel	f	2026-08-21 11:53:16.160894+02	0	\N	f	EMAIL	2026-08-21 11:52:04.135511+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	\N	$2b$12$tLOVcRrB6jpsjSgeZir6zesmhqRK.bLt6sUQmHzo6aaAFZwpzK6zW	AGENT_MINISTERE	INACTIF	T	U	f	2026-08-13 15:36:13.269819+02	0	\N	f	EMAIL	2026-08-13 15:19:35.230509+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
363a526d-88d0-4dfc-931f-65ed184f8d14	prodcol@pnlf.ga	074054314	$2b$12$9HYbfbjXnU7WP1Ta5bujne23/fgePdtazR02K2pnDT7kbjY.52knC	PRODUCTEUR	INACTIF	prodcol	prodcol	f	2026-09-06 20:08:30.686077+02	0	\N	f	EMAIL	2026-08-27 19:46:58.235794+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
98e2a59e-389d-4b72-ba98-0c3c026dcae1	test.producteur.ed721073@pnlf-test.local	074123456	$2b$12$oh8F3.wS5WVRSJwSTKPvnuMyNhq8/7tRynQ8ffJ66iGjdtl331MEe	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:23:03.473808+02	0	\N	f	EMAIL	2026-08-15 16:23:02.427509+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
499dde3f-543c-48da-aa30-55e4110c8fa9	test.producteur.82ad1e59@pnlf-test.local	074123456	$2b$12$Rhar.md39juwRoUB6pmXX.0Vbu8nN3V3zgJhCuPWJc23uB06jO7oG	PRODUCTEUR	INACTIF	Ondo	Jean	f	\N	0	\N	f	EMAIL	2026-08-15 16:21:50.598297+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
79b78eee-a7f2-43b2-9bb7-ed8d0d790982	test.producteur.430ae164@pnlf-test.local	074123456	$2b$12$POQicHqM.wHKNoX4iLYWaesZuC.SDdH4ApYNc900T3SDqJfvT.T/6	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:24:14.236996+02	0	\N	f	EMAIL	2026-08-15 16:24:13.135663+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
edc9a5ef-e345-4601-b244-735904555ea8	test.producteur.01fd83f3@pnlf-test.local	074123456	$2b$12$OaFmFGUOMGthQnWSefMww.AH.WknxfjUw16Q5mrQvIP/0o.5I7J3K	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:26:18.943473+02	0	\N	f	EMAIL	2026-08-15 16:26:17.935922+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
e8326ec9-a630-4ed6-ad0d-4775f22f5343	chat.acheteur.insc.461f8b@pnlf-test.local	074999111	$2b$12$jLP3ZsHAIHjQ92Eqoe1ep.V9pX7hc0Rcuk7tvkqyKC4ZISAX2ohUG	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 20:05:52.255383+02	2026-08-27 20:05:53.189438+02	2026-08-27 20:05:53.187903+02
4941947c-0aff-4934-9127-359cf1458942	test.coop.fe212e98@pnlf-test.local	074987654	$2b$12$6y/Fdl50.LUaTkpuQ5hW9uSs07kwUvDcg2v7WX2mmPEtouqOYUgUu	COOPERATIVE	INACTIF	Coopérative Test Moabi		f	\N	0	\N	f	EMAIL	2026-08-15 16:23:03.510935+02	2026-10-02 18:22:27.091825+02	2026-09-23 17:12:46.065062+02
84a30a4c-a0c4-4773-8da7-fb3d1ede070e	test.coop.d6e20562@pnlf-test.local	074987654	$2b$12$7k4PgOLZ8kYwLU82Ztu0u.Mo2TQiPsR.z1px3xxv7EjFacq2Z.5.u	COOPERATIVE	INACTIF	Coopérative Test Moabi		f	\N	0	\N	f	EMAIL	2026-08-15 16:26:38.515312+02	2026-10-02 18:22:27.091825+02	2026-09-23 17:12:46.065062+02
98240505-423c-4a4d-9118-f4e5fe0dce35	chat.acheteur.insc.d50186@pnlf-test.local	074999111	$2b$12$p55AbhnmNlSV2rPsCnZCzObwCAyRA2ZZtyE0vu3bSqLXrUCkAny56	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 15:40:26.162878+02	2026-08-27 15:40:26.77503+02	2026-08-27 15:40:26.774793+02
10c652a1-c147-4459-91ef-523fb13fc3ad	test.producteur.115f9ba6@pnlf-test.local	074123456	$2b$12$TJwWD0POcunvOf2k/OelwuABPORYEUt74W8PvSNRsLCC8VlM.QXBy	PRODUCTEUR	INACTIF	Ondo	Jean	f	2026-08-15 16:24:31.632704+02	0	\N	f	EMAIL	2026-08-15 16:24:30.567096+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
7a9c9370-c46f-4f06-bc4c-962a4ec44e27	parcours_attente_c2873650@pnlf-test.local	\N	$2b$12$6eFIMvypqXARQPqjCYcLU.fzhdp4L3fU4AfcAEdn0n1yqXCW11Ao2	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 12:20:18.628533+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
0cc7031d-9c14-4521-8394-a4bca39ffa4e	kaaki@pnlf.ga	+24174054314	$2b$12$qZyNVd/Pb.AuzqX5V0Zeuuv55Ax9zKV1MrvIu/.T2kvyBB0jBnILi	PRODUCTEUR	INACTIF	kaaki	d	f	\N	0	\N	f	EMAIL	2026-08-21 11:58:36.054656+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
86744704-e43d-4d31-8bda-5cde8d64b204	parcours_attente_01744a30@pnlf-test.local	\N	$2b$12$TsjPihilouCZwgJekMYMxOpwN1yY8X.KfO9yOv/D4Lx0rliFLPGKC	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 13:09:48.069821+02	2026-08-19 13:09:49.42501+02	2026-08-19 13:09:49.414913+02
70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	+241077000101	$2b$12$UwDaWWR.0hlv3CIHOzDB.eRrj1NYQKnnlhrOK4r.7yipYzU1ZY2XS	ADMINISTRATEUR	ACTIF	MOUKAGNI	Administrateur Démo	f	2026-10-03 16:48:37.049329+02	0	\N	f	EMAIL	2026-10-02 12:06:24.551122+02	2026-10-03 16:48:37.049982+02	\N
0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	+241077000305	$2b$12$XAJ9u6VewQhP7hOmJxFT5e4YPP.xpLq5akiV/wQ3DHLWFlGwPNeAy	COOPERATIVE	EN_ATTENTE	Coopérative des Femmes Productrices du Woleu-Ntem		f	\N	0	\N	f	EMAIL	2026-10-02 12:06:33.665253+02	2026-10-02 18:22:27.091825+02	\N
69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	+241077000102	$2b$12$kxXooljKNWByIDrjRD45a.BoQxO6TL9MIcdBrH1gRe7tMDHp3lc4q	AGENT_MINISTERE	ACTIF	NZIENGUI	Aline	f	2026-10-03 16:48:37.540414+02	0	\N	f	EMAIL	2026-10-02 12:06:24.915713+02	2026-10-03 16:48:37.540917+02	\N
f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	+241077000103	$2b$12$NOuFz8xgvnbUzQBOR3CNP.Pp3YCtmgZ8G2crnQHUs/1EbYDMR1NT6	AGENT_MINISTERE	ACTIF	MABIKA	Hervé	f	2026-10-03 16:48:37.997691+02	0	\N	t	EMAIL	2026-10-02 12:06:25.174742+02	2026-10-03 16:48:37.998588+02	\N
e8ef915a-9c62-4c93-9acb-6fe63d18b4d7	parcours_attente_765dc017@pnlf-test.local	\N	$2b$12$XbvtQibafW3RrYp/mI4TZ.UYpicOhrGRLa39cwLCD8iSGfnrJwwLS	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 12:21:12.192173+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
72bd473c-6010-4800-a9dd-2e3a247c2673	prod@pnlf.ga	074054314	$2b$12$IPhgvm2gkqTDn6tvcxhaEu1mz4Y73lWnzBVB7ZwKMYRN6v9Tiuz5i	AGENT_FORESTIER	INACTIF	prod	prod	f	2026-08-27 20:10:18.315527+02	0	\N	f	EMAIL	2026-08-27 19:45:13.33798+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
539cf044-9294-457a-9683-4f92db6f4e10	parcours_attente_ceb31aa0@pnlf-test.local	\N	$2b$12$bamL3FHVgDKraTKAhFN/nONmi4M8bkOnDCF51ry7YW61WWsR2Rf36	PRODUCTEUR	INACTIF	Attente	Inscription	f	\N	0	\N	f	EMAIL	2026-08-19 12:21:47.873922+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
9f1ffdb2-b800-4e03-8587-2ebe210fe622	test_acheteur@pnlf-test.local	\N	$2b$12$hwoDQoKx1pB8pHkRpo.wY.YQBSa7o7eKZ1Pa9B22vbk.n0JVxY46S	ACHETEUR	INACTIF	Test	acheteur	f	2026-08-13 12:33:14.171264+02	0	\N	f	EMAIL	2026-08-13 12:31:37.000195+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
505512be-a7e2-4291-b5cb-6f7f3bb54030	test_producteur@pnlf-test.local	\N	$2b$12$GiRvrnr0IuqM4D7DezlAbuM1el7O5so7ho8MMzrOZB/BjB6u4Nf7a	PRODUCTEUR	INACTIF	Test	producteur	f	2026-08-13 12:33:14.781944+02	0	\N	f	EMAIL	2026-08-13 12:31:37.319283+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
601c6616-d69f-4019-b949-0d5e84cf694b	prod2@outlook.com	+24174054315	$2b$12$95mvVExAkz0mFT3yM8wJSObXbPpx668OzDfkbt.vDK8AVrW8fwsBm	PRODUCTEUR	INACTIF	prod2	2	f	\N	0	\N	f	EMAIL	2026-09-23 11:19:22.534568+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
e0dad95c-4ba9-4249-8a44-4cc78cd267db	chat.acheteur.insc.64f02c@pnlf-test.local	074999111	$2b$12$mP.FDjfHTOFF1byt5lGSMuwk2NJ.8cX6sNxAgvg82GdQKjks/rBsC	ACHETEUR	ACTIF	Mba	Paul	f	\N	0	\N	f	EMAIL	2026-08-27 20:06:34.694432+02	2026-08-27 20:06:35.44517+02	2026-08-27 20:06:35.444831+02
36673c00-f3f0-4727-aa51-193272429712	deltest.36673c@pnlf-test.local	070000000	$2b$12$OduH2m4LOGKLqXocaxxeWOHBETUGQWFZsWb.yzHKxl8snK0vMKH6.	ACHETEUR	INACTIF	Del	Test	f	\N	0	\N	f	EMAIL	2026-08-27 16:47:07.690579+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
e7f43b56-b615-4214-9e26-e2b2e09d257e	yves@pnlf.ga	+24174054314	$2b$12$1fZtUJlHXfV0FVVEYpKy.eZli.DZaiAIYFTgcQvNMuOmCyniIScR2	PRODUCTEUR	INACTIF	yves	alain	f	2026-08-21 18:45:10.536953+02	0	\N	f	EMAIL	2026-08-21 18:30:33.871995+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	+24174054314	$2b$12$8qrTE2eeuiRjsFl2Lt7GJOPVasM9SB1n/p1JyXryFYIsdGwLdEFv.	ACHETEUR	INACTIF	mba	mba	f	2026-08-27 20:09:35.374596+02	0	\N	f	EMAIL	2026-08-27 15:46:07.376828+02	2026-09-23 17:12:46.065062+02	2026-09-23 17:12:46.065062+02
96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	+241077000104	$2b$12$XbqaF6arQkMatA1qltJ.9eiqpv7JQ/k9GQlTZYOarmSirFy26ZOFG	AGENT_FORESTIER	ACTIF	ESSONO	Rodrigue	f	2026-10-03 16:48:38.605364+02	0	\N	f	EMAIL	2026-10-02 12:06:25.430739+02	2026-10-03 16:48:38.606338+02	\N
df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	+241077000201	$2b$12$LPhZiiFzJvXq/OIQnDnMIuksPc2WNIxEm/WA/6hRd.VI2iKo51Uge	PRODUCTEUR	ACTIF	NDONG	Jean-Baptiste	f	2026-10-03 16:48:41.216715+02	0	\N	f	EMAIL	2026-10-02 12:06:26.295807+02	2026-10-03 16:48:41.217372+02	\N
b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	+241077000202	$2b$12$81fWEGblQU6NvCI0URgCcevc6Q/ESV4GCZu7sHdErUlTEp5ZwvtCS	PRODUCTEUR	ACTIF	MOUSSAVOU	Marie-Claire	f	2026-10-03 16:48:41.624332+02	0	\N	f	EMAIL	2026-10-02 12:06:27.159983+02	2026-10-03 16:48:41.624803+02	\N
5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	+241077000204	$2b$12$iqWB2gmpG/XDOQPBpFws6.6YQrmMUhJ1.Hg2RZSmnuu2p4ObO1qsS	PRODUCTEUR	ACTIF	MBOUMBA	Sylvie	f	2026-10-03 16:48:42.410555+02	0	\N	f	EMAIL	2026-10-02 12:06:27.842081+02	2026-10-03 16:48:42.411066+02	\N
baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	+241077000105	$2b$12$kLb.YOnu3wPSd4xmvdikcefL43aKzq65hMjWr.DDXzKBIclmmEPTq	AGENT_FORESTIER	SUSPENDU	KOUMBA	Patrice	f	\N	0	\N	f	EMAIL	2026-10-02 12:06:25.677407+02	2026-10-02 12:06:24.799502+02	\N
3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	+241077000106	$2b$12$cebBocS4t/UNYKC4uLIBnuWNcPvhbhxibu1xwu.kR6HtfPvJa/g/K	ACHETEUR	ACTIF	OYANE	Nadège	f	2026-10-03 16:48:44.343898+02	0	\N	f	EMAIL	2026-10-02 12:06:25.934964+02	2026-10-03 16:48:44.344386+02	\N
0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	+241077000207	$2b$12$OETQ2CNnI1YMy4DVvwm8Bu1DV6oFcMm7pcY9mwJH7aAQ3p6rfUHoq	PRODUCTEUR	EN_ATTENTE	MAPANGOU	Christelle	f	\N	0	\N	f	EMAIL	2026-10-02 12:06:29.035607+02	2026-10-02 12:06:29.035607+02	\N
aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	+241077000208	$2b$12$fkmKtKdxg3vtYVx1nyAMguWfDmJvg9BzBGX4Hpdg3EP1cKUymouSe	PRODUCTEUR	EN_ATTENTE	IKAPI	Ghislain	f	\N	0	\N	f	EMAIL	2026-10-02 12:06:29.568347+02	2026-10-02 12:06:29.568347+02	\N
1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	+241077000402	$2b$12$4bSiI3LhWOAum1Gh/q5vUOiIOOGV4.EhYf5zBF2XCGJSdGsGY8FxG	ACHETEUR	EN_ATTENTE	MOUNGUENGUI	Estelle	f	\N	0	\N	f	EMAIL	2026-10-02 12:06:34.97236+02	2026-10-02 12:06:34.97236+02	\N
\.


--
-- TOC entry 6948 (class 0 OID 69316)
-- Dependencies: 233
-- Data for Name: villages; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.villages (id, departement_id, nom, latitude, longitude, geom, actif, created_at, updated_at) FROM stdin;
daaffdbc-da45-4504-888e-8062640304fc	cf38827b-8288-4146-a599-bba708382b1d	Kango	0.1667000	10.1167000	0101000020E6100000EBE2361AC03B24402D211FF46C56C53F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0093155a-3018-46f8-94c0-2e28068765e6	7bb72885-b409-4a09-a0e3-de885874e010	Ntoum	0.3833000	9.7667000	0101000020E6100000B8AF03E78C8823409CA223B9FC87D83F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
11055751-f913-45a5-a990-157f56ded7da	06d2e9f5-8615-422f-ba7a-54af8047c7f5	Cocobeach	1.0000000	9.5833000	0101000020E61000007B832F4CA62A2340000000000000F03F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
16d0886d-942b-4a2a-a36b-54594d9a232e	8e640ef4-cc64-4b9d-ad40-29c7506bc205	Libreville	0.3901000	9.4544000	0101000020E6100000D49AE61DA7E82240BADA8AFD65F7D83F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d2e18c2b-e53a-42dc-8617-ff1cdb6c5941	e0b34d63-b611-498d-b75e-e714d54a677f	Onga	-0.8500000	14.1500000	0101000020E6100000CDCCCCCCCC4C2C40333333333333EBBF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
cb8be490-242a-40f9-af3f-a23b0e5b75b9	1699b7ec-f36d-411a-a50c-07bf3509eceb	Bongoville	-1.6500000	13.8667000	0101000020E6100000EBE2361AC0BB2B40666666666666FABF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
fb0ffe7e-560d-4ec2-88f2-84a637eb87af	e5e965fc-819a-483d-a6a9-b455a2344f57	Moanda	-1.5667000	13.2000000	0101000020E61000006666666666662A408C4AEA043411F9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
f2776fab-0c35-4f6a-91f8-65c4080a651e	6c7cba9f-402f-4826-96d6-201102f0a723	Ngouoni	-1.3500000	13.7500000	0101000020E61000000000000000802B409A9999999999F5BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
6559b9af-f6a9-4570-9028-12973b6b8b56	9dd6b61b-bd21-4ef1-b6ee-8b1edacf4283	Bakoumba	-1.8000000	13.0167000	0101000020E6100000B8AF03E78C082A40CDCCCCCCCCCCFCBF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
eacd0995-d4fd-4265-8a7a-e64920b51e0f	5e81b436-7183-4b2d-8b09-b7eaf2ddfc94	Akiéni	-1.1833000	13.9167000	0101000020E6100000857CD0B359D52B4074B515FBCBEEF2BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
7b9da9a5-7a17-46dc-aa33-58837264defa	cc3d5e68-9614-4d21-bb36-b3c36612b37b	Boumango	-2.1500000	13.6500000	0101000020E6100000CDCCCCCCCC4C2B4033333333333301C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
93271f46-1a4a-4c30-8f65-6b40c16b2bab	8d665c3a-0905-4d3e-b6ac-518abd7e3048	Franceville	-1.6333000	13.5833000	0101000020E61000007B832F4CA62A2B40A7E8482EFF21FABF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
cb7f1e58-9e73-4486-bf86-6b4686ef6cbc	5f6aa474-01a7-4631-b516-e8fcd3d6f154	Lékoni	-1.5833000	14.2667000	0101000020E6100000B8AF03E78C882C40DA1B7C613255F9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
ca550f8f-2780-4976-86e1-ed15b2df87aa	8c6cac3a-f9ae-4db2-974c-bf12613a5cd3	Okondja	-0.6833000	13.7833000	0101000020E6100000E2E995B20C912B40E86A2BF697DDE5BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
b06dbedb-3ff0-4209-bf85-179520537822	d595baea-82f0-4e05-a141-f650a012ee28	Aboumi	-0.5167000	14.0833000	0101000020E61000007B832F4CA62A2C407FFB3A70CE88E0BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
f926c47f-bcfb-410b-bb15-912e261e194d	3e7fe5b2-697f-44d4-80a0-0ff2ebd195b7	Ndjolé	-0.1833000	10.7667000	0101000020E6100000B8AF03E78C8825409FABADD85F76C7BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
4b1fc951-9995-4c82-b59a-eb6972b95b18	083ec496-43bc-4b74-8514-e63b86559ca1	Lambaréné	-0.7000000	10.2167000	0101000020E61000001E166A4DF36E2440666666666666E6BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
a4ffe8c8-8260-490e-ad1a-663ffc3384a5	d13daecd-deef-44a6-ba6a-7bdfe8ac3ac2	Mbigou	-1.9000000	11.9000000	0101000020E6100000CDCCCCCCCCCC2740666666666666FEBF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
727bc2fd-2081-4668-a9b3-051d5bdf22cd	118a620f-fb2d-4613-8333-c7dec4c0a80f	Ndendé	-2.3000000	11.3833000	0101000020E6100000151DC9E53FC4264066666666666602C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
c417c74b-fcd7-45a7-835d-7628541d133e	56943c85-7c1c-47f9-a595-38dbe982e3bc	Mouila	-1.8667000	11.0556000	0101000020E6100000B1506B9A771C26405917B7D100DEFDBF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
6b5cbd40-fc6e-4370-b63e-4992d4a0231b	faaa99cc-dcfc-4acb-bc0f-f92973ff91c1	Malinga	-2.2000000	12.2500000	0101000020E610000000000000008028409A999999999901C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
ca11ad31-3ba4-4e0f-9712-65431ea2885c	f844caac-39e7-492c-a9ed-982e341a34be	Lébamba	-2.2000000	11.5000000	0101000020E610000000000000000027409A999999999901C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
51d2f91e-a6d9-4984-8fef-8d9f27d8d4ab	4da04750-0971-42b5-821f-6afbe8e0f4fa	Mandji	-1.5833000	10.4000000	0101000020E6100000CDCCCCCCCCCC2440DA1B7C613255F9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
ca9d5769-b1e8-4218-b89e-8d051502d745	02c616fa-e4a3-4f68-b3b3-de992c98a42a	Mimongo	-1.6167000	11.6000000	0101000020E610000033333333333327405917B7D100DEF9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
dd92d865-472a-4a7f-bbcd-2b5c17514884	13de8477-071b-4375-9aec-b8f14f351ce1	Fougamou	-1.2167000	10.6000000	0101000020E61000003333333333332540F2B0506B9A77F3BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
c110cd16-8fdf-4499-b503-21c2ed3c8dec	366aa27f-7e8a-412b-985a-b999d7c03b18	Guietsou	-2.0500000	10.8000000	0101000020E61000009A9999999999254066666666666600C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
97af34fb-69e1-4382-b96b-126390762621	0967f0c8-f287-4f32-abf3-7856e34dc2a3	Mayumba	-3.4167000	10.6500000	0101000020E6100000CDCCCCCCCC4C254013F241CF66550BC0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d467cb3a-dea8-48bb-910f-53236ebcb702	5bd885ef-a736-45e6-b566-c2ed9f2ee1d2	Moabi	-2.4333000	10.9833000	0101000020E61000004850FC1873F72540BADA8AFD657703C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
c4177928-c0e1-45ce-96bf-64ce79fb1f58	8c56dc91-ef41-4222-8111-f85a3227b700	Mabanda	-2.7500000	11.4000000	0101000020E6100000CDCCCCCCCCCC264000000000000006C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
75a0c493-80c0-4aad-8519-150212cb3c57	b3ac6e70-4401-4770-9cc1-7f11087eb36d	Ndindi	-3.7000000	11.0000000	0101000020E610000000000000000026409A99999999990DC0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
96642fb1-2322-4994-b8b8-9eaed6913cee	0e039faf-0a05-4d7c-9fe2-df6f483a00f3	Tchibanga	-2.8500000	11.0167000	0101000020E6100000B8AF03E78C082640CDCCCCCCCCCC06C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
ed2e6040-5b8f-4612-9a22-8c80c6f9af89	5d266a70-f635-4447-bf48-40539a88d97b	Moulengui-Binza	-3.2500000	11.5833000	0101000020E61000007B832F4CA62A27400000000000000AC0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
bf148f8d-5f09-4d82-850d-a48aec703c8b	e4d7dea5-9056-4c46-b905-74aae292e4dd	Makokou	0.5667000	12.8500000	0101000020E61000003333333333B329401895D4096822E23F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
dbe850af-595e-4f81-97b1-056abca7c9d4	d96eb2c5-ec95-4691-82c0-bfa19680f78f	Booué	-0.1000000	11.9333000	0101000020E6100000AEB6627FD9DD27409A9999999999B9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
282812ea-0d0e-4558-bc83-167a6d106f6d	214d5429-953b-4600-b136-15793bbdf6ab	Ovan	0.3500000	12.1667000	0101000020E6100000857CD0B359552840666666666666D63F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
96c26b24-d3d6-4eb4-a099-fc79a82639ee	c58572ba-7298-408e-b523-ee2be28bce45	Mékambo	1.0167000	13.9333000	0101000020E6100000AEB6627FD9DD2B40BF7D1D386744F03F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
ebb8b1cb-485b-47a9-8ce0-cd9ca339879d	3a51074b-871e-495f-a135-1d7028b67916	Koulamoutou	-1.1333000	12.4667000	0101000020E61000001E166A4DF3EE2840A7E8482EFF21F2BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
a23c7ed1-d17a-4e7c-84ac-af034f4d2a77	0bcf799b-fe5e-4538-8c03-d0f97ea126ad	Pana	-1.4500000	12.6167000	0101000020E6100000EBE2361AC03B2940333333333333F7BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
5666f530-9b3a-4d51-83da-2eefa97d4b47	856fbac1-89d6-481b-a874-6ef4b66dbd5f	Lastoursville	-0.8167000	12.7167000	0101000020E61000001E166A4DF36E29401895D4096822EABF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
733d6374-2767-463d-8f4b-bf5edaafaf07	dbdafef5-6aca-4088-8cfe-92fd3a663009	Iboundji	-1.1000000	11.9167000	0101000020E6100000857CD0B359D527409A9999999999F1BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d521510e-10d3-4e37-9dad-e80836ef96ea	2f28fef3-c55d-4d24-a86f-5c4bb85a9f71	Port-Gentil	-0.7167000	8.7833000	0101000020E6100000E2E995B20C912140E561A1D634EFE6BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d41e8581-e3aa-480b-9b0a-5b8a1debe369	2e2e99be-9b7e-4894-8026-380f526c98d4	Omboué	-1.5667000	9.2667000	0101000020E6100000B8AF03E78C8822408C4AEA043411F9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
3588cdbc-fd93-48fc-a29e-8e885e4bd6bc	a13613de-fe11-479c-8bf7-4842009652cf	Gamba	-2.6500000	10.0000000	0101000020E6100000000000000000244033333333333305C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
173062b5-4dab-4964-99bc-dfad03972d2b	f4bae033-8914-4808-baca-cd59c094bd6f	Médouneu	0.9500000	10.7833000	0101000020E6100000E2E995B20C912540666666666666EE3F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
f1977e24-99c8-44fc-b8ff-fd5a8b19f7ec	bb465088-18fe-4a45-a826-127be2ebd83e	Minvoul	2.1500000	12.1333000	0101000020E6100000151DC9E53F4428403333333333330140	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
62ef0a7a-dc91-4ddc-bd3f-3734a7c8251a	816670eb-a0e7-40f7-a413-4ebe534c31ec	Bitam	2.0833000	11.5000000	0101000020E61000000000000000002740ED0DBE3099AA0040	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
0ebb0beb-3526-41a7-b619-924209ed919d	0549ba65-547a-4f79-b451-06c48f9bffe4	Mitzic	0.7833000	11.5500000	0101000020E61000009A999999991927401B9E5E29CB10E93F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
53b2361d-273d-4245-84a0-8d1236655b74	adb16100-f503-4a39-8e41-27732f8dddd5	Oyem	1.6000000	11.5833000	0101000020E61000007B832F4CA62A27409A9999999999F93F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
\.


--
-- TOC entry 6958 (class 0 OID 69638)
-- Dependencies: 243
-- Data for Name: zones_collecte; Type: TABLE DATA; Schema: pnlf; Owner: postgres
--

COPY pnlf.zones_collecte (id, code, libelle, province_id, description, latitude, longitude, geom, actif, created_at, updated_at) FROM stdin;
3e2fc1f2-f780-4461-bfd3-216a8eb20fe5	ZC-LOPE	Parc national de la Lopé	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	Zone forestière de référence PNLF	-0.2000000	11.6000000	0101000020E610000033333333333327409A9999999999C9BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
e741c59b-41f7-494a-bdef-ade0826b7064	ZC-IVINDO	Parc national d'Ivindo	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	Zone forestière de référence PNLF	0.5000000	12.8000000	0101000020E61000009A99999999992940000000000000E03F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
76cd7e43-0084-4e31-8013-62773eef9988	ZC-MOUKALABA	Parc national de Moukalaba-Doudou	86a5e90b-c713-4ccc-affe-2480b77fbbf0	Zone forestière de référence PNLF	-2.5000000	10.5000000	0101000020E6100000000000000000254000000000000004C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
3eae6e0a-2c6d-48ee-9d00-5c988a89b7e5	ZC-WAKA	Parc national de Waka	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	Zone forestière de référence PNLF	-1.1000000	11.1000000	0101000020E610000033333333333326409A9999999999F1BF	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
a23ca578-d045-471a-845b-f777bbd6d94d	ZC-CRISTAL	Parc national des Monts de Cristal	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	Zone forestière de référence PNLF	0.6000000	10.4000000	0101000020E6100000CDCCCCCCCCCC2440333333333333E33F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
9d441acb-7c66-4004-a6a6-2a6323e0c2c1	ZC-BATEKE	Parc national des Plateaux Batéké	cb1698dc-1a3a-4f23-ae61-0672d2e579db	Zone forestière de référence PNLF	-2.1000000	14.0000000	0101000020E61000000000000000002C40CDCCCCCCCCCC00C0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
d4c3af1d-4138-4eca-a7a1-4bba882c57b1	ZC-MWAGNE	Parc national de Mwagne	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	Zone forestière de référence PNLF	0.8000000	13.5000000	0101000020E61000000000000000002B409A9999999999E93F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
207fcbf8-e8c4-41a0-89ce-6fa393927b96	ZC-MAYUMBA	Parc national de Mayumba	86a5e90b-c713-4ccc-affe-2480b77fbbf0	Zone forestière de référence PNLF	-3.4000000	10.7000000	0101000020E610000066666666666625403333333333330BC0	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
095c2e6b-5985-4513-b3d5-96055022a78b	ZC-AKANDA	Parc national d'Akanda	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	Zone forestière de référence PNLF	0.6000000	9.4000000	0101000020E6100000CDCCCCCCCCCC2240333333333333E33F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
982177f7-b21f-4d6b-af1d-325b7dfd8ab7	ZC-PONGARA	Parc national de Pongara	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	Zone forestière de référence PNLF	0.1000000	9.4000000	0101000020E6100000CDCCCCCCCCCC22409A9999999999B93F	t	2026-08-10 14:49:06.017096+02	2026-08-10 14:49:06.017096+02
6fccaa8b-9bf4-4806-843d-8f86fe510c44	Z-AGF-c2873650	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 12:20:18.843601+02	2026-08-19 12:20:18.843601+02
4d78a694-9a9f-4f06-9228-01c77f7c1d40	Z-AGF-765dc017	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 12:21:12.651559+02	2026-08-19 12:21:12.651559+02
fb1331f1-5a67-497a-8e45-bd97cc2356b0	Z-AGF-ceb31aa0	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 12:21:48.341126+02	2026-08-19 12:21:48.341126+02
ad98e5a6-ee71-46e2-9305-8abe21de8401	Z-AGF-e8f55a10	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 12:40:19.441858+02	2026-08-19 12:40:19.441858+02
0577d95e-71be-4615-a95e-c05389d8e622	Z-PAR-01744a30	Zone test	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 13:09:48.495064+02	2026-08-19 13:09:48.495064+02
8c42d565-26c3-4908-994b-2490b274ee37	Z-AGF-01744a30	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 13:09:48.503725+02	2026-08-19 13:09:48.503725+02
0e30f3a4-dd98-42e4-8f7e-f2cea8a89b41	Z-PAR-ac43475c	Zone test	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 13:10:31.253534+02	2026-08-19 13:10:31.253534+02
277683f1-6c6e-4c7b-a3cb-38faec341ce0	Z-AGF-ac43475c	Zone forestier	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	\N	\N	\N	\N	t	2026-08-19 13:10:31.261711+02	2026-08-19 13:10:31.261711+02
8b79f5b9-a549-4942-9069-93850ce5d12f	DEMO-ZC-MINKEBE	Forêt de Minkébé, secteur de Makokou	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	Massif forestier riche en noisettes (owala), kola et poivre de Guinée.	0.6100000	12.7300000	\N	t	2026-10-02 12:06:36.059367+02	2026-10-02 12:06:36.059367+02
cf91171c-fc2d-44d3-870b-5618fc796032	DEMO-ZC-LOPE	Lopé, lisière forêt-savane	e1b4f519-6b38-40e4-af34-e66a2b43d2c5	Zone sous surveillance : espèces médicinales soumises à permis.	-0.2000000	11.6000000	\N	t	2026-10-02 12:06:36.075651+02	2026-10-02 12:06:36.075651+02
12d53253-f473-41ef-82a8-04778bcff530	DEMO-ZC-WAKA	Massif de Waka, abords de Mouila	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	Forêt dense humide : miel, cire et chenilles.	-1.7500000	11.1500000	\N	t	2026-10-02 12:06:36.093167+02	2026-10-02 12:06:36.093167+02
3fc8509c-9db1-4587-bbe5-0cb4914b418e	DEMO-ZC-CRISTAL	Monts de Cristal, versant de Kango	c0ca1acf-eb37-4dbf-ab62-b9cd8f049974	Rotin, raphia et feuilles de Marantacées.	0.4500000	10.2700000	\N	t	2026-10-02 12:06:36.107405+02	2026-10-02 12:06:36.107405+02
ec28c59a-9434-4f66-b272-368859a8b7fd	DEMO-ZC-RUCHERS-FOUGAMOU	Ruchers forestiers de Fougamou	ef0cbe60-012f-42aa-8ddc-b4ba84d2e49e	Zone déclarée par le producteur depuis le formulaire de lot.	-1.2100000	10.6000000	\N	t	2026-10-02 12:06:36.124784+02	2026-10-02 12:06:36.124784+02
\.


--
-- TOC entry 7001 (class 0 OID 86836)
-- Dependencies: 292
-- Data for Name: _data_ops; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public._data_ops (op_key, applied_at, note) FROM stdin;
purge_non_admins_v1	2026-09-23 17:12:46.065062+02	soft-purge local + soft users non-admin
seed_demo_acteurs_v1	2026-10-02 12:06:24.799502+02	Jeu de démonstration créé (161 appels API).
\.


--
-- TOC entry 6979 (class 0 OID 70121)
-- Dependencies: 267
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_group (id, name) FROM stdin;
\.


--
-- TOC entry 6981 (class 0 OID 70131)
-- Dependencies: 269
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
\.


--
-- TOC entry 6977 (class 0 OID 70111)
-- Dependencies: 265
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	2	add_permission
6	Can change permission	2	change_permission
7	Can delete permission	2	delete_permission
8	Can view permission	2	view_permission
9	Can add group	3	add_group
10	Can change group	3	change_group
11	Can delete group	3	delete_group
12	Can view group	3	view_group
13	Can add user	4	add_user
14	Can change user	4	change_user
15	Can delete user	4	delete_user
16	Can view user	4	view_user
17	Can add content type	5	add_contenttype
18	Can change content type	5	change_contenttype
19	Can delete content type	5	delete_contenttype
20	Can view content type	5	view_contenttype
21	Can add session	6	add_session
22	Can change session	6	change_session
23	Can delete session	6	delete_session
24	Can view session	6	view_session
25	Can add Blacklisted Token	7	add_blacklistedtoken
26	Can change Blacklisted Token	7	change_blacklistedtoken
27	Can delete Blacklisted Token	7	delete_blacklistedtoken
28	Can view Blacklisted Token	7	view_blacklistedtoken
29	Can add Outstanding Token	8	add_outstandingtoken
30	Can change Outstanding Token	8	change_outstandingtoken
31	Can delete Outstanding Token	8	delete_outstandingtoken
32	Can view Outstanding Token	8	view_outstandingtoken
33	Can add notification	9	add_notification
34	Can change notification	9	change_notification
35	Can delete notification	9	delete_notification
36	Can view notification	9	view_notification
37	Can add offre demande	10	add_offredemande
38	Can change offre demande	10	change_offredemande
39	Can delete offre demande	10	delete_offredemande
40	Can view offre demande	10	view_offredemande
41	Can add conversation	11	add_conversation
42	Can change conversation	11	change_conversation
43	Can delete conversation	11	delete_conversation
44	Can view conversation	11	view_conversation
45	Can add conversation participant	12	add_conversationparticipant
46	Can change conversation participant	12	change_conversationparticipant
47	Can delete conversation participant	12	delete_conversationparticipant
48	Can view conversation participant	12	view_conversationparticipant
49	Can add message	13	add_message
50	Can change message	13	change_message
51	Can delete message	13	delete_message
52	Can view message	13	view_message
53	Can add conversation context	14	add_conversationcontext
54	Can change conversation context	14	change_conversationcontext
55	Can delete conversation context	14	delete_conversationcontext
56	Can view conversation context	14	view_conversationcontext
57	Can add conversation participant meta	15	add_conversationparticipantmeta
58	Can change conversation participant meta	15	change_conversationparticipantmeta
59	Can delete conversation participant meta	15	delete_conversationparticipantmeta
60	Can view conversation participant meta	15	view_conversationparticipantmeta
61	Can add message piece	16	add_messagepiece
62	Can change message piece	16	change_messagepiece
63	Can delete message piece	16	delete_messagepiece
64	Can view message piece	16	view_messagepiece
65	Can add appareil sync	17	add_appareilsync
66	Can change appareil sync	17	change_appareilsync
67	Can delete appareil sync	17	delete_appareilsync
68	Can view appareil sync	17	view_appareilsync
69	Can add sync conflict	18	add_syncconflict
70	Can change sync conflict	18	change_syncconflict
71	Can delete sync conflict	18	delete_syncconflict
72	Can view sync conflict	18	view_syncconflict
\.


--
-- TOC entry 6983 (class 0 OID 70140)
-- Dependencies: 271
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) FROM stdin;
\.


--
-- TOC entry 6985 (class 0 OID 70159)
-- Dependencies: 273
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_user_groups (id, user_id, group_id) FROM stdin;
\.


--
-- TOC entry 6987 (class 0 OID 70168)
-- Dependencies: 275
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.auth_user_user_permissions (id, user_id, permission_id) FROM stdin;
\.


--
-- TOC entry 7005 (class 0 OID 86926)
-- Dependencies: 296
-- Data for Name: certifications_pieces; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.certifications_pieces (id, certification_id, intitule, chemin, nom_original, type_mime, taille_octets, depose_par_id, created_at) FROM stdin;
\.


--
-- TOC entry 7009 (class 0 OID 87006)
-- Dependencies: 300
-- Data for Name: connexions; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.connexions (id, utilisateur_id, email_saisi, role, succes, motif_echec, ip_adresse, appareil, systeme, navigateur, empreinte_appareil, created_at) FROM stdin;
489	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	\N	INCONNU	\N	\N	\N	2026-08-10 14:35:58.949512+02
490	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	\N	\N	728373547d8a1518d5c8a22eaee83306	2026-08-10 14:36:18.922239+02
491	1051c839-763f-4a10-9f0e-7b64d301a393	test_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:13.042601+02
492	1051c839-763f-4a10-9f0e-7b64d301a393	test_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:13.63455+02
493	9f1ffdb2-b800-4e03-8587-2ebe210fe622	test_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:14.209953+02
494	505512be-a7e2-4291-b5cb-6f7f3bb54030	test_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:14.821426+02
495	d2dd8717-64d9-47e9-a533-4fdce48ba54e	test_agent_min@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:15.381331+02
496	1051c839-763f-4a10-9f0e-7b64d301a393	test_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 12:33:15.688391+02
497	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	\N	INCONNU	\N	\N	\N	2026-08-13 12:33:37.810183+02
498	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:55.112488+02
499	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:56.09132+02
500	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:57.049977+02
501	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:57.995741+02
502	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:58.983985+02
503	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:50:59.850043+02
504	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:51:00.841959+02
505	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:51:54.564074+02
506	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:51:55.929453+02
507	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:51:57.327061+02
508	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:51:58.960424+02
509	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:52:00.330258+02
510	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:52:01.724752+02
511	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:06.570196+02
512	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:07.860873+02
513	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:09.124901+02
514	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:10.429882+02
515	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:11.731854+02
516	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:13.043263+02
517	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:53:13.943831+02
518	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:02.311254+02
519	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:03.72794+02
520	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:05.076611+02
521	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:06.461824+02
522	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:07.860285+02
523	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:09.202796+02
524	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:55:10.151458+02
525	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:10.447749+02
526	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:11.771872+02
527	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:13.035485+02
528	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:14.34154+02
529	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:15.612405+02
530	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:16.894565+02
531	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:17.79104+02
532	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:23.378707+02
533	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:24.76411+02
534	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:26.128929+02
535	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:27.534683+02
536	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:28.914238+02
537	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:30.258319+02
538	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 14:56:31.250997+02
539	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:16:53.459263+02
540	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:16:54.92747+02
541	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:16:56.276576+02
542	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:16:57.600573+02
543	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:16:58.976385+02
544	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:17:00.292212+02
545	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:51.066708+02
546	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:52.430096+02
547	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:53.771688+02
548	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:55.157453+02
549	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:56.467513+02
550	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:57.771348+02
551	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:18:58.714504+02
552	28685225-99bb-47f6-bee0-44618f80115d	cadrage_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:19:35.8914+02
553	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:19:36.467886+02
554	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:19:37.130154+02
555	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:21:12.693883+02
556	28685225-99bb-47f6-bee0-44618f80115d	cadrage_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:21:59.503948+02
557	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:22:00.089372+02
558	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:22:00.876692+02
559	28685225-99bb-47f6-bee0-44618f80115d	cadrage_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:36:12.657945+02
560	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:36:12.963184+02
561	2b4e609b-d46f-4187-b99a-e23d596d0334	cadrage_agent@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-13 15:36:13.274175+02
562	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:47:32.944046+02
563	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:48:17.492822+02
564	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:49:39.737375+02
565	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-13 20:50:39.205791+02
566	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:51:34.37616+02
567	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:52:28.260568+02
568	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:53:14.590688+02
569	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:54:18.156544+02
570	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-13 20:54:58.142406+02
571	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-13 20:55:20.210913+02
572	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-13 21:23:08.853653+02
573	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-13 21:33:46.287805+02
574	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-14 12:32:35.147232+02
575	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-14 12:41:37.099157+02
576	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-14 14:16:48.788081+02
577	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-14 14:27:13.024202+02
578	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-14 15:29:57.475473+02
579	98e2a59e-389d-4b72-ba98-0c3c026dcae1	test.producteur.ed721073@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:23:03.504398+02
580	79b78eee-a7f2-43b2-9bb7-ed8d0d790982	test.producteur.430ae164@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:24:14.257364+02
581	10c652a1-c147-4459-91ef-523fb13fc3ad	test.producteur.115f9ba6@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:24:31.654055+02
582	edc9a5ef-e345-4601-b244-735904555ea8	test.producteur.01fd83f3@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:26:18.957024+02
583	71b962d9-fdb9-4b61-a931-c6676b9225fd	test.producteur.e17bba51@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:26:38.20723+02
584	48577b92-7b4f-4356-a499-b8f88eff743d	test.producteur.19de46a7@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-15 16:30:18.037868+02
585	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 16:42:03.759256+02
586	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:17.971874+02
587	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 16:46:19.608383+02
588	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 16:51:54.992263+02
589	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 16:55:33.192551+02
590	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 17:00:43.322999+02
591	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 17:03:43.089655+02
592	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 17:06:17.99932+02
593	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	\N	\N	728373547d8a1518d5c8a22eaee83306	2026-08-15 17:51:52.610214+02
594	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-15 17:52:12.186218+02
595	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-15 18:00:08.897565+02
596	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:02:44.572262+02
597	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-15 18:05:12.967952+02
598	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:09:32.4115+02
599	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:11:03.039937+02
600	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:15:11.170854+02
601	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:17:42.893885+02
602	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:26:11.061329+02
603	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:26:45.094207+02
604	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:18.786747+02
605	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-15 18:27:29.409418+02
606	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	MOBILE	Android	Chrome	8279b5bcf6bced4de71e970eef6ec8b9	2026-08-17 16:11:15.905331+02
607	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	MOBILE	Android	Chrome	8279b5bcf6bced4de71e970eef6ec8b9	2026-08-17 16:12:10.233707+02
608	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-17 17:31:41.956896+02
609	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-17 17:33:52.975495+02
610	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-17 17:34:52.811736+02
611	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 17:41:19.503033+02
612	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 17:46:42.898526+02
613	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 17:48:11.70159+02
614	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 17:50:39.866049+02
615	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 17:58:32.306755+02
616	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-08-17 18:14:09.830537+02
617	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 18:17:10.614163+02
618	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 18:18:12.78016+02
619	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-17 18:19:03.121047+02
620	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-18 06:03:34.791052+02
621	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-18 15:28:03.422649+02
622	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 00:25:44.155075+02
623	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:35:43.947664+02
624	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:40:00.402982+02
625	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:42:22.54992+02
626	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:45:33.412929+02
627	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:49:12.164879+02
628	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 11:55:32.38369+02
629	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:14.405211+02
630	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:14.993301+02
631	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:15.524993+02
632	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:16.08517+02
633	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:16.670487+02
634	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:17.256618+02
635	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:20:18.309166+02
636	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:06.353175+02
637	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:07.130338+02
638	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:08.046894+02
639	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:08.96259+02
640	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:09.900389+02
641	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:10.881857+02
642	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:11.880058+02
643	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:42.787474+02
644	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:43.613254+02
645	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:44.403804+02
646	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:45.316209+02
647	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:46.218058+02
648	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:46.961492+02
649	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:21:47.627544+02
650	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:13.574078+02
651	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:14.406822+02
652	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:15.440854+02
653	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:16.289895+02
654	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:17.145979+02
655	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:42.503252+02
656	c324981c-2d16-41ee-9121-e21aa9c93565	rbac_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:43.348341+02
657	f1a7b6fc-8b1c-409c-9ffd-794e3d589828	rbac_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:44.18837+02
658	41f20506-4b04-4203-900c-5c52ab3209bf	rbac_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:45.170932+02
659	24cddb38-0a57-4661-928b-f97aba310218	rbac_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:46.146843+02
660	b1b1fd58-effa-4e7d-bb16-e3b507b161c2	rbac_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:46.987143+02
661	867247ca-c7cd-4240-a26d-184312b3fcc8	rbac_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 12:40:47.562472+02
662	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 12:46:01.13252+02
663	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 12:55:00.564987+02
664	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:41.611573+02
665	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:42.282638+02
666	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:43.0396+02
667	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:43.891207+02
668	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:44.839326+02
669	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:45.984597+02
670	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:09:47.84505+02
671	959c438c-ffd7-4a8c-8780-9fd321d60aee	parcours_admin@pnlf-test.local	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:25.581217+02
672	3e879f22-30a5-4295-a730-24b3e6b67875	parcours_agentmin@pnlf-test.local	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:26.388466+02
673	a392a4cc-cfe0-4949-8b4f-d7ed56152bc1	parcours_agentfor@pnlf-test.local	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:26.988362+02
674	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:27.708855+02
675	469a4ea8-2f2b-4d70-9514-4f96476dc47a	parcours_coop@pnlf-test.local	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:28.819695+02
676	27fb70b6-339d-4899-b1db-30c14de44778	parcours_acheteur@pnlf-test.local	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:29.970223+02
677	1a62a7d6-150a-4243-8056-3025dab6cbf7	parcours_producteur@pnlf-test.local	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-08-19 13:10:30.691348+02
678	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 13:57:21.686695+02
679	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 13:57:40.977625+02
680	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 14:01:17.440254+02
681	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:35:30.130532+02
682	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:40:30.126448+02
683	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:42:01.664478+02
684	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:43:26.464927+02
685	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:43:45.929778+02
686	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:44:03.703179+02
687	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 15:55:46.381545+02
688	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-19 16:02:44.662811+02
689	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-20 14:20:35.198709+02
690	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 11:50:05.470666+02
691	e300b89e-c6bc-4576-878f-bcdef266555e	acheteur@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 11:53:16.174034+02
692	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 11:55:41.064571+02
693	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 11:59:53.513052+02
694	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 12:01:27.066883+02
695	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 12:24:54.123548+02
696	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 13:11:48.308445+02
697	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 13:26:29.182432+02
698	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 13:38:37.749772+02
699	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 18:30:59.005133+02
700	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 18:41:52.532911+02
701	e7f43b56-b615-4214-9e26-e2b2e09d257e	yves@pnlf.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 18:45:10.588062+02
702	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 18:49:52.16832+02
703	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:02:34.595707+02
704	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:03:15.490257+02
705	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:04:48.088056+02
706	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:05:03.424308+02
707	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:07:51.409717+02
708	6d357352-e8fa-4ac3-a2ff-f1168e59d9ed	sylviamano7@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-21 19:08:16.851319+02
709	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-23 17:46:03.950056+02
710	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 10:51:58.679806+02
711	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 12:25:18.110659+02
712	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 12:33:45.077425+02
713	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 12:38:29.270516+02
714	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 12:38:53.112224+02
715	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 22:06:21.409771+02
716	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-25 22:09:26.806791+02
717	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 00:00:37.337929+02
718	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:46:20.885232+02
719	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:49:23.704381+02
720	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:50:52.335206+02
721	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:51:57.656852+02
722	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:52:23.293615+02
723	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 15:57:02.341763+02
724	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 16:00:01.379995+02
725	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 16:01:56.972246+02
726	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 16:05:53.564073+02
727	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 16:17:42.142343+02
728	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 16:46:45.293474+02
729	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:00:31.473859+02
730	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:02:57.417695+02
731	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:07:52.771484+02
732	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:09:43.990515+02
733	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:17:47.8647+02
734	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:18:28.274409+02
735	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:23:53.995556+02
736	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 17:28:02.354581+02
737	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:33:58.470848+02
738	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:36:59.386694+02
739	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:38:16.10496+02
740	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:44:41.070708+02
741	72bd473c-6010-4800-a9dd-2e3a247c2673	prod@pnlf.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:45:29.892301+02
742	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:46:20.396642+02
743	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:47:06.932089+02
744	363a526d-88d0-4dfc-931f-65ed184f8d14	prodcol@pnlf.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 19:47:28.731722+02
745	bf0dd7c8-13b3-41fe-9504-90e8eff158c7	mba@pnlf.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 20:09:35.388542+02
746	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 20:09:53.962457+02
747	72bd473c-6010-4800-a9dd-2e3a247c2673	prod@pnlf.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 20:10:18.331998+02
748	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 20:10:53.222979+02
749	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	40956f08f6c9af83802ecd226385c678	2026-08-27 20:26:10.766355+02
750	363a526d-88d0-4dfc-931f-65ed184f8d14	prodcol@pnlf.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	dc48245976c0b33c00f9f386a819478f	2026-09-06 20:08:31.030198+02
751	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	dc48245976c0b33c00f9f386a819478f	2026-09-06 20:09:40.987597+02
752	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 13:48:13.624227+02
753	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:00:29.547315+02
754	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:02:05.029042+02
755	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:13:38.92446+02
756	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:13:48.849353+02
757	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:15:12.548707+02
758	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:15:43.810648+02
759	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:09:57.072372+02
760	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:17:30.645838+02
761	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:19:41.543767+02
762	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:20:20.981309+02
763	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:24:20.8067+02
764	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:36:32.914944+02
765	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:37:09.899886+02
766	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:37:46.874674+02
767	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:38:24.222149+02
768	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:39:01.94542+02
769	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:40:45.530732+02
770	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	e7175d67562b16e83053a903ffb8b632	2026-09-21 14:44:23.368288+02
771	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:45:39.556714+02
772	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:56:33.355228+02
773	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 14:56:45.246855+02
774	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-09-21 14:57:53.845445+02
775	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	e7175d67562b16e83053a903ffb8b632	2026-09-21 15:52:34.363645+02
776	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 15:53:44.154082+02
777	ec38d815-0579-448c-b7dd-1c54b8dce005	staeelbent16@gmail.com	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 15:56:33.865676+02
778	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-21 15:59:05.961296+02
779	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 11:21:19.723658+02
780	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 11:44:37.468681+02
781	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 11:45:22.491652+02
782	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:13:57.72157+02
783	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 12:54:38.307175+02
784	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 13:28:28.532312+02
785	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	ac628f4cfda1bcac1aa445ee899b5f13	2026-09-23 22:55:09.861756+02
786	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:13:58.077091+02
787	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:13:58.367252+02
788	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:13:59.043445+02
789	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:00.020126+02
790	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:00.479802+02
791	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:01.66635+02
792	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:02.047221+02
793	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:02.326692+02
794	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:02.623858+02
795	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:03.976796+02
796	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:14:04.391332+02
797	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:20.197732+02
798	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:20.49663+02
799	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:20.736044+02
800	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:20.951026+02
801	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:21.437788+02
802	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:21.689842+02
803	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:22.522045+02
804	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:22.832874+02
805	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:23.047844+02
806	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:23.270526+02
807	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:24.089536+02
808	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:16:24.337854+02
809	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:11:10.218351+02
810	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:13:26.149841+02
811	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:14:26.586915+02
812	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:17:51.233579+02
813	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:18:50.053394+02
814	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:24:57.761449+02
815	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 15:34:38.647226+02
816	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 15:36:10.298932+02
817	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:11.284022+02
818	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:11.550157+02
819	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:11.777011+02
820	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:12.007387+02
821	\N	\N	\N	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:15:49.489916+02
822	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:11:24.233261+02
823	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:13:39.956846+02
824	\N	\N	\N	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:16:04.698215+02
825	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:18:03.986882+02
826	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:21:41.753874+02
827	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:25:14.40354+02
828	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 15:34:58.105634+02
829	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	\N	\N	728373547d8a1518d5c8a22eaee83306	2026-10-02 15:38:06.564635+02
830	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:12.231177+02
831	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:12.465859+02
832	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:12.694576+02
833	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:12.960374+02
834	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:13.240925+02
835	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:13.540762+02
836	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:13.815607+02
837	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:14.118367+02
838	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:16.553438+02
839	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:39.158216+02
840	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:39.529504+02
841	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:39.841575+02
842	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:40.155559+02
843	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:40.922909+02
844	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:41.409548+02
845	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:42.59143+02
846	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:42.973255+02
847	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:43.347942+02
848	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:43.704361+02
849	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:44.899301+02
850	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:07:45.234825+02
851	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:11:38.111588+02
852	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:13:53.537106+02
853	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 12:16:52.096663+02
854	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:18:17.217581+02
855	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:24:42.856645+02
856	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 12:25:48.302101+02
857	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	3caf269ff15e9469bb7f47985b75b52a	2026-10-02 15:35:18.063946+02
858	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:22.350825+02
859	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:22.700003+02
860	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:22.958877+02
861	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:23.258415+02
862	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:23.976911+02
863	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:24.404295+02
864	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:25.387586+02
865	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:25.757291+02
866	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:26.16241+02
867	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:26.434362+02
868	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:27.333191+02
869	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 15:38:27.584805+02
870	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:03:36.009674+02
871	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:06.853381+02
872	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:07.119601+02
873	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:07.353459+02
874	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:07.572417+02
875	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:08.00602+02
876	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:08.239671+02
877	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:08.958129+02
878	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:09.248193+02
879	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:09.556359+02
880	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:09.972043+02
881	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:11.386805+02
882	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:50:11.739621+02
883	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:08.987354+02
884	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:09.250333+02
885	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:09.500733+02
886	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:09.719699+02
887	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:10.166318+02
888	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:10.420326+02
889	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:11.058676+02
890	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:11.275397+02
891	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:11.49807+02
892	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:11.744512+02
893	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:47.97074+02
894	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:48.242227+02
895	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:48.494247+02
896	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:48.738156+02
897	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:49.191948+02
898	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:49.437884+02
899	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:50.200126+02
900	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:50.479625+02
901	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:50.893567+02
902	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:51.244157+02
903	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:52.329622+02
904	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 18:51:52.619184+02
905	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:12.877368+02
906	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:18:13.293239+02
907	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:51.826381+02
908	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:52.139175+02
909	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:52.398248+02
910	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:52.611641+02
911	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:53.054123+02
912	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:53.304331+02
913	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:54.148799+02
914	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:54.525525+02
915	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:54.805802+02
916	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:55.02448+02
917	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:55.870311+02
918	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:19:56.158711+02
919	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:13.244374+02
920	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:13.508541+02
921	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:13.827471+02
922	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:14.150147+02
923	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:14.669973+02
924	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:14.907857+02
925	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:15.779989+02
926	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:16.084047+02
927	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:16.414082+02
928	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:16.701574+02
929	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:17.760069+02
930	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:20:18.077376+02
931	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:45.271681+02
932	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:45.540469+02
933	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:45.771834+02
934	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:46.029699+02
935	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:46.80301+02
936	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:47.288296+02
937	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:48.269429+02
938	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:48.502881+02
939	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:48.736152+02
940	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:48.970365+02
941	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:49.816302+02
942	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-02 19:21:50.056339+02
943	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:26:04.231333+02
944	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:26:50.186015+02
945	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:27:32.102497+02
946	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:28:13.397045+02
947	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:28:54.792054+02
948	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:29:23.00475+02
949	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:31:06.094363+02
950	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:33:19.411421+02
951	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:34:54.741738+02
952	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:35:44.046728+02
953	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:36:33.738999+02
954	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:37:19.609773+02
955	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:38:00.623148+02
956	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:38:43.100518+02
957	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:39:24.960364+02
958	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 19:39:53.366882+02
959	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 20:10:47.698714+02
960	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 20:11:28.734081+02
961	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 20:15:22.712592+02
962	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 20:15:57.822443+02
963	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-02 20:16:27.363348+02
964	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:37.316128+02
965	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:37.726575+02
966	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:38.312791+02
967	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:38.621473+02
968	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:39.299138+02
969	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:39.707484+02
970	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:40.576461+02
971	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:40.956886+02
972	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:41.315263+02
973	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:41.612272+02
974	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:42.831949+02
975	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:43.131542+02
976	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	\N	2026-10-03 13:52:57.855637+02
977	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:51.653576+02
978	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:52.907744+02
979	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:53.442692+02
980	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:54.240344+02
981	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:54.887137+02
982	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:58:55.161687+02
983	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:51.418691+02
984	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:52.870525+02
985	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:54.726511+02
986	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:56.042523+02
987	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:56.546187+02
988	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:57.336141+02
989	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:58.125193+02
990	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 13:59:58.672444+02
991	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:11.035849+02
992	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:11.336142+02
993	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:11.583253+02
994	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:11.817725+02
995	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:12.052874+02
996	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:12.267211+02
997	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:12.535997+02
998	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:12.759919+02
999	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:12.98048+02
1000	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:13.207145+02
1001	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:13.452303+02
1002	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:13.679592+02
1003	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:13.907831+02
1004	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:14.134529+02
1005	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:14.349283+02
1006	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:14.569531+02
1007	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:14.797723+02
1008	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:15.049254+02
1009	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:15.282867+02
1010	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:15.711297+02
1011	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:03:15.96544+02
1371	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-06 13:57:23.768862+02
1049	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:48.915333+02
1050	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:49.42902+02
1051	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:49.926374+02
1052	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:50.469695+02
1053	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:50.943328+02
1054	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:51.356682+02
1055	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:51.892232+02
1056	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:52.416717+02
1057	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:52.830442+02
1058	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:53.292657+02
1059	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:53.818615+02
1060	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:54.299543+02
1061	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:54.748066+02
1062	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:55.293227+02
1063	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:55.688355+02
1064	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:56.061632+02
1065	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:56.46498+02
1066	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:56.948261+02
1067	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:57.434715+02
1069	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:58.208081+02
1070	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:13:58.630554+02
1098	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:01.591484+02
1099	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:01.966297+02
1100	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:02.312004+02
1101	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:02.629775+02
1102	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:02.981064+02
1103	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:03.303146+02
1104	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:03.708857+02
1105	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:04.030342+02
1106	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:04.337967+02
1107	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:04.649353+02
1108	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:05.013113+02
1109	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:05.367541+02
1110	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:05.713372+02
1111	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:06.038152+02
1112	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:06.337913+02
1113	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:06.624447+02
1114	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:06.952821+02
1115	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:07.313027+02
1116	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:07.66453+02
1117	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:08.272898+02
1118	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:16:08.575305+02
1119	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:48.869568+02
1120	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:49.195781+02
1121	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:49.458341+02
1122	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:49.698101+02
1123	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:49.940533+02
1124	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:50.171924+02
1125	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:50.472748+02
1126	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:50.714488+02
1127	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:50.965949+02
1128	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:51.293783+02
1129	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:51.845096+02
1130	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:52.390309+02
1131	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:52.930035+02
1132	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:53.390796+02
1133	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:53.615275+02
1134	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:53.854921+02
1135	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:54.134271+02
1136	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:54.63063+02
1137	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:55.176432+02
1138	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:55.760004+02
1139	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:23:55.988415+02
1164	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:01.144146+02
1165	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:01.595265+02
1166	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:01.957136+02
1167	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:02.300472+02
1168	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:02.665695+02
1169	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:03.012337+02
1170	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:03.413715+02
1171	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:03.759995+02
1172	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:04.088358+02
1173	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:04.435608+02
1174	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:04.786512+02
1175	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:05.137671+02
1176	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:05.496517+02
1177	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:05.869893+02
1178	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:06.21971+02
1179	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:06.567194+02
1180	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:06.924588+02
1181	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:07.318362+02
1182	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:07.688205+02
1183	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:08.592827+02
1184	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:30:09.020811+02
1185	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:15.704928+02
1186	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:16.79185+02
1187	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:17.806382+02
1188	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:18.596675+02
1189	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:19.383978+02
1190	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:20.240282+02
1191	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:21.23149+02
1192	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:22.010718+02
1193	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:22.671913+02
1194	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:23.352263+02
1195	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:23.987961+02
1196	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:24.695154+02
1197	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:25.416404+02
1198	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:26.087234+02
1199	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:26.67743+02
1200	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:27.322027+02
1201	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:27.934822+02
1202	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:28.607493+02
1203	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:29.235482+02
1204	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:30.366246+02
1205	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 14:33:30.936045+02
1281	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:37.081047+02
1369	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	f	IDENTIFIANTS	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-06 13:57:08.032758+02
1236	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:39:19.19247+02
1237	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:40:12.276684+02
1238	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:41:07.761821+02
1239	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:41:54.836803+02
1240	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:42:37.81207+02
1241	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:43:19.555014+02
1242	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:44:01.80374+02
1243	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:44:29.729943+02
1244	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:44:57.982396+02
1245	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:45:16.000442+02
1246	\N	doclinda@pnlf.ga	\N	f	IDENTIFIANTS	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-03 14:45:57.266895+02
1247	\N	doclinda@pnlf.ga	\N	f	IDENTIFIANTS	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-03 14:46:16.994904+02
1248	\N	doclinda@pnlf.ga	\N	f	IDENTIFIANTS	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-03 14:46:22.86541+02
1249	70dd1a0a-1111-47f4-9a12-efd092fbc67a	admin.demo@demo.pfnl.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	d72997d1fbd1e2478b6e633c0414d949	2026-10-03 14:46:31.823856+02
1250	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	t	\N	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-03 14:46:39.535917+02
1282	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	ministere.demo@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:37.550312+02
1283	f2d88f9a-597f-4c0f-88a8-13e670a28a58	ministere.nouveau@demo.pfnl.ga	AGENT_MINISTERE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:38.011195+02
1284	96c362a7-7215-490a-8443-371d2768cd2e	forestier.demo@demo.pfnl.ga	AGENT_FORESTIER	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:38.620669+02
1285	baa3d8fc-73a1-4ea7-bea2-61addb73958c	forestier.suspendu@demo.pfnl.ga	AGENT_FORESTIER	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:39.107181+02
1286	ec677a07-a583-40fd-9a61-370807755ac1	coop.ivindo@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:39.536734+02
1287	1f279d86-485b-4a3b-b0c5-3bfc813473b6	coop.ngounie@demo.pfnl.ga	COOPERATIVE	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:40.003822+02
1288	b894dc88-5275-4bba-9feb-13a700171cf3	coop.inactive@demo.pfnl.ga	COOPERATIVE	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:40.420385+02
1289	0d7cb814-c04e-4b90-a2f6-6d4e9fc51ef6	coop.attente@demo.pfnl.ga	COOPERATIVE	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:40.822081+02
1290	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	producteur.miel@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:41.228491+02
1291	b64ff13b-0617-456b-9589-257f95ae4fb7	producteur.kola@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:41.635419+02
1292	97a54b08-c1ef-46eb-8505-1f31b5cadb80	collecteur.ogooue@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:42.043232+02
1293	5dfd8155-3222-4e05-9702-06e9cc47cca1	producteur.independant@demo.pfnl.ga	PRODUCTEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:42.419044+02
1294	1d6791e9-3b17-4369-9041-924118ba2d22	producteur.inactif@demo.pfnl.ga	PRODUCTEUR	f	INACTIF	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:42.807405+02
1295	aac56367-b288-4ac9-8b81-d1c202be4ef8	producteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:43.184434+02
1296	0fed7e11-8cb4-4a19-a217-7b2f1a2c26b6	collecteur.attente@demo.pfnl.ga	PRODUCTEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:43.53694+02
1297	eaf22c78-d48d-431f-a7ae-660650279c0e	acheteur.export@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:43.929705+02
1298	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	acheteur.local@demo.pfnl.ga	ACHETEUR	t	\N	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:44.356492+02
1299	1a7015dd-2f54-424e-9b92-620a4cedabaa	acheteur.attente@demo.pfnl.ga	ACHETEUR	f	EN_ATTENTE	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:44.762417+02
1300	\N	producteur.rejete@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:45.508196+02
1301	\N	coop.rejetee@demo.pfnl.ga	\N	f	IDENTIFIANTS	127.0.0.1	INCONNU	\N	\N	d5b7f78a77e704ed2d3ec3780a2cc255	2026-10-03 16:48:45.901532+02
1370	2992fb5e-5580-483b-9462-98fe46cf7627	admin@pnlf.ga	ADMINISTRATEUR	f	IDENTIFIANTS	127.0.0.1	ORDINATEUR	Windows	Chrome	c4ea766a755ddee08f488270809d5745	2026-10-06 13:57:13.934102+02
\.


--
-- TOC entry 6993 (class 0 OID 86665)
-- Dependencies: 284
-- Data for Name: conversation_context; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.conversation_context (conversation_id, producteur_id, cooperative_id, est_groupe) FROM stdin;
15453ebc-6eba-4ada-90cf-8817007331b8	\N	17c571aa-c973-4da4-abe2-59fc08b7ded2	f
6aec5643-73f5-4767-9cd0-a7d990a50152	efddd969-6c0b-49f0-9204-5c846f4f7bba	\N	f
75cc426b-35bf-4b82-bf2a-582c16e92e93	\N	17c571aa-c973-4da4-abe2-59fc08b7ded2	t
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	34cc9c4d-801a-4e72-9ff8-2e673be01804	\N	f
\.


--
-- TOC entry 6995 (class 0 OID 86702)
-- Dependencies: 286
-- Data for Name: conversation_participant_meta; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.conversation_participant_meta (conversation_id, utilisateur_id, last_read_at, deleted_at) FROM stdin;
75cc426b-35bf-4b82-bf2a-582c16e92e93	97a54b08-c1ef-46eb-8505-1f31b5cadb80	2026-10-03 14:43:44.440971+02	\N
15453ebc-6eba-4ada-90cf-8817007331b8	3aadd7e2-cc8f-4448-8fd0-65d5aa32f209	2026-10-03 14:44:12.700413+02	\N
732a763f-ae05-499c-834f-5f785d39f339	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	2026-10-03 14:45:02.756073+02	\N
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	5dfd8155-3222-4e05-9702-06e9cc47cca1	2026-10-03 14:52:33.55394+02	\N
888bdf95-0bd2-42d5-9a86-dc4e4a377a61	2992fb5e-5580-483b-9462-98fe46cf7627	2026-10-03 14:52:41.485611+02	2026-10-03 14:52:41.52723+02
11a76a97-5e8f-4eb4-9500-c4fcee8fd636	eaf22c78-d48d-431f-a7ae-660650279c0e	2026-10-02 12:06:45.05915+02	\N
11a76a97-5e8f-4eb4-9500-c4fcee8fd636	df9e2ba3-fbc2-4b01-8a16-ff974c89a238	2026-10-02 12:06:45.183539+02	\N
15453ebc-6eba-4ada-90cf-8817007331b8	ec677a07-a583-40fd-9a61-370807755ac1	2026-10-02 12:06:45.460934+02	\N
6aec5643-73f5-4767-9cd0-a7d990a50152	b64ff13b-0617-456b-9589-257f95ae4fb7	2026-10-02 12:06:45.525426+02	\N
6aec5643-73f5-4767-9cd0-a7d990a50152	eaf22c78-d48d-431f-a7ae-660650279c0e	2026-10-02 12:06:45.654258+02	\N
732a763f-ae05-499c-834f-5f785d39f339	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	2026-10-03 14:40:42.766241+02	\N
840b065a-bd81-4aaf-b799-da196446caf3	96c362a7-7215-490a-8443-371d2768cd2e	2026-10-03 14:41:35.426236+02	\N
75cc426b-35bf-4b82-bf2a-582c16e92e93	ec677a07-a583-40fd-9a61-370807755ac1	2026-10-03 14:42:19.981971+02	\N
75cc426b-35bf-4b82-bf2a-582c16e92e93	b64ff13b-0617-456b-9589-257f95ae4fb7	2026-10-02 12:06:45.985652+02	\N
840b065a-bd81-4aaf-b799-da196446caf3	1f279d86-485b-4a3b-b0c5-3bfc813473b6	2026-10-02 12:06:46.479876+02	\N
\.


--
-- TOC entry 6989 (class 0 OID 70229)
-- Dependencies: 277
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
\.


--
-- TOC entry 6975 (class 0 OID 70099)
-- Dependencies: 263
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	permission
3	auth	group
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	token_blacklist	blacklistedtoken
8	token_blacklist	outstandingtoken
9	pnlf_platform	notification
10	pnlf_platform	offredemande
11	pnlf_platform	conversation
12	pnlf_platform	conversationparticipant
13	pnlf_platform	message
14	pnlf_platform	conversationcontext
15	pnlf_platform	conversationparticipantmeta
16	pnlf_platform	messagepiece
17	pnlf_platform	appareilsync
18	pnlf_platform	syncconflict
\.


--
-- TOC entry 6973 (class 0 OID 70087)
-- Dependencies: 261
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2026-08-10 14:14:56.341452+02
2	auth	0001_initial	2026-08-10 14:14:56.491873+02
3	admin	0001_initial	2026-08-10 14:14:56.52024+02
4	admin	0002_logentry_remove_auto_add	2026-08-10 14:14:56.524415+02
5	admin	0003_logentry_add_action_flag_choices	2026-08-10 14:14:56.530177+02
6	contenttypes	0002_remove_content_type_name	2026-08-10 14:14:56.540212+02
7	auth	0002_alter_permission_name_max_length	2026-08-10 14:14:56.545592+02
8	auth	0003_alter_user_email_max_length	2026-08-10 14:14:56.551409+02
9	auth	0004_alter_user_username_opts	2026-08-10 14:14:56.55665+02
10	auth	0005_alter_user_last_login_null	2026-08-10 14:14:56.56273+02
11	auth	0006_require_contenttypes_0002	2026-08-10 14:14:56.563547+02
12	auth	0007_alter_validators_add_error_messages	2026-08-10 14:14:56.567652+02
13	auth	0008_alter_user_username_max_length	2026-08-10 14:14:56.577024+02
14	auth	0009_alter_user_last_name_max_length	2026-08-10 14:14:56.582435+02
15	auth	0010_alter_group_name_max_length	2026-08-10 14:14:56.589224+02
16	auth	0011_update_proxy_permissions	2026-08-10 14:14:56.593667+02
17	auth	0012_alter_user_first_name_max_length	2026-08-10 14:14:56.598642+02
18	sessions	0001_initial	2026-08-10 14:14:56.60819+02
19	token_blacklist	0001_initial	2026-09-23 12:44:49.073013+02
20	token_blacklist	0002_outstandingtoken_jti_hex	2026-09-23 12:44:49.085129+02
21	token_blacklist	0003_auto_20171017_2007	2026-09-23 12:44:49.100287+02
22	token_blacklist	0004_auto_20171017_2013	2026-09-23 12:44:49.110377+02
23	token_blacklist	0005_remove_outstandingtoken_jti	2026-09-23 12:44:49.136196+02
24	token_blacklist	0006_auto_20171017_2113	2026-09-23 12:44:49.146338+02
25	token_blacklist	0007_auto_20171017_2214	2026-09-23 12:44:49.194193+02
26	token_blacklist	0008_migrate_to_bigautofield	2026-09-23 12:44:49.23594+02
27	token_blacklist	0010_fix_migrate_to_bigautofield	2026-09-23 12:44:49.252018+02
28	token_blacklist	0011_linearizes_history	2026-09-23 12:44:49.257248+02
29	token_blacklist	0012_alter_outstandingtoken_user	2026-09-23 12:44:49.264143+02
30	token_blacklist	0013_alter_blacklistedtoken_options_and_more	2026-09-23 12:44:49.271706+02
\.


--
-- TOC entry 6990 (class 0 OID 70269)
-- Dependencies: 278
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
\.


--
-- TOC entry 6996 (class 0 OID 86728)
-- Dependencies: 287
-- Data for Name: documents_inscription; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.documents_inscription (id, entite_type, entite_id, type_document, chemin, nom_original, depose_par_id, created_at) FROM stdin;
75b36ec2-c39e-428c-ab35-42ee1e564585	PRODUCTEUR	c660c2be-c52d-4fa6-8273-0f754efc497f	CNI	documents/inscriptions/producteurs/c660c2be-c52d-4fa6-8273-0f754efc497f_cni.png	Capture d’écran 2026-02-09 133122.png	\N	2026-09-23 11:19:22.534568+02
1b8f94bc-c714-4118-bdd5-9f6365864ced	PRODUCTEUR	c660c2be-c52d-4fa6-8273-0f754efc497f	FICHE_CIRCUIT	documents/inscriptions/producteurs/c660c2be-c52d-4fa6-8273-0f754efc497f_fiche_circuit.png	Capture d’écran 2026-02-09 133122.png	\N	2026-09-23 11:19:22.534568+02
4ce03eee-e159-4391-b6f4-2a6a5e88a987	PRODUCTEUR	ad0c1500-c241-4d87-90c6-ac3ec914f53a	CNI	documents/inscriptions/producteurs/ad0c1500-c241-4d87-90c6-ac3ec914f53a_cni.png	piece-identite.png	\N	2026-10-02 12:06:26.295807+02
96358e22-3427-4fa8-ada7-373f2ed6dabc	PRODUCTEUR	efddd969-6c0b-49f0-9204-5c846f4f7bba	CNI	documents/inscriptions/producteurs/efddd969-6c0b-49f0-9204-5c846f4f7bba_cni.png	piece-identite.png	\N	2026-10-02 12:06:27.159983+02
ada5d225-a4b9-4f6b-8291-badf739defc7	PRODUCTEUR	32b71cac-11e7-4f9e-a7e9-b909b42a7154	CNI	documents/inscriptions/producteurs/32b71cac-11e7-4f9e-a7e9-b909b42a7154_cni.png	piece-identite.png	\N	2026-10-02 12:06:27.49062+02
657467ca-1baa-4a99-a014-a5c103d82991	PRODUCTEUR	32b71cac-11e7-4f9e-a7e9-b909b42a7154	FICHE_CIRCUIT	documents/inscriptions/producteurs/32b71cac-11e7-4f9e-a7e9-b909b42a7154_fiche_circuit.png	fiche-circuit.png	\N	2026-10-02 12:06:27.49062+02
bbcc4540-17e3-4388-9d8f-c02bc1fb022a	PRODUCTEUR	34cc9c4d-801a-4e72-9ff8-2e673be01804	CNI	documents/inscriptions/producteurs/34cc9c4d-801a-4e72-9ff8-2e673be01804_cni.png	piece-identite.png	\N	2026-10-02 12:06:27.842081+02
27a9bc13-79df-47b8-a768-dea3cb60c46a	PRODUCTEUR	8d14134e-2de3-49e6-bc73-9e18699258a1	CNI	documents/inscriptions/producteurs/8d14134e-2de3-49e6-bc73-9e18699258a1_cni.png	piece-identite.png	\N	2026-10-02 12:06:28.191553+02
cb152b87-50f4-407d-a7ce-1e495ac1c528	PRODUCTEUR	5acc6d02-db6c-4886-80f7-2344e223ec3f	CNI	documents/inscriptions/producteurs/5acc6d02-db6c-4886-80f7-2344e223ec3f_cni.png	piece-identite.png	\N	2026-10-02 12:06:28.543403+02
82064de9-e409-4f58-a1fe-667204612250	PRODUCTEUR	47d0baea-0308-4618-ac9a-dcb5319e4d26	CNI	documents/inscriptions/producteurs/47d0baea-0308-4618-ac9a-dcb5319e4d26_cni.png	piece-identite.png	\N	2026-10-02 12:06:29.035607+02
19dc6bee-c38f-462c-8829-f3ffa3823b24	PRODUCTEUR	47d0baea-0308-4618-ac9a-dcb5319e4d26	FICHE_CIRCUIT	documents/inscriptions/producteurs/47d0baea-0308-4618-ac9a-dcb5319e4d26_fiche_circuit.png	fiche-circuit.png	\N	2026-10-02 12:06:29.035607+02
16c5de5f-4dd2-4110-9e87-fb6d86713323	PRODUCTEUR	c6c3eee1-a671-4e21-8c35-b792af24efc6	CNI	documents/inscriptions/producteurs/c6c3eee1-a671-4e21-8c35-b792af24efc6_cni.png	piece-identite.png	\N	2026-10-02 12:06:29.568347+02
1a88bdd5-9127-452f-b708-61eccf4695b2	COOPERATIVE	17c571aa-c973-4da4-abe2-59fc08b7ded2	CNI	documents/inscriptions/cooperatives/17c571aa-c973-4da4-abe2-59fc08b7ded2_cni.png	piece-identite.png	\N	2026-10-02 12:06:30.204846+02
9da3e137-95a8-4aae-8404-41664dc290cb	COOPERATIVE	17c571aa-c973-4da4-abe2-59fc08b7ded2	AGREMENT_NAGOYA	documents/inscriptions/cooperatives/17c571aa-c973-4da4-abe2-59fc08b7ded2_agrement_nagoya.png	agrement-nagoya.png	\N	2026-10-02 12:06:30.204846+02
59d69502-1cb2-475a-a5d1-a68ade2ed52d	COOPERATIVE	e5326de4-90ed-4b3b-acab-5c847db8bf0a	CNI	documents/inscriptions/cooperatives/e5326de4-90ed-4b3b-acab-5c847db8bf0a_cni.png	piece-identite.png	\N	2026-10-02 12:06:30.908028+02
2513961e-da50-40b5-87f3-2973c67ef78a	COOPERATIVE	06b7bec2-85a3-4b42-9844-fc9a927efcf7	CNI	documents/inscriptions/cooperatives/06b7bec2-85a3-4b42-9844-fc9a927efcf7_cni.png	piece-identite.png	\N	2026-10-02 12:06:31.753698+02
1a693fc5-024e-44e4-8a01-d9aa0a899973	COOPERATIVE	291e43ee-c88b-45a1-a5b1-b69e94b723af	CNI	documents/inscriptions/cooperatives/291e43ee-c88b-45a1-a5b1-b69e94b723af_cni.png	piece-identite.png	\N	2026-10-02 12:06:32.723715+02
39b64670-f095-4731-81ff-c7a37f28d169	COOPERATIVE	1b1aaec8-b1bc-4228-8b1b-278466538418	CNI	documents/inscriptions/cooperatives/1b1aaec8-b1bc-4228-8b1b-278466538418_cni.png	piece-identite.png	\N	2026-10-02 12:06:33.665253+02
\.


--
-- TOC entry 7003 (class 0 OID 86862)
-- Dependencies: 294
-- Data for Name: invitations_cooperative; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.invitations_cooperative (id, cooperative_id, producteur_id, statut, message, invite_par_id, repondu_par_id, motif_reponse, created_at, repondu_at) FROM stdin;
\.


--
-- TOC entry 7004 (class 0 OID 86900)
-- Dependencies: 295
-- Data for Name: lots_transitions; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.lots_transitions (id, lot_id, ancien_statut, nouveau_statut, mode, role_auteur, auteur_id, motif, created_at) FROM stdin;
573fb275-1a1d-4af2-9e0b-59cb7ee08c74	cbab41ae-0e5a-4b8e-a556-f0d173ef9f90	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
1bee0d3c-3bcb-4b04-aedf-9cc92b26c341	242cb5f0-bf99-4a9e-a8ae-b8482cf56adb	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
eeed42fa-f7c9-4738-bd91-ea781808e266	67fe58b6-5032-43e3-87ec-e5288cec9cf4	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
bbccd961-1eb9-4e60-a1d3-38b9efed2bee	07fa0834-2dd8-47b1-a514-176f1f8091a9	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
67232d82-708c-4a00-bd6c-f12eb9790e1a	cfeb7bb7-ccfb-48e3-839a-969001365b45	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
4f53160c-e567-4f7b-a25a-a66cfd69384d	74ce72a3-51ce-4843-965e-6aaa68792a32	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
eddb3413-105a-43ca-bb41-378ea64132a5	a53361f0-d36f-4224-ac8b-b16f89e2ac3e	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
fe144314-ec2c-436d-9eea-f1b428554212	c856c8fd-10cb-4128-86d2-a4517631f039	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
a76555bc-5ac7-404d-ab88-486b5fabaf9e	abef08e3-bf40-451b-a860-45bd366eee32	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
a46243d8-3302-4de2-a92e-2e78cf0a288e	7426e125-300b-4c0d-a1d6-5c6f9ba45f33	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
04df2d76-f0c9-47cc-aef1-cb2a3b5a4bdf	e77b0d44-e40f-47da-9436-338e24f4948a	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
00ec151a-19e5-476f-9c06-f6672bb62f0d	04f37203-6c70-438c-8898-0ef5fbea5650	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
68d6d1c8-c6c7-4a90-a77d-711006409e68	421c9eb8-2612-4025-b2ff-8b71c8c250b0	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
35cc7607-b737-4e96-ae6f-41f33c848af9	54b091df-1b94-42b1-956e-9ec210b70bee	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
501615b3-2410-47ff-9ec3-33a7db2e4bb5	309a3c6f-8439-4583-be13-0318f7fcaecb	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
990f3e35-479d-4d76-87cd-c855e95f2339	78492e02-c603-48c0-a488-8579d43e616f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
94125c2f-9013-45e1-b564-99c6915e5151	e9ba15d9-eea2-4474-90bb-3162bdf3674c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e092312d-25db-42c6-b679-14a79764a651	d25990de-abce-4a33-8532-370a252fe84e	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
6a9fe755-437b-46dd-a4dd-ddd85185760b	6c36cf89-bf38-4585-9ed7-6105d09c6834	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e1d9b36a-0e19-40c5-8018-77bae849f692	f732e990-3a92-4436-bfbe-45dccd6412f3	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
3f4fd44a-5e86-4078-b0ed-9f7b651cc688	eae7ddfb-aa9b-4a85-ad6f-3a1ba0cc1d80	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
fb1419c2-3a93-4ccf-ad7d-023f010a642a	72bfcb0e-d964-43f7-ace3-9ec798fbc9b5	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
65e7bbd2-84a7-43e1-9e1b-d313cc052fcb	36d41a1a-17df-485a-8af8-ca1e89301c1f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9d539626-4bfb-4a14-9857-329ce6a4d696	192b93a8-c496-43ef-8871-16b6c4d86f0c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
851a6b82-8155-4663-94c5-a6e12dba3654	680c23ed-0ad7-435c-93c2-0733a4312726	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
fdf2bb53-2796-4018-afcc-9e647d49145c	e437c0f5-36ad-4a4b-b637-9ae63759035e	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
661111cb-ac9e-481a-af62-88988b10e001	749e0d73-5539-438c-b82f-cf56e1478664	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
77ae1d4e-5a42-4367-9984-877ea3f052be	c3885f84-6a3e-491a-a07e-4e812836b66d	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
d65d0765-6373-42c7-baa5-bc00ca7bac88	30907e00-b121-4760-a042-f7d351b0fbf9	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
4dd50007-4d6a-4002-9343-408dc7f5ef60	6e99d951-70c9-46f1-8d40-388b6fbb8126	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
43ed9f77-7295-41fe-b224-1b9ecd9ae0a1	c2367dcb-a765-4713-beb5-e5dafbfd8501	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
d81482e3-340e-4d7c-a187-0076fa202ba5	5a335163-11c9-41ce-a66b-504d08c9f909	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
0050af19-79aa-4c20-991a-c5dfa9a33691	73e3c879-2b0a-4679-96f9-e14c889eaa7f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
bb9a00a5-5fbf-43f1-9576-114ba8bd2008	ea1b6189-2a4d-42c6-9410-bc59b3357468	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
d4430eb6-0533-47bf-bd00-06805a8e4ffa	cf6f989a-98d0-4682-948c-5538447e4b4b	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
f0d96878-6893-4419-9aea-1e7636cc1bd0	16649b4b-0929-45d1-b830-ae486e38be3d	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
b9057408-0880-4b35-afe8-3d93af87aeb7	87e9b6b2-f1c7-4bec-a267-8b45e8753e25	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
5e0b25b4-1f25-42af-ad37-9f1c4fcb55fd	39514cfc-0c93-4fe9-b85a-ff3fd8c043d0	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
2c69765e-1773-4cb2-9492-8a0ef0e7f99f	d25c710b-839a-49ec-a011-89b37ef436ec	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
2e1fbd4b-52d8-4759-8cf3-91933b3250b5	5c386e69-9870-4b6b-8e27-4d5bf9027da9	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
66f33118-2cbf-4195-b177-08ceea232136	e4b7c78d-8663-4b2a-afb3-71c1c7f3554b	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e7d67000-1a86-432b-9c83-986a3b7298f3	4c7da43b-544d-42e4-ae01-70caa3905819	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
11fb7366-d5aa-42fc-a76a-b9bd2eb0ac92	7103bd23-00dd-4ad8-9397-73280b333f3f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9707902e-2059-4fa3-af33-e0499f0153ff	4f532bb7-3727-41c4-b823-f79d20943430	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
6b1e1e07-4615-41f7-a21f-92e3a59a0375	226d5a29-c768-4283-9510-c0ee09ab6ad0	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
31611ba5-fac2-4be5-a387-5e3ae8c24157	23726099-ba5f-4900-8824-9d5ac5f2d8ee	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
12034182-6450-4b17-8369-fb649d7dfefc	2805594d-f18f-47b4-aff1-d1263143f8a3	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
ebedf48d-95ce-4d50-8e37-1c76bf0a9f1a	ebf56ae8-e877-45ee-b444-620ca79df018	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9e6bc2d9-689f-4a68-8703-5842995c4ab9	5f2fc59a-b2d2-4d4e-9db6-3a36ea46c34c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e217b563-8cff-4ee3-9831-25c51d83d713	3dd1ba95-ac23-4045-902a-95a261153c17	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
10dde8e5-ea76-44d1-9bf9-74b320ee06d9	907fb82c-92f8-4545-8175-f2936c9561bb	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
07bd39e4-c41a-491e-9b4a-8449d6a79247	7a948d05-8a65-4fd5-8a20-52fca42aff5d	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
c2046fe6-9713-481d-8122-6087827c3eff	a6ecae99-b5d9-42a5-8371-bb48e8f26c86	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
1cda7436-94c4-4072-9844-be3c7c8ec168	bdc4005d-08ee-4a9f-be9f-cd666e715270	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
748203ef-7b5d-4fb9-b27a-2cd229f788f8	4af77ba1-b515-42e3-8156-d299733b266e	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e29a1971-1c06-4101-90fe-faebf6937b07	58237198-493a-412c-b06f-5a9dd504e426	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
3c072de4-966c-4bc9-807e-c43f7735db9f	87057364-ce8b-4dc3-8c87-658c8b4de90e	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e851ce1e-3adc-4f0f-88c9-a45f63980b6c	0c0106ee-1b58-4b85-8ddd-cea26904d0ff	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
8ac5dea5-b18d-40f7-b34a-91a1ce84d28a	88181504-eb0e-4036-a6ef-bc43be5beed6	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
277c7de5-4161-4fc3-9c9c-307600089ce4	18a8c9f8-e0fb-4053-877f-023e68359da7	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
1fe8726c-fd4c-43db-b4a4-67af3762bab9	954bede4-567a-480a-a715-58c0b6a9828c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
63269493-ef82-4e8d-a5cc-40e767e45209	06787104-09da-485e-897f-ec09c69ebca0	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
3d5a1831-301f-4980-88f1-a7cd95584656	09508320-8436-41a6-ac38-bad3927786de	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
6c381244-fd30-4ba7-ae20-7972ac619af7	dfde6062-15c1-4238-b853-6e1e40969f74	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
6ccd6d3a-7c25-4f97-aed7-913b19d46da3	b5b08992-60f8-4936-aa89-10c2904df08d	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
44259adc-e635-495f-8828-ba838c85e834	87dd0477-1172-4893-9dac-1aac9c934792	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9f45f58a-9064-431e-83d8-699414dd6955	efa5499c-ebdd-48a9-8771-748225ebc2c8	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
350ea333-1b33-4da8-aef2-795ccdaeb152	7890cc23-a774-4768-b9fc-fa31d63e675c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
18801e88-3e17-4248-862f-02e331d4c762	8ec32c4a-4ad4-4840-a4f4-eb8dde3d158b	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
e64d9389-64cc-4ca2-96a1-ce2e1a82f160	53532fa4-2495-4bb7-ad57-c0b842d1d0ca	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
42e71671-1caa-44bd-97fe-f8ad69c1bb3f	31e28129-f299-44ef-8bc4-2cabb1dd7ffc	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
0b39e211-2d41-4f8b-800c-baa412ce5d48	fe29adac-04cb-47d3-bd9d-73f3ed3649d8	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
80a9310e-42eb-47b4-911b-6d633de9b990	50fce242-90c5-4af3-8349-4907f9649a1c	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
93bf6e2c-ff0b-469e-904e-0fd5ae50e06f	e96f14dd-1165-4db8-b979-a60b2141f830	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
91487c9d-1f01-4bf0-87a5-fe66141ac0cd	61d7ebae-83cb-44fc-b34d-f3a484d95ff3	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
879ccce8-a480-41da-9052-17c2baef4b9c	cd7faaa4-8d83-4e01-aa9b-9804a80b396f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
42773b49-2d28-4e12-8b2e-a11fbdaeccee	0db80fe5-1427-4a01-8be9-183de8232ae9	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
986601c7-2b74-49ef-b96a-8a2c142e488d	e16b7be4-1d09-426d-a064-9dc93c2b3c97	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9d34c8aa-ce53-4f79-8d42-dd2de959e4f6	f0e40537-ecf1-4242-94d1-65339dde604f	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
d8cfdc71-af6f-49ff-a12e-bff02895f0f7	b41386d7-ef39-4e9d-8854-f23c1a9137ac	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
5d7d532f-852d-4085-8569-ba6d9d789545	ca95422f-ebbe-43a4-b199-6a2075afe0af	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
ee381120-0a09-4c0a-ac33-3a87406b5811	2b3c8331-3445-44be-b861-a6df69c126a6	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
3b4ace56-4c5d-42ac-9dc9-cc68a1af2727	2d43927b-1ef1-4179-802c-38e2ec495ae3	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
142b2e02-f8ee-4458-95bf-01ad09bd7bd7	2bdbbed9-9ebf-4e94-8c3d-f857cfcee8bc	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
a6d02840-93fd-4118-8a5a-608f4eb2d008	92f2903a-395a-4daf-a693-fcbf85494663	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
02c6d4ad-9802-47df-b44d-22a298841fd2	8242374c-f334-4e11-afd4-e5504950b786	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
9a50dc2f-01eb-4064-a1f1-00ea117b760e	134f6a3d-20da-4ae3-b853-002795421487	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
ea5d77cb-4253-435d-a0f8-c7fe0ec1ac45	08480520-7787-45e4-afbd-db51aff36d80	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
64b06930-ec9f-4d47-8a0b-ac5f7435f5d9	12b57849-fa7e-42ed-8fb7-cb5004a3ec2d	DECLARE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
3d59fcbd-436b-4a8d-8bab-cc478f958b0a	2c9fe26c-95eb-4b84-80eb-93bc10b3d187	TRANSFORME	VALIDE	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
7b79a63e-24cf-47aa-ba6d-42dff87d3d35	eb80791e-3f0c-4ba9-a30b-c0176a9c2aec	EN_TRANSIT	VALIDE	MIGRATION	\N	\N	Passage au cycle à trois statuts (brouillon, validé, commercialisé).	2026-10-03 13:53:59.538256+02
7f495131-5225-4520-9234-0b69f1a06527	b76576f5-5a0c-4adc-941d-8f5d584033e7	ANNULE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts : lot annulé ou archivé retiré des listes.	2026-10-03 13:53:59.538256+02
f77b3f4b-db47-4b0f-b643-fea0f7ac3a7d	67381035-8c17-475b-a555-6a929aca6db1	ARCHIVE	BROUILLON	MIGRATION	\N	\N	Passage au cycle à trois statuts : lot annulé ou archivé retiré des listes.	2026-10-03 13:53:59.538256+02
\.


--
-- TOC entry 6994 (class 0 OID 86688)
-- Dependencies: 285
-- Data for Name: message_pieces; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.message_pieces (message_id, piece_type, piece_path) FROM stdin;
\.


--
-- TOC entry 7012 (class 0 OID 87067)
-- Dependencies: 303
-- Data for Name: moderation_images; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.moderation_images (id, chemin, type_objet, objet_id, envoye_par_id, verdict, score_nsfw, scores, statut, motif, traite_par_id, traite_at, created_at) FROM stdin;
\.


--
-- TOC entry 7006 (class 0 OID 86952)
-- Dependencies: 297
-- Data for Name: offres_details; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.offres_details (offre_id, categorie_id, prix_total, negociable, conditionnement, qualite, localite, disponible_du, mode_remise, modalites_livraison, moyens_paiement, conditions_paiement, afficher_telephone, afficher_email, updated_at) FROM stdin;
\.


--
-- TOC entry 7007 (class 0 OID 86983)
-- Dependencies: 298
-- Data for Name: offres_moderation; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.offres_moderation (offre_id, decision, moderateur_id, moderateur_nom, motif, decide_at) FROM stdin;
1e5154fd-a8a7-4ca2-9e57-610654f1f521	VALIDEE	70dd1a0a-1111-47f4-9a12-efd092fbc67a	Administrateur Démo MOUKAGNI	\N	2026-10-02 12:06:24.799502+02
2378a2d4-443f-450f-b63b-a63c6789c82a	VALIDEE	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Aline NZIENGUI	\N	2026-10-02 12:06:24.799502+02
34d135f3-82bd-46fa-8817-c7a9bc40e62f	VALIDEE	70dd1a0a-1111-47f4-9a12-efd092fbc67a	Administrateur Démo MOUKAGNI	\N	2026-10-02 12:06:24.799502+02
efd1c8b5-a4ee-4d50-af79-e5124c71a23a	REJETEE	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Aline NZIENGUI	\N	2026-10-02 12:06:24.799502+02
f8cbdbeb-f57c-497e-baa1-3610a8e939ee	VALIDEE	69e41ae7-ff35-4ef0-bb3f-77d067d299ad	Aline NZIENGUI	\N	2026-10-02 12:06:24.799502+02
\.


--
-- TOC entry 6992 (class 0 OID 78480)
-- Dependencies: 283
-- Data for Name: offres_statut_workflow; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.offres_statut_workflow (offre_id, statut, updated_at) FROM stdin;
74645428-6803-4c56-b9d2-e1a16581b664	OUVERTE	2026-08-19 12:40:20.021178+02
c51aae46-6707-41a7-8253-ac358b5e52d4	CLOTUREE	2026-08-19 12:49:34.291724+02
85259450-734c-47fd-baf8-5343185b1282	OUVERTE	2026-08-19 13:09:49.121534+02
88a16c5c-f976-478d-9522-68e85310cefa	OUVERTE	2026-08-19 13:10:31.70883+02
d9f23389-ccb8-467f-99ab-f7595fdbea73	CLOTUREE	2026-08-21 19:03:42.807973+02
b0350371-7264-4096-a2ba-03e7bcd9a384	OUVERTE	2026-09-23 11:44:52.020568+02
d41cc54f-ed02-46d8-b259-2dc8ed763527	EN_VALIDATION	2026-10-02 12:06:42.88139+02
ac5f5311-20f7-4b40-a159-52c28402e13f	EN_VALIDATION	2026-10-02 12:06:43.543642+02
2378a2d4-443f-450f-b63b-a63c6789c82a	OUVERTE	2026-10-02 12:06:43.794229+02
34d135f3-82bd-46fa-8817-c7a9bc40e62f	OUVERTE	2026-10-02 12:06:43.90164+02
f8cbdbeb-f57c-497e-baa1-3610a8e939ee	OUVERTE	2026-10-02 12:06:44.019697+02
efd1c8b5-a4ee-4d50-af79-e5124c71a23a	REJETEE	2026-10-02 12:06:44.085146+02
1e5154fd-a8a7-4ca2-9e57-610654f1f521	CLOTUREE	2026-10-02 12:06:44.291862+02
\.


--
-- TOC entry 7002 (class 0 OID 86854)
-- Dependencies: 293
-- Data for Name: pnlf_evolutions; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.pnlf_evolutions (nom, appliquee_le) FROM stdin;
14_invitations_cooperatives.sql	2026-10-03 13:53:12.374834+02
16_annonces_statistiques.sql	2026-10-03 13:58:29.27165+02
15_lots_cycle_certifications.sql	2026-10-03 13:59:40.789599+02
17_moderation_images.sql	2026-10-03 14:08:35.798944+02
18_connexions_blocage_ip.sql	2026-10-06 13:45:50.636679+02
\.


--
-- TOC entry 7010 (class 0 OID 87027)
-- Dependencies: 301
-- Data for Name: presences; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.presences (utilisateur_id, empreinte_appareil, appareil, systeme, navigateur, ip_adresse, debut_at, derniere_activite) FROM stdin;
2992fb5e-5580-483b-9462-98fe46cf7627	c4ea766a755ddee08f488270809d5745	ORDINATEUR	Windows	Chrome	127.0.0.1	2026-10-06 13:57:23.774197+02	2026-10-06 14:01:24.13498+02
\.


--
-- TOC entry 6255 (class 0 OID 68162)
-- Dependencies: 227
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 6998 (class 0 OID 86752)
-- Dependencies: 289
-- Data for Name: token_blacklist_blacklistedtoken; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.token_blacklist_blacklistedtoken (id, blacklisted_at, token_id) FROM stdin;
\.


--
-- TOC entry 7000 (class 0 OID 86760)
-- Dependencies: 291
-- Data for Name: token_blacklist_outstandingtoken; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.token_blacklist_outstandingtoken (id, token, created_at, expires_at, user_id, jti) FROM stdin;
\.


--
-- TOC entry 7011 (class 0 OID 87048)
-- Dependencies: 302
-- Data for Name: visites_publiques; Type: TABLE DATA; Schema: public; Owner: pnlf_app
--

COPY public.visites_publiques (jour, page, appareil, visites) FROM stdin;
2026-10-03	/annuaire	ORDINATEUR	1
2026-10-03	/verifier	ORDINATEUR	1
2026-10-03	/inscription	ORDINATEUR	1
2026-10-03	/faq	ORDINATEUR	1
2026-10-03	/autre	ORDINATEUR	4
2026-10-03	/	ORDINATEUR	3
2026-10-03	/connexion	ORDINATEUR	1
2026-10-03	/verifier/:id	ORDINATEUR	2
2026-10-06	/annuaire/:id	ORDINATEUR	1
2026-10-06	/verifier	ORDINATEUR	1
2026-10-06	/inscription	ORDINATEUR	1
2026-10-06	/connexion	ORDINATEUR	1
2026-10-06	/autre	ORDINATEUR	2
2026-10-06	/annuaire	ORDINATEUR	13
2026-10-06	/verifier/:id	ORDINATEUR	2
2026-10-06	/	ORDINATEUR	15
2026-10-08	/	ORDINATEUR	1
\.


--
-- TOC entry 7072 (class 0 OID 0)
-- Dependencies: 253
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: pnlf; Owner: postgres
--

SELECT pg_catalog.setval('pnlf.audit_logs_id_seq', 3883, true);


--
-- TOC entry 7073 (class 0 OID 0)
-- Dependencies: 266
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);


--
-- TOC entry 7074 (class 0 OID 0)
-- Dependencies: 268
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);


--
-- TOC entry 7075 (class 0 OID 0)
-- Dependencies: 264
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 72, true);


--
-- TOC entry 7076 (class 0 OID 0)
-- Dependencies: 272
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- TOC entry 7077 (class 0 OID 0)
-- Dependencies: 270
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, false);


--
-- TOC entry 7078 (class 0 OID 0)
-- Dependencies: 274
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- TOC entry 7079 (class 0 OID 0)
-- Dependencies: 299
-- Name: connexions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.connexions_id_seq', 1371, true);


--
-- TOC entry 7080 (class 0 OID 0)
-- Dependencies: 276
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- TOC entry 7081 (class 0 OID 0)
-- Dependencies: 262
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 18, true);


--
-- TOC entry 7082 (class 0 OID 0)
-- Dependencies: 260
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 30, true);


--
-- TOC entry 7083 (class 0 OID 0)
-- Dependencies: 288
-- Name: token_blacklist_blacklistedtoken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.token_blacklist_blacklistedtoken_id_seq', 1, false);


--
-- TOC entry 7084 (class 0 OID 0)
-- Dependencies: 290
-- Name: token_blacklist_outstandingtoken_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pnlf_app
--

SELECT pg_catalog.setval('public.token_blacklist_outstandingtoken_id_seq', 1, false);


--
-- TOC entry 6573 (class 2606 OID 70016)
-- Name: appareils_sync appareils_sync_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.appareils_sync
    ADD CONSTRAINT appareils_sync_pkey PRIMARY KEY (id);


--
-- TOC entry 6569 (class 2606 OID 69993)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 6500 (class 2606 OID 69573)
-- Name: categories_produit categories_produit_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.categories_produit
    ADD CONSTRAINT categories_produit_pkey PRIMARY KEY (id);


--
-- TOC entry 6547 (class 2606 OID 69832)
-- Name: certifications certifications_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.certifications
    ADD CONSTRAINT certifications_pkey PRIMARY KEY (id);


--
-- TOC entry 6560 (class 2606 OID 69918)
-- Name: conversation_participants conversation_participants_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.conversation_participants
    ADD CONSTRAINT conversation_participants_pkey PRIMARY KEY (conversation_id, utilisateur_id);


--
-- TOC entry 6558 (class 2606 OID 69904)
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 6498 (class 2606 OID 69546)
-- Name: cooperative_membres cooperative_membres_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperative_membres
    ADD CONSTRAINT cooperative_membres_pkey PRIMARY KEY (cooperative_id, producteur_id);


--
-- TOC entry 6476 (class 2606 OID 69442)
-- Name: cooperatives cooperatives_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT cooperatives_pkey PRIMARY KEY (id);


--
-- TOC entry 6450 (class 2606 OID 69306)
-- Name: departements departements_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.departements
    ADD CONSTRAINT departements_pkey PRIMARY KEY (id);


--
-- TOC entry 6527 (class 2606 OID 69700)
-- Name: lots lots_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_pkey PRIMARY KEY (id);


--
-- TOC entry 6564 (class 2606 OID 69943)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 6629 (class 2606 OID 70325)
-- Name: messages_publics messages_publics_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.messages_publics
    ADD CONSTRAINT messages_publics_pkey PRIMARY KEY (id);


--
-- TOC entry 6539 (class 2606 OID 69765)
-- Name: mouvements mouvements_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT mouvements_pkey PRIMARY KEY (id);


--
-- TOC entry 6567 (class 2606 OID 69974)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 6555 (class 2606 OID 69879)
-- Name: offres_demandes offres_demandes_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.offres_demandes
    ADD CONSTRAINT offres_demandes_pkey PRIMARY KEY (id);


--
-- TOC entry 6514 (class 2606 OID 69627)
-- Name: producteur_produits producteur_produits_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteur_produits
    ADD CONSTRAINT producteur_produits_pkey PRIMARY KEY (producteur_id, produit_id);


--
-- TOC entry 6490 (class 2606 OID 69493)
-- Name: producteurs producteurs_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_pkey PRIMARY KEY (id);


--
-- TOC entry 6508 (class 2606 OID 69605)
-- Name: produits produits_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.produits
    ADD CONSTRAINT produits_pkey PRIMARY KEY (id);


--
-- TOC entry 6444 (class 2606 OID 69284)
-- Name: provinces provinces_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.provinces
    ADD CONSTRAINT provinces_pkey PRIMARY KEY (id);


--
-- TOC entry 6472 (class 2606 OID 69416)
-- Name: reinitialisations_mdp reinitialisations_mdp_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.reinitialisations_mdp
    ADD CONSTRAINT reinitialisations_mdp_pkey PRIMARY KEY (id);


--
-- TOC entry 6468 (class 2606 OID 69394)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 6578 (class 2606 OID 70039)
-- Name: sync_conflicts sync_conflicts_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.sync_conflicts
    ADD CONSTRAINT sync_conflicts_pkey PRIMARY KEY (id);


--
-- TOC entry 6543 (class 2606 OID 69809)
-- Name: types_certification types_certification_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.types_certification
    ADD CONSTRAINT types_certification_pkey PRIMARY KEY (id);


--
-- TOC entry 6575 (class 2606 OID 70018)
-- Name: appareils_sync uq_appareils_device; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.appareils_sync
    ADD CONSTRAINT uq_appareils_device UNIQUE (utilisateur_id, device_id);


--
-- TOC entry 6502 (class 2606 OID 69575)
-- Name: categories_produit uq_categories_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.categories_produit
    ADD CONSTRAINT uq_categories_code UNIQUE (code);


--
-- TOC entry 6504 (class 2606 OID 69577)
-- Name: categories_produit uq_categories_libelle; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.categories_produit
    ADD CONSTRAINT uq_categories_libelle UNIQUE (libelle);


--
-- TOC entry 6480 (class 2606 OID 69444)
-- Name: cooperatives uq_cooperatives_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT uq_cooperatives_code UNIQUE (code);


--
-- TOC entry 6482 (class 2606 OID 69446)
-- Name: cooperatives uq_cooperatives_nom; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT uq_cooperatives_nom UNIQUE (nom);


--
-- TOC entry 6452 (class 2606 OID 69308)
-- Name: departements uq_departements_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.departements
    ADD CONSTRAINT uq_departements_code UNIQUE (code);


--
-- TOC entry 6454 (class 2606 OID 69310)
-- Name: departements uq_departements_nom_province; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.departements
    ADD CONSTRAINT uq_departements_nom_province UNIQUE (province_id, nom);


--
-- TOC entry 6529 (class 2606 OID 69706)
-- Name: lots uq_lots_client_uuid; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT uq_lots_client_uuid UNIQUE (client_uuid);


--
-- TOC entry 6531 (class 2606 OID 69702)
-- Name: lots uq_lots_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT uq_lots_code UNIQUE (code_lot);


--
-- TOC entry 6533 (class 2606 OID 69704)
-- Name: lots uq_lots_uuid_public; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT uq_lots_uuid_public UNIQUE (uuid_public);


--
-- TOC entry 6541 (class 2606 OID 69767)
-- Name: mouvements uq_mouvements_client_uuid; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT uq_mouvements_client_uuid UNIQUE (client_uuid);


--
-- TOC entry 6492 (class 2606 OID 69499)
-- Name: producteurs uq_producteurs_client_uuid; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT uq_producteurs_client_uuid UNIQUE (client_uuid);


--
-- TOC entry 6494 (class 2606 OID 69495)
-- Name: producteurs uq_producteurs_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT uq_producteurs_code UNIQUE (code_producteur);


--
-- TOC entry 6496 (class 2606 OID 69497)
-- Name: producteurs uq_producteurs_piece; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT uq_producteurs_piece UNIQUE (type_piece_identite, numero_piece);


--
-- TOC entry 6510 (class 2606 OID 69607)
-- Name: produits uq_produits_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.produits
    ADD CONSTRAINT uq_produits_code UNIQUE (code);


--
-- TOC entry 6512 (class 2606 OID 69609)
-- Name: produits uq_produits_nom; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.produits
    ADD CONSTRAINT uq_produits_nom UNIQUE (nom);


--
-- TOC entry 6446 (class 2606 OID 69286)
-- Name: provinces uq_provinces_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.provinces
    ADD CONSTRAINT uq_provinces_code UNIQUE (code);


--
-- TOC entry 6448 (class 2606 OID 69288)
-- Name: provinces uq_provinces_nom; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.provinces
    ADD CONSTRAINT uq_provinces_nom UNIQUE (nom);


--
-- TOC entry 6474 (class 2606 OID 69418)
-- Name: reinitialisations_mdp uq_reset_token; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.reinitialisations_mdp
    ADD CONSTRAINT uq_reset_token UNIQUE (token_hash);


--
-- TOC entry 6470 (class 2606 OID 69396)
-- Name: sessions uq_sessions_jti; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.sessions
    ADD CONSTRAINT uq_sessions_jti UNIQUE (jti);


--
-- TOC entry 6545 (class 2606 OID 69811)
-- Name: types_certification uq_types_cert_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.types_certification
    ADD CONSTRAINT uq_types_cert_code UNIQUE (code);


--
-- TOC entry 6463 (class 2606 OID 69377)
-- Name: utilisateurs uq_utilisateurs_email; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.utilisateurs
    ADD CONSTRAINT uq_utilisateurs_email UNIQUE (email);


--
-- TOC entry 6457 (class 2606 OID 69336)
-- Name: villages uq_villages_nom_dept; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.villages
    ADD CONSTRAINT uq_villages_nom_dept UNIQUE (departement_id, nom);


--
-- TOC entry 6517 (class 2606 OID 69659)
-- Name: zones_collecte uq_zones_code; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.zones_collecte
    ADD CONSTRAINT uq_zones_code UNIQUE (code);


--
-- TOC entry 6465 (class 2606 OID 69375)
-- Name: utilisateurs utilisateurs_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.utilisateurs
    ADD CONSTRAINT utilisateurs_pkey PRIMARY KEY (id);


--
-- TOC entry 6459 (class 2606 OID 69334)
-- Name: villages villages_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.villages
    ADD CONSTRAINT villages_pkey PRIMARY KEY (id);


--
-- TOC entry 6519 (class 2606 OID 69657)
-- Name: zones_collecte zones_collecte_pkey; Type: CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.zones_collecte
    ADD CONSTRAINT zones_collecte_pkey PRIMARY KEY (id);


--
-- TOC entry 6656 (class 2606 OID 86845)
-- Name: _data_ops _data_ops_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public._data_ops
    ADD CONSTRAINT _data_ops_pkey PRIMARY KEY (op_key);


--
-- TOC entry 6592 (class 2606 OID 70265)
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- TOC entry 6597 (class 2606 OID 70186)
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- TOC entry 6600 (class 2606 OID 70138)
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6594 (class 2606 OID 70127)
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 6587 (class 2606 OID 70177)
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- TOC entry 6589 (class 2606 OID 70119)
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 6608 (class 2606 OID 70166)
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 6611 (class 2606 OID 70201)
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- TOC entry 6602 (class 2606 OID 70155)
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- TOC entry 6614 (class 2606 OID 70175)
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 6617 (class 2606 OID 70215)
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- TOC entry 6605 (class 2606 OID 70258)
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- TOC entry 6668 (class 2606 OID 86940)
-- Name: certifications_pieces certifications_pieces_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.certifications_pieces
    ADD CONSTRAINT certifications_pieces_pkey PRIMARY KEY (id);


--
-- TOC entry 6676 (class 2606 OID 87019)
-- Name: connexions connexions_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.connexions
    ADD CONSTRAINT connexions_pkey PRIMARY KEY (id);


--
-- TOC entry 6633 (class 2606 OID 86670)
-- Name: conversation_context conversation_context_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_context
    ADD CONSTRAINT conversation_context_pkey PRIMARY KEY (conversation_id);


--
-- TOC entry 6640 (class 2606 OID 86708)
-- Name: conversation_participant_meta conversation_participant_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_participant_meta
    ADD CONSTRAINT conversation_participant_meta_pkey PRIMARY KEY (conversation_id, utilisateur_id);


--
-- TOC entry 6620 (class 2606 OID 70242)
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- TOC entry 6582 (class 2606 OID 70109)
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- TOC entry 6584 (class 2606 OID 70107)
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 6580 (class 2606 OID 70097)
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 6624 (class 2606 OID 70278)
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- TOC entry 6643 (class 2606 OID 86744)
-- Name: documents_inscription documents_inscription_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.documents_inscription
    ADD CONSTRAINT documents_inscription_pkey PRIMARY KEY (id);


--
-- TOC entry 6662 (class 2606 OID 86876)
-- Name: invitations_cooperative invitations_cooperative_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.invitations_cooperative
    ADD CONSTRAINT invitations_cooperative_pkey PRIMARY KEY (id);


--
-- TOC entry 6666 (class 2606 OID 86914)
-- Name: lots_transitions lots_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.lots_transitions
    ADD CONSTRAINT lots_transitions_pkey PRIMARY KEY (id);


--
-- TOC entry 6638 (class 2606 OID 86696)
-- Name: message_pieces message_pieces_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.message_pieces
    ADD CONSTRAINT message_pieces_pkey PRIMARY KEY (message_id);


--
-- TOC entry 6688 (class 2606 OID 87089)
-- Name: moderation_images moderation_images_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.moderation_images
    ADD CONSTRAINT moderation_images_pkey PRIMARY KEY (id);


--
-- TOC entry 6672 (class 2606 OID 86971)
-- Name: offres_details offres_details_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_details
    ADD CONSTRAINT offres_details_pkey PRIMARY KEY (offre_id);


--
-- TOC entry 6674 (class 2606 OID 86994)
-- Name: offres_moderation offres_moderation_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_moderation
    ADD CONSTRAINT offres_moderation_pkey PRIMARY KEY (offre_id);


--
-- TOC entry 6631 (class 2606 OID 78488)
-- Name: offres_statut_workflow offres_statut_workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_statut_workflow
    ADD CONSTRAINT offres_statut_workflow_pkey PRIMARY KEY (offre_id);


--
-- TOC entry 6658 (class 2606 OID 86861)
-- Name: pnlf_evolutions pnlf_evolutions_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.pnlf_evolutions
    ADD CONSTRAINT pnlf_evolutions_pkey PRIMARY KEY (nom);


--
-- TOC entry 6682 (class 2606 OID 87041)
-- Name: presences presences_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.presences
    ADD CONSTRAINT presences_pkey PRIMARY KEY (utilisateur_id, empreinte_appareil);


--
-- TOC entry 6646 (class 2606 OID 86800)
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_pkey PRIMARY KEY (id);


--
-- TOC entry 6648 (class 2606 OID 86823)
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_token_id_key; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_token_id_key UNIQUE (token_id);


--
-- TOC entry 6651 (class 2606 OID 86791)
-- Name: token_blacklist_outstandingtoken token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_uniq; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_uniq UNIQUE (jti);


--
-- TOC entry 6653 (class 2606 OID 86810)
-- Name: token_blacklist_outstandingtoken token_blacklist_outstandingtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outstandingtoken_pkey PRIMARY KEY (id);


--
-- TOC entry 6684 (class 2606 OID 87057)
-- Name: visites_publiques visites_publiques_pkey; Type: CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.visites_publiques
    ADD CONSTRAINT visites_publiques_pkey PRIMARY KEY (jour, page, appareil);


--
-- TOC entry 6570 (class 1259 OID 70000)
-- Name: idx_audit_table; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_audit_table ON pnlf.audit_logs USING btree (table_cible, created_at DESC);


--
-- TOC entry 6571 (class 1259 OID 69999)
-- Name: idx_audit_user; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_audit_user ON pnlf.audit_logs USING btree (utilisateur_id, created_at DESC);


--
-- TOC entry 6548 (class 1259 OID 69853)
-- Name: idx_certifications_lot; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_certifications_lot ON pnlf.certifications USING btree (lot_id);


--
-- TOC entry 6549 (class 1259 OID 69854)
-- Name: idx_certifications_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_certifications_statut ON pnlf.certifications USING btree (statut);


--
-- TOC entry 6477 (class 1259 OID 69467)
-- Name: idx_cooperatives_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_cooperatives_geom ON pnlf.cooperatives USING gist (geom);


--
-- TOC entry 6478 (class 1259 OID 78478)
-- Name: idx_cooperatives_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_cooperatives_statut ON pnlf.cooperatives USING btree (statut);


--
-- TOC entry 6520 (class 1259 OID 69740)
-- Name: idx_lots_date; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_date ON pnlf.lots USING btree (date_collecte DESC);


--
-- TOC entry 6521 (class 1259 OID 69741)
-- Name: idx_lots_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_geom ON pnlf.lots USING gist (geom);


--
-- TOC entry 6522 (class 1259 OID 69738)
-- Name: idx_lots_producteur; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_producteur ON pnlf.lots USING btree (producteur_id);


--
-- TOC entry 6523 (class 1259 OID 69737)
-- Name: idx_lots_produit; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_produit ON pnlf.lots USING btree (produit_id);


--
-- TOC entry 6524 (class 1259 OID 69739)
-- Name: idx_lots_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_statut ON pnlf.lots USING btree (statut) WHERE (deleted_at IS NULL);


--
-- TOC entry 6525 (class 1259 OID 70289)
-- Name: idx_lots_statut_date; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_lots_statut_date ON pnlf.lots USING btree (statut, date_collecte DESC) WHERE (deleted_at IS NULL);


--
-- TOC entry 6561 (class 1259 OID 69954)
-- Name: idx_messages_conv; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_messages_conv ON pnlf.messages USING btree (conversation_id, created_at);


--
-- TOC entry 6562 (class 1259 OID 70288)
-- Name: idx_messages_expediteur; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_messages_expediteur ON pnlf.messages USING btree (expediteur_id, created_at DESC);


--
-- TOC entry 6626 (class 1259 OID 70332)
-- Name: idx_messages_publics_producteur; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_messages_publics_producteur ON pnlf.messages_publics USING btree (producteur_id, created_at DESC);


--
-- TOC entry 6627 (class 1259 OID 70333)
-- Name: idx_messages_publics_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_messages_publics_statut ON pnlf.messages_publics USING btree (statut, created_at DESC);


--
-- TOC entry 6534 (class 1259 OID 69790)
-- Name: idx_mouvements_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_mouvements_geom ON pnlf.mouvements USING gist (geom);


--
-- TOC entry 6535 (class 1259 OID 69788)
-- Name: idx_mouvements_lot; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_mouvements_lot ON pnlf.mouvements USING btree (lot_id, date_mouvement);


--
-- TOC entry 6536 (class 1259 OID 69789)
-- Name: idx_mouvements_type; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_mouvements_type ON pnlf.mouvements USING btree (type_mouvement);


--
-- TOC entry 6537 (class 1259 OID 70290)
-- Name: idx_mouvements_type_date; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_mouvements_type_date ON pnlf.mouvements USING btree (type_mouvement, date_mouvement DESC);


--
-- TOC entry 6565 (class 1259 OID 69980)
-- Name: idx_notifications_dest; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_notifications_dest ON pnlf.notifications USING btree (destinataire_id, lue, created_at DESC);


--
-- TOC entry 6550 (class 1259 OID 69895)
-- Name: idx_od_produit; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_od_produit ON pnlf.offres_demandes USING btree (produit_id, type_annonce, statut);


--
-- TOC entry 6551 (class 1259 OID 70287)
-- Name: idx_offres_demandes_auteur; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_offres_demandes_auteur ON pnlf.offres_demandes USING btree (auteur_id, statut);


--
-- TOC entry 6552 (class 1259 OID 70286)
-- Name: idx_offres_demandes_province; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_offres_demandes_province ON pnlf.offres_demandes USING btree (province_id, statut, type_annonce);


--
-- TOC entry 6553 (class 1259 OID 78498)
-- Name: idx_offres_demandes_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_offres_demandes_statut ON pnlf.offres_demandes USING btree (statut);


--
-- TOC entry 6483 (class 1259 OID 69531)
-- Name: idx_producteurs_coop; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_coop ON pnlf.producteurs USING btree (cooperative_id);


--
-- TOC entry 6484 (class 1259 OID 69532)
-- Name: idx_producteurs_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_geom ON pnlf.producteurs USING gist (geom);


--
-- TOC entry 6485 (class 1259 OID 69533)
-- Name: idx_producteurs_nom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_nom ON pnlf.producteurs USING gin (((((nom)::text || ' '::text) || (prenoms)::text)) public.gin_trgm_ops);


--
-- TOC entry 6486 (class 1259 OID 69530)
-- Name: idx_producteurs_province; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_province ON pnlf.producteurs USING btree (province_id);


--
-- TOC entry 6487 (class 1259 OID 70285)
-- Name: idx_producteurs_type_acteur; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_type_acteur ON pnlf.producteurs USING btree (type_acteur) WHERE (deleted_at IS NULL);


--
-- TOC entry 6488 (class 1259 OID 70334)
-- Name: idx_producteurs_visible_public; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_producteurs_visible_public ON pnlf.producteurs USING btree (statut, visible_public) WHERE (deleted_at IS NULL);


--
-- TOC entry 6505 (class 1259 OID 69615)
-- Name: idx_produits_categorie; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_produits_categorie ON pnlf.produits USING btree (categorie_id);


--
-- TOC entry 6506 (class 1259 OID 69616)
-- Name: idx_produits_nom_trgm; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_produits_nom_trgm ON pnlf.produits USING gin (nom public.gin_trgm_ops);


--
-- TOC entry 6442 (class 1259 OID 69343)
-- Name: idx_provinces_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_provinces_geom ON pnlf.provinces USING gist (geom);


--
-- TOC entry 6466 (class 1259 OID 69402)
-- Name: idx_sessions_user; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_sessions_user ON pnlf.sessions USING btree (utilisateur_id) WHERE (revoquee_at IS NULL);


--
-- TOC entry 6576 (class 1259 OID 70045)
-- Name: idx_sync_conflicts_ouverts; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_sync_conflicts_ouverts ON pnlf.sync_conflicts USING btree (resolu, created_at) WHERE (resolu = false);


--
-- TOC entry 6460 (class 1259 OID 69378)
-- Name: idx_utilisateurs_role; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_utilisateurs_role ON pnlf.utilisateurs USING btree (role) WHERE (deleted_at IS NULL);


--
-- TOC entry 6461 (class 1259 OID 69379)
-- Name: idx_utilisateurs_statut; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_utilisateurs_statut ON pnlf.utilisateurs USING btree (statut) WHERE (deleted_at IS NULL);


--
-- TOC entry 6455 (class 1259 OID 69342)
-- Name: idx_villages_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_villages_geom ON pnlf.villages USING gist (geom);


--
-- TOC entry 6515 (class 1259 OID 69665)
-- Name: idx_zones_geom; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE INDEX idx_zones_geom ON pnlf.zones_collecte USING gist (geom);


--
-- TOC entry 6556 (class 1259 OID 78497)
-- Name: uq_offres_demandes_uuid_public; Type: INDEX; Schema: pnlf; Owner: postgres
--

CREATE UNIQUE INDEX uq_offres_demandes_uuid_public ON pnlf.offres_demandes USING btree (uuid_public) WHERE (uuid_public IS NOT NULL);


--
-- TOC entry 6590 (class 1259 OID 70266)
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- TOC entry 6595 (class 1259 OID 70197)
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- TOC entry 6598 (class 1259 OID 70198)
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- TOC entry 6585 (class 1259 OID 70183)
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- TOC entry 6606 (class 1259 OID 70213)
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- TOC entry 6609 (class 1259 OID 70212)
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- TOC entry 6612 (class 1259 OID 70227)
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- TOC entry 6615 (class 1259 OID 70226)
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- TOC entry 6603 (class 1259 OID 70259)
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- TOC entry 6618 (class 1259 OID 70253)
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- TOC entry 6621 (class 1259 OID 70254)
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- TOC entry 6622 (class 1259 OID 70280)
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- TOC entry 6625 (class 1259 OID 70279)
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- TOC entry 6669 (class 1259 OID 86951)
-- Name: idx_certifications_pieces_cert; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_certifications_pieces_cert ON public.certifications_pieces USING btree (certification_id, created_at);


--
-- TOC entry 6677 (class 1259 OID 87025)
-- Name: idx_connexions_created_at; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_connexions_created_at ON public.connexions USING btree (created_at DESC);


--
-- TOC entry 6678 (class 1259 OID 87531)
-- Name: idx_connexions_ip; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_connexions_ip ON public.connexions USING btree (ip_adresse, created_at DESC);


--
-- TOC entry 6679 (class 1259 OID 87026)
-- Name: idx_connexions_utilisateur; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_connexions_utilisateur ON public.connexions USING btree (utilisateur_id, created_at DESC);


--
-- TOC entry 6634 (class 1259 OID 86687)
-- Name: idx_conversation_context_cooperative; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_conversation_context_cooperative ON public.conversation_context USING btree (cooperative_id) WHERE (cooperative_id IS NOT NULL);


--
-- TOC entry 6635 (class 1259 OID 86722)
-- Name: idx_conversation_context_groupe; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_conversation_context_groupe ON public.conversation_context USING btree (cooperative_id) WHERE (est_groupe = true);


--
-- TOC entry 6636 (class 1259 OID 86686)
-- Name: idx_conversation_context_producteur; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_conversation_context_producteur ON public.conversation_context USING btree (producteur_id) WHERE (producteur_id IS NOT NULL);


--
-- TOC entry 6641 (class 1259 OID 86719)
-- Name: idx_cpm_user_active; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_cpm_user_active ON public.conversation_participant_meta USING btree (utilisateur_id) WHERE (deleted_at IS NULL);


--
-- TOC entry 6644 (class 1259 OID 86750)
-- Name: idx_documents_inscription_entite; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_documents_inscription_entite ON public.documents_inscription USING btree (entite_type, entite_id);


--
-- TOC entry 6659 (class 1259 OID 86899)
-- Name: idx_invitation_coop_cooperative; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_invitation_coop_cooperative ON public.invitations_cooperative USING btree (cooperative_id, statut, created_at DESC);


--
-- TOC entry 6660 (class 1259 OID 86898)
-- Name: idx_invitation_coop_producteur; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_invitation_coop_producteur ON public.invitations_cooperative USING btree (producteur_id, statut);


--
-- TOC entry 6664 (class 1259 OID 86925)
-- Name: idx_lots_transitions_lot; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_lots_transitions_lot ON public.lots_transitions USING btree (lot_id, created_at);


--
-- TOC entry 6685 (class 1259 OID 87100)
-- Name: idx_moderation_images_en_attente; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_moderation_images_en_attente ON public.moderation_images USING btree (chemin) WHERE ((statut)::text = 'EN_ATTENTE'::text);


--
-- TOC entry 6686 (class 1259 OID 87101)
-- Name: idx_moderation_images_statut; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_moderation_images_statut ON public.moderation_images USING btree (statut, created_at DESC);


--
-- TOC entry 6670 (class 1259 OID 86982)
-- Name: idx_offres_details_categorie; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_offres_details_categorie ON public.offres_details USING btree (categorie_id);


--
-- TOC entry 6680 (class 1259 OID 87047)
-- Name: idx_presences_activite; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX idx_presences_activite ON public.presences USING btree (derniere_activite DESC);


--
-- TOC entry 6649 (class 1259 OID 86792)
-- Name: token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_like; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX token_blacklist_outstandingtoken_jti_hex_d9bdf6f7_like ON public.token_blacklist_outstandingtoken USING btree (jti varchar_pattern_ops);


--
-- TOC entry 6654 (class 1259 OID 86788)
-- Name: token_blacklist_outstandingtoken_user_id_83bc629a; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE INDEX token_blacklist_outstandingtoken_user_id_83bc629a ON public.token_blacklist_outstandingtoken USING btree (user_id);


--
-- TOC entry 6663 (class 1259 OID 86897)
-- Name: uq_invitation_coop_en_attente; Type: INDEX; Schema: public; Owner: pnlf_app
--

CREATE UNIQUE INDEX uq_invitation_coop_en_attente ON public.invitations_cooperative USING btree (cooperative_id, producteur_id) WHERE ((statut)::text = 'EN_ATTENTE'::text);


--
-- TOC entry 6786 (class 2620 OID 70003)
-- Name: audit_logs trg_audit_immutable_del; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_audit_immutable_del BEFORE DELETE ON pnlf.audit_logs FOR EACH ROW EXECUTE FUNCTION pnlf.interdire_modif_audit();


--
-- TOC entry 6787 (class 2620 OID 70002)
-- Name: audit_logs trg_audit_immutable_upd; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_audit_immutable_upd BEFORE UPDATE ON pnlf.audit_logs FOR EACH ROW EXECUTE FUNCTION pnlf.interdire_modif_audit();


--
-- TOC entry 6777 (class 2620 OID 70052)
-- Name: categories_produit trg_categories_produit_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_categories_produit_updated_at BEFORE UPDATE ON pnlf.categories_produit FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6784 (class 2620 OID 70056)
-- Name: certifications trg_certifications_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_certifications_updated_at BEFORE UPDATE ON pnlf.certifications FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6775 (class 2620 OID 70050)
-- Name: cooperatives trg_cooperatives_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_cooperatives_updated_at BEFORE UPDATE ON pnlf.cooperatives FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6772 (class 2620 OID 70047)
-- Name: departements trg_departements_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_departements_updated_at BEFORE UPDATE ON pnlf.departements FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6780 (class 2620 OID 69742)
-- Name: lots trg_lots_code; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_lots_code BEFORE INSERT ON pnlf.lots FOR EACH ROW EXECUTE FUNCTION pnlf.generer_code_lot();


--
-- TOC entry 6781 (class 2620 OID 70055)
-- Name: lots trg_lots_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_lots_updated_at BEFORE UPDATE ON pnlf.lots FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6782 (class 2620 OID 69793)
-- Name: mouvements trg_mouvements_immutable_del; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_mouvements_immutable_del BEFORE DELETE ON pnlf.mouvements FOR EACH ROW EXECUTE FUNCTION pnlf.interdire_modif_mouvement();


--
-- TOC entry 6783 (class 2620 OID 69792)
-- Name: mouvements trg_mouvements_immutable_upd; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_mouvements_immutable_upd BEFORE UPDATE ON pnlf.mouvements FOR EACH ROW EXECUTE FUNCTION pnlf.interdire_modif_mouvement();


--
-- TOC entry 6785 (class 2620 OID 70057)
-- Name: offres_demandes trg_offres_demandes_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_offres_demandes_updated_at BEFORE UPDATE ON pnlf.offres_demandes FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6776 (class 2620 OID 70051)
-- Name: producteurs trg_producteurs_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_producteurs_updated_at BEFORE UPDATE ON pnlf.producteurs FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6778 (class 2620 OID 70053)
-- Name: produits trg_produits_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_produits_updated_at BEFORE UPDATE ON pnlf.produits FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6771 (class 2620 OID 70046)
-- Name: provinces trg_provinces_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_provinces_updated_at BEFORE UPDATE ON pnlf.provinces FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6774 (class 2620 OID 70049)
-- Name: utilisateurs trg_utilisateurs_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_utilisateurs_updated_at BEFORE UPDATE ON pnlf.utilisateurs FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6773 (class 2620 OID 70048)
-- Name: villages trg_villages_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_villages_updated_at BEFORE UPDATE ON pnlf.villages FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6779 (class 2620 OID 70054)
-- Name: zones_collecte trg_zones_collecte_updated_at; Type: TRIGGER; Schema: pnlf; Owner: postgres
--

CREATE TRIGGER trg_zones_collecte_updated_at BEFORE UPDATE ON pnlf.zones_collecte FOR EACH ROW EXECUTE FUNCTION pnlf.set_updated_at();


--
-- TOC entry 6734 (class 2606 OID 70019)
-- Name: appareils_sync appareils_sync_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.appareils_sync
    ADD CONSTRAINT appareils_sync_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6733 (class 2606 OID 69994)
-- Name: audit_logs audit_logs_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.audit_logs
    ADD CONSTRAINT audit_logs_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6705 (class 2606 OID 69578)
-- Name: categories_produit categories_produit_parent_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.categories_produit
    ADD CONSTRAINT categories_produit_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES pnlf.categories_produit(id) ON DELETE SET NULL;


--
-- TOC entry 6720 (class 2606 OID 69838)
-- Name: certifications certifications_lot_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.certifications
    ADD CONSTRAINT certifications_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES pnlf.lots(id) ON DELETE CASCADE;


--
-- TOC entry 6721 (class 2606 OID 69843)
-- Name: certifications certifications_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.certifications
    ADD CONSTRAINT certifications_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE CASCADE;


--
-- TOC entry 6722 (class 2606 OID 69833)
-- Name: certifications certifications_type_certification_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.certifications
    ADD CONSTRAINT certifications_type_certification_id_fkey FOREIGN KEY (type_certification_id) REFERENCES pnlf.types_certification(id) ON DELETE RESTRICT;


--
-- TOC entry 6723 (class 2606 OID 69848)
-- Name: certifications certifications_valide_par_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.certifications
    ADD CONSTRAINT certifications_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6728 (class 2606 OID 69919)
-- Name: conversation_participants conversation_participants_conversation_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.conversation_participants
    ADD CONSTRAINT conversation_participants_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES pnlf.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 6729 (class 2606 OID 69924)
-- Name: conversation_participants conversation_participants_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.conversation_participants
    ADD CONSTRAINT conversation_participants_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6727 (class 2606 OID 69905)
-- Name: conversations conversations_offre_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.conversations
    ADD CONSTRAINT conversations_offre_id_fkey FOREIGN KEY (offre_id) REFERENCES pnlf.offres_demandes(id) ON DELETE SET NULL;


--
-- TOC entry 6703 (class 2606 OID 69547)
-- Name: cooperative_membres cooperative_membres_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperative_membres
    ADD CONSTRAINT cooperative_membres_cooperative_id_fkey FOREIGN KEY (cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE CASCADE;


--
-- TOC entry 6704 (class 2606 OID 69552)
-- Name: cooperative_membres cooperative_membres_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperative_membres
    ADD CONSTRAINT cooperative_membres_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE CASCADE;


--
-- TOC entry 6693 (class 2606 OID 69452)
-- Name: cooperatives cooperatives_departement_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT cooperatives_departement_id_fkey FOREIGN KEY (departement_id) REFERENCES pnlf.departements(id) ON DELETE SET NULL;


--
-- TOC entry 6694 (class 2606 OID 69447)
-- Name: cooperatives cooperatives_province_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT cooperatives_province_id_fkey FOREIGN KEY (province_id) REFERENCES pnlf.provinces(id) ON DELETE SET NULL;


--
-- TOC entry 6695 (class 2606 OID 69462)
-- Name: cooperatives cooperatives_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT cooperatives_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6696 (class 2606 OID 69457)
-- Name: cooperatives cooperatives_village_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.cooperatives
    ADD CONSTRAINT cooperatives_village_id_fkey FOREIGN KEY (village_id) REFERENCES pnlf.villages(id) ON DELETE SET NULL;


--
-- TOC entry 6689 (class 2606 OID 69311)
-- Name: departements departements_province_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.departements
    ADD CONSTRAINT departements_province_id_fkey FOREIGN KEY (province_id) REFERENCES pnlf.provinces(id) ON DELETE RESTRICT;


--
-- TOC entry 6710 (class 2606 OID 69717)
-- Name: lots lots_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_cooperative_id_fkey FOREIGN KEY (cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL;


--
-- TOC entry 6711 (class 2606 OID 69727)
-- Name: lots lots_declare_par_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_declare_par_fkey FOREIGN KEY (declare_par) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6712 (class 2606 OID 69712)
-- Name: lots lots_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE RESTRICT;


--
-- TOC entry 6713 (class 2606 OID 69707)
-- Name: lots lots_produit_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES pnlf.produits(id) ON DELETE RESTRICT;


--
-- TOC entry 6714 (class 2606 OID 69732)
-- Name: lots lots_valide_par_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6715 (class 2606 OID 69722)
-- Name: lots lots_zone_collecte_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.lots
    ADD CONSTRAINT lots_zone_collecte_id_fkey FOREIGN KEY (zone_collecte_id) REFERENCES pnlf.zones_collecte(id) ON DELETE SET NULL;


--
-- TOC entry 6730 (class 2606 OID 69944)
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES pnlf.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 6731 (class 2606 OID 69949)
-- Name: messages messages_expediteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.messages
    ADD CONSTRAINT messages_expediteur_id_fkey FOREIGN KEY (expediteur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6745 (class 2606 OID 70326)
-- Name: messages_publics messages_publics_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.messages_publics
    ADD CONSTRAINT messages_publics_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE CASCADE;


--
-- TOC entry 6716 (class 2606 OID 69783)
-- Name: mouvements mouvements_acteur_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT mouvements_acteur_cooperative_id_fkey FOREIGN KEY (acteur_cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL;


--
-- TOC entry 6717 (class 2606 OID 69778)
-- Name: mouvements mouvements_acteur_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT mouvements_acteur_producteur_id_fkey FOREIGN KEY (acteur_producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE SET NULL;


--
-- TOC entry 6718 (class 2606 OID 69773)
-- Name: mouvements mouvements_acteur_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT mouvements_acteur_utilisateur_id_fkey FOREIGN KEY (acteur_utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6719 (class 2606 OID 69768)
-- Name: mouvements mouvements_lot_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.mouvements
    ADD CONSTRAINT mouvements_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES pnlf.lots(id) ON DELETE RESTRICT;


--
-- TOC entry 6732 (class 2606 OID 69975)
-- Name: notifications notifications_destinataire_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.notifications
    ADD CONSTRAINT notifications_destinataire_id_fkey FOREIGN KEY (destinataire_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6724 (class 2606 OID 69880)
-- Name: offres_demandes offres_demandes_auteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.offres_demandes
    ADD CONSTRAINT offres_demandes_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6725 (class 2606 OID 69885)
-- Name: offres_demandes offres_demandes_produit_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.offres_demandes
    ADD CONSTRAINT offres_demandes_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES pnlf.produits(id) ON DELETE RESTRICT;


--
-- TOC entry 6726 (class 2606 OID 69890)
-- Name: offres_demandes offres_demandes_province_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.offres_demandes
    ADD CONSTRAINT offres_demandes_province_id_fkey FOREIGN KEY (province_id) REFERENCES pnlf.provinces(id) ON DELETE SET NULL;


--
-- TOC entry 6707 (class 2606 OID 69628)
-- Name: producteur_produits producteur_produits_producteur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteur_produits
    ADD CONSTRAINT producteur_produits_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE CASCADE;


--
-- TOC entry 6708 (class 2606 OID 69633)
-- Name: producteur_produits producteur_produits_produit_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteur_produits
    ADD CONSTRAINT producteur_produits_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES pnlf.produits(id) ON DELETE CASCADE;


--
-- TOC entry 6697 (class 2606 OID 69515)
-- Name: producteurs producteurs_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_cooperative_id_fkey FOREIGN KEY (cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL;


--
-- TOC entry 6698 (class 2606 OID 69505)
-- Name: producteurs producteurs_departement_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_departement_id_fkey FOREIGN KEY (departement_id) REFERENCES pnlf.departements(id) ON DELETE SET NULL;


--
-- TOC entry 6699 (class 2606 OID 69500)
-- Name: producteurs producteurs_province_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_province_id_fkey FOREIGN KEY (province_id) REFERENCES pnlf.provinces(id) ON DELETE RESTRICT;


--
-- TOC entry 6700 (class 2606 OID 69520)
-- Name: producteurs producteurs_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6701 (class 2606 OID 69525)
-- Name: producteurs producteurs_valide_par_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6702 (class 2606 OID 69510)
-- Name: producteurs producteurs_village_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.producteurs
    ADD CONSTRAINT producteurs_village_id_fkey FOREIGN KEY (village_id) REFERENCES pnlf.villages(id) ON DELETE SET NULL;


--
-- TOC entry 6706 (class 2606 OID 69610)
-- Name: produits produits_categorie_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.produits
    ADD CONSTRAINT produits_categorie_id_fkey FOREIGN KEY (categorie_id) REFERENCES pnlf.categories_produit(id) ON DELETE RESTRICT;


--
-- TOC entry 6692 (class 2606 OID 69419)
-- Name: reinitialisations_mdp reinitialisations_mdp_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.reinitialisations_mdp
    ADD CONSTRAINT reinitialisations_mdp_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6691 (class 2606 OID 69397)
-- Name: sessions sessions_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.sessions
    ADD CONSTRAINT sessions_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6735 (class 2606 OID 70040)
-- Name: sync_conflicts sync_conflicts_appareil_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.sync_conflicts
    ADD CONSTRAINT sync_conflicts_appareil_id_fkey FOREIGN KEY (appareil_id) REFERENCES pnlf.appareils_sync(id) ON DELETE SET NULL;


--
-- TOC entry 6690 (class 2606 OID 69337)
-- Name: villages villages_departement_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.villages
    ADD CONSTRAINT villages_departement_id_fkey FOREIGN KEY (departement_id) REFERENCES pnlf.departements(id) ON DELETE RESTRICT;


--
-- TOC entry 6709 (class 2606 OID 69660)
-- Name: zones_collecte zones_collecte_province_id_fkey; Type: FK CONSTRAINT; Schema: pnlf; Owner: postgres
--

ALTER TABLE ONLY pnlf.zones_collecte
    ADD CONSTRAINT zones_collecte_province_id_fkey FOREIGN KEY (province_id) REFERENCES pnlf.provinces(id) ON DELETE RESTRICT;


--
-- TOC entry 6737 (class 2606 OID 70192)
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6738 (class 2606 OID 70187)
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6736 (class 2606 OID 70178)
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6739 (class 2606 OID 70207)
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6740 (class 2606 OID 70202)
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6741 (class 2606 OID 70221)
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6742 (class 2606 OID 70216)
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6761 (class 2606 OID 86941)
-- Name: certifications_pieces certifications_pieces_certification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.certifications_pieces
    ADD CONSTRAINT certifications_pieces_certification_id_fkey FOREIGN KEY (certification_id) REFERENCES pnlf.certifications(id) ON DELETE CASCADE;


--
-- TOC entry 6762 (class 2606 OID 86946)
-- Name: certifications_pieces certifications_pieces_depose_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.certifications_pieces
    ADD CONSTRAINT certifications_pieces_depose_par_id_fkey FOREIGN KEY (depose_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6767 (class 2606 OID 87020)
-- Name: connexions connexions_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.connexions
    ADD CONSTRAINT connexions_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6746 (class 2606 OID 86671)
-- Name: conversation_context conversation_context_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_context
    ADD CONSTRAINT conversation_context_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES pnlf.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 6747 (class 2606 OID 86681)
-- Name: conversation_context conversation_context_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_context
    ADD CONSTRAINT conversation_context_cooperative_id_fkey FOREIGN KEY (cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE SET NULL;


--
-- TOC entry 6748 (class 2606 OID 86676)
-- Name: conversation_context conversation_context_producteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_context
    ADD CONSTRAINT conversation_context_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE SET NULL;


--
-- TOC entry 6750 (class 2606 OID 86709)
-- Name: conversation_participant_meta conversation_participant_meta_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_participant_meta
    ADD CONSTRAINT conversation_participant_meta_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES pnlf.conversations(id) ON DELETE CASCADE;


--
-- TOC entry 6751 (class 2606 OID 86714)
-- Name: conversation_participant_meta conversation_participant_meta_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.conversation_participant_meta
    ADD CONSTRAINT conversation_participant_meta_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6743 (class 2606 OID 70243)
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6744 (class 2606 OID 70248)
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6752 (class 2606 OID 86745)
-- Name: documents_inscription documents_inscription_depose_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.documents_inscription
    ADD CONSTRAINT documents_inscription_depose_par_id_fkey FOREIGN KEY (depose_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6755 (class 2606 OID 86877)
-- Name: invitations_cooperative invitations_cooperative_cooperative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.invitations_cooperative
    ADD CONSTRAINT invitations_cooperative_cooperative_id_fkey FOREIGN KEY (cooperative_id) REFERENCES pnlf.cooperatives(id) ON DELETE CASCADE;


--
-- TOC entry 6756 (class 2606 OID 86887)
-- Name: invitations_cooperative invitations_cooperative_invite_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.invitations_cooperative
    ADD CONSTRAINT invitations_cooperative_invite_par_id_fkey FOREIGN KEY (invite_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6757 (class 2606 OID 86882)
-- Name: invitations_cooperative invitations_cooperative_producteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.invitations_cooperative
    ADD CONSTRAINT invitations_cooperative_producteur_id_fkey FOREIGN KEY (producteur_id) REFERENCES pnlf.producteurs(id) ON DELETE CASCADE;


--
-- TOC entry 6758 (class 2606 OID 86892)
-- Name: invitations_cooperative invitations_cooperative_repondu_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.invitations_cooperative
    ADD CONSTRAINT invitations_cooperative_repondu_par_id_fkey FOREIGN KEY (repondu_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6759 (class 2606 OID 86920)
-- Name: lots_transitions lots_transitions_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.lots_transitions
    ADD CONSTRAINT lots_transitions_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6760 (class 2606 OID 86915)
-- Name: lots_transitions lots_transitions_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.lots_transitions
    ADD CONSTRAINT lots_transitions_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES pnlf.lots(id) ON DELETE CASCADE;


--
-- TOC entry 6749 (class 2606 OID 86697)
-- Name: message_pieces message_pieces_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.message_pieces
    ADD CONSTRAINT message_pieces_message_id_fkey FOREIGN KEY (message_id) REFERENCES pnlf.messages(id) ON DELETE CASCADE;


--
-- TOC entry 6769 (class 2606 OID 87090)
-- Name: moderation_images moderation_images_envoye_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.moderation_images
    ADD CONSTRAINT moderation_images_envoye_par_id_fkey FOREIGN KEY (envoye_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6770 (class 2606 OID 87095)
-- Name: moderation_images moderation_images_traite_par_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.moderation_images
    ADD CONSTRAINT moderation_images_traite_par_id_fkey FOREIGN KEY (traite_par_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6763 (class 2606 OID 86977)
-- Name: offres_details offres_details_categorie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_details
    ADD CONSTRAINT offres_details_categorie_id_fkey FOREIGN KEY (categorie_id) REFERENCES pnlf.categories_produit(id) ON DELETE SET NULL;


--
-- TOC entry 6764 (class 2606 OID 86972)
-- Name: offres_details offres_details_offre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_details
    ADD CONSTRAINT offres_details_offre_id_fkey FOREIGN KEY (offre_id) REFERENCES pnlf.offres_demandes(id) ON DELETE CASCADE;


--
-- TOC entry 6765 (class 2606 OID 87000)
-- Name: offres_moderation offres_moderation_moderateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_moderation
    ADD CONSTRAINT offres_moderation_moderateur_id_fkey FOREIGN KEY (moderateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE SET NULL;


--
-- TOC entry 6766 (class 2606 OID 86995)
-- Name: offres_moderation offres_moderation_offre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.offres_moderation
    ADD CONSTRAINT offres_moderation_offre_id_fkey FOREIGN KEY (offre_id) REFERENCES pnlf.offres_demandes(id) ON DELETE CASCADE;


--
-- TOC entry 6768 (class 2606 OID 87042)
-- Name: presences presences_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.presences
    ADD CONSTRAINT presences_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES pnlf.utilisateurs(id) ON DELETE CASCADE;


--
-- TOC entry 6753 (class 2606 OID 86830)
-- Name: token_blacklist_blacklistedtoken token_blacklist_blacklistedtoken_token_id_3cc7fe56_fk; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_blacklistedtoken
    ADD CONSTRAINT token_blacklist_blacklistedtoken_token_id_3cc7fe56_fk FOREIGN KEY (token_id) REFERENCES public.token_blacklist_outstandingtoken(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 6754 (class 2606 OID 86793)
-- Name: token_blacklist_outstandingtoken token_blacklist_outs_user_id_83bc629a_fk_auth_user; Type: FK CONSTRAINT; Schema: public; Owner: pnlf_app
--

ALTER TABLE ONLY public.token_blacklist_outstandingtoken
    ADD CONSTRAINT token_blacklist_outs_user_id_83bc629a_fk_auth_user FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 7019 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA pnlf; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA pnlf TO pnlf_app;
GRANT USAGE ON SCHEMA pnlf TO pnlf_readonly;


--
-- TOC entry 7020 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO pnlf_app;
GRANT USAGE ON SCHEMA public TO pnlf_readonly;


--
-- TOC entry 7027 (class 0 OID 0)
-- Dependencies: 504
-- Name: FUNCTION generer_code_lot(); Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON FUNCTION pnlf.generer_code_lot() TO pnlf_app;


--
-- TOC entry 7028 (class 0 OID 0)
-- Dependencies: 981
-- Name: FUNCTION interdire_modif_audit(); Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON FUNCTION pnlf.interdire_modif_audit() TO pnlf_app;


--
-- TOC entry 7029 (class 0 OID 0)
-- Dependencies: 421
-- Name: FUNCTION interdire_modif_mouvement(); Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON FUNCTION pnlf.interdire_modif_mouvement() TO pnlf_app;


--
-- TOC entry 7030 (class 0 OID 0)
-- Dependencies: 917
-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON FUNCTION pnlf.set_updated_at() TO pnlf_app;


--
-- TOC entry 7031 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE appareils_sync; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.appareils_sync TO pnlf_app;
GRANT SELECT ON TABLE pnlf.appareils_sync TO pnlf_readonly;


--
-- TOC entry 7033 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE audit_logs; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE pnlf.audit_logs TO pnlf_app;
GRANT SELECT ON TABLE pnlf.audit_logs TO pnlf_readonly;


--
-- TOC entry 7035 (class 0 OID 0)
-- Dependencies: 253
-- Name: SEQUENCE audit_logs_id_seq; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON SEQUENCE pnlf.audit_logs_id_seq TO pnlf_app;


--
-- TOC entry 7036 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE categories_produit; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.categories_produit TO pnlf_app;
GRANT SELECT ON TABLE pnlf.categories_produit TO pnlf_readonly;


--
-- TOC entry 7037 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE certifications; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.certifications TO pnlf_app;
GRANT SELECT ON TABLE pnlf.certifications TO pnlf_readonly;


--
-- TOC entry 7038 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE conversation_participants; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.conversation_participants TO pnlf_app;
GRANT SELECT ON TABLE pnlf.conversation_participants TO pnlf_readonly;


--
-- TOC entry 7039 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE conversations; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.conversations TO pnlf_app;
GRANT SELECT ON TABLE pnlf.conversations TO pnlf_readonly;


--
-- TOC entry 7040 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE cooperative_membres; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.cooperative_membres TO pnlf_app;
GRANT SELECT ON TABLE pnlf.cooperative_membres TO pnlf_readonly;


--
-- TOC entry 7041 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE cooperatives; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.cooperatives TO pnlf_app;
GRANT SELECT ON TABLE pnlf.cooperatives TO pnlf_readonly;


--
-- TOC entry 7042 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE departements; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.departements TO pnlf_app;
GRANT SELECT ON TABLE pnlf.departements TO pnlf_readonly;


--
-- TOC entry 7044 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE lots; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.lots TO pnlf_app;
GRANT SELECT ON TABLE pnlf.lots TO pnlf_readonly;


--
-- TOC entry 7045 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE messages; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.messages TO pnlf_app;
GRANT SELECT ON TABLE pnlf.messages TO pnlf_readonly;


--
-- TOC entry 7046 (class 0 OID 0)
-- Dependencies: 282
-- Name: TABLE messages_publics; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pnlf.messages_publics TO pnlf_app;
GRANT SELECT ON TABLE pnlf.messages_publics TO pnlf_readonly;


--
-- TOC entry 7048 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE mouvements; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE pnlf.mouvements TO pnlf_app;
GRANT SELECT ON TABLE pnlf.mouvements TO pnlf_readonly;


--
-- TOC entry 7049 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE notifications; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.notifications TO pnlf_app;
GRANT SELECT ON TABLE pnlf.notifications TO pnlf_readonly;


--
-- TOC entry 7050 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE offres_demandes; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.offres_demandes TO pnlf_app;
GRANT SELECT ON TABLE pnlf.offres_demandes TO pnlf_readonly;


--
-- TOC entry 7051 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE producteur_produits; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.producteur_produits TO pnlf_app;
GRANT SELECT ON TABLE pnlf.producteur_produits TO pnlf_readonly;


--
-- TOC entry 7052 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE producteurs; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.producteurs TO pnlf_app;
GRANT SELECT ON TABLE pnlf.producteurs TO pnlf_readonly;


--
-- TOC entry 7053 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE produits; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.produits TO pnlf_app;
GRANT SELECT ON TABLE pnlf.produits TO pnlf_readonly;


--
-- TOC entry 7054 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE provinces; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.provinces TO pnlf_app;
GRANT SELECT ON TABLE pnlf.provinces TO pnlf_readonly;


--
-- TOC entry 7055 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE reinitialisations_mdp; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.reinitialisations_mdp TO pnlf_app;
GRANT SELECT ON TABLE pnlf.reinitialisations_mdp TO pnlf_readonly;


--
-- TOC entry 7056 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE sessions; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.sessions TO pnlf_app;
GRANT SELECT ON TABLE pnlf.sessions TO pnlf_readonly;


--
-- TOC entry 7057 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE sync_conflicts; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.sync_conflicts TO pnlf_app;
GRANT SELECT ON TABLE pnlf.sync_conflicts TO pnlf_readonly;


--
-- TOC entry 7058 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE types_certification; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.types_certification TO pnlf_app;
GRANT SELECT ON TABLE pnlf.types_certification TO pnlf_readonly;


--
-- TOC entry 7059 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE utilisateurs; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.utilisateurs TO pnlf_app;
GRANT SELECT ON TABLE pnlf.utilisateurs TO pnlf_readonly;


--
-- TOC entry 7060 (class 0 OID 0)
-- Dependencies: 280
-- Name: TABLE v_dashboard_lots; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pnlf.v_dashboard_lots TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_dashboard_lots TO pnlf_readonly;


--
-- TOC entry 7061 (class 0 OID 0)
-- Dependencies: 281
-- Name: TABLE v_dashboard_mouvements; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pnlf.v_dashboard_mouvements TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_dashboard_mouvements TO pnlf_readonly;


--
-- TOC entry 7062 (class 0 OID 0)
-- Dependencies: 279
-- Name: TABLE v_dashboard_producteurs; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pnlf.v_dashboard_producteurs TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_dashboard_producteurs TO pnlf_readonly;


--
-- TOC entry 7063 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE v_stats_lots_par_produit; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.v_stats_lots_par_produit TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_stats_lots_par_produit TO pnlf_readonly;


--
-- TOC entry 7064 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE v_stats_producteurs_par_province; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.v_stats_producteurs_par_province TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_stats_producteurs_par_province TO pnlf_readonly;


--
-- TOC entry 7065 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE v_tracabilite_lot; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.v_tracabilite_lot TO pnlf_app;
GRANT SELECT ON TABLE pnlf.v_tracabilite_lot TO pnlf_readonly;


--
-- TOC entry 7066 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE villages; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.villages TO pnlf_app;
GRANT SELECT ON TABLE pnlf.villages TO pnlf_readonly;


--
-- TOC entry 7067 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE zones_collecte; Type: ACL; Schema: pnlf; Owner: postgres
--

GRANT ALL ON TABLE pnlf.zones_collecte TO pnlf_app;
GRANT SELECT ON TABLE pnlf.zones_collecte TO pnlf_readonly;


--
-- TOC entry 7069 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.geography_columns TO pnlf_app;


--
-- TOC entry 7070 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.geometry_columns TO pnlf_app;


--
-- TOC entry 7071 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.spatial_ref_sys TO pnlf_app;


--
-- TOC entry 3414 (class 826 OID 70076)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: pnlf; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA pnlf GRANT SELECT,USAGE ON SEQUENCES TO pnlf_app;


--
-- TOC entry 3413 (class 826 OID 70075)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: pnlf; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA pnlf GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO pnlf_app;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA pnlf GRANT SELECT ON TABLES TO pnlf_readonly;


--
-- TOC entry 3416 (class 826 OID 70085)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO pnlf_app;


--
-- TOC entry 3415 (class 826 OID 70084)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO pnlf_app;


-- Completed on 2026-11-18 16:51:17

--
-- PostgreSQL database dump complete
--

\unrestrict 1hU877PMe8nP5rpwih8gHN3fbcA8xzVYs9zWk0pXDL1eOuXwjK63UGpxMf7HIhT

