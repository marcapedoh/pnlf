"""Gestionnaire d'exceptions DRF : messages d'erreur 100 % en français, clairs et explicatifs.

Conserve le format DRF (``{"champ": ["message"]}``, ``{"detail": "...", "code": "..."}``) et les codes
applicatifs (``password_change_required``, ``token_not_valid``...) attendus par le frontend.
"""
from __future__ import annotations

import logging
import re

from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.http import Http404
from rest_framework import exceptions, status
from rest_framework.response import Response
from rest_framework.views import exception_handler, set_rollback

logger = logging.getLogger('pfnl.api')

MESSAGE_ERREUR_INTERNE = (
    'Une erreur interne est survenue sur le serveur. Réessayez dans quelques instants ; '
    'si le problème persiste, contactez l’assistance de la plateforme.'
)

MESSAGES_PAR_CODE = {
    'not_authenticated': 'Vous devez être connecté pour accéder à cette ressource. Connectez-vous puis réessayez.',
    'authentication_failed': 'Authentification impossible : vos identifiants de session ne sont pas valides. '
                             'Reconnectez-vous.',
    'token_not_valid': 'Votre session a expiré ou n’est plus valide. Reconnectez-vous pour continuer.',
    'user_not_found': 'Le compte associé à cette session est introuvable. Reconnectez-vous.',
    'user_inactive': 'Ce compte est inactif ou suspendu. Contactez l’École Nationale des Eaux et Forêts.',
    'password_changed': 'Votre mot de passe a été modifié : reconnectez-vous avec le nouveau mot de passe.',
    'permission_denied': 'Vous n’avez pas les droits nécessaires pour effectuer cette action.',
    'not_found': 'L’élément demandé est introuvable. Il a peut-être été supprimé ou vous n’y avez pas accès.',
    'method_not_allowed': 'Cette opération n’est pas autorisée sur cette ressource.',
    'not_acceptable': 'Le format de réponse demandé n’est pas pris en charge par le serveur.',
    'unsupported_media_type': 'Le format des données envoyées n’est pas pris en charge.',
    'parse_error': 'Les données envoyées sont mal formées. Rechargez la page puis réessayez.',
}

# Messages DRF / Django / SimpleJWT restés en anglais (ou peu explicites) : remplacés à l'identique.
TRADUCTIONS = {
    'This field is required.': 'Ce champ est obligatoire.',
    'This field may not be blank.': 'Ce champ ne peut pas être vide.',
    'This field may not be null.': 'Ce champ est obligatoire.',
    'Enter a valid email address.': 'Saisissez une adresse e-mail valide.',
    'A valid integer is required.': 'Saisissez un nombre entier valide.',
    'A valid number is required.': 'Saisissez un nombre valide.',
    'Must be a valid UUID.': 'Identifiant invalide.',
    'Must be a valid boolean.': 'Valeur invalide : oui ou non attendu.',
    'Not a valid string.': 'Texte invalide.',
    'Invalid data. Expected a dictionary, but got {datatype}.': 'Données invalides.',
    'Not found.': MESSAGES_PAR_CODE['not_found'],
    'Authentication credentials were not provided.': MESSAGES_PAR_CODE['not_authenticated'],
    'Incorrect authentication credentials.': MESSAGES_PAR_CODE['authentication_failed'],
    'You do not have permission to perform this action.': MESSAGES_PAR_CODE['permission_denied'],
    'Token is invalid or expired': MESSAGES_PAR_CODE['token_not_valid'],
    'Token is invalid': MESSAGES_PAR_CODE['token_not_valid'],
    'Token is expired': MESSAGES_PAR_CODE['token_not_valid'],
    'Given token not valid for any token type': MESSAGES_PAR_CODE['token_not_valid'],
    'User not found': MESSAGES_PAR_CODE['user_not_found'],
    'User is inactive': MESSAGES_PAR_CODE['user_inactive'],
    'Invalid page.': 'Cette page de résultats n’existe pas. Revenez à la première page.',
    'Page non valide.': 'Cette page de résultats n’existe pas. Revenez à la première page.',
    # Messages internes de PnlfJWTAuthentication
    'Jeton sans user_id': MESSAGES_PAR_CODE['token_not_valid'],
    'Utilisateur introuvable': MESSAGES_PAR_CODE['user_not_found'],
    'Compte inactif': MESSAGES_PAR_CODE['user_inactive'],
    'Session révoquée': MESSAGES_PAR_CODE['password_changed'],
    'Session révoquée.': MESSAGES_PAR_CODE['password_changed'],
}

