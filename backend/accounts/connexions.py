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
}


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
