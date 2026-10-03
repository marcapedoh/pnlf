"""Services métier traçabilité : workflow lots, QR, mouvements."""

from __future__ import annotations

import io
from pathlib import Path

from django.conf import settings
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from config import media_store

from .models import Certification, Lot, LotTransition, Mouvement

# Cycle de vie d'un lot : trois statuts seulement (les autres valeurs de l'énumération SQL
# pnlf.statut_lot ne sont plus utilisées, voir l'évolution 15).
STATUTS_LOT = ('BROUILLON', 'VALIDE', 'COMMERCIALISE')

STATUT_LIBELLES = {
    'BROUILLON': 'Brouillon',
    'VALIDE': 'Validé',
    'COMMERCIALISE': 'Commercialisé',
}

TRANSITIONS_LOT: dict[str, tuple[str, ...]] = {
    'BROUILLON': ('VALIDE',),
    'VALIDE': ('COMMERCIALISE',),
    'COMMERCIALISE': (),
}

# Lots vérifiables par QR code : un lot commercialisé reste vérifiable par l'acheteur final.
STATUTS_LOT_VERIFIABLES = ('VALIDE', 'COMMERCIALISE')
# Lots présentés dans les listes, fiches et compteurs publics.
STATUTS_LOT_PUBLICS = ('VALIDE',)

TYPES_MOUVEMENT = {
    'COLLECTE', 'RECEPTION_COOPERATIVE', 'TRANSFERT', 'TRANSFORMATION',
    'CONTROLE', 'VENTE', 'EXPORT', 'AUTRE',
}

TYPES_MOUVEMENT_LIBELLES = {
    'COLLECTE': 'Collecte',
    'RECEPTION_COOPERATIVE': 'Réception par la coopérative',
    'TRANSFERT': 'Transport',
    'TRANSFORMATION': 'Transformation',
    'CONTROLE': 'Contrôle',
    'VENTE': 'Vente',
    'EXPORT': 'Exportation',
    'AUTRE': 'Autre étape',
}

# Seules étapes ayant un effet sur le statut : une vente ou une exportation commercialise le lot.
TYPES_MOUVEMENT_COMMERCIALISATION = ('VENTE', 'EXPORT')

ROLE_LIBELLES_GENERIQUES = {
    'ADMINISTRATEUR': 'Administration PFNL',
    'AGENT_MINISTERE': 'Agent du ministère',
    'AGENT_FORESTIER': 'Agent forestier',
    'COOPERATIVE': 'Coopérative',
    'PRODUCTEUR': 'Producteur',
    'ACHETEUR': 'Acheteur',
}

TYPE_ACTEUR_LIBELLES = {
    'PRODUCTEUR': 'Producteur',
    'COLLECTEUR': 'Collecteur',
    'RECOLTEUR': 'Récolteur',
}

UNITES_MESURE = ('KG', 'G', 'LITRE', 'ML', 'UNITE', 'BOTTE', 'SAC', 'M3', 'METRE')

ROLES_AGENTS = ('ADMINISTRATEUR', 'AGENT_MINISTERE', 'AGENT_FORESTIER')

TYPES_MOUVEMENT_PAR_ROLE: dict[str, set[str]] = {
    'ADMINISTRATEUR': set(TYPES_MOUVEMENT),
    'AGENT_MINISTERE': set(TYPES_MOUVEMENT),
    'AGENT_FORESTIER': set(TYPES_MOUVEMENT),
    'COOPERATIVE': {'RECEPTION_COOPERATIVE', 'TRANSFERT', 'TRANSFORMATION', 'VENTE', 'EXPORT', 'AUTRE'},
    'PRODUCTEUR': {'TRANSFERT', 'TRANSFORMATION', 'VENTE', 'EXPORT', 'AUTRE'},
}

# Titulaire (producteur, coopérative) : modification et suppression tant que le lot n'est pas validé.
STATUTS_LOT_MODIFIABLES = ('BROUILLON',)
# Autorités : correction possible jusqu'à la commercialisation ; un lot commercialisé est figé
# (son QR code doit rester vérifiable par l'acheteur final).
STATUTS_LOT_MODIFIABLES_AGENT = ('BROUILLON', 'VALIDE')


