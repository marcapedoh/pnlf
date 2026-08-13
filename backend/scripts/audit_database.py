"""Audit complet de la base pnlf : intégrité, contraintes, sécurité."""
import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / 'backend' / '.env')

PASS = []
FAIL = []
WARN = []


def ok(msg):
    PASS.append(msg)
    print(f'  [OK] {msg}')


def fail(msg):
    FAIL.append(msg)
    print(f'  [FAIL] {msg}')


def warn(msg):
    WARN.append(msg)
    print(f'  [WARN] {msg}')


def connect(user=None, password=None):
    return psycopg.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        port=os.getenv('DB_PORT', '5432'),
        dbname=os.getenv('DB_NAME', 'pnlf'),
        user=user or os.getenv('DB_USER', 'pnlf_app'),
        password=password or os.getenv('DB_PASSWORD', ''),
        options='-c search_path=pnlf,public',
    )


def audit_extensions(cur):
    print('\n=== Extensions ===')
    cur.execute("SELECT extname FROM pg_extension WHERE extname IN ('pgcrypto','postgis','citext','uuid-ossp','pg_trgm','unaccent')")
    exts = {r[0] for r in cur.fetchall()}
    for e in ('pgcrypto', 'postgis', 'citext', 'uuid-ossp', 'pg_trgm', 'unaccent'):
        if e in exts:
            ok(f'Extension {e}')
        else:
            fail(f'Extension manquante: {e}')


def audit_referential_data(cur):
    print('\n=== Données référentielles ===')
    checks = [
        ('provinces actives', 'SELECT COUNT(*) FROM provinces WHERE actif', 9, 'eq'),
        ('départements', 'SELECT COUNT(*) FROM departements WHERE actif', 48, 'ge'),
        ('chefs-lieux (villages)', 'SELECT COUNT(*) FROM villages WHERE actif', 48, 'ge'),
        ('produits PFNL', "SELECT COUNT(*) FROM produits WHERE actif AND code LIKE 'PFNL-%'", 20, 'ge'),
        ('zones collecte', 'SELECT COUNT(*) FROM zones_collecte WHERE actif', 8, 'ge'),
        ('catégories produit', 'SELECT COUNT(*) FROM categories_produit WHERE actif', 8, 'ge'),
        ('types certification', 'SELECT COUNT(*) FROM types_certification', 4, 'ge'),
    ]
    for label, sql, expected, op in checks:
        cur.execute(sql)
        n = cur.fetchone()[0]
        if op == 'eq' and n == expected:
            ok(f'{label}: {n}')
        elif op == 'ge' and n >= expected:
            ok(f'{label}: {n}')
        else:
            fail(f'{label}: {n} (attendu {expected})')

    cur.execute("""
        SELECT COUNT(*) FROM departements d
        LEFT JOIN provinces p ON p.id = d.province_id WHERE p.id IS NULL
    """)
    if cur.fetchone()[0] == 0:
        ok('FK departements -> provinces')
    else:
        fail('Départements orphelins')

    cur.execute("""
        SELECT COUNT(*) FROM villages v
        LEFT JOIN departements d ON d.id = v.departement_id WHERE d.id IS NULL
    """)
    if cur.fetchone()[0] == 0:
        ok('FK villages -> departements')
    else:
        fail('Villages orphelins')

    cur.execute("""
        SELECT COUNT(*) FROM produits pr
        LEFT JOIN categories_produit c ON c.id = pr.categorie_id WHERE c.id IS NULL
    """)
    if cur.fetchone()[0] == 0:
        ok('FK produits -> categories')
    else:
        fail('Produits sans catégorie')

    cur.execute("""
        SELECT p.nom, COUNT(d.id) FROM provinces p
        LEFT JOIN departements d ON d.province_id = p.id AND d.actif
        GROUP BY p.nom HAVING COUNT(d.id) = 0
    """)
    orphans = cur.fetchall()
    if not orphans:
        ok('Chaque province a au moins 1 département')
    else:
        fail(f'Provinces sans département: {orphans}')


