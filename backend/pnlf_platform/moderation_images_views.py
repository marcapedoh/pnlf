"""File de modération des images douteuses (super administrateur) : consultation, approbation, rejet."""

from __future__ import annotations

import logging
import uuid
from pathlib import Path

from django.conf import settings
from django.db import transaction
from django.utils import timezone
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from accounts.audit import request_meta, write_audit
from accounts.models import Utilisateur
from accounts.permissions import IsAdmin
from config import media_store
from config.media_views import build_moderation_url
from config.moderation_images import APPROUVEE, EN_ATTENTE, REJETEE, REMPLACEE

from .models import Message, MessagePiece, ModerationImage, OffreDemande
from .services import creer_notification

logger = logging.getLogger(__name__)

TYPES_LIBELLES = {
    'PRODUCTEUR': 'Photo de producteur ou collecteur',
    'COOPERATIVE': 'Photo de coopérative',
    'LOT': 'Photo de lot',
    'OFFRE': 'Photo d’annonce',
    'PRODUIT': 'Photo de produit (référentiel)',
    'UTILISATEUR': 'Photo de profil',
    'MESSAGE': 'Image envoyée en messagerie',
    'DOCUMENT_INSCRIPTION': 'Document d’inscription',
    'CERTIFICATION': 'Justificatif de certification',
    'AUTRE': 'Autre image',
}

# Fiche liée à la notification envoyée à l'auteur (voir notification-target.util.ts côté front).
_TABLES_NOTIFICATION = {
    'PRODUCTEUR': 'producteurs',
    'COOPERATIVE': 'cooperatives',
    'LOT': 'lots',
    'OFFRE': 'offres_demandes',
}

MOTIF_MIN = 5
MOTIF_MAX = 500


def _nom(user: Utilisateur | None) -> str | None:
    if not user:
        return None
    return f'{user.prenoms} {user.nom}'.strip() or user.email


_DOSSIERS_INSCRIPTION = {'producteurs': 'PRODUCTEUR', 'cooperatives': 'COOPERATIVE', 'utilisateurs': 'UTILISATEUR'}


def _cible(m: ModerationImage) -> tuple[str | None, uuid.UUID | None]:
    """Fiche à présenter : un document d'inscription renvoie à la fiche inscrite."""
    if m.type_objet == 'DOCUMENT_INSCRIPTION':
        dossier = (m.chemin.split('/') + ['', '', ''])[2]
        return _DOSSIERS_INSCRIPTION.get(dossier), m.objet_id
    return m.type_objet, m.objet_id


def _contextes(lignes: list[ModerationImage]) -> dict:
    """Libellé et route front de l'objet concerné, résolus par lot de requêtes (pas de N+1)."""
    from traceability.models import Certification, Cooperative, Lot, Producteur, Produit

    ids: dict[str, set] = {}
    for m in lignes:
        genre, objet_id = _cible(m)
        if genre and objet_id:
            ids.setdefault(genre, set()).add(objet_id)
    resultat: dict = {}
    for p in Producteur.objects.filter(id__in=ids.get('PRODUCTEUR', set())):
        resultat[('PRODUCTEUR', p.id)] = (f'{p.prenoms} {p.nom} ({p.code_producteur})', ['/app/producteurs', str(p.id)])
    for c in Cooperative.objects.filter(id__in=ids.get('COOPERATIVE', set())):
        resultat[('COOPERATIVE', c.id)] = (c.nom, ['/app/cooperatives', str(c.id)])
    for lot in Lot.objects.filter(id__in=ids.get('LOT', set())):
        resultat[('LOT', lot.id)] = (f'Lot {lot.code_lot}', ['/app/lots', str(lot.id)])
    for o in OffreDemande.objects.filter(id__in=ids.get('OFFRE', set())):
        resultat[('OFFRE', o.id)] = (o.titre, ['/app/marketplace/offres', str(o.id)])
    for p in Produit.objects.filter(id__in=ids.get('PRODUIT', set())):
        resultat[('PRODUIT', p.id)] = (p.nom, None)
    for u in Utilisateur.objects.filter(id__in=ids.get('UTILISATEUR', set())):
        resultat[('UTILISATEUR', u.id)] = (_nom(u), ['/app/utilisateurs', str(u.id)])
    for c in Certification.objects.filter(id__in=ids.get('CERTIFICATION', set())).select_related(
        'type_certification', 'producteur',
    ):
        titulaire = f' : {c.producteur.prenoms} {c.producteur.nom}' if c.producteur_id else ''
        resultat[('CERTIFICATION', c.id)] = (f'{c.type_certification.libelle}{titulaire}', ['/app/certifications'])
    for msg in Message.objects.filter(id__in=ids.get('MESSAGE', set())).select_related('conversation'):
        resultat[('MESSAGE', msg.id)] = (f'Discussion « {msg.conversation.sujet or "sans sujet"} »', None)
    return resultat