def libelle_statut_lot(statut: str) -> str:
    return STATUT_LIBELLES.get(statut, statut)


def libelle_type_acteur(type_acteur: str | None) -> str:
    return TYPE_ACTEUR_LIBELLES.get((type_acteur or 'PRODUCTEUR').upper(), 'Producteur')


def type_acteur_producteur(producteur) -> str:
    from .db_utils import get_optional_column

    return get_optional_column('producteurs', 'type_acteur', producteur.id, default='PRODUCTEUR') or 'PRODUCTEUR'


def _cooperatives_gerees(user) -> set:
    from .models import Cooperative

    return set(Cooperative.objects.filter(utilisateur_id=getattr(user, 'id', None)).values_list('id', flat=True))


def est_titulaire_lot(user, lot: Lot) -> bool:
    """Producteur du lot, ou coopérative à laquelle le lot ou son producteur est rattaché."""
    role = getattr(user, 'role', None)
    if role == 'PRODUCTEUR':
        return bool(lot.producteur_id and lot.producteur.utilisateur_id == user.id)
    if role == 'COOPERATIVE':
        coops = _cooperatives_gerees(user)
        return bool(coops) and (
            lot.cooperative_id in coops or (lot.producteur_id and lot.producteur.cooperative_id in coops)
        )
    return False


def certifications_actives_qs(lot: Lot):
    """Certifications obtenues et non expirées du producteur du lot ou du lot lui-même.

    Le modèle de données ne porte pas de certification propre aux coopératives : pour un lot
    géré par une coopérative, c'est la certification du producteur du lot qui compte.
    """
    from django.db.models import Q

    aujourd_hui = timezone.localdate()
    return (
        Certification.objects.filter(Q(producteur_id=lot.producteur_id) | Q(lot_id=lot.id), statut='OBTENUE')
        .filter(Q(date_expiration__isnull=True) | Q(date_expiration__gte=aujourd_hui))
        .select_related('type_certification')
    )


def droits_lot(user, lot: Lot) -> dict:
    """Actions possibles sur un lot pour l'utilisateur, avec l'explication d'un éventuel refus."""
    role = getattr(user, 'role', None)
    agent = role in ROLES_AGENTS
    titulaire = est_titulaire_lot(user, lot)
    certifie = titulaire and lot.statut == 'BROUILLON' and certifications_actives_qs(lot).exists()
    motif = None
    if lot.statut == 'BROUILLON' and titulaire and not certifie:
        if role == 'COOPERATIVE':
            motif = (
                'La validation de ce lot revient à un agent du ministère, un agent forestier ou à '
                "l'administration. Pour valider vous-même les lots de vos membres, le producteur "
                'concerné doit détenir une certification active (demande depuis le menu Certifications).'
            )
        else:
            motif = (
                'La validation de ce lot revient à un agent du ministère, un agent forestier ou à '
                "l'administration. Pour valider vous-même vos lots, obtenez une certification active "
                '(demande depuis le menu Certifications).'
            )
    statuts_modifiables = STATUTS_LOT_MODIFIABLES_AGENT if agent else STATUTS_LOT_MODIFIABLES
    gestionnaire = agent or titulaire
    return {
        'peut_valider': lot.statut == 'BROUILLON' and (agent or certifie),
        'mode_validation': 'AGENT' if agent else ('AUTO' if certifie else None),
        'motif_validation': motif,
        'peut_commercialiser': lot.statut == 'VALIDE' and gestionnaire,
        'peut_modifier': gestionnaire and lot.statut in statuts_modifiables,
        'peut_supprimer': gestionnaire and lot.statut in statuts_modifiables,
        'peut_ajouter_etape': gestionnaire and role in TYPES_MOUVEMENT_PAR_ROLE,
    }


