"""Statut métier des offres/demandes.

L'enum PostgreSQL historique (`OUVERTE`, `CLOTUREE`, `ANNULEE`) ne contient pas
`EN_VALIDATION` / `REJETEE`. Tant que database/09 n'est pas appliqué en
superuser, le statut métier est stocké dans public.offres_statut_workflow.
"""
from __future__ import annotations

from django.db import connection
from django.utils import timezone

_ENUM_CACHE: set[str] | None = None


def enum_labels() -> set[str]:
    global _ENUM_CACHE
    if _ENUM_CACHE is None:
        with connection.cursor() as cur:
            cur.execute(
                """
                SELECT e.enumlabel
                FROM pg_enum e
                JOIN pg_type t ON t.oid = e.enumtypid
                JOIN pg_namespace n ON n.oid = t.typnamespace
                WHERE n.nspname = 'pnlf' AND t.typname = 'statut_offre'
                """
            )
            _ENUM_CACHE = {row[0] for row in cur.fetchall()}
    return _ENUM_CACHE


def enum_supports(label: str) -> bool:
    return label in enum_labels()


def _storage_value(statut: str) -> str:
    if enum_supports(statut):
        return statut
    mapping = {
        'EN_VALIDATION': 'OUVERTE',
        'REJETEE': 'ANNULEE',
        'OUVERTE': 'OUVERTE',
        'CLOTUREE': 'CLOTUREE',
        'ANNULEE': 'ANNULEE',
    }
    return mapping.get(statut, 'OUVERTE')


def set_workflow(offre_id, statut: str) -> None:
    now = timezone.now()
    with connection.cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS offres_statut_workflow (
                offre_id UUID PRIMARY KEY,
                statut VARCHAR(20) NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        cur.execute(
            """
            INSERT INTO offres_statut_workflow (offre_id, statut, updated_at)
            VALUES (%s, %s, %s)
            ON CONFLICT (offre_id) DO UPDATE
            SET statut = EXCLUDED.statut, updated_at = EXCLUDED.updated_at
            """,
            [str(offre_id), statut, now],
        )


def get_workflow(offre_id) -> str | None:
    with connection.cursor() as cur:
        cur.execute(
            'SELECT statut FROM offres_statut_workflow WHERE offre_id = %s',
            [str(offre_id)],
        )
        row = cur.fetchone()
        return row[0] if row else None


def read_statut(offre) -> str:
    workflow = get_workflow(offre.id)
    if workflow:
        return workflow
    return offre.statut


def write_statut(offre, statut: str) -> None:
    """Écrit le statut métier + une valeur compatible avec l'enum SQL."""
    offre.statut = _storage_value(statut)
    offre.updated_at = timezone.now()
    offre.save(update_fields=['statut', 'updated_at'])
    try:
        set_workflow(offre.id, statut)
    except Exception:
        if not enum_supports(statut):
            raise


def published_ids() -> list[str]:
    """Annonces visibles publiquement (validées)."""
    with connection.cursor() as cur:
        cur.execute(
            """
            SELECT o.id::text
            FROM offres_demandes o
            LEFT JOIN offres_statut_workflow w ON w.offre_id = o.id
            WHERE o.statut = 'OUVERTE'
              AND (w.statut IS NULL OR w.statut = 'OUVERTE')
            """
        )
        return [row[0] for row in cur.fetchall()]
