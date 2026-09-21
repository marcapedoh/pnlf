"""Envoi réel d'e-mails et de SMS (inscription publique, validation, mot de passe).

Chaque tentative d'envoi est systématiquement journalisée dans la table
``notifications`` (``type_notif`` EMAIL/SMS, ``envoyee_at`` en cas de succès,
``erreur_envoi`` en cas d'échec ou d'absence de fournisseur configuré) afin de
garder une traçabilité complète, y compris quand aucun fournisseur SMTP/SMS
n'est encore branché.
"""

from __future__ import annotations

import logging
import re
import uuid

from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.utils import timezone

logger = logging.getLogger('pnlf.messaging')


def _log(destinataire_id, type_notif: str, titre: str, corps: str, *, metadata=None, envoyee: bool = False, erreur: str | None = None) -> None:
    if not destinataire_id:
        return
    from pnlf_platform.models import Notification

    Notification.objects.create(
        id=uuid.uuid4(),
        destinataire_id=destinataire_id,
        type_notif=type_notif,
        titre=titre,
        corps=corps,
        metadata=metadata or {},
        envoyee_at=timezone.now() if envoyee else None,
        erreur_envoi=erreur,
        created_at=timezone.now(),
    )


def envoyer_email(
    *,
    destinataire_id=None,
    email: str,
    sujet: str,
    corps_texte: str,
    corps_html: str | None = None,
    metadata: dict | None = None,
) -> bool:
    """Envoie un e-mail transactionnel. Retourne True si l'envoi a réussi."""
    if not email:
        return False
    try:
        message = EmailMultiAlternatives(
            subject=sujet,
            body=corps_texte,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[email],
        )
        if corps_html:
            message.attach_alternative(corps_html, 'text/html')
        message.send(fail_silently=False)
        _log(destinataire_id, 'EMAIL', sujet, corps_texte, metadata=metadata, envoyee=True)
        return True
    except Exception as exc:  # noqa: BLE001 — on journalise toute erreur fournisseur
        logger.warning('Échec envoi email à %s : %s', email, exc)
        _log(destinataire_id, 'EMAIL', sujet, corps_texte, metadata=metadata, erreur=str(exc)[:500])
        return False


def _normaliser_numero_gabon(numero: str) -> str:
    numero = re.sub(r'[\s().-]', '', numero.strip())
    if numero.startswith('+'):
        return numero
    if numero.startswith('00'):
        return f'+{numero[2:]}'
    if numero.startswith('0'):
        return f'+241{numero[1:]}'
    return f'+241{numero}'


def envoyer_sms(
    *,
    destinataire_id=None,
    telephone: str,
    message: str,
    metadata: dict | None = None,
) -> bool:
    """Envoie un SMS via Twilio si configuré. Journalise systématiquement la tentative."""
    if not telephone:
        return False
    numero = _normaliser_numero_gabon(telephone)

    if not (settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN and settings.TWILIO_FROM_NUMBER):
        logger.info('SMS non envoyé (fournisseur non configuré) à %s : %s', numero, message)
        _log(
            destinataire_id, 'SMS', 'SMS', message, metadata=metadata,
            erreur='Fournisseur SMS non configuré (variables TWILIO_* manquantes dans .env).',
        )
        return False

    try:
        from twilio.rest import Client

        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.messages.create(body=message, from_=settings.TWILIO_FROM_NUMBER, to=numero)
        _log(destinataire_id, 'SMS', 'SMS', message, metadata=metadata, envoyee=True)
        return True
    except Exception as exc:  # noqa: BLE001
        logger.warning('Échec envoi SMS à %s : %s', numero, exc)
        _log(destinataire_id, 'SMS', 'SMS', message, metadata=metadata, erreur=str(exc)[:500])
        return False