def _journaliser_transition(lot: Lot, ancien: str, user, mode: str, motif: str | None = None) -> None:
    LotTransition.objects.create(
        lot=lot, ancien_statut=ancien, nouveau_statut=lot.statut, mode=mode,
        role_auteur=getattr(user, 'role', None), auteur_id=getattr(user, 'id', None),
        motif=motif, created_at=timezone.now(),
    )


def valider_lot(lot: Lot, user) -> str:
    """Passe un lot BROUILLON au statut VALIDE. Retourne le mode de validation (AGENT ou AUTO)."""
    if lot.statut != 'BROUILLON':
        raise ValidationError({
            'statut': f'Seul un lot en brouillon peut être validé (statut actuel : « {libelle_statut_lot(lot.statut)} »).',
        })
    droits = droits_lot(user, lot)
    if not droits['peut_valider']:
        from rest_framework.exceptions import PermissionDenied

        raise PermissionDenied(droits['motif_validation'] or 'Vous n’êtes pas habilité à valider ce lot.')
    if lot.producteur.statut != 'ACTIF' or lot.producteur.deleted_at is not None:
        raise ValidationError({
            'statut': 'La fiche du producteur de ce lot doit être active pour que le lot soit validé.',
        })
    now = timezone.now()
    lot.statut = 'VALIDE'
    lot.valide_par_id = user.id
    lot.valide_at = now
    lot.updated_at = now
    lot.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'updated_at'])
    _journaliser_transition(lot, 'BROUILLON', user, droits['mode_validation'])
    return droits['mode_validation']


def commercialiser_lot(lot: Lot, user, *, motif: str | None = None) -> None:
    """Passe un lot VALIDE au statut COMMERCIALISE (titulaire ou autorité)."""
    if lot.statut != 'VALIDE':
        if lot.statut == 'BROUILLON':
            message = 'Le lot doit d’abord être validé avant d’être commercialisé.'
        else:
            message = 'Ce lot est déjà commercialisé.'
        raise ValidationError({'statut': message})
    if not droits_lot(user, lot)['peut_commercialiser']:
        from rest_framework.exceptions import PermissionDenied

        raise PermissionDenied(
            'Seuls le producteur, la coopérative titulaire du lot ou une autorité peuvent le déclarer commercialisé.'
        )
    lot.statut = 'COMMERCIALISE'
    lot.updated_at = timezone.now()
    lot.save(update_fields=['statut', 'updated_at'])
    mode = 'AGENT' if getattr(user, 'role', None) in ROLES_AGENTS else 'PROPRIETAIRE'
    _journaliser_transition(lot, 'VALIDE', user, mode, motif)


def valider_type_mouvement(type_mouvement: str) -> str:
    t = (type_mouvement or '').upper()
    if t not in TYPES_MOUVEMENT:
        valeurs = ', '.join(TYPES_MOUVEMENT_LIBELLES[k] for k in sorted(TYPES_MOUVEMENT))
        raise ValidationError({'type_mouvement': f'Type de mouvement inconnu. Valeurs acceptées : {valeurs}.'})
    return t


def valider_type_mouvement_pour_role(type_mouvement: str, role: str | None) -> None:
    autorises = TYPES_MOUVEMENT_PAR_ROLE.get(role or '', set())
    if type_mouvement not in autorises:
        libelle = TYPES_MOUVEMENT_LIBELLES.get(type_mouvement, type_mouvement)
        raise ValidationError({
            'type_mouvement': f'Votre profil ne permet pas d’enregistrer une étape « {libelle} ».',
        })


def verifier_mouvement_compatible(lot: Lot, type_mouvement: str) -> None:
    """Toutes les étapes sont acceptées, sauf la vente ou l'exportation d'un lot non validé."""
    if type_mouvement in TYPES_MOUVEMENT_COMMERCIALISATION and lot.statut == 'BROUILLON':
        libelle = TYPES_MOUVEMENT_LIBELLES[type_mouvement].lower()
        raise ValidationError({
            'type_mouvement': f'Le lot doit être validé avant toute {libelle}.',
        })


