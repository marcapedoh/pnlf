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
