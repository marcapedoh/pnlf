"""Indicateurs du tableau de bord par rôle.

Chaque compteur est calculé avec le même périmètre que la liste vers laquelle il renvoie
(scope_lots_qs, scope_producteurs_qs, file « À traiter »), pour que les chiffres concordent.
"""

from __future__ import annotations

from datetime import datetime, time

from django.db.models import Count, Q
from django.utils import timezone

from accounts.models import Utilisateur
from accounts.permissions import scope_lots_qs, scope_producteurs_qs

R = Utilisateur.Role
ROLES_AGENTS = (R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER)
ROLES_PILOTAGE = (R.ADMINISTRATEUR, R.AGENT_MINISTERE)

STATUTS_LOT = ('BROUILLON', 'VALIDE', 'COMMERCIALISE')
LIBELLES_STATUT_LOT = {'BROUILLON': 'Brouillon', 'VALIDE': 'Validé', 'COMMERCIALISE': 'Commercialisé'}
LIBELLES_CERTIFICATION = {
    'DEMANDEE': 'Demandée',
    'EN_COURS': 'En cours d’instruction',
    'OBTENUE': 'Obtenue',
    'REFUSEE': 'Refusée',
    'EXPIREE': 'Expirée',
    'SUSPENDUE': 'Suspendue',
    'RETIREE': 'Retirée',
    'REVOQUEE': 'Révoquée',
}
LIBELLES_FICHE = {'EN_VALIDATION': 'En attente de validation', 'ACTIF': 'Active', 'INACTIF': 'Inactive', 'REJETE': 'Rejetée'}
STATUTS_ANNONCE = ('EN_VALIDATION', 'OUVERTE', 'REJETEE', 'CLOTUREE')
LIBELLES_ANNONCE = {
    'EN_VALIDATION': 'En attente de validation',
    'OUVERTE': 'Publiées',
    'REJETEE': 'Rejetées',
    'CLOTUREE': 'Clôturées',
}

# Qui peut traiter quoi : doit rester aligné sur les permissions des actions correspondantes.
DROITS_A_TRAITER = {
    'producteurs': ROLES_AGENTS,
    'cooperatives': ROLES_PILOTAGE,
    'certifications': (R.ADMINISTRATEUR,),
    'lots': ROLES_AGENTS,
    'offres': ROLES_PILOTAGE,
    'acheteurs': ROLES_PILOTAGE,
    'images': (R.ADMINISTRATEUR,),
}


def _repartition(compteurs: dict, statuts, libelles: dict) -> list[dict]:
    return [{'cle': s, 'libelle': libelles.get(s, s), 'nombre': int(compteurs.get(s, 0))} for s in statuts]


def lots_par_statut(qs) -> dict:
    compteurs = dict(qs.values_list('statut').annotate(n=Count('id')).values_list('statut', 'n'))
    return {
        'total': sum(compteurs.get(s, 0) for s in STATUTS_LOT),
        'par_statut': _repartition(compteurs, STATUTS_LOT, LIBELLES_STATUT_LOT),
    }


def _lots_visibles(user):
    from traceability.models import Lot

    return scope_lots_qs(Lot.objects.filter(deleted_at__isnull=True), user)


def _certifications_visibles(user):
    from traceability.models import Certification, Cooperative

    qs = Certification.objects.all()
    if user.role in ROLES_AGENTS:
        return qs
    if user.role == R.COOPERATIVE:
        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(Q(lot__cooperative_id__in=coop_ids) | Q(producteur__cooperative_id__in=coop_ids))
    if user.role == R.PRODUCTEUR:
        return qs.filter(producteur__utilisateur_id=user.id)
    return qs.none()


def certifications_par_statut(qs) -> dict:
    compteurs = dict(qs.values_list('statut').annotate(n=Count('id')).values_list('statut', 'n'))
    aujourd_hui = timezone.localdate()
    valides = qs.filter(statut='OBTENUE').filter(
        Q(date_expiration__isnull=True) | Q(date_expiration__gte=aujourd_hui)
    ).count()
    statuts = [s for s in LIBELLES_CERTIFICATION if compteurs.get(s)] or ['DEMANDEE', 'EN_COURS', 'OBTENUE']
    return {
        'total': sum(compteurs.values()),
        'valides': valides,
        'en_instruction': int(compteurs.get('DEMANDEE', 0) + compteurs.get('EN_COURS', 0)),
        'par_statut': _repartition(compteurs, statuts, LIBELLES_CERTIFICATION),
    }


