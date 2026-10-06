"""Suivi des connexions et de la présence en temps réel (statistiques intégrées, sans cookie tiers)."""

from __future__ import annotations

import logging
from datetime import timedelta

from django.db import connection, transaction
from django.utils import timezone

from .appareils import analyser_user_agent, empreinte_appareil
from .audit import request_meta

logger = logging.getLogger(__name__)

# Un utilisateur est « en ligne » si son dernier signal date de moins de 2 minutes.
DELAI_EN_LIGNE = timedelta(minutes=2)
# Les présences plus anciennes sont purgées au fil de l'eau.
DELAI_PURGE_PRESENCE = timedelta(days=1)

MOTIFS_ECHEC = {
    'IDENTIFIANTS': 'Identifiants invalides',
    'VERROUILLE': 'Compte verrouillé',
    'EN_ATTENTE': 'Compte en attente de validation',
    'INACTIF': 'Compte inactif ou suspendu',
    'BLOQUE_IP': 'Trop de tentatives, attente imposée',
}

# Après LIMITE_ECHECS_IP échecs rapprochés depuis une même adresse IP, toute tentative de connexion
# est refusée pendant DUREE_BLOCAGE_IP, quel que soit le compte visé.
LIMITE_ECHECS_IP = 3
DUREE_BLOCAGE_IP = timedelta(minutes=5)
# Les tentatives refusées pendant l'attente ne prolongent pas le blocage.
_MOTIFS_COMPTES_IP = ('IDENTIFIANTS', 'VERROUILLE')


def etat_tentatives_ip(ip: str | None) -> tuple[int, int]:
    """(secondes d'attente restantes, tentatives encore permises) pour une adresse IP.

    Une série d'échecs s'arrête à la dernière connexion réussie de l'adresse ou dès que deux échecs
    consécutifs sont espacés de plus de DUREE_BLOCAGE_IP : un blocage écoulé rend donc 3 essais."""
    if not ip:
        return 0, LIMITE_ECHECS_IP
    maintenant = timezone.now()
    try:
        with connection.cursor() as cur:
            cur.execute(
                """
                SELECT c.created_at
                FROM connexions c
                WHERE c.ip_adresse = %s::inet
                  AND NOT c.succes
                  AND c.motif_echec = ANY(%s)
                  AND c.created_at > %s
                  AND c.created_at > COALESCE(
                      (SELECT MAX(s.created_at) FROM connexions s WHERE s.ip_adresse = %s::inet AND s.succes),
                      '-infinity'::timestamptz
                  )
                ORDER BY c.created_at DESC
                LIMIT %s
                """,
                [ip, list(_MOTIFS_COMPTES_IP), maintenant - 2 * DUREE_BLOCAGE_IP, ip, LIMITE_ECHECS_IP],
            )
            dates = [ligne[0] for ligne in cur.fetchall()]
    except Exception:
        logger.exception('Lecture des tentatives de connexion impossible')
        return 0, LIMITE_ECHECS_IP

    if not dates or maintenant - dates[0] > DUREE_BLOCAGE_IP:
        return 0, LIMITE_ECHECS_IP
    serie = 1
    while serie < len(dates) and dates[serie - 1] - dates[serie] <= DUREE_BLOCAGE_IP:
        serie += 1
    if serie >= LIMITE_ECHECS_IP:
        attente = (dates[0] + DUREE_BLOCAGE_IP - maintenant).total_seconds()
        return max(1, int(attente + 0.999)), 0
    return 0, LIMITE_ECHECS_IP - serie


def enregistrer_connexion(request, *, succes: bool, utilisateur=None, email: str | None = None,
                          motif_echec: str | None = None) -> None:
    """Trace une tentative de connexion. N'interrompt jamais l'authentification en cas d'échec."""
    ip, ua = request_meta(request)
    infos = analyser_user_agent(ua)
    try:
        with transaction.atomic(), connection.cursor() as cur:
            cur.execute(
                """
                INSERT INTO connexions (
                    utilisateur_id, email_saisi, role, succes, motif_echec, ip_adresse,
                    appareil, systeme, navigateur, empreinte_appareil, created_at
                ) VALUES (%s, %s, %s, %s, %s, %s::inet, %s, %s, %s, %s, %s)
                """,
                [
                    str(utilisateur.id) if utilisateur is not None else None,
                    (email or getattr(utilisateur, 'email', None) or '')[:254] or None,
                    getattr(utilisateur, 'role', None),
                    succes,
                    motif_echec,
                    ip,
                    infos['appareil'],
                    infos['systeme'],
                    infos['navigateur'],
                    empreinte_appareil(ua),
                    timezone.now(),
                ],
            )
    except Exception:
        logger.exception('Échec de l’enregistrement de la connexion')
    if succes and utilisateur is not None:
        signaler_presence(request, utilisateur)


def signaler_presence(request, utilisateur) -> None:
    """Met à jour la présence de l'utilisateur sur l'appareil courant (heartbeat)."""
    ip, ua = request_meta(request)
    infos = analyser_user_agent(ua)
    maintenant = timezone.now()
    try:
        with transaction.atomic(), connection.cursor() as cur:
            cur.execute(
                """
                INSERT INTO presences (
                    utilisateur_id, empreinte_appareil, appareil, systeme, navigateur,
                    ip_adresse, debut_at, derniere_activite
                ) VALUES (%s, %s, %s, %s, %s, %s::inet, %s, %s)
                ON CONFLICT (utilisateur_id, empreinte_appareil) DO UPDATE SET
                    ip_adresse = EXCLUDED.ip_adresse,
                    debut_at = CASE
                        WHEN presences.derniere_activite < %s THEN EXCLUDED.debut_at
                        ELSE presences.debut_at
                    END,
                    derniere_activite = EXCLUDED.derniere_activite
                """,
                [
                    str(utilisateur.id), empreinte_appareil(ua), infos['appareil'], infos['systeme'],
                    infos['navigateur'], ip, maintenant, maintenant, maintenant - DELAI_EN_LIGNE,
                ],
            )
            cur.execute('DELETE FROM presences WHERE derniere_activite < %s', [maintenant - DELAI_PURGE_PRESENCE])
    except Exception:
        logger.exception('Échec de la mise à jour de la présence')


def retirer_presence(request, utilisateur) -> None:
    """Déconnexion : l'appareil courant n'est plus compté comme en ligne."""
    _ip, ua = request_meta(request)
    try:
        with transaction.atomic(), connection.cursor() as cur:
            cur.execute(
                'DELETE FROM presences WHERE utilisateur_id = %s AND empreinte_appareil = %s',
                [str(utilisateur.id), empreinte_appareil(ua)],
            )
    except Exception:
        logger.exception('Échec du retrait de la présence')


def seuil_en_ligne():
    return timezone.now() - DELAI_EN_LIGNE