_MOTIFS = (
    (re.compile(r'^No .+ matches the given query\.?$'), MESSAGES_PAR_CODE['not_found']),
    (re.compile(r'^JSON parse error'), MESSAGES_PAR_CODE['parse_error']),
    (re.compile(r'^Method "(\w+)" not allowed\.?$'), MESSAGES_PAR_CODE['method_not_allowed']),
    (re.compile(r'^Méthode « ?\w+ ?» non autorisée\.?$'), MESSAGES_PAR_CODE['method_not_allowed']),
    (re.compile(r'^Unsupported media type'), MESSAGES_PAR_CODE['unsupported_media_type']),
    (re.compile(r'^Ensure this field has no more than (\d+) characters\.?$'),
     lambda m: f'Ce texte est trop long ({m.group(1)} caractères maximum).'),
    (re.compile(r'^Ensure this value is greater than or equal to ([\d.,-]+)\.?$'),
     lambda m: f'La valeur doit être supérieure ou égale à {m.group(1)}.'),
    (re.compile(r'^Ensure this value is less than or equal to ([\d.,-]+)\.?$'),
     lambda m: f'La valeur doit être inférieure ou égale à {m.group(1)}.'),
    (re.compile(r'^"(.+)" is not a valid choice\.?$'), lambda m: f'« {m.group(1)} » n’est pas un choix valide.'),
    (re.compile(r'^Date has wrong format\.'), 'Date invalide (format attendu : AAAA-MM-JJ).'),
    (re.compile(r'^Datetime has wrong format\.'), 'Date et heure invalides.'),
    (re.compile(r'^The submitted data was not a file\.'), 'Aucun fichier valide n’a été reçu.'),
    (re.compile(r'^The submitted file is empty\.?$'), 'Le fichier envoyé est vide.'),
    (re.compile(r'^Upload a valid image\.'), 'Le fichier envoyé n’est pas une image valide.'),
    (re.compile(r'^Expected a list of items'), 'Une liste de valeurs est attendue.'),
)


def _duree(secondes: int) -> str:
    if secondes < 60:
        return f'{secondes} seconde{"s" if secondes > 1 else ""}'
    minutes = -(-secondes // 60)
    return f'{minutes} minute{"s" if minutes > 1 else ""}'


def traduire(message: str) -> str:
    texte = str(message)
    if texte in TRADUCTIONS:
        return TRADUCTIONS[texte]
    for motif, remplacement in _MOTIFS:
        correspondance = motif.match(texte)
        if correspondance:
            return remplacement(correspondance) if callable(remplacement) else remplacement
    return texte


def _traduire_donnees(donnees):
    if isinstance(donnees, dict):
        return {cle: _traduire_donnees(valeur) for cle, valeur in donnees.items() if cle != 'messages'}
    if isinstance(donnees, list):
        return [_traduire_donnees(valeur) for valeur in donnees]
    if isinstance(donnees, exceptions.ErrorDetail):
        return exceptions.ErrorDetail(traduire(donnees), code=donnees.code)
    if isinstance(donnees, str):
        return traduire(donnees)
    return donnees


def _code_principal(exc) -> str | None:
    codes = exc.get_codes() if isinstance(exc, exceptions.APIException) else None
    if isinstance(codes, str):
        return codes
    if isinstance(codes, dict) and isinstance(codes.get('code'), str):
        return codes['code']
    if isinstance(codes, dict) and isinstance(codes.get('detail'), str):
        return codes['detail']
    return None


def gestionnaire_exceptions(exc, context):
    if isinstance(exc, Http404):
        exc = exceptions.NotFound()
    elif isinstance(exc, DjangoPermissionDenied):
        exc = exceptions.PermissionDenied()

    response = exception_handler(exc, context)
    if response is None:
        set_rollback()
        vue = context.get('view')
        logger.exception('Erreur non gérée dans %s', type(vue).__name__ if vue else 'une vue API', exc_info=exc)
        return Response(
            {'detail': MESSAGE_ERREUR_INTERNE, 'code': 'server_error'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    donnees = _traduire_donnees(response.data)
    code = _code_principal(exc)

    if isinstance(exc, exceptions.Throttled):
        attente = int(exc.wait or 0)
        detail = 'Trop de requêtes en peu de temps : par sécurité, cette action est momentanément bloquée.'
        if attente > 0:
            detail += f' Réessayez dans {_duree(attente)}.'
        donnees = {'detail': detail, 'code': 'throttled', 'attente_secondes': attente}
    elif isinstance(donnees, dict) and isinstance(donnees.get('detail'), str):
        if code in MESSAGES_PAR_CODE and (code in CODES_TOUJOURS_GENERIQUES or _est_generique(donnees['detail'])):
            donnees['detail'] = MESSAGES_PAR_CODE[code]
        if code in MESSAGES_PAR_CODE and 'code' not in donnees:
            donnees['code'] = code
    elif isinstance(donnees, list):
        donnees = {'non_field_errors': donnees}

    response.data = donnees
    return response


# Détails techniques du framework jamais utiles à l'utilisateur.
CODES_TOUJOURS_GENERIQUES = {'parse_error', 'method_not_allowed', 'unsupported_media_type', 'not_acceptable'}

# Messages génériques du framework (déjà traduits par Django) remplacés par une explication plus utile.
_MESSAGES_GENERIQUES = {
    "Informations d'authentification non fournies.",
    "Informations d'authentification incorrectes.",
    "Vous n'avez pas la permission d'effectuer cette action.",
    'Pas trouvé.',
    'Non trouvé.',
    "Le type de jeton fourni n'est pas valide",
    'Le jeton est invalide ou expiré',
    'Le jeton a expiré',
    'Utilisateur non trouvé',
    "L'utilisateur est désactivé",
}


def _est_generique(detail: str) -> bool:
    # Seuls les messages génériques par code sont normalisés : une traduction dédiée (ex. page inexistante) est gardée.
    return detail in _MESSAGES_GENERIQUES or detail in MESSAGES_PAR_CODE.values()
