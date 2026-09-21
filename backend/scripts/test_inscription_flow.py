"""Test end-to-end du flux d'inscription publique -> validation -> notification.

Usage:
  python backend/scripts/test_inscription_flow.py
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
from pnlf_platform.models import Notification
from traceability.models import Cooperative, Producteur, Province

PASS: list[str] = []
FAIL: list[str] = []


def check(label: str, ok: bool, detail: str = '') -> None:
    if ok:
        PASS.append(label)
        print(f'  [OK] {label}')
    else:
        FAIL.append(label)
        print(f'  [FAIL] {label} {detail}')


def make_photo() -> SimpleUploadedFile:
    from PIL import Image

    buf = io.BytesIO()
    Image.new('RGB', (100, 100), color=(10, 120, 60)).save(buf, format='JPEG')
    buf.seek(0)
    return SimpleUploadedFile('photo.jpg', buf.read(), content_type='image/jpeg')


def get_or_create_admin() -> Utilisateur:
    admin = Utilisateur.objects.filter(email='inscription_test_admin@pnlf-test.local').first()
    if admin:
        if admin.deleted_at is not None or admin.statut != Utilisateur.Statut.ACTIF:
            admin.deleted_at = None
            admin.statut = Utilisateur.Statut.ACTIF
            admin.save(update_fields=['deleted_at', 'statut'])
        return admin
    admin = Utilisateur(
        id=uuid.uuid4(), email='inscription_test_admin@pnlf-test.local', telephone='074000000',
        role=Utilisateur.Role.ADMINISTRATEUR, statut=Utilisateur.Statut.ACTIF, nom='Test', prenoms='Admin',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    admin.set_password('AdminTest2026!')
    admin.save()
    return admin


def cleanup(emails: list[str]) -> None:
    Producteur.objects.filter(email__in=emails).delete()
    Cooperative.objects.filter(email__in=emails).delete()
    Cooperative.objects.filter(nom__startswith='Coopérative Test Moabi').delete()
    # Soft-delete uniquement : certains de ces comptes ont pu générer une ligne
    # audit_logs (ex. LOGIN), or cette table est immuable (trigger BEFORE UPDATE/DELETE)
    # et sa contrainte FK ON DELETE SET NULL empêcherait alors le DELETE ORM.
    Utilisateur.objects.filter(email__in=emails).update(deleted_at=timezone.now())


def main() -> None:
    # Nettoyage préalable au cas où une exécution précédente aurait échoué avant son propre nettoyage.
    Cooperative.objects.filter(nom__startswith='Coopérative Test Moabi').delete()

    province = Province.objects.filter(actif=True).first()
    if not province:
        print('Aucune province active en base — impossible de tester.')
        sys.exit(1)

    admin = get_or_create_admin()
    admin_client = APIClient()
    admin_client.force_authenticate(user=admin)
    anon_client = APIClient()

    email_prod = f'test.producteur.{uuid.uuid4().hex[:8]}@pnlf-test.local'
    email_coop = f'test.coop.{uuid.uuid4().hex[:8]}@pnlf-test.local'
    email_bot = f'bot.{uuid.uuid4().hex[:6]}@pnlf-test.local'

    print("\n=== 1. Inscription publique — producteur ===")
    payload = {
        'type_demande': 'PRODUCTEUR',
        'nom': 'Ondo', 'prenoms': 'Jean',
        'email': email_prod, 'telephone': '074123456',
        'password': 'MotDePasse2026!', 'password_confirmation': 'MotDePasse2026!',
        'photo': make_photo(),
        'province': str(province.id),
        'accepte_conditions': 'true',
        'message': 'Je collecte du moabi et du kola.',
    }
    resp = anon_client.post('/api/public/inscription/', payload, format='multipart')
    check('POST /public/inscription/ producteur -> 201', resp.status_code == 201, str(resp.data) if resp.status_code != 201 else '')

    user_prod = Utilisateur.objects.filter(email__iexact=email_prod).first()
    check('Utilisateur créé avec statut EN_ATTENTE', bool(user_prod) and user_prod.statut == 'EN_ATTENTE')
    fiche_prod = Producteur.objects.filter(email__iexact=email_prod).first()
    check('Producteur créé avec statut EN_VALIDATION', bool(fiche_prod) and fiche_prod.statut == 'EN_VALIDATION')
    check('Photo enregistrée sur disque', fiche_prod is not None and _photo_exists('producteurs', fiche_prod.id))

    # Honeypot : doit être rejeté
    payload2 = dict(payload)
    payload2['email'] = email_bot
    payload2['site_web'] = 'http://spam.example'
    payload2['photo'] = make_photo()
    resp_bot = anon_client.post('/api/public/inscription/', payload2, format='multipart')
    check('Honeypot rempli -> requête rejetée (400)', resp_bot.status_code == 400)

    # Email dupliqué refusé
    payload3 = dict(payload)
    payload3['photo'] = make_photo()
    resp_dup = anon_client.post('/api/public/inscription/', payload3, format='multipart')
    check('Email déjà utilisé -> requête rejetée (400)', resp_dup.status_code == 400)

    print("\n=== 2. Connexion refusée avant validation ===")
    resp_login = anon_client.post(
        '/api/auth/login/', {'email': email_prod, 'password': 'MotDePasse2026!'}, format='json',
    )
    check('Connexion refusée (compte en attente)', resp_login.status_code in (400, 401))

    print("\n=== 3. Validation admin — producteur ===")
    resp_val = admin_client.post(f'/api/producteurs/{fiche_prod.id}/valider/')
    check('POST /producteurs/{id}/valider/ -> 200', resp_val.status_code == 200, str(resp_val.data) if resp_val.status_code != 200 else '')
    user_prod.refresh_from_db()
    check('Utilisateur activé (statut ACTIF)', user_prod.statut == 'ACTIF')

    notifs = Notification.objects.filter(destinataire_id=user_prod.id).order_by('created_at')
    check('Notifications EMAIL/SMS journalisées', notifs.filter(type_notif__in=['EMAIL', 'SMS']).exists())
    email_notif = notifs.filter(type_notif='EMAIL').order_by('-created_at').first()
    check('Email de validation marqué envoyé (console backend)', bool(email_notif) and email_notif.envoyee_at is not None)
    sms_notif = notifs.filter(type_notif='SMS').order_by('-created_at').first()
    check('SMS journalisé (erreur si Twilio non configuré)', bool(sms_notif))

    print("\n=== 4. Connexion possible après validation ===")
    resp_login2 = anon_client.post(
        '/api/auth/login/', {'email': email_prod, 'password': 'MotDePasse2026!'}, format='json',
    )
    check('Connexion réussie après validation', resp_login2.status_code == 200, str(resp_login2.data) if resp_login2.status_code != 200 else '')

    print("\n=== 5. Inscription publique — coopérative + rejet ===")
    payload_coop = {
        'type_demande': 'COOPERATIVE',
        'nom': 'Coopérative Test Moabi',
        'email': email_coop, 'telephone': '074987654',
        'password': 'MotDePasse2026!', 'password_confirmation': 'MotDePasse2026!',
        'photo': make_photo(),
        'province': str(province.id),
        'accepte_conditions': 'true',
    }
    resp_coop = anon_client.post('/api/public/inscription/', payload_coop, format='multipart')
    check('POST /public/inscription/ coopérative -> 201', resp_coop.status_code == 201, str(resp_coop.data) if resp_coop.status_code != 201 else '')

    fiche_coop = Cooperative.objects.filter(email__iexact=email_coop).first()
    check('Coopérative créée avec actif=False', bool(fiche_coop) and fiche_coop.actif is False)
    user_coop = Utilisateur.objects.filter(email__iexact=email_coop).first()
    check('Utilisateur coopérative créé (rôle COOPERATIVE, EN_ATTENTE)', bool(user_coop) and user_coop.role == 'COOPERATIVE' and user_coop.statut == 'EN_ATTENTE')

    resp_admin_list = admin_client.get('/api/cooperatives/', {'actif': 'false'})
    check('Admin voit les coopératives en attente dans la liste', resp_admin_list.status_code == 200)

    resp_rej = admin_client.post(f'/api/cooperatives/{fiche_coop.id}/rejeter/', {'motif': 'Numéro d\'agrément à fournir.'}, format='json')
    check('POST /cooperatives/{id}/rejeter/ -> 200', resp_rej.status_code == 200, str(resp_rej.data) if resp_rej.status_code != 200 else '')
    check('Utilisateur coopérative supprimé après rejet (email libéré)', not Utilisateur.objects.filter(pk=user_coop.id).exists())
    fiche_coop.refresh_from_db()
    check('Nom de la coopérative rejetée suffixé (libère le nom)', '[REJETÉ' in fiche_coop.nom)

    # Un nouvel essai avec le même email ET le même nom doit maintenant être possible
    payload_coop2 = dict(payload_coop)
    payload_coop2['photo'] = make_photo()
    resp_retry = anon_client.post('/api/public/inscription/', payload_coop2, format='multipart')
    check(
        'Nouvel essai possible après rejet (email + nom libérés)',
        resp_retry.status_code == 201, str(resp_retry.data) if resp_retry.status_code != 201 else '',
    )

    print("\n=== Nettoyage ===")
    cleanup([email_prod, email_coop, email_bot])
    Utilisateur.objects.filter(email='inscription_test_admin@pnlf-test.local').update(deleted_at=timezone.now())
    print('OK')

    print(f"\n=== RÉSUMÉ : {len(PASS)} OK / {len(FAIL)} ÉCHECS ===")
    if FAIL:
        print('Échecs :', FAIL)
        sys.exit(1)


def _photo_exists(sous_dossier: str, entite_id) -> bool:
    from django.conf import settings

    return (Path(settings.MEDIA_ROOT) / 'photos' / sous_dossier / f'{entite_id}.jpg').exists()


if __name__ == '__main__':
    with override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1']):
        main()
