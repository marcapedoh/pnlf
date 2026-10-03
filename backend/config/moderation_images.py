"""Détection des images sensibles (nudité, contenu explicite) par IA, sur CPU avec ONNX Runtime.

Modèle : Marqo/nsfw-image-detection-384 (ViT-tiny, classes ``nsfw`` / ``safe``), installé au build par
``scripts/telecharger_modele_nsfw.py``. Une session par processus, chargée à la première analyse.

Verdicts :
- ``ACCEPTABLE`` : stockage normal ;
- ``DOUTEUX`` : stockage, mais l'image reste masquée jusqu'à la décision d'un administrateur
  (table ``public.moderation_images``) ; aussi appliqué quand le modèle est indisponible ;
- ``EXPLICITE`` : refus (HTTP 400), rien n'est stocké, l'événement est journalisé sans l'image.
"""

from __future__ import annotations

import contextvars
import logging
import re
import threading
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path

from django.conf import settings
from django.db import DatabaseError, transaction
from django.http import HttpResponse
from django.utils import timezone
from rest_framework.exceptions import ValidationError

logger = logging.getLogger('pfnl.moderation')

ACCEPTABLE = 'ACCEPTABLE'
DOUTEUX = 'DOUTEUX'
EXPLICITE = 'EXPLICITE'

EN_ATTENTE = 'EN_ATTENTE'
APPROUVEE = 'APPROUVEE'
REJETEE = 'REJETEE'
REMPLACEE = 'REMPLACEE'

MESSAGE_REFUS = (
    'Cette image a été refusée car elle contient du contenu inapproprié '
    '(nudité ou contenu explicite). Choisissez une autre image.'
)
MESSAGE_INVALIDE = 'Fichier image invalide (JPEG/PNG/WEBP attendu).'
MESSAGE_ENREGISTREMENT = (
    'L’image n’a pas pu être soumise à la vérification automatique. Réessayez dans quelques instants.'
)
EN_TETE_REPONSE = 'X-Moderation-Image'

SEUIL_DOUTEUX_DEFAUT = 0.60
SEUIL_EXPLICITE_DEFAUT = 0.92

TAILLE_ENTREE = 384
PIXELS_MAX = 40_000_000
_DIMENSION_ANALYSE = 768
_RATIO_VUE_UNIQUE = 1.15
_IMAGES_ANIMEES = 3
_VUES_MAX = 6
_DELAI_NOUVEL_ESSAI_S = 300

