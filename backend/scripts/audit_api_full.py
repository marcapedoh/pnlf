"""Tests intégration + sécurité API sur base réelle (avec nettoyage)."""
import os
import sys
import uuid
from datetime import date
from pathlib import Path

import django
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
ROOT = BACKEND.parent
sys.path.insert(0, str(BACKEND))
load_dotenv(BACKEND / '.env')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import Utilisateur
from traceability.models import Lot, Producteur, Produit, Province

PASS, FAIL, WARN = [], [], []


def ok(m):
    PASS.append(m)
    print(f'  [OK] {m}')


def fail(m, detail=''):
    FAIL.append(m)
    print(f'  [FAIL] {m}' + (f' — {detail}' if detail else ''))


def warn(m):
    WARN.append(m)
    print(f'  [WARN] {m}')


def make_user(suffix, role, password='TestPass123!'):
    import bcrypt
    email = f'test_{suffix}@pnlf-test.local'
    pwd_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()
    u, created = Utilisateur.objects.get_or_create(
        email=email,
        defaults={
            'mot_de_passe_hash': pwd_hash,
            'role': role,
            'statut': Utilisateur.Statut.ACTIF,
            'nom': 'Test',
            'prenoms': suffix,
            'created_at': timezone.now(),
            'updated_at': timezone.now(),
        },
    )
    if not created:
        Utilisateur.objects.filter(pk=u.pk).update(
            mot_de_passe_hash=pwd_hash,
            role=role,
            statut=Utilisateur.Statut.ACTIF,
            deleted_at=None,
        )
        u.refresh_from_db()
    return u, password


def login(client, email, password):
    r = client.post('/api/auth/login/', {'email': email, 'password': password}, format='json')
    return r


def auth(client, email, password):
    r = login(client, email, password)
    if r.status_code != 200:
        return None
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
    return r.data


# IDs créés pour nettoyage
_cleanup_users = []
_cleanup_producteurs = []
_cleanup_lots = []
_cleanup_produits = []


def cleanup():
    from django.db import connection
    for lid in _cleanup_lots:
        Lot.objects.filter(pk=lid).update(deleted_at=timezone.now())
    for pid in _cleanup_producteurs:
        Producteur.objects.filter(pk=pid).update(deleted_at=timezone.now())
    for prid in _cleanup_produits:
        Produit.objects.filter(pk=prid).update(actif=False)
    for uid in _cleanup_users:
        Utilisateur.objects.filter(pk=uid).update(deleted_at=timezone.now(), statut='INACTIF')
    # audit_logs append-only pour pnlf_app : pas de DELETE en cleanup
    pass


def section(title):
    print(f'\n=== {title} ===')


