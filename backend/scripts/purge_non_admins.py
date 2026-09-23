"""
Purge : tous les utilisateurs sauf ADMINISTRATEUR + données métier liées.

  python scripts/purge_non_admins.py --production --force   # Render
  python scripts/purge_non_admins.py --force                # local
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parents[1]
OP_KEY = "purge_non_admins_v1"
LOCAL_FLAG = BACKEND / f".{OP_KEY}.done"


def load_env(*, production: bool) -> None:
    load_dotenv(BACKEND / ".env", override=True)
    if not production:
        load_dotenv(BACKEND / ".env.local", override=True)


def connect() -> psycopg.Connection:
    kwargs = {"options": "-c search_path=pnlf,public", "connect_timeout": 20}
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        if "render.com" in database_url and "sslmode" not in database_url:
            sep = "&" if "?" in database_url else "?"
            database_url = f"{database_url}{sep}sslmode=require"
        return psycopg.connect(database_url, **kwargs)

    host = os.getenv("DB_HOST", "127.0.0.1")
    params: dict = {
        "host": host,
        "port": os.getenv("DB_PORT", "5432"),
        "dbname": os.getenv("DB_NAME", "pnlf"),
        "user": os.getenv("DB_SUPERUSER") or os.getenv("DB_USER", "pnlf_app"),
        "password": os.getenv("DB_SUPERPASSWORD") or os.getenv("DB_PASSWORD", ""),
        **kwargs,
    }
    if "render.com" in host:
        params["sslmode"] = "require"
    return psycopg.connect(**params)


def table_exists(cur, schema: str, name: str) -> bool:
    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = %s AND table_name = %s
        """,
        (schema, name),
    )
    return bool(cur.fetchone())


def has_column(cur, table: str, column: str) -> bool:
    cur.execute(
        """
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'pnlf' AND table_name = %s AND column_name = %s
        """,
        (table, column),
    )
    return bool(cur.fetchone())


def safe_delete(cur, table: str) -> int:
    if not table_exists(cur, "pnlf", table):
        return 0
    cur.execute(f"DELETE FROM pnlf.{table}")
    return cur.rowcount


def print_counts(cur, label: str) -> None:
    print(f"--- {label} ---")
    cur.execute(
        """
        SELECT role, count(*) FROM pnlf.utilisateurs
        WHERE deleted_at IS NULL
        GROUP BY role ORDER BY 1
        """
    )
    rows = cur.fetchall()
    if not rows:
        print("  (aucun utilisateur actif)")
    for role, n in rows:
        print(f"  utilisateurs.{role}: {n}")

    for table in (
        "lots",
        "producteurs",
        "cooperatives",
        "mouvements",
        "certifications",
        "offres_demandes",
        "notifications",
        "messages",
    ):
        if not table_exists(cur, "pnlf", table):
            continue
        if has_column(cur, table, "deleted_at"):
            cur.execute(f"SELECT count(*) FROM pnlf.{table} WHERE deleted_at IS NULL")
        else:
            cur.execute(f"SELECT count(*) FROM pnlf.{table}")
        print(f"  {table}: {cur.fetchone()[0]}")


def already_applied(cur) -> bool:
    if LOCAL_FLAG.exists():
        return True
    for schema in ("pnlf", "public"):
        if table_exists(cur, schema, "_data_ops"):
            cur.execute(f"SELECT 1 FROM {schema}._data_ops WHERE op_key = %s", (OP_KEY,))
            if cur.fetchone():
                return True
    return False


