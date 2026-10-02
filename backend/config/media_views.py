"""Servir les médias : public (whitelist) ou sécurisé (jeton signé + contrôle d'accès)."""

from __future__ import annotations

import mimetypes
import re
from pathlib import Path

from django.conf import settings
from django.core import signing
from django.http import FileResponse, Http404, HttpResponseForbidden
from django.views import View
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView

from accounts.models import Utilisateur
from accounts.permissions import user_can_access_lot, user_can_access_producteur

from . import media_store

MEDIA_SIGN_SALT = 'pfnl-media-v1'
MEDIA_SIGN_MAX_AGE = 60 * 60  # 1 h

# Préfixes volontairement publics (annuaire, QR, illustrations lots/offres).
PUBLIC_PREFIXES = (
    'qr/',
    'photos/producteurs/',
    'photos/lots/',
    'photos/offres/',
    'photos/produits/',
    'photos/cooperatives/',
)

SENSITIVE_PREFIXES = (
    'documents/',
    'chat/',
    'photos/utilisateurs/',
)

# Photos publiques seulement si la fiche est validée (ACTIF) et non supprimée.
_PHOTO_FICHE_RE = re.compile(r'^photos/(producteurs|cooperatives)/([0-9a-fA-F-]{36})')

# Types servis pour les pièces de messagerie (jamais déduits du contenu par le navigateur).
_CHAT_CONTENT_TYPES = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.webm': 'audio/webm',
    '.ogg': 'audio/ogg',
    '.mp3': 'audio/mpeg',
    '.m4a': 'audio/mp4',
    '.mp4': 'audio/mp4',
    '.aac': 'audio/aac',
    '.wav': 'audio/wav',
}


def _safe_rel(rel: str) -> str:
    rel = (rel or '').replace('\\', '/').lstrip('/')
    if not rel or '..' in rel.split('/'):
        raise Http404('Chemin invalide.')
    return rel


def is_public_media(rel: str) -> bool:
    rel = _safe_rel(rel)
    return any(rel.startswith(p) for p in PUBLIC_PREFIXES)


def is_sensitive_media(rel: str) -> bool:
    rel = _safe_rel(rel)
    return any(rel.startswith(p) for p in SENSITIVE_PREFIXES)


def _fiche_photo(rel: str):
    """(type, fiche) pour une photo de producteur / coopérative, sinon None."""
    m = _PHOTO_FICHE_RE.match(rel)
    if not m:
        return None
    from traceability.models import Cooperative, Producteur

    if m.group(1) == 'producteurs':
        return 'producteur', Producteur.objects.filter(pk=m.group(2)).first()
    return 'cooperative', Cooperative.objects.filter(pk=m.group(2)).first()


def photo_fiche_publique(rel: str) -> bool:
    """Vrai si ``rel`` n'est pas une photo de fiche, ou si la fiche est publiable."""
    trouve = _fiche_photo(rel)
    if trouve is None:
        return True
    genre, fiche = trouve
    if fiche is None:
        return False
    if genre == 'producteur':
        return fiche.statut == 'ACTIF' and fiche.deleted_at is None
    return fiche.statut == 'ACTIF' and fiche.actif


def _peut_voir_photo_fiche(user, rel: str) -> bool:
    trouve = _fiche_photo(rel)
    if trouve is None or trouve[1] is None:
        return False
    genre, fiche = trouve
    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
    ):
        return True
    if genre == 'producteur':
        return fiche.deleted_at is None and user_can_access_producteur(user, fiche)
    return fiche.utilisateur_id == user.id


def build_media_url(rel: str | None, request=None) -> str | None:
    """URL absolue : publique ou signée selon le préfixe."""
    if not rel:
        return None
    if rel.startswith('http://') or rel.startswith('https://'):
        return rel
    rel = _safe_rel(rel.removeprefix('media/').lstrip('/'))
    if is_public_media(rel) and photo_fiche_publique(rel):
        path = f'/api/media/public/{rel}'
        if request:
            return request.build_absolute_uri(path)
        return path
    user = getattr(request, 'user', None) if request else None
    if request and user is not None and getattr(user, 'is_authenticated', False):
        token = signing.dumps({'p': rel, 'u': str(user.id)}, salt=MEDIA_SIGN_SALT)
        path = f'/api/media/secure/{token}/'
        return request.build_absolute_uri(path)
    # Pas d'utilisateur : ne jamais exposer un chemin /media/ sensible en clair.
    return None


def _absolute_file(rel: str) -> Path:
    root = Path(settings.MEDIA_ROOT).resolve()
    full = (root / rel).resolve()
    if not str(full).startswith(str(root)):
        raise Http404('Fichier introuvable.')
    if not full.is_file() and not media_store.assurer_local(full.relative_to(root).as_posix()):
        raise Http404('Fichier introuvable.')
    return full