def run_tests():
    client = APIClient()
    province = Province.objects.filter(actif=True).first()
    produit = Produit.objects.filter(actif=True, code__startswith='PFNL-').first()
    if not province or not produit:
        fail('Données référentielles manquantes (province/produit)')
        return

    section('Auth')
    admin, pwd = make_user('admin', Utilisateur.Role.ADMINISTRATEUR)
    _cleanup_users.append(admin.id)

    r = login(client, admin.email, pwd)
    if r.status_code == 200 and 'access' in r.data:
        ok('Login admin réussi')
    else:
        fail('Login admin', str(r.status_code))

    r_bad = client.post('/api/auth/login/', {'email': admin.email, 'password': 'wrong'}, format='json')
    if r_bad.status_code == 400:
        ok('Login mot de passe incorrect rejeté')
    else:
        fail('Login bad password', str(r_bad.status_code))

    client.credentials()
    r_no = client.get('/api/provinces/')
    if r_no.status_code == 401:
        ok('Accès sans token refusé (401)')
    else:
        fail('Accès sans token', str(r_no.status_code))

    auth(client, admin.email, pwd)
    r_me = client.get('/api/accounts/me/')
    if r_me.status_code == 200 and r_me.data.get('role') == 'ADMINISTRATEUR':
        ok('/api/accounts/me/ OK')
    else:
        fail('/api/accounts/me/', str(r_me.status_code))

    section('RBAC — Acheteur (lecture seule)')
    acheteur, pwd_a = make_user('acheteur', Utilisateur.Role.ACHETEUR)
    _cleanup_users.append(acheteur.id)
    auth(client, acheteur.email, pwd_a)

    if client.get('/api/provinces/').status_code == 200:
        ok('Acheteur: lecture provinces')
    else:
        fail('Acheteur: lecture provinces')

    r = client.post('/api/producteurs/', {
        'code_producteur': f'ACH-{uuid.uuid4().hex[:6]}',
        'nom': 'X', 'prenoms': 'Y', 'province': str(province.id), 'statut': 'ACTIF',
    }, format='json')
    if r.status_code == 403:
        ok('Acheteur: création producteur refusée (403)')
    else:
        fail('Acheteur: création producteur', str(r.status_code))

    r = client.post('/api/produits/', {
        'code': 'TST-FORBID', 'nom': 'Interdit', 'categorie': str(produit.categorie_id), 'unite_defaut': 'KG',
    }, format='json')
    if r.status_code == 403:
        ok('Acheteur: création produit refusée (403)')
    else:
        fail('Acheteur: création produit', str(r.status_code))

    section('RBAC — Producteur (ses données uniquement)')
    prod_user, pwd_p = make_user('producteur', Utilisateur.Role.PRODUCTEUR)
    _cleanup_users.append(prod_user.id)

    own = Producteur.objects.create(
        code_producteur=f'OWN-{uuid.uuid4().hex[:6]}',
        nom='Moi', prenoms='Prod', province=province,
        utilisateur_id=prod_user.id, statut='ACTIF',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup_producteurs.append(own.id)

    other = Producteur.objects.create(
        code_producteur=f'OTH-{uuid.uuid4().hex[:6]}',
        nom='Autre', prenoms='Prod', province=province, statut='ACTIF',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup_producteurs.append(other.id)

    auth(client, prod_user.email, pwd_p)
    r = client.get('/api/producteurs/')
    results = r.data.get('results', r.data) if r.status_code == 200 else []
    codes = [x['code_producteur'] for x in results]
    if own.code_producteur in codes and other.code_producteur not in codes:
        ok('Producteur: voit uniquement sa fiche')
    else:
        fail('Producteur: filtrage données', f'codes={codes}')

    r = client.post('/api/produits/', {
        'code': f'TST-{uuid.uuid4().hex[:6]}',
        'nom': 'Interdit prod', 'categorie': str(produit.categorie_id), 'unite_defaut': 'KG',
    }, format='json')
    if r.status_code == 403:
        ok('Producteur: création produit refusée')
    else:
        fail('Producteur: création produit', str(r.status_code))

    section('RBAC — Agent ministère')
    agent, pwd_ag = make_user('agent_min', Utilisateur.Role.AGENT_MINISTERE)
    _cleanup_users.append(agent.id)
    auth(client, agent.email, pwd_ag)

    code = f'TST-AG-{uuid.uuid4().hex[:6]}'
    r = client.post('/api/produits/', {
        'code': code, 'nom': 'Produit agent', 'categorie': str(produit.categorie_id), 'unite_defaut': 'KG',
    }, format='json')
    if r.status_code in (200, 201):
        ok('Agent ministère: création produit autorisée')
        pr = Produit.objects.filter(code=code).first()
        if pr:
            _cleanup_produits.append(pr.id)
    else:
        fail('Agent ministère: création produit', str(r.status_code))

    section('Traçabilité — Lot + mouvement')
    auth(client, admin.email, pwd)
    producteur = Producteur.objects.create(
        code_producteur=f'LOT-{uuid.uuid4().hex[:6]}',
        nom='Lot', prenoms='Test', province=province, statut='ACTIF',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup_producteurs.append(producteur.id)

    r = client.post('/api/lots/', {
        'produit': str(produit.id),
        'producteur': str(producteur.id),
        'date_collecte': str(date.today()),
        'quantite': '15.000',
        'unite': 'KG',
        'statut': 'DECLARE',
    }, format='json')
    if r.status_code == 201:
        code_lot = r.data.get('code_lot', '')
        mvts = r.data.get('mouvements', [])
        if code_lot.startswith('PNLF-') and len(mvts) >= 1:
            ok(f'Création lot + mouvement COLLECTE ({code_lot})')
            _cleanup_lots.append(r.data['id'])
        else:
            fail('Lot sans code_lot ou mouvement', str(r.data))
    else:
        fail('Création lot', f'{r.status_code} {getattr(r, "data", r.content)}')

    if r.status_code == 201:
        lot_id = r.data['id']
        r_tr = client.get(f'/api/lots/{lot_id}/tracabilite/')
        if r_tr.status_code == 200:
            ok('Endpoint traçabilité lot')
        else:
            fail('Traçabilité lot', str(r_tr.status_code))

        r_del = client.delete(f'/api/lots/{lot_id}/')
        if r_del.status_code == 204:
            ok('Soft-delete lot')
        else:
            fail('Soft-delete lot', str(r_del.status_code))

    section('Audit')
    from django.db import connection
    with connection.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM audit_logs WHERE action = 'LOGIN'")
        n = cur.fetchone()[0]
    if n > 0:
        ok(f'Journal audit LOGIN actif ({n} entrées)')
    else:
        warn('Aucune entrée audit LOGIN (vérifier write_audit)')

    section('Settings sécurité')
    from django.conf import settings
    if not settings.DEBUG:
        ok('DEBUG=False')
    else:
        warn('DEBUG=True (acceptable en dev local uniquement)')
    if settings.SECRET_KEY and settings.SECRET_KEY != 'insecure-dev-key':
        ok('SECRET_KEY personnalisée')
    else:
        warn('SECRET_KEY par défaut — à changer en production')
    if settings.SIMPLE_JWT.get('ACCESS_TOKEN_LIFETIME').total_seconds() <= 3600 * 2:
        ok('Durée token access raisonnable (<=2h)')
    else:
        warn('Token access très long')
    if settings.REST_FRAMEWORK.get('DEFAULT_THROTTLE_RATES', {}).get('login'):
        ok('Rate-limit login configuré')
    else:
        warn('Pas de throttle login')


if __name__ == '__main__':
    print('AUDIT API / BACKEND PNLF')
    print('=' * 50)
    try:
        with override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1']):
            run_tests()
    finally:
        print('\n--- Nettoyage donnees test ---')
        cleanup()
        print('Nettoyage termine')

    print('\n' + '=' * 50)
    print(f'RESULTAT: {len(PASS)} OK | {len(WARN)} WARN | {len(FAIL)} FAIL')
    for f in FAIL:
        print(f'  ! {f}')
    for w in WARN:
        print(f'  ? {w}')
    if FAIL:
        sys.exit(1)