def _serialiser(lignes: list[ModerationImage], request) -> list[dict]:
    contextes = _contextes(lignes)
    user_ids = {m.envoye_par_id for m in lignes if m.envoye_par_id} | {m.traite_par_id for m in lignes if m.traite_par_id}
    users = {u.id: u for u in Utilisateur.objects.filter(id__in=user_ids)}
    donnees = []
    for m in lignes:
        libelle, route = contextes.get(_cible(m), (None, None))
        auteur = users.get(m.envoye_par_id)
        visible = m.statut in (EN_ATTENTE, APPROUVEE) and (Path(settings.MEDIA_ROOT) / m.chemin).is_file()
        donnees.append({
            'id': str(m.id),
            'chemin': m.chemin,
            'type_objet': m.type_objet,
            'type_objet_libelle': TYPES_LIBELLES.get(m.type_objet, TYPES_LIBELLES['AUTRE']),
            'objet_id': str(m.objet_id) if m.objet_id else None,
            'objet_libelle': libelle,
            'objet_route': route,
            'envoye_par': {
                'id': str(auteur.id), 'nom': _nom(auteur), 'email': auteur.email, 'role': auteur.role,
            } if auteur else None,
            'verdict': m.verdict,
            'score_nsfw': float(m.score_nsfw) if m.score_nsfw is not None else None,
            'scores': m.scores or {},
            'statut': m.statut,
            'statut_libelle': ModerationImage.Statut(m.statut).label,
            'motif': m.motif,
            'traite_par_nom': _nom(users.get(m.traite_par_id)),
            'traite_at': m.traite_at,
            'created_at': m.created_at,
            'apercu_url': build_moderation_url(m.chemin, request) if visible else None,
        })
    return donnees


def _clore_images_disparues() -> None:
    """Une image en attente dont le fichier a été remplacé ou supprimé sort de la file."""
    maintenant = timezone.now()
    for m in ModerationImage.objects.filter(statut=EN_ATTENTE).only('id', 'chemin'):
        if not media_store.assurer_local(m.chemin):
            ModerationImage.objects.filter(pk=m.pk, statut=EN_ATTENTE).update(statut=REMPLACEE, traite_at=maintenant)


def compter_en_attente() -> int:
    return ModerationImage.objects.filter(statut=EN_ATTENTE).count()


def _nettoyer_objet(m: ModerationImage) -> None:
    """Retire l'image rejetée des données qui la référencent (les photos sont résolues par leur fichier)."""
    from traceability.models import Certification, DocumentInscription, PieceCertification

    from .chat import PLACEHOLDER_PHOTO

    if m.type_objet == 'DOCUMENT_INSCRIPTION':
        DocumentInscription.objects.filter(chemin=m.chemin).delete()
    elif m.type_objet == 'CERTIFICATION':
        Certification.objects.filter(document_path=m.chemin).update(document_path=None, updated_at=timezone.now())
        PieceCertification.objects.filter(chemin=m.chemin).delete()
    elif m.type_objet == 'MESSAGE':
        MessagePiece.objects.filter(piece_path=m.chemin).delete()
        if m.objet_id:
            Message.objects.filter(pk=m.objet_id, contenu=PLACEHOLDER_PHOTO).update(
                contenu='Photo retirée par un administrateur (contenu inapproprié).',
            )


def _supprimer_fichier(rel: str) -> None:
    try:
        (Path(settings.MEDIA_ROOT) / rel).unlink(missing_ok=True)
    except OSError:
        logger.exception('Image rejetée non supprimée du disque local : %s', rel)
    media_store.supprimer(rel)


def _notifier_auteur(m: ModerationImage, titre: str, corps: str) -> None:
    if not m.envoye_par_id:
        return
    metadata = {'type': 'MODERATION_IMAGE', 'statut': m.statut}
    table = _TABLES_NOTIFICATION.get(m.type_objet)
    if table and m.objet_id:
        metadata.update(table_cible=table, enregistrement_id=str(m.objet_id))
    creer_notification(m.envoye_par_id, titre, corps, metadata=metadata)


class ModerationImageViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """GET /api/moderation-images/?statut=EN_ATTENTE|TRAITEES ; actions approuver / rejeter."""

    permission_classes = [IsAdmin]
    queryset = ModerationImage.objects.all()
    filter_backends: list = []

    def get_queryset(self):
        statut = (self.request.query_params.get('statut') or EN_ATTENTE).upper()
        if statut == EN_ATTENTE:
            return ModerationImage.objects.filter(statut=EN_ATTENTE).order_by('created_at')
        if statut in (APPROUVEE, REJETEE, REMPLACEE):
            return ModerationImage.objects.filter(statut=statut).order_by('-traite_at')
        if statut == 'TRAITEES':
            return ModerationImage.objects.exclude(statut=EN_ATTENTE).order_by('-traite_at')
        raise ValidationError({'statut': 'Filtre inconnu. Valeurs acceptées : EN_ATTENTE, TRAITEES, APPROUVEE, REJETEE.'})

    def list(self, request, *args, **kwargs):
        if (request.query_params.get('statut') or EN_ATTENTE).upper() == EN_ATTENTE:
            _clore_images_disparues()
        page = self.paginate_queryset(self.get_queryset())
        return self.get_paginated_response(_serialiser(list(page), request))

    @action(detail=False, methods=['get'])
    def compteur(self, request):
        return Response({'en_attente': compter_en_attente()})

    def _ligne_en_attente(self, pk) -> ModerationImage:
        try:
            pk = uuid.UUID(str(pk))
        except ValueError:
            raise ValidationError({'detail': 'Image introuvable.'})
        m = ModerationImage.objects.select_for_update().filter(pk=pk).first()
        if m is None:
            raise ValidationError({'detail': 'Image introuvable.'})
        if m.statut != EN_ATTENTE:
            raise ValidationError({
                'detail': f'Cette image a déjà été traitée (statut « {ModerationImage.Statut(m.statut).label} »).',
            })
        return m

    @action(detail=True, methods=['post'])
    def approuver(self, request, pk=None):
        with transaction.atomic():
            m = self._ligne_en_attente(pk)
            m.statut, m.traite_par_id, m.traite_at = APPROUVEE, request.user.id, timezone.now()
            m.save(update_fields=['statut', 'traite_par_id', 'traite_at'])
            _notifier_auteur(
                m, 'Image validée',
                f'Votre image ({TYPES_LIBELLES.get(m.type_objet, "image").lower()}) a été vérifiée par un '
                'administrateur : elle est désormais visible.',
            )
            ip, ua = request_meta(request)
            write_audit(
                utilisateur_id=request.user.id, action='MODERATION_IMAGE_APPROUVEE', table_cible='moderation_images',
                enregistrement_id=m.id, ip_adresse=ip, user_agent=ua,
                nouvelles_valeurs={'chemin': m.chemin, 'type_objet': m.type_objet, 'score_nsfw': m.score_nsfw},
            )
        return Response(_serialiser([m], request)[0])

    @action(detail=True, methods=['post'])
    def rejeter(self, request, pk=None):
        motif = ' '.join(str(request.data.get('motif') or '').split())
        if len(motif) < MOTIF_MIN:
            raise ValidationError({'motif': f'Indiquez le motif du rejet ({MOTIF_MIN} caractères minimum) : il sera communiqué à l’auteur.'})
        if len(motif) > MOTIF_MAX:
            raise ValidationError({'motif': f'Le motif ne peut pas dépasser {MOTIF_MAX} caractères.'})
        with transaction.atomic():
            m = self._ligne_en_attente(pk)
            m.statut, m.motif, m.traite_par_id, m.traite_at = REJETEE, motif, request.user.id, timezone.now()
            m.save(update_fields=['statut', 'motif', 'traite_par_id', 'traite_at'])
            _nettoyer_objet(m)
            _notifier_auteur(
                m, 'Image retirée',
                f'Votre image ({TYPES_LIBELLES.get(m.type_objet, "image").lower()}) a été retirée par un '
                f'administrateur. Motif : {motif.rstrip(".")}. Vous pouvez envoyer une autre image.',
            )
            ip, ua = request_meta(request)
            write_audit(
                utilisateur_id=request.user.id, action='MODERATION_IMAGE_REJETEE', table_cible='moderation_images',
                enregistrement_id=m.id, ip_adresse=ip, user_agent=ua,
                nouvelles_valeurs={'chemin': m.chemin, 'type_objet': m.type_objet, 'motif': motif},
            )
            chemin = m.chemin
            transaction.on_commit(lambda: _supprimer_fichier(chemin))
        return Response(_serialiser([m], request)[0])
