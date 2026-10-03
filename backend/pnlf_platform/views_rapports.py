"""Rapports statistiques intégrés (connexions, présence, inscriptions, filière), exports et visites publiques."""

from __future__ import annotations

import logging

from django.db import transaction
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.appareils import type_appareil
from accounts.audit import request_meta, write_audit
from accounts.permissions import CanExportJournal, CanViewDashboard, scope_lots_qs
from pnlf_platform import statistiques
from pnlf_platform.rapports_export import exporter
from pnlf_platform.views import ExportFileView, _format_export, _pdf_ou_erreur, _uuid_filtre
from traceability.models import Lot

logger = logging.getLogger(__name__)

RAPPORTS_EXPORTABLES = ('connexions', 'en-ligne', 'inscriptions', 'filiere', 'visites')


def recherche(request) -> str | None:
    return (request.query_params.get('q') or '').strip()[:100] or None


def pagination(request, defaut: int = 25, maximum: int = 100) -> tuple[int, int]:
    try:
        page = max(1, int(request.query_params.get('page') or 1))
    except (TypeError, ValueError):
        page = 1
    try:
        taille = min(maximum, max(1, int(request.query_params.get('page_size') or defaut)))
    except (TypeError, ValueError):
        taille = defaut
    return page, taille


def param_succes(request):
    valeur = (request.query_params.get('succes') or '').strip().lower()
    if not valeur:
        return None
    if valeur in ('1', 'true', 'oui'):
        return True
    if valeur in ('0', 'false', 'non'):
        return False
    raise ValidationError({'succes': 'Valeur attendue : 1 (connexions réussies) ou 0 (tentatives échouées).'})


def filtres_inscriptions(request) -> dict:
    params = request.query_params
    return {
        'q': recherche(request),
        'type_demande': (params.get('type_demande') or '').strip().upper() or None,
        'statut': (params.get('statut') or '').strip().upper() or None,
    }


def filiere(request):
    params = request.query_params
    return statistiques.statistiques_filiere(
        statistiques.lire_periode(params), q=recherche(request),
        province=_uuid_filtre(params, 'province'), produit=_uuid_filtre(params, 'produit'),
        lots_qs=scope_lots_qs(Lot.objects.all(), request.user),
    )


class RapportConnexionsView(APIView):
    """Statistiques de connexion et de fréquentation des pages publiques sur une période."""
    permission_classes = [CanExportJournal]

    def get(self, request):
        periode = statistiques.lire_periode(request.query_params)
        donnees = statistiques.statistiques_connexions(periode, recherche(request))
        donnees['visites'] = statistiques.statistiques_visites(periode)
        return Response(donnees)


class RapportConnexionsListeView(APIView):
    """Dernières connexions (réussies ou échouées), adresse IP partiellement masquée."""
    permission_classes = [CanExportJournal]

    def get(self, request):
        periode = statistiques.lire_periode(request.query_params)
        page, taille = pagination(request)
        total, lignes = statistiques.liste_connexions(
            periode, recherche(request), param_succes(request), limit=taille, offset=(page - 1) * taille,
        )
        return Response({'count': total, 'page': page, 'page_size': taille, 'results': lignes})


class RapportEnLigneView(APIView):
    """Utilisateurs en ligne en temps réel (activité dans les 2 dernières minutes)."""
    permission_classes = [CanExportJournal]

    def get(self, request):
        return Response(statistiques.presence_en_ligne())


class RapportInscriptionsView(APIView):
    """Demandes d'inscription reçues, en attente, validées et rejetées, avec délai moyen de traitement."""
    permission_classes = [CanExportJournal]

    def get(self, request):
        periode = statistiques.lire_periode(request.query_params)
        filtres = filtres_inscriptions(request)
        toutes = statistiques.demandes_inscription(periode, q=filtres['q'])
        filtrees = statistiques.demandes_inscription(periode, **filtres)
        page, taille = pagination(request)
        donnees = statistiques.statistiques_inscriptions(periode, toutes)
        donnees.update({
            'count': len(filtrees),
            'page': page,
            'page_size': taille,
            'results': filtrees[(page - 1) * taille: page * taille],
        })
        return Response(donnees)


class RapportFiliereView(APIView):
    """Lots collectés sur la période selon les 3 statuts du cycle, par produit, province et période."""
    permission_classes = [CanViewDashboard]

    def get(self, request):
        return Response(filiere(request))


class ExportRapportView(ExportFileView):
    """Export CSV / XLSX (GET) ou PDF (GET ou POST pour l'aperçu) d'un rapport, avec les filtres de l'écran."""
    permission_classes = [CanExportJournal]

    def get(self, request, rapport: str):
        return self._exporter(request, rapport, _format_export(request))

    def post(self, request, rapport: str):
        return _pdf_ou_erreur(lambda: self._exporter(request, rapport, 'pdf'), 'du rapport')

    def _exporter(self, request, rapport: str, fmt: str):
        from pnlf_platform.rapports_tableaux import construire

        if rapport not in RAPPORTS_EXPORTABLES:
            raise ValidationError({'rapport': 'Rapport inconnu : connexions, en-ligne, inscriptions, filiere ou visites.'})
        tableau = construire(rapport, request)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible=f'rapport_{rapport.replace("-", "_")}',
            ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': fmt, 'filtres': dict(request.query_params.items())},
        )
        return exporter(tableau, fmt, request.user)


class PublicVisiteView(APIView):
    """Compteur anonyme agrégé (page, jour, type d'appareil) des pages publiques : aucune donnée personnelle."""
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        _ip, ua = request_meta(request)
        appareil = type_appareil(ua)
        if appareil != 'ROBOT':
            try:
                with transaction.atomic():
                    statistiques.enregistrer_visite(str(request.data.get('page') or '/'), appareil)
            except Exception:
                logger.exception('Échec de l’enregistrement d’une visite publique')
        return Response(status=status.HTTP_204_NO_CONTENT)