TYPES_OBJET = {
    'producteurs': 'PRODUCTEUR',
    'cooperatives': 'COOPERATIVE',
    'lots': 'LOT',
    'offres': 'OFFRE',
    'produits': 'PRODUIT',
    'utilisateurs': 'UTILISATEUR',
    'acheteurs': 'UTILISATEUR',
}
_UUID_RE = re.compile(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')

_requete_courante: contextvars.ContextVar = contextvars.ContextVar('pfnl_requete_moderation', default=None)
_session = None
_verrou = threading.Lock()
_echec_chargement: float | None = None


class ModeleIndisponible(RuntimeError):
    pass


@dataclass(frozen=True)
class Analyse:
    verdict: str
    score: float | None = None
    scores_vues: tuple[float, ...] = ()
    duree_ms: float = 0.0
    motif: str = ''
    seuils: tuple[float, float] = field(default=(SEUIL_DOUTEUX_DEFAUT, SEUIL_EXPLICITE_DEFAUT))

    def scores_json(self) -> dict:
        return {
            'nsfw': None if self.score is None else round(self.score, 5),
            'vues': [round(s, 5) for s in self.scores_vues],
            'duree_ms': round(self.duree_ms, 1),
            'seuil_douteux': self.seuils[0],
            'seuil_explicite': self.seuils[1],
            'motif': self.motif or None,
            'modele': Path(settings.NSFW_MODELE).name,
        }


def actif() -> bool:
    return bool(getattr(settings, 'NSFW_ACTIF', True))


def seuils() -> tuple[float, float]:
    douteux = float(getattr(settings, 'NSFW_SEUIL_DOUTEUX', SEUIL_DOUTEUX_DEFAUT))
    explicite = float(getattr(settings, 'NSFW_SEUIL_EXPLICITE', SEUIL_EXPLICITE_DEFAUT))
    if not 0 < douteux < explicite <= 1:
        logger.error(
            'Seuils NSFW incohérents (douteux=%s, explicite=%s) : valeurs par défaut appliquées.', douteux, explicite,
        )
        return SEUIL_DOUTEUX_DEFAUT, SEUIL_EXPLICITE_DEFAUT
    return douteux, explicite


def verdict_pour(score: float, seuil_douteux: float, seuil_explicite: float) -> str:
    if score >= seuil_explicite:
        return EXPLICITE
    if score >= seuil_douteux:
        return DOUTEUX
    return ACCEPTABLE


# --- Session ONNX ----------------------------------------------------------------------------------

def session():
    """Session ONNX Runtime du processus (chargement paresseux, une seule fois, thread-safe)."""
    global _session, _echec_chargement
    if _session is not None:
        return _session
    with _verrou:
        if _session is not None:
            return _session
        if _echec_chargement is not None and time.monotonic() - _echec_chargement < _DELAI_NOUVEL_ESSAI_S:
            raise ModeleIndisponible('chargement en échec récent')
        chemin = Path(settings.NSFW_MODELE)
        debut = time.perf_counter()
        try:
            if not chemin.is_file():
                raise FileNotFoundError(f'fichier absent : {chemin}')
            import onnxruntime as ort

            options = ort.SessionOptions()
            options.intra_op_num_threads = max(1, int(getattr(settings, 'NSFW_THREADS', 1)))
            options.inter_op_num_threads = 1
            options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
            options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
            options.enable_cpu_mem_arena = False
            options.log_severity_level = 3
            charge = ort.InferenceSession(str(chemin), sess_options=options, providers=['CPUExecutionProvider'])
        except Exception as exc:
            _echec_chargement = time.monotonic()
            logger.error(
                'ALERTE modération : modèle NSFW indisponible (%s). Les images envoyées sont mises en '
                'attente de vérification par un administrateur.', exc,
            )
            raise ModeleIndisponible(str(exc)) from exc
        _session = charge
        _echec_chargement = None
        logger.info('Modèle NSFW chargé en %.0f ms (%s).', (time.perf_counter() - debut) * 1000, chemin.name)
        return _session


# --- Préparation des images ------------------------------------------------------------------------

def _a_transparence(image) -> bool:
    return image.mode in ('RGBA', 'LA', 'PA', 'RGBa', 'La') or (
        image.mode == 'P' and 'transparency' in image.info
    )


def aplatir(image):
    """RGB, transparence composée sur fond blanc (rien ne reste caché sous un canal alpha nul)."""
    from PIL import Image

    if _a_transparence(image):
        rgba = image.convert('RGBA')
        fond = Image.new('RGB', rgba.size, (255, 255, 255))
        fond.paste(rgba, mask=rgba.getchannel('A'))
        return fond
    return image.convert('RGB')


def _message_trop_grande(largeur: int | None = None, hauteur: int | None = None) -> str:
    dimensions = f' ({largeur} x {hauteur} pixels)' if largeur and hauteur else ''
    return (
        f'Image trop grande{dimensions}. '
        f'Réduisez-la à {PIXELS_MAX // 1_000_000} mégapixels maximum puis réessayez.'
    )


def _indices_trames(image) -> list[int]:
    trames = getattr(image, 'n_frames', 1) or 1
    if trames <= 1:
        return [0]
    return sorted({round(i * (trames - 1) / (_IMAGES_ANIMEES - 1)) for i in range(_IMAGES_ANIMEES)})


def ouvrir_image(fichier, *, champ: str, dimension_max: int, message_invalide: str = MESSAGE_INVALIDE):
    """Ouvre une image envoyée : vérification, orientation EXIF, transparence sur fond blanc, taille bornée.

    Les JPEG volumineux sont décodés directement à taille réduite (``draft``) pour borner la mémoire.
    """
    from PIL import Image, ImageOps, UnidentifiedImageError

    try:
        fichier.seek(0)
        with Image.open(fichier) as controle:
            controle.verify()
        fichier.seek(0)
        image = Image.open(fichier)
        if image.width * image.height > PIXELS_MAX:
            raise ValidationError({champ: _message_trop_grande(image.width, image.height)})
        image.draft('RGB', (dimension_max, dimension_max))
        image = aplatir(ImageOps.exif_transpose(image))
        image.thumbnail((dimension_max, dimension_max))
        return image
    except ValidationError:
        raise
    except Image.DecompressionBombError:
        raise ValidationError({champ: _message_trop_grande()})
    except (UnidentifiedImageError, OSError, ValueError, SyntaxError, EOFError):
        raise ValidationError({champ: message_invalide})


def _variantes_fichier(fichier, champ: str) -> list:
    """Images à analyser pour un fichier conservé tel quel (documents) : plusieurs trames si animé,
    rendu sur fond blanc et, en cas de transparence, rendu sans canal alpha."""
    from PIL import Image, ImageOps, UnidentifiedImageError

    try:
        fichier.seek(0)
        image = Image.open(fichier)
        if image.width * image.height > PIXELS_MAX:
            raise ValidationError({champ: _message_trop_grande(image.width, image.height)})
        image.draft('RGB', (_DIMENSION_ANALYSE, _DIMENSION_ANALYSE))
        variantes = []
        for index in _indices_trames(image):
            if index:
                image.seek(index)
            trame = ImageOps.exif_transpose(image) if index == 0 else image.copy()
            trame.thumbnail((_DIMENSION_ANALYSE, _DIMENSION_ANALYSE))
            variantes.append(aplatir(trame))
            if index == 0 and _a_transparence(trame):
                variantes.append(trame.convert('RGB'))
        return variantes
    except ValidationError:
        raise
    except Image.DecompressionBombError:
        raise ValidationError({champ: _message_trop_grande()})
    except (UnidentifiedImageError, OSError, ValueError, SyntaxError, EOFError):
        raise ValidationError({champ: MESSAGE_INVALIDE})
    finally:
        fichier.seek(0)


def vues(image) -> list:
    """Vue de référence du modèle (petit côté à 384 px puis recadrage central) et, pour une image
    non carrée, l'image entière sans déformation sur fond blanc (aucune zone périphérique
    n'échappe à l'analyse). Une image étirée ou des recadrages latéraux font monter les faux
    positifs sur les documents et les cartes."""
    from PIL import Image

    largeur, hauteur = image.size
    echelle = TAILLE_ENTREE / min(largeur, hauteur)
    nl = max(TAILLE_ENTREE, round(largeur * echelle))
    nh = max(TAILLE_ENTREE, round(hauteur * echelle))
    reduite = image.resize((nl, nh), Image.Resampling.BICUBIC)
    gauche, haut = round((nl - TAILLE_ENTREE) / 2), round((nh - TAILLE_ENTREE) / 2)
    resultat = [reduite.crop((gauche, haut, gauche + TAILLE_ENTREE, haut + TAILLE_ENTREE))]
    if max(largeur, hauteur) / min(largeur, hauteur) > _RATIO_VUE_UNIQUE:
        entiere = image.copy()
        entiere.thumbnail((TAILLE_ENTREE, TAILLE_ENTREE), Image.Resampling.BICUBIC)
        fond = Image.new('RGB', (TAILLE_ENTREE, TAILLE_ENTREE), (255, 255, 255))
        fond.paste(entiere, ((TAILLE_ENTREE - entiere.width) // 2, (TAILLE_ENTREE - entiere.height) // 2))
        resultat.append(fond)
    return resultat


def _tenseur(vue):
    import numpy as np

    pixels = np.asarray(vue, dtype=np.float32) * np.float32(2.0 / 255.0) - np.float32(1.0)
    return np.ascontiguousarray(pixels.transpose(2, 0, 1)[None, ...])


def scores_nsfw(images: list) -> list[float]:
    """Probabilité ``nsfw`` (softmax) de chaque vue, dans la limite de ``_VUES_MAX`` inférences."""
    import numpy as np

    sess = session()
    entree = sess.get_inputs()[0].name
    a_analyser = [v for image in images for v in vues(image)][:_VUES_MAX]
    resultats = []
    for vue in a_analyser:
        logits = sess.run(None, {entree: _tenseur(vue)})[0][0].astype(np.float64)
        exp = np.exp(logits - logits.max())
        resultats.append(float(exp[0] / exp.sum()))
    return resultats


def analyser(images: list) -> Analyse:
    """Analyse une ou plusieurs images RGB (le score retenu est le maximum des vues)."""
    if not actif():
        return Analyse(ACCEPTABLE, motif='analyse désactivée (NSFW_ACTIF=False)')
    seuil_douteux, seuil_explicite = seuils()
    debut = time.perf_counter()
    try:
        scores = scores_nsfw(images)
    except ModeleIndisponible:
        return Analyse(DOUTEUX, motif='modèle indisponible', seuils=(seuil_douteux, seuil_explicite))
    except Exception:
        logger.exception('ALERTE modération : échec de l’analyse NSFW, image mise en attente de vérification.')
        return Analyse(DOUTEUX, motif='erreur d’analyse', seuils=(seuil_douteux, seuil_explicite))
    duree = (time.perf_counter() - debut) * 1000
    score = max(scores)
    analyse = Analyse(
        verdict_pour(score, seuil_douteux, seuil_explicite), score, tuple(scores), duree,
        seuils=(seuil_douteux, seuil_explicite),
    )
    logger.info('Analyse NSFW : %s (score %.3f, %d vue(s), %.0f ms).', analyse.verdict, score, len(scores), duree)
    return analyse


# --- Contexte de requête (auteur, IP) --------------------------------------------------------------

class ModerationImagesMiddleware:
    """Expose la requête en cours au module et signale au client une image mise en attente."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        jeton = _requete_courante.set(request)
        try:
            response = self.get_response(request)
        finally:
            _requete_courante.reset(jeton)
        if getattr(request, '_pfnl_image_en_attente', False):
            response[EN_TETE_REPONSE] = EN_ATTENTE
        return response


def _utilisateur_courant_id():
    requete = _requete_courante.get()
    user = getattr(requete, 'user', None) if requete is not None else None
    if user is not None and getattr(user, 'is_authenticated', False):
        return getattr(user, 'id', None)
    return None


def _uuid_dans(texte: str):
    m = _UUID_RE.search(texte or '')
    return uuid.UUID(m.group(0)) if m else None


def contexte_chemin(rel: str) -> tuple[str, uuid.UUID | None]:
    """(type d'objet, identifiant) déduits du chemin relatif du média."""
    morceaux = rel.split('/')
    objet_id = _uuid_dans(rel)
    if morceaux[0] == 'photos' and len(morceaux) > 2:
        return TYPES_OBJET.get(morceaux[1], 'AUTRE'), objet_id
    if morceaux[0] == 'chat':
        return 'MESSAGE', objet_id
    if rel.startswith('documents/inscriptions/'):
        return 'DOCUMENT_INSCRIPTION', objet_id
    if rel.startswith('documents/certifications'):
        return 'CERTIFICATION', objet_id
    return 'AUTRE', objet_id


def _proprietaire(rel: str, type_objet: str, objet_id):
    """Compte propriétaire de l'objet, quand l'envoi est anonyme (inscription publique)."""
    if objet_id is None:
        return None
    from traceability.models import Cooperative, Producteur

    if type_objet == 'UTILISATEUR' or rel.startswith('documents/inscriptions/utilisateurs/'):
        return objet_id
    if type_objet == 'PRODUCTEUR' or rel.startswith('documents/inscriptions/producteurs/'):
        return Producteur.objects.filter(pk=objet_id).values_list('utilisateur_id', flat=True).first()
    if type_objet == 'COOPERATIVE' or rel.startswith('documents/inscriptions/cooperatives/'):
        return Cooperative.objects.filter(pk=objet_id).values_list('utilisateur_id', flat=True).first()
    return None


# --- Points d'entrée -------------------------------------------------------------------------------

def controler(images, *, champ: str, rel: str) -> Analyse:
    """Analyse avant écriture : lève une ValidationError (HTTP 400) si l'image est explicite."""
    analyse = analyser(images if isinstance(images, list) else [images])
    if analyse.verdict != EXPLICITE:
        return analyse
    from accounts.audit import request_meta, write_audit

    type_objet, objet_id = contexte_chemin(rel)
    ip, ua = request_meta(_requete_courante.get())
    logger.warning('Image explicite refusée (%s, score %.3f).', rel, analyse.score or 0)
    write_audit(
        utilisateur_id=_utilisateur_courant_id(), action='MODERATION_IMAGE_REFUSEE',
        table_cible='moderation_images', enregistrement_id=objet_id, ip_adresse=ip, user_agent=ua,
        nouvelles_valeurs={'champ': champ, 'chemin': rel, 'type_objet': type_objet, 'verdict': EXPLICITE,
                           'scores': analyse.scores_json()},
    )
    raise ValidationError({champ: MESSAGE_REFUS})


def controler_fichier(fichier, *, champ: str, rel: str) -> Analyse:
    """Variante pour un fichier image conservé tel quel (documents JPEG/PNG)."""
    return controler(_variantes_fichier(fichier, champ), champ=champ, rel=rel)


def consigner(analyse: Analyse, rel: str) -> None:
    """À appeler juste avant l'écriture du fichier : clôt la vérification d'une image remplacée et
    place une image douteuse en file de vérification. En cas d'échec, rien ne doit être écrit."""
    from pnlf_platform.models import ModerationImage

    maintenant = timezone.now()
    try:
        with transaction.atomic():
            ModerationImage.objects.filter(chemin=rel, statut=EN_ATTENTE).update(
                statut=REMPLACEE, traite_at=maintenant,
            )
            if analyse.verdict != DOUTEUX:
                return
            type_objet, objet_id = contexte_chemin(rel)
            ModerationImage.objects.create(
                id=uuid.uuid4(), chemin=rel, type_objet=type_objet, objet_id=objet_id,
                envoye_par_id=_utilisateur_courant_id() or _proprietaire(rel, type_objet, objet_id),
                verdict=DOUTEUX, score_nsfw=None if analyse.score is None else round(analyse.score, 5),
                scores=analyse.scores_json(), statut=EN_ATTENTE, created_at=maintenant,
            )
    except DatabaseError:
        logger.exception('Mise en file de vérification impossible pour %s.', rel)
        if analyse.verdict == DOUTEUX:
            raise ValidationError({'detail': MESSAGE_ENREGISTREMENT})
        return
    requete = _requete_courante.get()
    if requete is not None:
        requete._pfnl_image_en_attente = True


def est_masquee(rel: str) -> bool:
    """Vrai si l'image attend la décision d'un administrateur."""
    from pnlf_platform.models import ModerationImage

    try:
        return ModerationImage.objects.filter(chemin=rel, statut=EN_ATTENTE).exists()
    except DatabaseError:
        logger.exception('Lecture de la file de modération impossible.')
        return False


_IMAGE_EN_VERIFICATION = (
    '<svg xmlns="http://www.w3.org/2000/svg" width="480" height="480" viewBox="0 0 480 480" role="img" '
    'aria-label="Image en cours de vérification">'
    '<rect width="480" height="480" fill="#eef2ef"/>'
    '<circle cx="240" cy="200" r="58" fill="none" stroke="#5c6b63" stroke-width="10"/>'
    '<path d="M240 168v36l24 16" fill="none" stroke="#5c6b63" stroke-width="10" stroke-linecap="round"/>'
    '<text x="240" y="310" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="26" '
    'font-weight="700" fill="#1f3a2d">Image en cours</text>'
    '<text x="240" y="346" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="26" '
    'font-weight="700" fill="#1f3a2d">de vérification</text>'
    '</svg>'
).encode('utf-8')


def reponse_image_en_verification() -> HttpResponse:
    """Visuel neutre servi à la place d'une image en attente (jamais mis en cache)."""
    resp = HttpResponse(_IMAGE_EN_VERIFICATION, content_type='image/svg+xml')
    resp['Cache-Control'] = 'no-store'
    resp['X-Content-Type-Options'] = 'nosniff'
    resp['Content-Security-Policy'] = "default-src 'none'; style-src 'unsafe-inline'; sandbox"
    resp[EN_TETE_REPONSE] = EN_ATTENTE
    return resp
