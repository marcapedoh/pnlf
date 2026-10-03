"""Analyse légère du User-Agent (type d'appareil, système, navigateur) et masquage d'adresse IP.

Les règles sont reprises à l'identique dans l'évolution SQL 16 (reprise de l'historique des connexions).
"""
from __future__ import annotations

import hashlib
import ipaddress
import re

APPAREILS = ('ORDINATEUR', 'MOBILE', 'TABLETTE', 'ROBOT', 'INCONNU')
LIBELLES_APPAREIL = {
    'ORDINATEUR': 'Ordinateur',
    'MOBILE': 'Mobile',
    'TABLETTE': 'Tablette',
    'ROBOT': 'Robot ou script',
    'INCONNU': 'Inconnu',
}

_ROBOT = re.compile(r'bot|crawler|spider|curl|wget|python-requests|httpclient', re.I)
_TABLETTE = re.compile(r'ipad|tablet|kindle|silk', re.I)
_MOBILE = re.compile(r'mobi|iphone|ipod|android|windows phone', re.I)

_SYSTEMES = (
    (re.compile(r'windows phone', re.I), 'Windows Phone'),
    (re.compile(r'windows', re.I), 'Windows'),
    (re.compile(r'android', re.I), 'Android'),
    (re.compile(r'iphone|ipad|ipod', re.I), 'iOS'),
    (re.compile(r'cros', re.I), 'ChromeOS'),
    (re.compile(r'mac os|macintosh', re.I), 'macOS'),
    (re.compile(r'linux', re.I), 'Linux'),
)

_NAVIGATEURS = (
    (re.compile(r'edg(e|a|ios)?/', re.I), 'Edge'),
    (re.compile(r'opr/|opera', re.I), 'Opera'),
    (re.compile(r'samsungbrowser', re.I), 'Samsung Internet'),
    (re.compile(r'(firefox|fxios)/', re.I), 'Firefox'),
    (re.compile(r'(chrome|crios|chromium)/', re.I), 'Chrome'),
    (re.compile(r'safari/', re.I), 'Safari'),
)


def type_appareil(user_agent: str | None) -> str:
    ua = user_agent or ''
    if not ua.strip():
        return 'INCONNU'
    if _ROBOT.search(ua):
        return 'ROBOT'
    if _TABLETTE.search(ua) or (re.search(r'android', ua, re.I) and not re.search(r'mobile', ua, re.I)):
        return 'TABLETTE'
    if _MOBILE.search(ua):
        return 'MOBILE'
    return 'ORDINATEUR'


def _premier(motifs, ua: str) -> str | None:
    for motif, libelle in motifs:
        if motif.search(ua):
            return libelle
    return None


def analyser_user_agent(user_agent: str | None) -> dict:
    ua = (user_agent or '')[:1000]
    return {
        'appareil': type_appareil(ua),
        'systeme': _premier(_SYSTEMES, ua),
        'navigateur': _premier(_NAVIGATEURS, ua),
    }


def empreinte_appareil(user_agent: str | None) -> str:
    """Identifiant stable d'un navigateur (hachage du User-Agent), sans cookie ni stockage côté client."""
    return hashlib.sha256((user_agent or 'inconnu').encode('utf-8', 'ignore')).hexdigest()[:32]


def masquer_ip(ip: str | None) -> str | None:
    """192.168.1.42 -> 192.168.x.x ; 2001:db8:1:2::5 -> 2001:db8:x:x:x:x:x:x."""
    if not ip:
        return None
    try:
        adresse = ipaddress.ip_address(str(ip).split('/')[0])
    except ValueError:
        return None
    if adresse.version == 4:
        octets = str(adresse).split('.')
        return f'{octets[0]}.{octets[1]}.x.x'
    groupes = adresse.exploded.split(':')
    return ':'.join([groupes[0].lstrip('0') or '0', groupes[1].lstrip('0') or '0'] + ['x'] * 6)
