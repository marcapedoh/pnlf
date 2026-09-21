"""Vérifie la messagerie : fils producteur, pièces, isolation acheteur, droits admin.

Usage:
  python backend/scripts/test_chat.py
"""
from __future__ import annotations

import io
import os
import sys
import uuid
from pathlib import Path

import django
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))
load_dotenv(BACKEND / '.env')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import Utilisateur
from pnlf_platform.models import Conversation, ConversationParticipant, Message
from traceability.models import Producteur, Province

PASS: list[str] = []
FAIL: list[str] = []
CLEAN_EMAILS = [
    'chat_admin@pnlf-test.local',
    'chat_prod@pnlf-test.local',
    'chat_acheteur_a@pnlf-test.local',
    'chat_acheteur_b@pnlf-test.local',
]


def check(label: str, ok: bool, detail: str = '') -> None:
    if ok:
        PASS.append(label)
        print(f'  [OK] {label}')
    else:
        FAIL.append(label)
        print(f'  [FAIL] {label} {detail[:300]}')


def make_photo() -> SimpleUploadedFile:
    from PIL import Image

    buf = io.BytesIO()
    Image.new('RGB', (80, 80), color=(20, 140, 70)).save(buf, format='JPEG')
    buf.seek(0)
    return SimpleUploadedFile('chat.jpg', buf.read(), content_type='image/jpeg')


def make_audio() -> SimpleUploadedFile:
    return SimpleUploadedFile('vocal.webm', b'OggSFAKEAUDIO' + b'\x00' * 64, content_type='audio/webm')


def make_user(email: str, role: str, prenoms: str) -> Utilisateur:
    user = Utilisateur.objects.filter(email=email).first()
    now = timezone.now()
    if user:
        user.deleted_at = None
        user.statut = Utilisateur.Statut.ACTIF
        user.role = role
        user.set_password('ChatTest2026!')
        user.updated_at = now
        user.save()
        return user
    user = Utilisateur(
        id=uuid.uuid4(), email=email, telephone='074000001',
        role=role, statut=Utilisateur.Statut.ACTIF, nom='Chat', prenoms=prenoms,
        created_at=now, updated_at=now,
    )
    user.set_password('ChatTest2026!')
    user.save()
    return user


def client_for(user: Utilisateur) -> APIClient:
    c = APIClient(raise_request_exception=False)
    c.force_authenticate(user=user)
    return c


def cleanup() -> None:
    from pnlf_platform.models import ConversationContext, ConversationParticipantMeta, MessagePiece

    users = list(Utilisateur.objects.filter(email__in=CLEAN_EMAILS))
    ids = [u.id for u in users]
    conv_ids = list(ConversationParticipant.objects.filter(utilisateur_id__in=ids).values_list('conversation_id', flat=True))
    msg_ids = list(Message.objects.filter(conversation_id__in=conv_ids).values_list('id', flat=True))
    MessagePiece.objects.filter(message_id__in=msg_ids).delete()
    Message.objects.filter(conversation_id__in=conv_ids).delete()
    ConversationParticipantMeta.objects.filter(conversation_id__in=conv_ids).delete()
    ConversationParticipant.objects.filter(conversation_id__in=conv_ids).delete()
    ConversationContext.objects.filter(conversation_id__in=conv_ids).delete()
    Conversation.objects.filter(id__in=conv_ids).delete()
    Producteur.objects.filter(email__in=CLEAN_EMAILS).delete()
    Utilisateur.objects.filter(email__in=CLEAN_EMAILS).update(deleted_at=timezone.now())


