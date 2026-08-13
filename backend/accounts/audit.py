"""Journal d'audit applicatif → table pnlf.audit_logs."""

from __future__ import annotations

import uuid
from typing import Any

from django.db import connection


def write_audit(
    *,
    utilisateur_id: uuid.UUID | str | None,
    action: str,
    table_cible: str | None = None,
    enregistrement_id: uuid.UUID | str | None = None,
    ip_adresse: str | None = None,
    user_agent: str | None = None,
    anciennes_valeurs: dict[str, Any] | None = None,
    nouvelles_valeurs: dict[str, Any] | None = None,
) -> None:
    """Insert append-only dans audit_logs (ignore les échecs pour ne pas casser le flux métier)."""
    import json

    try:
        with connection.cursor() as cur:
            cur.execute(
                """
                INSERT INTO audit_logs (
                    utilisateur_id, action, table_cible, enregistrement_id,
                    ip_adresse, user_agent, anciennes_valeurs, nouvelles_valeurs
                ) VALUES (
                    %s, %s, %s, %s,
                    %s::inet, %s, %s::jsonb, %s::jsonb
                )
                """,
                [
                    str(utilisateur_id) if utilisateur_id else None,
                    action[:50],
                    table_cible,
                    str(enregistrement_id) if enregistrement_id else None,
                    ip_adresse,
                    (user_agent or '')[:2000] or None,
                    json.dumps(anciennes_valeurs) if anciennes_valeurs is not None else None,
                    json.dumps(nouvelles_valeurs) if nouvelles_valeurs is not None else None,
                ],
            )
    except Exception:
        # Ne jamais faire échouer la requête métier pour un problème d'audit
        pass


def request_meta(request) -> tuple[str | None, str | None]:
    ip = None
    if request is not None:
        xff = request.META.get('HTTP_X_FORWARDED_FOR')
        if xff:
            ip = xff.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        ua = request.META.get('HTTP_USER_AGENT')
        return ip, ua
    return None, None
