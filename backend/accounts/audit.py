"""Journal d'audit applicatif → table pnlf.audit_logs."""

from __future__ import annotations

import ipaddress
import logging
import uuid
from typing import Any

from django.conf import settings
from django.db import connection, transaction

logger = logging.getLogger(__name__)


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
    """Insert append-only dans audit_logs.

    Exécuté dans un point de sauvegarde : un échec est journalisé sans annuler ni casser la
    transaction métier englobante."""
    import json

    try:
        with transaction.atomic(), connection.cursor() as cur:
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
                    json.dumps(anciennes_valeurs, default=str) if anciennes_valeurs is not None else None,
                    json.dumps(nouvelles_valeurs, default=str) if nouvelles_valeurs is not None else None,
                ],
            )
    except Exception:
        logger.exception('Échec écriture audit_logs (action=%s, table=%s)', action, table_cible)


def _ip_valide(valeur: str | None) -> str | None:
    texte = (valeur or '').strip()
    if not texte:
        return None
    try:
        return str(ipaddress.ip_address(texte))
    except ValueError:
        return None


def client_ip(request) -> str | None:
    """IP du client telle que vue par le dernier proxy de confiance.

    Avec ``NUM_PROXIES`` proxys devant l'application, seules les ``NUM_PROXIES`` dernières entrées
    de X-Forwarded-For sont fiables : les précédentes sont fournies par le client lui-même."""
    if request is None:
        return None
    meta = request.META
    num_proxies = settings.REST_FRAMEWORK.get('NUM_PROXIES') or 0
    xff = meta.get('HTTP_X_FORWARDED_FOR')
    if xff and num_proxies > 0:
        adresses = [a.strip() for a in xff.split(',') if a.strip()]
        ip = _ip_valide(adresses[-min(num_proxies, len(adresses))]) if adresses else None
        if ip:
            return ip
    return _ip_valide(meta.get('REMOTE_ADDR'))


def request_meta(request) -> tuple[str | None, str | None]:
    if request is None:
        return None, None
    return client_ip(request), request.META.get('HTTP_USER_AGENT')
