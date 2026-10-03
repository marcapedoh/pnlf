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


def get_workflows(offre_ids) -> dict[str, str | None]:
    """Statut workflow de plusieurs annonces en une requête (``None`` si aucune ligne)."""
    ids = list(dict.fromkeys(str(i) for i in offre_ids))
    resultat: dict[str, str | None] = dict.fromkeys(ids)
    if ids:
        with connection.cursor() as cur:
            cur.execute(
                'SELECT offre_id::text, statut FROM offres_statut_workflow WHERE offre_id = ANY(%s::uuid[])',
                [ids],
            )
            resultat.update(cur.fetchall())
    return resultat


def read_statut(offre, workflows: dict | None = None) -> str:
    """``workflows`` : résultat préchargé de ``get_workflows`` (listes), sinon lecture unitaire."""
    cle = str(offre.id)
    workflow = workflows[cle] if workflows is not None and cle in workflows else get_workflow(offre.id)
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


_WORKFLOW_PRESENT = False


def _workflow_present() -> bool:
    """Table workflow créée ? (seule la présence est mémorisée : elle peut apparaître en cours de vie)."""
    global _WORKFLOW_PRESENT
    if not _WORKFLOW_PRESENT:
        with connection.cursor() as cur:
            cur.execute("SELECT to_regclass('offres_statut_workflow') IS NOT NULL")
            _WORKFLOW_PRESENT = bool(cur.fetchone()[0])
    return _WORKFLOW_PRESENT


def statuts_par_offre_auteur(auteur_id) -> dict[str, str]:
    """Statut métier (workflow prioritaire) de chaque annonce de l'auteur, en une requête."""
    with connection.cursor() as cur:
        if _workflow_present():
            cur.execute(
                """
                SELECT o.id::text, COALESCE(w.statut, o.statut::text)
                FROM offres_demandes o
                LEFT JOIN offres_statut_workflow w ON w.offre_id = o.id
                WHERE o.auteur_id = %s
                """,
                [str(auteur_id)],
            )
        else:
            cur.execute('SELECT id::text, statut::text FROM offres_demandes WHERE auteur_id = %s', [str(auteur_id)])
        return dict(cur.fetchall())


def ids_par_statut(statut: str) -> list[str]:
    """Identifiants des annonces dont le statut métier (workflow prioritaire) vaut ``statut``."""
    with connection.cursor() as cur:
        if _workflow_present():
            cur.execute(
                """
                SELECT o.id::text
                FROM offres_demandes o
                LEFT JOIN offres_statut_workflow w ON w.offre_id = o.id
                WHERE COALESCE(w.statut, o.statut::text) = %s
                """,
                [statut],
            )
        else:
            cur.execute('SELECT id::text FROM offres_demandes WHERE statut::text = %s', [statut])
        return [row[0] for row in cur.fetchall()]


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