def appliquer_mouvement_sur_lot(lot: Lot, type_mouvement: str, user) -> bool:
    """Une vente ou une exportation commercialise un lot validé. Retourne True si le statut change."""
    if type_mouvement not in TYPES_MOUVEMENT_COMMERCIALISATION or lot.statut != 'VALIDE':
        return False
    commercialiser_lot(lot, user, motif=f'Étape « {TYPES_MOUVEMENT_LIBELLES[type_mouvement]} » enregistrée.')
    return True


def _role_par_utilisateur(ids) -> dict:
    from accounts.models import Utilisateur

    ids = {i for i in ids if i}
    if not ids:
        return {}
    return dict(Utilisateur.objects.filter(id__in=ids).values_list('id', 'role'))


def libelle_validation(mode: str | None, role: str | None, type_acteur: str | None = None) -> str:
    """Autorité de validation exprimée sans aucune donnée personnelle de l'agent."""
    if mode == 'AUTO':
        if role == 'COOPERATIVE':
            return 'Auto-validé par la coopérative (producteur certifié)'
        return f'Auto-validé ({libelle_type_acteur(type_acteur).lower()} certifié)'
    return {
        'AGENT_MINISTERE': 'Validé par un agent du ministère',
        'AGENT_FORESTIER': 'Validé par un agent forestier',
        'ADMINISTRATEUR': "Validé par l'administration PFNL",
    }.get(role or '', 'Validé par une autorité habilitée')


def _gps_arrondi(valeur):
    """Position arrondie (environ 1 km) : la parcelle exacte n'est pas diffusée publiquement."""
    return round(valeur, 2) if valeur is not None else None


def validation_lot(lot: Lot, transitions=None, roles=None) -> dict | None:
    """Date et autorité de validation (journal des transitions, à défaut colonnes du lot)."""
    if lot.statut not in STATUTS_LOT_VERIFIABLES:
        return None
    transitions = list(lot.transitions.all()) if transitions is None else transitions
    t = next((t for t in transitions if t.nouveau_statut == 'VALIDE' and t.mode in ('AGENT', 'AUTO')), None)
    type_acteur = type_acteur_producteur(lot.producteur)
    if t is not None:
        return {
            'date': t.created_at, 'mode': t.mode, 'role': t.role_auteur,
            'libelle': libelle_validation(t.mode, t.role_auteur, type_acteur),
        }
    roles = _role_par_utilisateur([lot.valide_par_id]) if roles is None else roles
    role = roles.get(lot.valide_par_id)
    mode = 'AUTO' if role in ('PRODUCTEUR', 'COOPERATIVE') else ('AGENT' if role else None)
    return {'date': lot.valide_at, 'mode': mode, 'role': role, 'libelle': libelle_validation(mode, role, type_acteur)}


