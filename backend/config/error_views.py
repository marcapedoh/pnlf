"""Réponses d'erreur JSON uniformes pour l'API PNLF-PFNL.

Ces vues sont utilisées par Django comme gestionnaires globaux (handler400,
handler403, handler404, handler500) pour toute requête qui ne serait pas
prise en charge par un ViewSet DRF (ex : URL totalement inconnue, en-tête
hôte invalide, erreur non interceptée). En production (DEBUG=False), sans
cela, Django afficherait une page HTML technique peu appropriée pour une API.
"""

from __future__ import annotations

from django.http import JsonResponse


def bad_request(request, exception=None, *args, **kwargs):
    return JsonResponse(
        {
            'detail': "Requête invalide. Vérifiez les paramètres envoyés au serveur.",
            'code': 'bad_request',
        },
        status=400,
    )


def permission_denied(request, exception=None, *args, **kwargs):
    return JsonResponse(
        {
            'detail': "Vous n'avez pas les droits nécessaires pour accéder à cette ressource.",
            'code': 'permission_denied',
        },
        status=403,
    )


def not_found(request, exception=None, *args, **kwargs):
    return JsonResponse(
        {
            'detail': "La ressource demandée est introuvable.",
            'code': 'not_found',
        },
        status=404,
    )


def server_error(request, *args, **kwargs):
    return JsonResponse(
        {
            'detail': "Une erreur interne est survenue. L'équipe technique a été notifiée.",
            'code': 'server_error',
        },
        status=500,
    )
