-- =============================================================================
-- PNLF — Purge définitive des données métier (hors administrateurs système)
-- Conservé : utilisateurs ADMINISTRATEUR + référentiels
-- Idempotent via pnlf._data_ops.op_key = purge_non_admins_v1
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS pnlf._data_ops (
    op_key VARCHAR(100) PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT
);

-- Helper : DELETE sûr si la table existe
CREATE OR REPLACE FUNCTION pnlf._purge_truncate_if_exists(p_table text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'pnlf' AND table_name = p_table
    ) THEN
        EXECUTE format('DELETE FROM pnlf.%I', p_table);
    END IF;
END;
$$;

-- Désactiver l'inaltérabilité le temps de la purge
ALTER TABLE pnlf.mouvements DISABLE TRIGGER USER;
ALTER TABLE pnlf.audit_logs DISABLE TRIGGER USER;

SELECT pnlf._purge_truncate_if_exists('mouvements');
SELECT pnlf._purge_truncate_if_exists('certifications');
SELECT pnlf._purge_truncate_if_exists('documents_inscription');
SELECT pnlf._purge_truncate_if_exists('messages_publics');
SELECT pnlf._purge_truncate_if_exists('message_pieces');
SELECT pnlf._purge_truncate_if_exists('conversation_participant_meta');
SELECT pnlf._purge_truncate_if_exists('messages');
SELECT pnlf._purge_truncate_if_exists('conversation_participants');
SELECT pnlf._purge_truncate_if_exists('conversation_contexts');
SELECT pnlf._purge_truncate_if_exists('conversations');
SELECT pnlf._purge_truncate_if_exists('offres_demandes');
SELECT pnlf._purge_truncate_if_exists('notifications');
SELECT pnlf._purge_truncate_if_exists('sync_conflicts');
SELECT pnlf._purge_truncate_if_exists('appareils_sync');

DELETE FROM pnlf.sessions
WHERE utilisateur_id IN (
    SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
);
DELETE FROM pnlf.reinitialisations_mdp
WHERE utilisateur_id IN (
    SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
);

SELECT pnlf._purge_truncate_if_exists('cooperative_membres');
SELECT pnlf._purge_truncate_if_exists('producteur_produits');
SELECT pnlf._purge_truncate_if_exists('lots');
SELECT pnlf._purge_truncate_if_exists('producteurs');
SELECT pnlf._purge_truncate_if_exists('cooperatives');

DELETE FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR';

SELECT pnlf._purge_truncate_if_exists('audit_logs');

ALTER TABLE pnlf.mouvements ENABLE TRIGGER USER;
ALTER TABLE pnlf.audit_logs ENABLE TRIGGER USER;

DROP FUNCTION IF EXISTS pnlf._purge_truncate_if_exists(text);

INSERT INTO pnlf._data_ops (op_key, note)
VALUES (
    'purge_non_admins_v1',
    'Purge utilisateurs non-ADMINISTRATEUR + lots/producteurs/coop/chat/offres'
)
ON CONFLICT (op_key) DO UPDATE
SET applied_at = NOW(),
    note = EXCLUDED.note;

COMMIT;
