"""
Tests smoke des nouveaux modules cadrage (6.1–6.9).
Usage: python backend/scripts/test_cadrage_modules.py
"""
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

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import Utilisateur

PASS, FAIL = [], []


def ok(m):
    PASS.append(m)
    print(f'  [OK] {m}')


def fail(m, d=''):
    FAIL.append(m)
    print(f'  [FAIL] {m} — {d}')


def _hash(p):
    import bcrypt
    return bcrypt.hashpw(p.encode(), bcrypt.gensalt(12)).decode()


def ensure_user(email, role):
    u, _ = Utilisateur.objects.get_or_create(
        email=email,
        defaults={
            'mot_de_passe_hash': _hash('Test2026!'),
            'role': role, 'statut': 'ACTIF', 'nom': 'T', 'prenoms': 'U',
            'created_at': timezone.now(), 'updated_at': timezone.now(),
        },
    )
    Utilisateur.objects.filter(pk=u.pk).update(deleted_at=None, statut='ACTIF')
    return u


def login(client, email):
    r = client.post('/api/auth/login/', {'email': email, 'password': 'Test2026!'}, format='json')
    assert r.status_code == 200, r.data
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {r.data["access"]}')


def run():
    client = APIClient()
    admin = ensure_user('cadrage_admin@pnlf-test.local', Utilisateur.Role.ADMINISTRATEUR)
    agent = ensure_user('cadrage_agent@pnlf-test.local', Utilisateur.Role.AGENT_MINISTERE)

    print('=== Module 6.1 Utilisateurs ===')
    login(client, admin.email)
    r = client.get('/api/accounts/utilisateurs/')
    ok('GET utilisateurs') if r.status_code == 200 else fail('GET utilisateurs', str(r.status_code))

    print('=== Module 6.5 Géo ===')
    r = client.get('/api/departements/')
    ok('GET departements') if r.status_code == 200 else fail('GET departements', str(r.status_code))
    r = client.get('/api/villages/')
    ok('GET villages') if r.status_code == 200 else fail('GET villages', str(r.status_code))
    r = client.get('/api/zones-collecte/')
    ok('GET zones-collecte') if r.status_code == 200 else fail('GET zones-collecte', str(r.status_code))

    print('=== Module 6.2 Coopératives ===')
    r = client.get('/api/cooperatives/')
    ok('GET cooperatives') if r.status_code == 200 else fail('GET cooperatives', str(r.status_code))

    print('=== Module 6.6 Dashboard ===')
    login(client, agent.email)
    r = client.get('/api/dashboard/stats/')
    ok('GET dashboard') if r.status_code == 200 else fail('GET dashboard', str(r.status_code))

    print('=== Module 6.7 Export ===')
    r = client.get('/api/exports/lots/?export_format=csv')
    ok('EXPORT csv') if r.status_code == 200 else fail('EXPORT csv', str(r.status_code))

    print('=== Module 6.8 Notifications ===')
    r = client.get('/api/notifications/')
    ok('GET notifications') if r.status_code == 200 else fail('GET notifications', str(r.status_code))

    print('=== Module 6.9 Mise en relation ===')
    r = client.get('/api/offres-demandes/')
    ok('GET offres-demandes') if r.status_code == 200 else fail('GET offres-demandes', str(r.status_code))
    r = client.get('/api/annuaire/')
    ok('GET annuaire') if r.status_code == 200 else fail('GET annuaire', str(r.status_code))

    print('=== Module 6.4 Vérification publique ===')
    client.credentials()
    from traceability.models import Lot
    lot = Lot.objects.filter(deleted_at__isnull=True).first()
    if not lot:
        # créer lot minimal via admin si base vide
        from traceability.models import Producteur, Produit, Province
        prov = Province.objects.filter(actif=True).first()
        prod = Produit.objects.filter(actif=True).first()
        pr = Producteur.objects.filter(deleted_at__isnull=True).first()
        if prov and prod and pr:
            from datetime import date
            lot = Lot.objects.create(
                produit=prod, producteur=pr, date_collecte=date.today(),
                quantite=1, unite='KG', statut='BROUILLON',
                created_at=timezone.now(), updated_at=timezone.now(),
            )
            lot.refresh_from_db()
    if lot:
        r = client.get(f'/api/verify/{lot.uuid_public}/')
        ok('GET verify public') if r.status_code == 200 else fail('GET verify public', str(r.status_code))
    else:
        fail('GET verify public', 'aucun lot')

    print('=== Certifications ===')
    login(client, agent.email)
    r = client.get('/api/types-certification/')
    ok('GET types-certification') if r.status_code == 200 else fail('GET types-certification', str(r.status_code))

    print('=== Sync offline ===')
    r = client.post('/api/sync/push/', {'device_id': f'test-{uuid.uuid4().hex[:6]}'}, format='json')
    ok('POST sync/push') if r.status_code == 200 else fail('POST sync/push', str(r.status_code))
    r = client.get('/api/sync/pull/')
    ok('GET sync/pull') if r.status_code == 200 else fail('GET sync/pull', str(r.status_code))


if __name__ == '__main__':
    print('TEST MODULES CADRAGE PNLF')
    print('=' * 50)
    with override_settings(ALLOWED_HOSTS=['testserver', 'localhost']):
        run()
    print('=' * 50)
    print(f'RESULTAT: {len(PASS)} OK | {len(FAIL)} FAIL')
    if FAIL:
        for f in FAIL:
            print(f'  - {f}')
        sys.exit(1)