def construire_frise_lot(lot: Lot, *, public: bool) -> list[dict]:
    """Frise chronologique complète : collecte, déclaration, étapes, validation, commercialisation.

    En mode public, aucun commentaire, destinataire ni identité d'acteur n'est exposé : l'acteur
    est désigné par son rôle (producteur, coopérative, agent forestier...).
    """
    from datetime import datetime, time, timedelta

    mouvements = list(lot.mouvements.all().order_by('date_mouvement', 'created_at'))
    transitions = list(lot.transitions.all())
    roles = _role_par_utilisateur(
        [m.acteur_utilisateur_id for m in mouvements] + [lot.declare_par_id, lot.valide_par_id]
    )
    type_acteur = type_acteur_producteur(lot.producteur)
    titulaire_uid = lot.producteur.utilisateur_id if lot.producteur_id else None

    def acteur(uid) -> str:
        if uid and uid == titulaire_uid:
            return libelle_type_acteur(type_acteur)
        return ROLE_LIBELLES_GENERIQUES.get(roles.get(uid), 'Acteur de la filière')

    zone = lot.zone_collecte if lot.zone_collecte_id else None
    lieu_collecte = zone.libelle if zone else None
    debut_collecte = timezone.make_aware(datetime.combine(lot.date_collecte, time.min))
    evenements = [
        {
            'type': 'COLLECTE', 'libelle': 'Collecte du produit', 'date': debut_collecte, 'date_seule': True,
            'lieu': lieu_collecte, 'quantite': lot.quantite, 'unite': lot.unite,
            'acteur': libelle_type_acteur(type_acteur),
        },
        {
            'type': 'DECLARATION', 'libelle': 'Déclaration sur la plateforme', 'date': lot.created_at,
            'lieu': None, 'quantite': None, 'unite': None, 'acteur': acteur(lot.declare_par_id),
        },
    ]
    for m in mouvements:
        # Étape de collecte générée automatiquement à la déclaration : déjà représentée ci-dessus.
        if m.type_mouvement == 'COLLECTE' and abs(m.date_mouvement - lot.created_at) <= timedelta(minutes=10):
            continue
        evt = {
            'type': 'MOUVEMENT', 'code': m.type_mouvement,
            'libelle': TYPES_MOUVEMENT_LIBELLES.get(m.type_mouvement, m.type_mouvement),
            'date': m.date_mouvement, 'lieu': m.lieu_libelle,
            'quantite': m.quantite, 'unite': m.unite, 'acteur': acteur(m.acteur_utilisateur_id),
        }
        if public:
            evt['latitude'], evt['longitude'] = _gps_arrondi(m.latitude), _gps_arrondi(m.longitude)
        else:
            evt.update({
                'latitude': m.latitude, 'longitude': m.longitude,
                'destinataire': m.destinataire_libelle, 'commentaire': m.commentaire,
            })
        evenements.append(evt)

    validation = validation_lot(lot, transitions, roles)
    if validation and validation['date']:
        evenements.append({
            'type': 'VALIDATION', 'libelle': validation['libelle'], 'date': validation['date'],
            'lieu': None, 'quantite': None, 'unite': None,
            'acteur': (
                libelle_type_acteur(type_acteur) if validation['role'] == 'PRODUCTEUR'
                else ROLE_LIBELLES_GENERIQUES.get(validation['role'], 'Autorité habilitée')
            ),
        })
    if lot.statut == 'COMMERCIALISE':
        t = next((t for t in reversed(transitions) if t.nouveau_statut == 'COMMERCIALISE'), None)
        vente = next((m for m in mouvements if m.type_mouvement in TYPES_MOUVEMENT_COMMERCIALISATION), None)
        date_c = t.created_at if t else (vente.date_mouvement if vente else lot.updated_at)
        evenements.append({
            'type': 'COMMERCIALISATION', 'libelle': 'Lot commercialisé', 'date': date_c,
            'lieu': None, 'quantite': None, 'unite': None,
            'acteur': (
                ROLE_LIBELLES_GENERIQUES.get(t.role_auteur, 'Acteur de la filière')
                if t and t.auteur_id != titulaire_uid else libelle_type_acteur(type_acteur)
            ),
        })
    priorite = {'COLLECTE': 0, 'DECLARATION': 1, 'MOUVEMENT': 2, 'VALIDATION': 3, 'COMMERCIALISATION': 4}
    evenements.sort(key=lambda e: (e['date'], priorite[e['type']]))
    for e in evenements:
        e.setdefault('date_seule', False)
    return evenements


def certifications_publiques(lot: Lot) -> list[dict]:
    return [
        {
            'libelle': c.type_certification.libelle,
            'organisme': c.type_certification.organisme,
            'numero_certificat': c.numero_certificat,
            'date_obtention': c.date_obtention,
            'date_expiration': c.date_expiration,
            'portee': 'LOT' if c.lot_id == lot.id else 'PRODUCTEUR',
        }
        for c in certifications_actives_qs(lot).order_by('type_certification__libelle')
    ]


def generer_qr_payload(lot: Lot) -> str:
    return f'PNLF:{lot.uuid_public}'