def main() -> None:
    cleanup()
    province = Province.objects.filter(actif=True).first()
    if not province:
        print('Aucune province active — impossible de tester.')
        sys.exit(1)

    admin = make_user(CLEAN_EMAILS[0], Utilisateur.Role.ADMINISTRATEUR, 'Admin')
    prod_user = make_user(CLEAN_EMAILS[1], Utilisateur.Role.PRODUCTEUR, 'Producteur')
    acheteur_a = make_user(CLEAN_EMAILS[2], Utilisateur.Role.ACHETEUR, 'AcheteurA')
    acheteur_b = make_user(CLEAN_EMAILS[3], Utilisateur.Role.ACHETEUR, 'AcheteurB')

    now = timezone.now()
    fiche = Producteur.objects.create(
        id=uuid.uuid4(),
        code_producteur=f'PRD-CHAT{uuid.uuid4().hex[:4].upper()}',
        nom='Chat', prenoms='Producteur',
        telephone='074000002', email=CLEAN_EMAILS[1],
        province=province, utilisateur_id=prod_user.id, statut='ACTIF',
        sync_statut='SYNCED', sync_version=1, created_at=now, updated_at=now,
    )

    ca = client_for(acheteur_a)
    cb = client_for(acheteur_b)
    cp = client_for(prod_user)
    cadm = client_for(admin)
    anon = APIClient(raise_request_exception=False)

    print('\n=== 1. Ouverture de fil acheteur -> producteur ===')
    r = ca.post('/api/conversations/', {'producteur_id': str(fiche.id), 'sujet': 'Achat moabi'}, format='json')
    check('POST conversation producteur_id -> 201/200', r.status_code in (200, 201), str(getattr(r, 'data', r.content)))
    conv_id = (getattr(r, 'data', None) or {}).get('id') if r.status_code < 400 else None
    check('Conversation id renvoyé', bool(conv_id), str(getattr(r, 'data', r.content))[:200])
    if not conv_id:
        print('Impossible de continuer sans conversation.')
        cleanup()
        sys.exit(1)

    r2 = ca.post('/api/conversations/', {'producteur_id': str(fiche.id)}, format='json')
    check('Réouverture réutilise le même fil', r2.status_code in (200, 201) and str(r2.data.get('id')) == str(conv_id), str(r2.data))

    print('\n=== 2. Messages texte / image / audio ===')
    r = ca.post(f'/api/conversations/{conv_id}/messages/', {'contenu': 'Bonjour, je souhaite acheter 20 kg.'}, format='json')
    check('POST message texte -> 201', r.status_code == 201, str(getattr(r, 'data', r.content)))

    r = ca.post(
        f'/api/conversations/{conv_id}/messages/',
        {'contenu': 'Voici une photo', 'piece': make_photo()},
        format='multipart',
    )
    check('POST message image -> 201', r.status_code == 201, str(getattr(r, 'data', r.content)))
    check('piece_type IMAGE', (r.data or {}).get('piece_type') == 'IMAGE', str(r.data))
    check('piece_url présent', bool((r.data or {}).get('piece_url')), str(r.data))

    r = ca.post(
        f'/api/conversations/{conv_id}/messages/',
        {'piece': make_audio()},
        format='multipart',
    )
    check('POST message audio sans texte -> 201', r.status_code == 201, str(getattr(r, 'data', r.content)))
    check('piece_type AUDIO', (r.data or {}).get('piece_type') == 'AUDIO', str(r.data))

    r = cp.get(f'/api/conversations/{conv_id}/messages/')
    check('Producteur lit le fil', r.status_code == 200 and len(r.data) >= 3, f'{r.status_code} {len(r.data) if r.status_code == 200 else r.data}')

    print('\n=== 3. Isolation acheteur B ===')
    r = cb.get(f'/api/conversations/{conv_id}/')
    check('Acheteur B ne voit pas le fil (404)', r.status_code == 404, str(r.status_code))
    r = cb.get('/api/conversations/')
    ids = [str(x.get('id')) for x in (r.data.get('results') if isinstance(r.data, dict) else r.data or [])]
    check('Liste acheteur B sans le fil A', conv_id not in ids and r.status_code == 200, str(ids))

    print('\n=== 4. Isolation admin + supervision lecture seule ===')
    r = cadm.get('/api/conversations/')
    check('Admin liste son inbox perso', r.status_code == 200, str(getattr(r, 'data', r.content))[:200])
    data = r.data.get('results') if isinstance(r.data, dict) else r.data
    ids = [str(x.get('id')) for x in (data or [])]
    check('Admin ne voit PAS le fil privé dans son inbox', conv_id not in ids, str(ids[:8]))
    r = cadm.get('/api/conversations/supervision/')
    check('Admin supervision sans recherche -> 200', r.status_code == 200, str(getattr(r, 'data', r.content))[:200])
    all_ids = [str(x.get('id')) for x in ((r.data or {}).get('results') or [])]
    check('Admin voit tous les fils en supervision', conv_id in all_ids, str(all_ids[:8]))
    r = cadm.get('/api/conversations/supervision/', {'q': 'moabi'})
    check('Admin supervision recherche -> 200', r.status_code == 200, str(getattr(r, 'data', r.content))[:200])
    s_ids = [str(x.get('id')) for x in ((r.data or {}).get('results') or [])]
    check('Admin trouve le fil via supervision', conv_id in s_ids, str(s_ids[:8]))
    r = cadm.get(f'/api/conversations/{conv_id}/supervision-lire/')
    check(
        'Admin lit en supervision',
        r.status_code == 200 and len((r.data or {}).get('results') or []) >= 1,
        str(getattr(r, 'data', r.content))[:200],
    )
    r = cadm.post(f'/api/conversations/{conv_id}/messages/', {'contenu': 'Tentative écriture admin.'}, format='json')
    check('Admin ne peut pas écrire hors participation', r.status_code in (403, 404), str(r.status_code))
    r = cadm.post('/api/conversations/', {'destinataire_id': str(acheteur_a.id), 'sujet': 'Suivi admin'}, format='json')
    check('Admin ouvre un fil perso avec destinataire_id', r.status_code in (200, 201), str(getattr(r, 'data', r.content)))

    print('\n=== 5. Public + inscription acheteur ===')
    r = anon.get(f'/api/public/producteurs/{fiche.id}/')
    check('Fiche publique compte_connecte=true', r.status_code == 200 and r.data.get('compte_connecte') is True, str(getattr(r, 'data', r.content))[:240])

    email_new = f'chat.acheteur.insc.{uuid.uuid4().hex[:6]}@pnlf-test.local'
    r = anon.post(
        '/api/public/inscription/',
        {
            'type_demande': 'ACHETEUR',
            'nom': 'Mba', 'prenoms': 'Paul',
            'email': email_new, 'telephone': '074999111',
            'password': 'MotDePasse2026!', 'password_confirmation': 'MotDePasse2026!',
            'accepte_conditions': 'true',
        },
        format='multipart',
    )
    check('Inscription publique ACHETEUR -> 201', r.status_code == 201, str(getattr(r, 'data', r.content)))
    u_new = Utilisateur.objects.filter(email__iexact=email_new).first()
    check('Compte acheteur EN_ATTENTE', bool(u_new) and u_new.statut == Utilisateur.Statut.EN_ATTENTE and u_new.role == Utilisateur.Role.ACHETEUR)
    r = cadm.get('/api/dashboard/a-traiter/')
    check('À traiter contient les acheteurs', r.status_code == 200 and (r.data.get('acheteurs') or {}).get('count', 0) >= 1, str(getattr(r, 'data', {}))[:200])
    if u_new:
        r = cadm.post(f'/api/accounts/utilisateurs/{u_new.id}/activer/')
        check('Admin active le compte acheteur', r.status_code == 200, str(getattr(r, 'data', r.content)))
        u_new.refresh_from_db()
        check('Acheteur inscrit est ACTIF', u_new.statut == Utilisateur.Statut.ACTIF)
        CLEAN_EMAILS.append(email_new)

    r = anon.get('/api/conversations/')
    check('Anonyme ne liste pas les conversations (401/403)', r.status_code in (401, 403), str(r.status_code))

    print('\n=== 6. Statuts, non-lus, suppression ===')
    r = ca.post(f'/api/conversations/{conv_id}/messages/', {'contenu': 'Message pour statut'}, format='json')
    check('Message avec statut sortant', r.status_code == 201 and r.data.get('statut') in ('ENVOYE', 'RECU', 'LU'), str(r.data))
    r = cp.get('/api/conversations/non-lus/')
    check('Producteur non-lus > 0', r.status_code == 200 and (r.data or {}).get('count', 0) >= 1, str(r.data))
    r = cp.get(f'/api/conversations/{conv_id}/messages/')
    check('Lecture producteur OK', r.status_code == 200, str(r.status_code))
    r = cp.get('/api/conversations/non-lus/')
    check('Non-lus à 0 après lecture', r.status_code == 200 and (r.data or {}).get('count', 0) == 0, str(r.data))
    r = ca.get(f'/api/conversations/{conv_id}/messages/')
    mine = [m for m in (r.data or []) if m.get('expediteur_id') == str(acheteur_a.id)]
    check('Statut LU après lecture destinataire', any(m.get('statut') == 'LU' for m in mine), str(mine[-1] if mine else None))
    r = ca.delete(f'/api/conversations/{conv_id}/')
    check('Soft-delete conversation -> 204', r.status_code == 204, str(r.status_code))
    r = ca.get('/api/conversations/')
    ids = [str(x.get('id')) for x in (r.data.get('results') if isinstance(r.data, dict) else r.data or [])]
    check('Conversation absente après suppression', conv_id not in ids, str(ids[:8]))
    r = cp.get('/api/conversations/')
    ids = [str(x.get('id')) for x in (r.data.get('results') if isinstance(r.data, dict) else r.data or [])]
    check('Producteur conserve le fil', conv_id in ids, str(ids[:8]))

    print('\n=== 7. Pagination publique ===')
    r = anon.get('/api/public/producteurs/', {'page': 1, 'page_size': 5})
    check('Annuaire public paginé', r.status_code == 200 and 'results' in (r.data or {}) and 'count' in (r.data or {}), str(r.data)[:120])
    r = anon.get('/api/public/offres-demandes/', {'page': 1, 'page_size': 5})
    check('Offres publiques paginées', r.status_code == 200 and 'results' in (r.data or {}) and 'count' in (r.data or {}), str(r.data)[:120])

    print('\n=== Nettoyage ===')
    cleanup()
    print(f'\nRésultat : {len(PASS)} OK, {len(FAIL)} FAIL')
    if FAIL:
        sys.exit(1)


if __name__ == '__main__':
    with override_settings(
        ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'],
        PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'],
    ):
        main()