def _file_response(full: Path, *, as_attachment: bool, rel: str = '') -> FileResponse:
    if rel.startswith('chat/'):
        content_type = _CHAT_CONTENT_TYPES.get(full.suffix.lower(), 'application/octet-stream')
    else:
        content_type, _ = mimetypes.guess_type(str(full))
    resp = FileResponse(
        full.open('rb'),
        content_type=content_type or 'application/octet-stream',
        as_attachment=as_attachment,
        filename=full.name,
    )
    resp['X-Content-Type-Options'] = 'nosniff'
    if content_type != 'application/pdf':
        resp['Content-Security-Policy'] = "default-src 'none'; sandbox"
    if as_attachment:
        resp['Content-Disposition'] = f'attachment; filename="{full.name}"'
    return resp


def _user_can_access_rel(user, rel: str) -> bool:
    if not user or not getattr(user, 'is_authenticated', False):
        return False
    role = getattr(user, 'role', None)

    if _PHOTO_FICHE_RE.match(rel):
        return photo_fiche_publique(rel) or _peut_voir_photo_fiche(user, rel)

    if rel.startswith('photos/utilisateurs/'):
        m = re.match(r'^photos/utilisateurs/([0-9a-fA-F-]{36})', rel)
        if not m:
            return False
        uid = m.group(1)
        if str(user.id) == uid:
            return True
        if role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
        ):
            return True
        from pnlf_platform.models import ConversationParticipant
        mes_conversations = ConversationParticipant.objects.filter(
            utilisateur_id=user.id,
        ).values('conversation_id')
        return ConversationParticipant.objects.filter(
            utilisateur_id=uid, conversation_id__in=mes_conversations,
        ).exists()

    if rel.startswith('documents/inscriptions/producteurs/'):
        if role not in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            return False
        m = re.match(r'^documents/inscriptions/producteurs/([0-9a-fA-F-]{36})', rel)
        if not m:
            return False
        from traceability.models import Producteur
        prod = Producteur.objects.filter(pk=m.group(1), deleted_at__isnull=True).first()
        return bool(prod and user_can_access_producteur(user, prod))

    if rel.startswith('documents/inscriptions/cooperatives/'):
        return role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )

    if rel.startswith('documents/certifications/'):
        m = re.match(r'^documents/certifications/([0-9a-fA-F-]{36})', rel)
        if not m:
            return role in (
                Utilisateur.Role.ADMINISTRATEUR,
                Utilisateur.Role.AGENT_MINISTERE,
            )
        from traceability.models import Certification
        cert = Certification.objects.filter(pk=m.group(1)).select_related('producteur').first()
        if not cert:
            return False
        if role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            return True
        if cert.producteur_id and cert.producteur.utilisateur_id == user.id:
            return True
        return False

    if rel.startswith('documents/'):
        return role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )

    if rel.startswith('chat/'):
        m = re.match(r'^chat/([0-9a-fA-F-]{36})', rel)
        if not m:
            return False
        from pnlf_platform.models import ConversationParticipant, Message
        msg = Message.objects.filter(pk=m.group(1)).first()
        if not msg:
            return False
        if role == Utilisateur.Role.ADMINISTRATEUR:
            return True
        return ConversationParticipant.objects.filter(
            conversation_id=msg.conversation_id, utilisateur_id=user.id,
        ).exists()

    return False


class PublicMediaView(View):
    """GET /api/media/public/<path> : assets non sensibles uniquement."""

    def get(self, request, relpath: str):
        rel = _safe_rel(relpath)
        if not is_public_media(rel):
            return HttpResponseForbidden('Accès refusé.')
        if not photo_fiche_publique(rel):
            raise Http404('Fichier introuvable.')
        full = _absolute_file(rel)
        return _file_response(full, as_attachment=False)


class SecureMediaView(APIView):
    """GET /api/media/secure/<token>/ : jeton signé lié à un utilisateur + contrôle d'objet."""

    permission_classes = [AllowAny]  # l'auth est le jeton signé

    def get(self, request, token: str):
        try:
            payload = signing.loads(token, salt=MEDIA_SIGN_SALT, max_age=MEDIA_SIGN_MAX_AGE)
        except signing.BadSignature:
            raise Http404('Lien expiré ou invalide.')
        rel = _safe_rel(payload.get('p') or '')
        uid = payload.get('u')
        user = Utilisateur.objects.filter(pk=uid, deleted_at__isnull=True).first()
        if not user or not user.is_active:
            return HttpResponseForbidden('Accès refusé.')
        if not _user_can_access_rel(user, rel):
            return HttpResponseForbidden('Accès refusé.')
        full = _absolute_file(rel)
        as_attachment = rel.startswith('documents/')
        return _file_response(full, as_attachment=as_attachment, rel=rel)


class AuthenticatedMediaView(APIView):
    """GET /api/media/auth/<path> : alternative Bearer JWT (fetch Blob côté Angular)."""

    permission_classes = [IsAuthenticated]

    def get(self, request, relpath: str):
        rel = _safe_rel(relpath)
        if is_public_media(rel) and not _PHOTO_FICHE_RE.match(rel):
            full = _absolute_file(rel)
            return _file_response(full, as_attachment=False)
        if not _user_can_access_rel(request.user, rel):
            return HttpResponseForbidden('Accès refusé.')
        full = _absolute_file(rel)
        return _file_response(full, as_attachment=rel.startswith('documents/'), rel=rel)