def messages_non_lus(user) -> dict:
    """Même calcul que le badge de la messagerie (messages reçus après la dernière lecture)."""
    from pnlf_platform.models import ConversationParticipantMeta, Message
    from pnlf_platform.views import _conversation_queryset

    conv_ids = list(_conversation_queryset(user).values_list('id', flat=True))
    lectures = dict(
        ConversationParticipantMeta.objects.filter(conversation_id__in=conv_ids, utilisateur_id=user.id)
        .values_list('conversation_id', 'last_read_at')
    )
    total = 0
    fils = 0
    for conv_id in conv_ids:
        qs = Message.objects.filter(conversation_id=conv_id).exclude(expediteur_id=user.id)
        if lectures.get(conv_id):
            qs = qs.filter(created_at__gt=lectures[conv_id])
        n = qs.count()
        total += n
        fils += 1 if n else 0
    return {'non_lus': total, 'conversations_non_lues': fils, 'conversations': len(conv_ids)}


def annonces_de(user) -> dict:
    from pnlf_platform.models import OffreDemande
    from pnlf_platform.offre_statut import ids_par_statut

    mes_ids = set(str(i) for i in OffreDemande.objects.filter(auteur_id=user.id).values_list('id', flat=True))
    compteurs = {s: len(mes_ids.intersection(ids_par_statut(s))) for s in STATUTS_ANNONCE} if mes_ids else {}
    return {'total': len(mes_ids), 'par_statut': _repartition(compteurs, STATUTS_ANNONCE, LIBELLES_ANNONCE)}


def annonces_marche() -> dict:
    """Annonces visibles par tous les connectés : publiées et non expirées (comme la liste)."""
    from pnlf_platform.models import OffreDemande
    from pnlf_platform.offre_statut import ids_par_statut

    qs = OffreDemande.objects.filter(id__in=ids_par_statut('OUVERTE')).filter(
        Q(expire_at__isnull=True) | Q(expire_at__gt=timezone.now())
    )
    compteurs = dict(qs.values_list('type_annonce').annotate(n=Count('id')).values_list('type_annonce', 'n'))
    return {'offres': int(compteurs.get('OFFRE', 0)), 'demandes': int(compteurs.get('DEMANDE', 0))}


