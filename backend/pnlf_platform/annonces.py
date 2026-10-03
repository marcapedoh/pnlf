"""Annonces (offres et demandes) : détails complémentaires, profil public de l'auteur, trace de modération."""

from __future__ import annotations

from django.utils import timezone

from accounts.models import Utilisateur

PHOTOS_OFFRE_MAX = 4

MODES_REMISE = {
    'LIVRAISON': 'Livraison par le vendeur',
    'RETRAIT': 'Retrait sur place',
    'LIVRAISON_OU_RETRAIT': 'Livraison ou retrait',
}
MOYENS_PAIEMENT = {
    'ESPECES': 'Espèces',
    'MOBILE_MONEY': 'Mobile Money (Airtel Money, Moov Money)',
    'VIREMENT': 'Virement bancaire',
    'CHEQUE': 'Chèque',
    'A_LA_LIVRAISON': 'Paiement à la livraison',
    'ACOMPTE': 'Acompte à la commande',
}
CHAMPS_DETAILS = (
    'categorie_id', 'prix_total', 'negociable', 'conditionnement', 'qualite', 'localite',
    'disponible_du', 'mode_remise', 'modalites_livraison', 'moyens_paiement', 'conditions_paiement',
    'afficher_telephone', 'afficher_email',
)
ROLES_MODERATION = (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE)

LIBELLES_TYPE_ACTEUR = {
    'PRODUCTEUR': 'Producteur',
    'COLLECTEUR': 'Collecteur',
    'RECOLTEUR': 'Récolteur',
}
LIBELLES_ROLE_PUBLIC = {
    Utilisateur.Role.COOPERATIVE: 'Coopérative',
    Utilisateur.Role.ACHETEUR: 'Acheteur',
    Utilisateur.Role.PRODUCTEUR: 'Producteur',
    Utilisateur.Role.ADMINISTRATEUR: 'Administration de la plateforme',
    Utilisateur.Role.AGENT_MINISTERE: 'Ministère des Eaux et Forêts',
    Utilisateur.Role.AGENT_FORESTIER: 'Administration forestière',
}


def details_de(offre):
    from pnlf_platform.models import OffreDetails

    try:
        return offre.details
    except OffreDetails.DoesNotExist:
        return None


def enregistrer_details(offre, valeurs: dict) -> None:
    """Crée ou met à jour la ligne public.offres_details de l'annonce (seuls les champs fournis changent)."""
    from pnlf_platform.models import OffreDetails

    if not valeurs:
        return
    details = details_de(offre)
    if details is None:
        details = OffreDetails(offre=offre)
    for champ, valeur in valeurs.items():
        setattr(details, champ, valeur)
    if details.categorie_id is None:
        from traceability.models import Produit

        details.categorie_id = Produit.objects.filter(pk=offre.produit_id).values_list('categorie_id', flat=True).first()
    details.updated_at = timezone.now()
    details.save()
    offre.details = details


def enregistrer_moderation(offre, *, decision: str, moderateur, motif: str | None = None) -> None:
    from pnlf_platform.models import OffreModeration

    OffreModeration.objects.update_or_create(
        offre=offre,
        defaults={
            'decision': decision,
            'moderateur_id': moderateur.id,
            'moderateur_nom': moderateur.get_full_name() or moderateur.email,
            'motif': motif or None,
            'decide_at': timezone.now(),
        },
    )


def _producteur_certifie(producteur_id) -> bool:
    from django.db.models import Q

    from traceability.models import Certification

    aujourd_hui = timezone.localdate()
    return Certification.objects.filter(
        Q(date_expiration__isnull=True) | Q(date_expiration__gte=aujourd_hui),
        producteur_id=producteur_id, statut='OBTENUE',
    ).exists()


def profil_auteur(auteur_id, request=None, cache: dict | None = None) -> dict | None:
    """Informations PUBLIQUES de l'auteur d'une annonce (aucune coordonnée, aucun identifiant interne)."""
    cle = str(auteur_id)
    if cache is not None and cle in cache:
        return cache[cle]
    from traceability.db_utils import get_optional_column
    from traceability.models import Cooperative, Producteur
    from traceability.services import photo_url

    user = Utilisateur.objects.filter(pk=auteur_id).first()
    if user is None:
        profil = None
    else:
        profil = {
            'nom': user.get_full_name() or 'Membre de la plateforme',
            'type_acteur': LIBELLES_ROLE_PUBLIC.get(user.role, 'Membre'),
            'province': None,
            'photo_url': photo_url('utilisateurs', user.id, request),
            'membre_depuis': user.created_at.date().isoformat() if user.created_at else None,
            'certifie': False,
            'fiche_publique_id': None,
        }
        if user.role == Utilisateur.Role.COOPERATIVE:
            coop = Cooperative.objects.select_related('province').filter(utilisateur_id=user.id).first()
            if coop is not None:
                profil['nom'] = coop.nom
                profil['province'] = coop.province.nom if coop.province_id else None
                profil['photo_url'] = profil['photo_url'] or photo_url('cooperatives', coop.id, request)
        elif user.role == Utilisateur.Role.PRODUCTEUR:
            fiche = (
                Producteur.objects.select_related('province')
                .filter(utilisateur_id=user.id, deleted_at__isnull=True).first()
            )
            if fiche is not None:
                type_acteur = get_optional_column('producteurs', 'type_acteur', fiche.id) or 'PRODUCTEUR'
                profil['type_acteur'] = LIBELLES_TYPE_ACTEUR.get(str(type_acteur), 'Producteur')
                profil['province'] = fiche.province.nom if fiche.province_id else None
                profil['photo_url'] = profil['photo_url'] or photo_url('producteurs', fiche.id, request)
                profil['certifie'] = _producteur_certifie(fiche.id)
                visible = get_optional_column('producteurs', 'visible_public', fiche.id)
                if fiche.statut == 'ACTIF' and visible is not False:
                    profil['fiche_publique_id'] = str(fiche.id)
    if cache is not None:
        cache[cle] = profil
    return profil


def contact_auteur(offre, details, cache: dict | None = None) -> dict:
    """Coordonnées que l'auteur a choisi d'afficher sur son annonce."""
    contact = {'telephone': None, 'email': None}
    if details is None or not (details.afficher_telephone or details.afficher_email):
        return contact
    cle = f'contact:{offre.auteur_id}'
    if cache is not None and cle in cache:
        user = cache[cle]
    else:
        user = Utilisateur.objects.filter(pk=offre.auteur_id).only('telephone', 'email').first()
        if cache is not None:
            cache[cle] = user
    if user is None:
        return contact
    if details.afficher_telephone:
        contact['telephone'] = user.telephone or None
    if details.afficher_email:
        contact['email'] = user.email
    return contact


def moderation_visible(offre, user) -> dict | None:
    """Décision de modération : réservée aux modérateurs et à l'auteur, jamais publique."""
    from pnlf_platform.models import OffreModeration

    if user is None or not getattr(user, 'is_authenticated', False):
        return None
    if user.role not in ROLES_MODERATION and str(offre.auteur_id) != str(user.id):
        return None
    try:
        moderation = offre.moderation
    except OffreModeration.DoesNotExist:
        return None
    return {
        'decision': moderation.decision,
        'moderateur_nom': moderation.moderateur_nom,
        'decide_at': moderation.decide_at,
        'motif': moderation.motif,
    }