def generer_qr_image(lot: Lot) -> str:
    """Génère PNG QR et retourne le chemin relatif media."""
    import qrcode

    payload = lot.qr_payload or generer_qr_payload(lot)
    qr_dir = Path(settings.MEDIA_ROOT) / 'qr'
    qr_dir.mkdir(parents=True, exist_ok=True)
    filename = f'{lot.uuid_public}.png'
    filepath = qr_dir / filename

    img = qrcode.make(payload)
    img.save(filepath)

    rel = f'qr/{filename}'
    media_store.pousser(rel)
    if lot.qr_payload != payload or lot.qr_image_path != rel:
        lot.qr_payload = payload
        lot.qr_image_path = rel
        lot.save(update_fields=['qr_payload', 'qr_image_path'])
    return rel


def qr_image_bytes(lot: Lot) -> bytes:
    """Retourne les octets PNG du QR (génère si absent)."""
    rel = generer_qr_image(lot)
    path = Path(settings.MEDIA_ROOT) / rel
    return path.read_bytes()


PHOTO_MAX_SIZE_BYTES = 5 * 1024 * 1024
PHOTO_MAX_DIMENSION = 1200


LOT_MAX_PHOTOS = 2


def chemin_photo(sous_dossier: str, entite_id, suffixe: str = '') -> Path:
    return Path(settings.MEDIA_ROOT) / 'photos' / sous_dossier / f'{entite_id}{suffixe}.jpg'


def photo_url(sous_dossier: str, entite_id, request=None, suffixe: str = '') -> str | None:
    """Résout l'URL d'une photo par convention de nommage (aucune colonne BDD requise)."""
    if not chemin_photo(sous_dossier, entite_id, suffixe).exists():
        return None
    rel = f'photos/{sous_dossier}/{entite_id}{suffixe}.jpg'
    from config.media_views import build_media_url
    return build_media_url(rel, request)


DOCUMENT_MAX_SIZE_BYTES = 8 * 1024 * 1024
DOCUMENT_ALLOWED_EXT = {'.pdf', '.jpg', '.jpeg', '.png'}
DOCUMENT_MAGIC = {
    '.pdf': (b'%PDF',),
    '.jpg': (b'\xff\xd8\xff',),
    '.jpeg': (b'\xff\xd8\xff',),
    '.png': (b'\x89PNG\r\n\x1a\n',),
}


def _valider_magic_document(fichier, ext: str) -> None:
    """Vérifie les magic bytes ; refuse les polyglottes basiques."""
    expected = DOCUMENT_MAGIC.get(ext)
    if not expected:
        raise ValidationError({'document': 'Formats acceptés : PDF, JPG, PNG.'})
    pos = fichier.tell()
    try:
        fichier.seek(0)
        head = fichier.read(16)
    finally:
        fichier.seek(pos)
    if not any(head.startswith(sig) for sig in expected):
        raise ValidationError({'document': 'Contenu du fichier incohérent avec l’extension déclarée.'})


def enregistrer_document(fichier, sous_dossier: str, entite_id) -> str:
    """Valide et enregistre un document justificatif (PDF/JPEG/PNG). Retourne le chemin relatif media.

    Utilisé pour les pièces jointes administratives (documents d'inscription,
    justificatifs de certification…). Remplace tout document existant pour la
    même entité/sous-dossier (un seul document actif à la fois).
    """
    if fichier.size > DOCUMENT_MAX_SIZE_BYTES:
        raise ValidationError({'document': 'Fichier trop volumineux (8 Mo maximum).'})
    ext = Path(fichier.name or '').suffix.lower()
    if ext not in DOCUMENT_ALLOWED_EXT:
        raise ValidationError({'document': 'Formats acceptés : PDF, JPG, PNG.'})
    _valider_magic_document(fichier, ext)
    if ext != '.pdf':
        from config import moderation_images

        rel_image = f'documents/{sous_dossier}/{entite_id}{ext}'
        analyse = moderation_images.controler_fichier(fichier, champ='document', rel=rel_image)
        moderation_images.consigner(analyse, rel_image)
    doc_dir = Path(settings.MEDIA_ROOT) / 'documents' / sous_dossier
    doc_dir.mkdir(parents=True, exist_ok=True)
    # Supprime toute variante d'extension précédente pour éviter les doublons.
    for old_ext in DOCUMENT_ALLOWED_EXT:
        if old_ext == ext:
            continue
        old_path = doc_dir / f'{entite_id}{old_ext}'
        if old_path.exists():
            old_path.unlink(missing_ok=True)
        media_store.supprimer(f'documents/{sous_dossier}/{entite_id}{old_ext}')
    filename = f'{entite_id}{ext}'
    filepath = doc_dir / filename
    with open(filepath, 'wb') as out:
        for chunk in fichier.chunks():
            out.write(chunk)
    rel = f'documents/{sous_dossier}/{filename}'
    media_store.pousser(rel)
    return rel