def file_a_traiter(user, *, limite: int = 20) -> dict:
    """File « À traiter » : seules les sections que le profil peut réellement traiter sont comptées."""
    from pnlf_platform.models import OffreDemande
    from pnlf_platform.offre_statut import ids_par_statut
    from traceability.models import Certification, Cooperative, Lot, Producteur

    def autorise(section: str) -> bool:
        return user.role in DROITS_A_TRAITER[section]

    sections = {}

    qs = Producteur.objects.filter(deleted_at__isnull=True, statut='EN_VALIDATION')
    sections['producteurs'] = (qs, lambda q: list(
        q.order_by('-created_at').values('id', 'nom', 'prenoms', 'code_producteur', 'created_at')[:limite]
    ))
    qs = Cooperative.objects.filter(statut='EN_VALIDATION')
    sections['cooperatives'] = (qs, lambda q: list(q.order_by('-created_at').values('id', 'nom', 'code', 'created_at')[:limite]))
    qs = Certification.objects.filter(statut__in=('DEMANDEE', 'EN_COURS'))
    sections['certifications'] = (qs, lambda q: [
        {
            'id': c.id,
            'type_libelle': c.type_certification.libelle if c.type_certification_id else None,
            'producteur_nom': f'{c.producteur.prenoms} {c.producteur.nom}'.strip() if c.producteur_id else None,
            'statut': c.statut,
            'nb_pieces': c.nb_pieces,
            'created_at': c.created_at,
        }
        for c in q.select_related('type_certification', 'producteur').annotate(nb_pieces=Count('pieces'))
        .order_by('-created_at')[:limite]
    ])
    qs = Lot.objects.filter(
        deleted_at__isnull=True, statut='BROUILLON', producteur__statut='ACTIF', producteur__deleted_at__isnull=True,
    )
    sections['lots'] = (qs, lambda q: [
        {
            'id': lot.id,
            'code_lot': lot.code_lot,
            'produit_nom': lot.produit.nom if lot.produit_id else None,
            'producteur_nom': f'{lot.producteur.prenoms} {lot.producteur.nom}'.strip(),
            'quantite': lot.quantite,
            'unite': lot.unite,
            'created_at': lot.created_at,
        }
        for lot in q.select_related('produit', 'producteur').order_by('created_at')[:limite]
    ])
    qs = OffreDemande.objects.filter(id__in=ids_par_statut('EN_VALIDATION'))
    sections['offres'] = (qs, lambda q: [
        {**o, 'statut': 'EN_VALIDATION'}
        for o in q.order_by('-created_at').values('id', 'titre', 'type_annonce', 'created_at')[:limite]
    ])
    qs = Utilisateur.objects.filter(deleted_at__isnull=True, statut=Utilisateur.Statut.EN_ATTENTE, role=R.ACHETEUR)
    sections['acheteurs'] = (qs, lambda q: list(
        q.order_by('-created_at').values('id', 'nom', 'prenoms', 'email', 'created_at')[:limite]
    ))
    from pnlf_platform.models import ModerationImage
    from pnlf_platform.moderation_images_views import TYPES_LIBELLES

    qs = ModerationImage.objects.filter(statut='EN_ATTENTE')
    sections['images'] = (qs, lambda q: [
        {'id': m['id'], 'type_libelle': TYPES_LIBELLES.get(m['type_objet'], TYPES_LIBELLES['AUTRE']),
         'created_at': m['created_at']}
        for m in q.order_by('created_at').values('id', 'type_objet', 'created_at')[:limite]
    ])

    resultat = {}
    for nom, (qs, lister) in sections.items():
        if autorise(nom):
            resultat[nom] = {'autorise': True, 'count': qs.count(), 'results': lister(qs) if limite else []}
        else:
            resultat[nom] = {'autorise': False, 'count': 0, 'results': []}
    resultat['total'] = sum(bloc['count'] for bloc in resultat.values())
    return resultat


def _activite_temps_reel() -> dict:
    from django.db import connection

    from accounts.connexions import seuil_en_ligne

    debut_jour = timezone.make_aware(datetime.combine(timezone.localdate(), time.min))
    with connection.cursor() as cur:
        cur.execute(
            """
            SELECT
                (SELECT COUNT(DISTINCT p.utilisateur_id) FROM presences p
                   JOIN utilisateurs u ON u.id = p.utilisateur_id AND u.deleted_at IS NULL
                  WHERE p.derniere_activite >= %s),
                (SELECT COUNT(*) FROM presences p
                   JOIN utilisateurs u ON u.id = p.utilisateur_id AND u.deleted_at IS NULL
                  WHERE p.derniere_activite >= %s),
                (SELECT COUNT(*) FROM connexions WHERE succes AND created_at >= %s),
                (SELECT COUNT(DISTINCT utilisateur_id) FROM connexions WHERE succes AND created_at >= %s),
                (SELECT COUNT(*) FROM connexions WHERE NOT succes AND created_at >= %s),
                (SELECT COALESCE(SUM(visites), 0) FROM visites_publiques WHERE jour = %s)
            """,
            [seuil_en_ligne(), seuil_en_ligne(), debut_jour, debut_jour, debut_jour, timezone.localdate()],
        )
        en_ligne, appareils, connexions, utilisateurs, echecs, visites = cur.fetchone()
    return {
        'en_ligne': en_ligne,
        'appareils_en_ligne': appareils,
        'connexions_jour': connexions,
        'utilisateurs_jour': utilisateurs,
        'echecs_jour': echecs,
        'visites_jour': int(visites),
    }