def mark_applied(cur, note: str) -> None:
    try:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS public._data_ops (
                op_key VARCHAR(100) PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                note TEXT
            )
            """
        )
        cur.execute(
            """
            INSERT INTO public._data_ops (op_key, note)
            VALUES (%s, %s)
            ON CONFLICT (op_key) DO UPDATE
            SET applied_at = NOW(), note = EXCLUDED.note
            """,
            (OP_KEY, note),
        )
    except Exception:
        pass
    LOCAL_FLAG.write_text(note, encoding="utf-8")


def can_hard_purge(cur) -> bool:
    cur.execute("SELECT has_table_privilege(current_user, 'pnlf.mouvements', 'DELETE')")
    if not cur.fetchone()[0]:
        return False
    try:
        cur.execute("ALTER TABLE pnlf.mouvements DISABLE TRIGGER USER")
        cur.execute("ALTER TABLE pnlf.mouvements ENABLE TRIGGER USER")
        return True
    except Exception:
        return False


def run_hard_purge(cur) -> None:
    cur.execute("ALTER TABLE pnlf.mouvements DISABLE TRIGGER USER")
    cur.execute("ALTER TABLE pnlf.audit_logs DISABLE TRIGGER USER")

    for table in (
        "mouvements",
        "certifications",
        "documents_inscription",
        "messages_publics",
        "message_pieces",
        "conversation_participant_meta",
        "messages",
        "conversation_participants",
        "conversation_contexts",
        "conversations",
        "offres_demandes",
        "notifications",
        "sync_conflicts",
        "appareils_sync",
        "cooperative_membres",
        "producteur_produits",
        "lots",
        "producteurs",
        "cooperatives",
        "audit_logs",
    ):
        n = safe_delete(cur, table)
        if n:
            print(f"  deleted {table}: {n}")

    cur.execute(
        """
        DELETE FROM pnlf.sessions
        WHERE utilisateur_id IN (
            SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
        )
        """
    )
    cur.execute(
        """
        DELETE FROM pnlf.reinitialisations_mdp
        WHERE utilisateur_id IN (
            SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
        )
        """
    )
    cur.execute("DELETE FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'")
    print(f"  deleted utilisateurs (non-admin): {cur.rowcount}")

    cur.execute("ALTER TABLE pnlf.mouvements ENABLE TRIGGER USER")
    cur.execute("ALTER TABLE pnlf.audit_logs ENABLE TRIGGER USER")
    mark_applied(cur, "hard-purge non-ADMINISTRATEUR + métier")


def run_soft_purge_local(cur) -> None:
    print("  Mode soft-delete local (droits mouvements insuffisants)")

    for table in (
        "certifications",
        "documents_inscription",
        "messages_publics",
        "messages",
        "conversation_participants",
        "conversations",
        "offres_demandes",
        "notifications",
        "sync_conflicts",
        "appareils_sync",
        "cooperative_membres",
        "producteur_produits",
    ):
        n = safe_delete(cur, table)
        if n:
            print(f"  deleted {table}: {n}")

    for table in ("lots", "producteurs"):
        if table_exists(cur, "pnlf", table) and has_column(cur, table, "deleted_at"):
            cur.execute(
                f"""
                UPDATE pnlf.{table}
                SET deleted_at = COALESCE(deleted_at, NOW())
                WHERE deleted_at IS NULL
                """
            )
            print(f"  soft-deleted {table}: {cur.rowcount}")

    if table_exists(cur, "pnlf", "cooperatives"):
        n = safe_delete(cur, "cooperatives")
        print(f"  deleted cooperatives: {n}")

    cur.execute(
        """
        DELETE FROM pnlf.sessions
        WHERE utilisateur_id IN (
            SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
        )
        """
    )
    cur.execute(
        """
        DELETE FROM pnlf.reinitialisations_mdp
        WHERE utilisateur_id IN (
            SELECT id FROM pnlf.utilisateurs WHERE role <> 'ADMINISTRATEUR'
        )
        """
    )
    cur.execute(
        """
        UPDATE pnlf.utilisateurs
        SET deleted_at = COALESCE(deleted_at, NOW()), statut = 'INACTIF'
        WHERE role <> 'ADMINISTRATEUR' AND deleted_at IS NULL
        """
    )
    print(f"  soft-deleted utilisateurs (non-admin): {cur.rowcount}")
    # Soft-delete seulement en local : hard DELETE échoue (audit_logs inaltérable / SET NULL)
    mark_applied(cur, "soft-purge local + soft users non-admin")


def main() -> int:
    production = "--production" in sys.argv
    force = "--force" in sys.argv
    load_env(production=production)
    print(
        f"Cible: {'PRODUCTION' if production else 'LOCAL'} / "
        f"host={os.getenv('DB_HOST')} / db={os.getenv('DB_NAME')} / "
        f"user={os.getenv('DB_SUPERUSER') or os.getenv('DB_USER')}"
    )

    try:
        conn = connect()
    except Exception as exc:  # noqa: BLE001
        print(f"Connexion impossible: {exc}", file=sys.stderr)
        return 1

    try:
        with conn.cursor() as cur:
            print_counts(cur, "AVANT")
            if already_applied(cur) and not force:
                print(f"Déjà appliqué ({OP_KEY}). Utilisez --force pour recommencer.")
                return 0
            if force and LOCAL_FLAG.exists():
                LOCAL_FLAG.unlink()
            if can_hard_purge(cur):
                run_hard_purge(cur)
            else:
                run_soft_purge_local(cur)
        conn.commit()
        with conn.cursor() as cur:
            print(f"Purge OK ({OP_KEY})")
            print_counts(cur, "APRÈS")
        return 0
    except Exception as exc:  # noqa: BLE001
        conn.rollback()
        print(f"ERREUR: {exc}", file=sys.stderr)
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