def document_url(document_path: str | None, request=None) -> str | None:
    """Résout l'URL d'un document déjà enregistré (chemin relatif media)."""
    if not document_path:
        return None
    from config.media_views import build_media_url
    return build_media_url(document_path, request)


def photos_urls_lot(lot_id, request=None) -> list[str]:
    """Jusqu'à 2 photos illustrant la marchandise d'un lot (suffixes _1 / _2)."""
    urls = []
    for i in range(1, LOT_MAX_PHOTOS + 1):
        url = photo_url('lots', lot_id, request, suffixe=f'_{i}')
        if url:
            urls.append(url)
    return urls


def enregistrer_photo(fichier, sous_dossier: str, entite_id, suffixe: str = '') -> str:
    """Valide, analyse (modération IA), redimensionne et enregistre une photo. Retourne le chemin relatif media."""
    from config import moderation_images

    if fichier.size > PHOTO_MAX_SIZE_BYTES:
        raise ValidationError({'photo': 'Image trop volumineuse (5 Mo maximum).'})

    image = moderation_images.ouvrir_image(fichier, champ='photo', dimension_max=PHOTO_MAX_DIMENSION)
    filename = f'{entite_id}{suffixe}.jpg'
    rel = f'photos/{sous_dossier}/{filename}'
    analyse = moderation_images.controler(image, champ='photo', rel=rel)
    moderation_images.consigner(analyse, rel)

    photo_dir = Path(settings.MEDIA_ROOT) / 'photos' / sous_dossier
    photo_dir.mkdir(parents=True, exist_ok=True)
    image.save(photo_dir / filename, format='JPEG', quality=85)
    media_store.pousser(rel)
    return rel


PIECES_CERTIFICATION_MAX = 10
PIECE_INTITULE_MAX = 150
PIECES_TYPES_MIME = {'.pdf': 'application/pdf', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png'}


def controler_piece_justificative(fichier, intitule: str, rang: int) -> str:
    """Contrôle une pièce avant tout enregistrement (une erreur n'écrit aucun fichier). Retourne l'intitulé nettoyé."""
    nom = fichier.name or 'document'
    intitule = (intitule or '').strip()
    if not intitule:
        raise ValidationError({'pieces': f'Document {rang} (« {nom} ») : indiquez un intitulé (ex. « Attestation de récolte »).'})
    if len(intitule) > PIECE_INTITULE_MAX:
        raise ValidationError({'pieces': f'Document {rang} : l’intitulé ne doit pas dépasser {PIECE_INTITULE_MAX} caractères.'})
    if fichier.size > DOCUMENT_MAX_SIZE_BYTES:
        raise ValidationError({'pieces': f'« {nom} » est trop volumineux : 8 Mo maximum par document.'})
    ext = Path(nom).suffix.lower()
    if ext not in DOCUMENT_ALLOWED_EXT:
        raise ValidationError({'pieces': f'« {nom} » n’est pas accepté : formats PDF, JPG ou PNG uniquement.'})
    try:
        _valider_magic_document(fichier, ext)
    except ValidationError:
        raise ValidationError({'pieces': f'Le contenu de « {nom} » ne correspond pas à un fichier {ext[1:].upper()} valide.'})
    return intitule