def resume(user) -> dict:
    from pnlf_platform.models import Notification
    from traceability.models import Cooperative, CooperativeMembre, InvitationCooperative, Producteur

    donnees: dict = {
        'role': user.role,
        'role_libelle': dict(R.choices).get(user.role, user.role),
        'genere_at': timezone.now().isoformat(),
        'messages': messages_non_lus(user),
        'notifications_non_lues': Notification.objects.filter(
            destinataire_id=user.id, type_notif='INTERNE', lue=False,
        ).count(),
        'annonces': {'miennes': annonces_de(user), 'marche': annonces_marche()},
    }

    if user.role in ROLES_AGENTS:
        donnees['a_traiter'] = {
            nom: {'autorise': bloc['autorise'], 'count': bloc['count']}
            for nom, bloc in file_a_traiter(user, limite=0).items() if nom != 'total'
        }
        donnees['a_traiter_total'] = sum(b['count'] for b in donnees['a_traiter'].values())
        donnees['lots'] = lots_par_statut(_lots_visibles(user))
        producteurs = scope_producteurs_qs(Producteur.objects.filter(deleted_at__isnull=True), user)
        compteurs = dict(producteurs.values_list('statut').annotate(n=Count('id')).values_list('statut', 'n'))
        donnees['producteurs'] = {
            'total': sum(compteurs.values()),
            'par_statut': _repartition(compteurs, ('ACTIF', 'EN_VALIDATION', 'INACTIF', 'REJETE'), LIBELLES_FICHE),
        }
        compteurs = dict(Cooperative.objects.values_list('statut').annotate(n=Count('id')).values_list('statut', 'n'))
        donnees['cooperatives'] = {
            'total': sum(compteurs.values()),
            'par_statut': _repartition(compteurs, ('ACTIF', 'EN_VALIDATION', 'INACTIF', 'REJETE'), LIBELLES_FICHE),
        }
        donnees['certifications'] = certifications_par_statut(_certifications_visibles(user))
        if user.role in ROLES_PILOTAGE:
            donnees['activite'] = _activite_temps_reel()
        return donnees

    if user.role == R.PRODUCTEUR:
        fiche = Producteur.objects.filter(utilisateur_id=user.id, deleted_at__isnull=True).select_related('cooperative').first()
        donnees['fiche'] = None if fiche is None else {
            'id': str(fiche.id),
            'statut': fiche.statut,
            'statut_libelle': LIBELLES_FICHE.get(fiche.statut, fiche.statut),
            'cooperative': fiche.cooperative.nom if fiche.cooperative_id else None,
            'cooperative_id': str(fiche.cooperative_id) if fiche.cooperative_id else None,
        }
        donnees['lots'] = lots_par_statut(_lots_visibles(user))
        donnees['certifications'] = certifications_par_statut(_certifications_visibles(user))
        donnees['cooperative'] = {
            'invitations_recues': InvitationCooperative.objects.filter(
                producteur=fiche, statut=InvitationCooperative.Statut.EN_ATTENTE,
            ).count() if fiche else 0,
            'adhesion_en_attente': CooperativeMembre.objects.filter(producteur=fiche, actif=False).exists() if fiche else False,
        }
        return donnees

    if user.role == R.COOPERATIVE:
        coop = Cooperative.objects.filter(utilisateur_id=user.id).first()
        donnees['fiche'] = None if coop is None else {
            'id': str(coop.id),
            'nom': coop.nom,
            'statut': coop.statut,
            'statut_libelle': LIBELLES_FICHE.get(coop.statut, coop.statut),
        }
        donnees['lots'] = lots_par_statut(_lots_visibles(user))
        donnees['certifications'] = certifications_par_statut(_certifications_visibles(user))
        donnees['cooperative'] = {
            'membres_actifs': CooperativeMembre.objects.filter(
                cooperative=coop, actif=True, producteur__deleted_at__isnull=True,
            ).count() if coop else 0,
            'demandes_adhesion': CooperativeMembre.objects.filter(
                cooperative=coop, actif=False, producteur__deleted_at__isnull=True,
            ).count() if coop else 0,
            'invitations_en_attente': InvitationCooperative.objects.filter(
                cooperative=coop, statut=InvitationCooperative.Statut.EN_ATTENTE,
            ).count() if coop else 0,
        }
        return donnees

    if user.role == R.ACHETEUR:
        donnees['lots_disponibles'] = _lots_visibles(user).count()
    return donnees
