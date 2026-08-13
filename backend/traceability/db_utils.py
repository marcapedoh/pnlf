"""Utilitaires schéma BDD — détection colonnes optionnelles."""

from django.db import connection

_cache: dict[str, bool] = {}


def column_exists(table: str, column: str, schema: str = 'pnlf') -> bool:
    key = f'{schema}.{table}.{column}'
    if key not in _cache:
        with connection.cursor() as cur:
            cur.execute(
                """
                SELECT 1 FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s AND column_name = %s
                """,
                [schema, table, column],
            )
            _cache[key] = cur.fetchone() is not None
    return _cache[key]


def table_exists(table: str, schema: str = 'pnlf') -> bool:
    key = f'{schema}.{table}'
    if key not in _cache:
        with connection.cursor() as cur:
            cur.execute(
                'SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s',
                [schema, table],
            )
            _cache[key] = cur.fetchone() is not None
    return _cache[key]


def get_optional_column(table: str, column: str, pk, default=None):
    """Lit une colonne pas forcément déployée (migration 06+) sans casser l'ORM."""
    if not column_exists(table, column):
        return default
    with connection.cursor() as cur:
        cur.execute(f'SELECT {column} FROM {table} WHERE id = %s', [str(pk)])  # noqa: S608 — colonne validée en amont
        row = cur.fetchone()
        return row[0] if row and row[0] is not None else default


def set_optional_column(table: str, column: str, pk, value) -> bool:
    """Écrit une colonne pas forcément déployée. Retourne False si la migration n'est pas encore appliquée."""
    if not column_exists(table, column):
        return False
    with connection.cursor() as cur:
        cur.execute(f'UPDATE {table} SET {column} = %s WHERE id = %s', [value, str(pk)])  # noqa: S608
    return True