def audit_constraints(conn):
    print('\n=== Contraintes metier (tests negatifs) ===')
    cur = conn.cursor()

    # ck_mvt_acteur : mouvement sans acteur doit échouer
    cur.execute("SELECT id FROM lots WHERE deleted_at IS NULL LIMIT 1")
    lot = cur.fetchone()
    if lot:
        try:
            cur.execute("""
                INSERT INTO mouvements (lot_id, type_mouvement, date_mouvement, created_at)
                VALUES (%s, 'COLLECTE', NOW(), NOW())
            """, [lot[0]])
            conn.commit()
            fail('ck_mvt_acteur non appliquée (INSERT sans acteur accepté)')
        except psycopg.Error:
            conn.rollback()
            ok('ck_mvt_acteur bloque INSERT sans acteur')
    else:
        warn('Pas de lot pour tester ck_mvt_acteur')

    # Immutabilité mouvements (trigger)
    cur.execute("SELECT id FROM mouvements LIMIT 1")
    mvt = cur.fetchone()
    if mvt:
        try:
            cur.execute("UPDATE mouvements SET commentaire = 'hack' WHERE id = %s", [mvt[0]])
            conn.commit()
            fail('Trigger immutabilité mouvements absent (UPDATE accepté)')
        except psycopg.Error:
            conn.rollback()
            ok('Trigger immutabilité mouvements (UPDATE bloqué)')
        try:
            cur.execute("DELETE FROM mouvements WHERE id = %s", [mvt[0]])
            conn.commit()
            fail('Trigger immutabilité mouvements absent (DELETE accepté)')
        except psycopg.Error:
            conn.rollback()
            ok('Trigger immutabilité mouvements (DELETE bloqué)')
    else:
        warn('Pas de mouvement pour tester immutabilité')

    # Immutabilité audit_logs
    cur.execute("SELECT id FROM audit_logs LIMIT 1")
    aud = cur.fetchone()
    if aud:
        try:
            cur.execute("UPDATE audit_logs SET action = 'HACK' WHERE id = %s", [aud[0]])
            conn.commit()
            fail('Trigger immutabilité audit absent')
        except psycopg.Error:
            conn.rollback()
            ok('Trigger immutabilité audit_logs (UPDATE bloqué)')
    else:
        warn('Pas de log audit pour tester immutabilité trigger')

    # ck_lots_quantite
    cur.execute("SELECT id, produit_id, producteur_id FROM lots LIMIT 1")
    row = cur.fetchone()
    if row:
        try:
            cur.execute("""
                INSERT INTO lots (code_lot, produit_id, producteur_id, date_collecte, quantite, unite, created_at, updated_at)
                VALUES ('TEST-BAD-QTY', %s, %s, CURRENT_DATE, -1, 'KG', NOW(), NOW())
            """, [row[1], row[2]])
            conn.commit()
            fail('ck_lots_quantite non appliquée')
        except psycopg.Error:
            conn.rollback()
            ok('ck_lots_quantite bloque quantité négative')

    # Email invalide utilisateurs
    try:
        cur.execute("""
            INSERT INTO utilisateurs (email, mot_de_passe_hash, role, statut, nom, prenoms, created_at, updated_at)
            VALUES ('bad-email', 'x' || repeat('a', 30), 'ACHETEUR', 'ACTIF', 'T', 'T', NOW(), NOW())
        """)
        conn.commit()
        fail('ck_utilisateurs_email non appliquée')
    except psycopg.Error:
        conn.rollback()
        ok('ck_utilisateurs_email bloque email invalide')


def audit_grants(cur):
    print('\n=== Privilèges pnlf_app (sécurité) ===')
    cur.execute("""
        SELECT privilege_type FROM information_schema.table_privileges
        WHERE grantee = 'pnlf_app' AND table_schema = 'pnlf' AND table_name = 'mouvements'
    """)
    privs = {r[0] for r in cur.fetchall()}
    if 'INSERT' in privs and 'SELECT' in privs:
        ok('mouvements: SELECT + INSERT')
    else:
        fail(f'mouvements privilèges insuffisants: {privs}')
    if 'UPDATE' not in privs and 'DELETE' not in privs:
        ok('mouvements: pas UPDATE/DELETE (03_harden_grants appliqué)')
    else:
        warn(f'mouvements: UPDATE/DELETE encore accordés — exécuter 03_harden_grants.sql: {privs}')

    cur.execute("""
        SELECT privilege_type FROM information_schema.table_privileges
        WHERE grantee = 'pnlf_app' AND table_schema = 'pnlf' AND table_name = 'audit_logs'
    """)
    privs = {r[0] for r in cur.fetchall()}
    if 'UPDATE' not in privs and 'DELETE' not in privs:
        ok('audit_logs: pas UPDATE/DELETE')
    else:
        warn(f'audit_logs: UPDATE/DELETE encore accordés: {privs}')

    cur.execute("""
        SELECT has_schema_privilege('pnlf_app', 'pnlf', 'CREATE')
    """)
    if not cur.fetchone()[0]:
        ok('pnlf_app: pas CREATE sur schéma pnlf')
    else:
        warn('pnlf_app a encore CREATE sur schéma pnlf')


def audit_password_storage(cur):
    print('\n=== Stockage mots de passe ===')
    cur.execute("SELECT mot_de_passe_hash FROM utilisateurs WHERE email = 'admin@pnlf.ga'")
    row = cur.fetchone()
    if row and row[0].startswith('$2'):
        ok('Hash bcrypt pour admin (pas en clair)')
    else:
        fail('Mot de passe admin non hashé correctement')


if __name__ == '__main__':
    print('AUDIT BASE DE DONNÉES PNLF')
    print('=' * 50)
    try:
        conn = connect()
    except Exception as e:
        print(f'ERREUR connexion: {e}')
        sys.exit(1)

    with conn.cursor() as cur:
        audit_extensions(cur)
        audit_referential_data(cur)
        audit_constraints(conn)
        audit_grants(cur)
        audit_password_storage(cur)
    conn.close()

    print('\n' + '=' * 50)
    print(f'RÉSULTAT: {len(PASS)} OK | {len(WARN)} WARN | {len(FAIL)} FAIL')
    if FAIL:
        sys.exit(1)
