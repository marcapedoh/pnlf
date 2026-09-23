"""Utilitaires JWT PFNL."""

from __future__ import annotations

import hashlib


def password_fingerprint(user) -> str:
    raw = (getattr(user, 'mot_de_passe_hash', None) or '').encode('utf-8')
    return hashlib.sha256(raw).hexdigest()[:24]
