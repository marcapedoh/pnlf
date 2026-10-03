"""
Matrice RBAC complète — alignée note de cadrage §5.2

Profils et droits attendus (API V1 actuelle) :
  ADMINISTRATEUR     : accès total
  AGENT_MINISTERE    : lecture + écriture + validation (référentiel inclus)
  AGENT_FORESTIER    : lecture + écriture terrain (pas référentiel produits)
  PRODUCTEUR         : lecture/écriture sur ses propres données
  COOPERATIVE        : lecture/écriture sur données des membres
  ACHETEUR           : lecture seule

Usage:
  python backend/scripts/test_rbac_matrix.py
"""
from __future__ import annotations

import os
import sys
import uuid
from dataclasses import dataclass
from datetime import date
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
from traceability.models import Cooperative, Lot, Producteur, Produit, Province

PWD = 'RbacTest2026!'
PASS: list[str] = []
FAIL: list[str] = []
SKIP: list[str] = []

# IDs pour nettoyage
_cleanup = {
    'users': [],
    'coops': [],
    'producteurs': [],
    'lots': [],
    'produits': [],
}


@dataclass
class RoleCtx:
    key: str
    role: str
    email: str
    user: Utilisateur | None = None
    token: str | None = None


ROLES = [
    RoleCtx('admin', Utilisateur.Role.ADMINISTRATEUR, 'rbac_admin@pnlf-test.local'),
    RoleCtx('agent_min', Utilisateur.Role.AGENT_MINISTERE, 'rbac_agentmin@pnlf-test.local'),
    RoleCtx('agent_for', Utilisateur.Role.AGENT_FORESTIER, 'rbac_agentfor@pnlf-test.local'),
    RoleCtx('producteur', Utilisateur.Role.PRODUCTEUR, 'rbac_producteur@pnlf-test.local'),
    RoleCtx('cooperative', Utilisateur.Role.COOPERATIVE, 'rbac_coop@pnlf-test.local'),
    RoleCtx('acheteur', Utilisateur.Role.ACHETEUR, 'rbac_acheteur@pnlf-test.local'),
]


def _hash_pwd(raw: str) -> str:
    import bcrypt
    return bcrypt.hashpw(raw.encode(), bcrypt.gensalt(rounds=12)).decode()


def ok(case_id: str, detail: str = ''):
    PASS.append(case_id)
    print(f'  [OK] {case_id}' + (f' — {detail}' if detail else ''))


def fail(case_id: str, expected: str, got: str):
    FAIL.append(case_id)
    print(f'  [FAIL] {case_id} — attendu {expected}, obtenu {got}')


def expect_status(case_id: str, response, expected: int | set[int]):
    exp = {expected} if isinstance(expected, int) else expected
    if response.status_code in exp:
        ok(case_id, str(response.status_code))
        return True
    fail(case_id, str(exp), str(response.status_code))
    return False


def make_user(ctx: RoleCtx) -> Utilisateur:
    u, created = Utilisateur.objects.get_or_create(
        email=ctx.email,
        defaults={
            'mot_de_passe_hash': _hash_pwd(PWD),
            'role': ctx.role,
            'statut': Utilisateur.Statut.ACTIF,
            'nom': 'Test',
            'prenoms': ctx.key,
            'created_at': timezone.now(),
            'updated_at': timezone.now(),
        },
    )
    if not created:
        Utilisateur.objects.filter(pk=u.pk).update(
            mot_de_passe_hash=_hash_pwd(PWD),
            role=ctx.role,
            statut=Utilisateur.Statut.ACTIF,
            deleted_at=None,
        )
        u.refresh_from_db()
    ctx.user = u
    _cleanup['users'].append(u.id)
    return u


def login(client: APIClient, ctx: RoleCtx) -> str:
    r = client.post('/api/auth/login/', {'email': ctx.email, 'password': PWD}, format='json')
    assert r.status_code == 200, f'Login {ctx.key} failed: {r.status_code}'
    ctx.token = r.data['access']
    return ctx.token


def auth_as(client: APIClient, ctx: RoleCtx):
    if not ctx.token:
        login(client, ctx)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {ctx.token}')


def pre_cleanup():
    """Nettoie les résidus d'exécutions précédentes interrompues."""
    now = timezone.now()
    tag = uuid.uuid4().hex[:8]
    Cooperative.objects.filter(nom='Coopérative Test RBAC').update(
        nom=f'Coopérative Test RBAC archivée {tag}',
        actif=False,
        updated_at=now,
    )
    Lot.objects.filter(code_lot__startswith='PNLF-RBAC-').update(deleted_at=now, updated_at=now)
    Producteur.objects.filter(
        code_producteur__regex=r'^(PRD-(OWN|MEM|OTH)|RBAC|AGF)-'
    ).update(deleted_at=now, updated_at=now)
    for p in Produit.objects.filter(code__startswith='RBAC-') | Produit.objects.filter(code__startswith='AGF-BAD-'):
        suffix = uuid.uuid4().hex[:6]
        Produit.objects.filter(pk=p.pk).update(
            code=f'X{suffix}',
            nom=f'Archivé {suffix}',
            actif=False,
            updated_at=now,
        )
    for p in Produit.objects.filter(nom__startswith='Test RBAC '):
        suffix = uuid.uuid4().hex[:6]
        Produit.objects.filter(pk=p.pk).update(
            nom=f'Archivé {suffix}',
            actif=False,
            updated_at=now,
        )
    Utilisateur.objects.filter(email__endswith='@pnlf-test.local').update(
        deleted_at=None,
        statut=Utilisateur.Statut.ACTIF,
        updated_at=now,
    )


def setup_fixtures(province: Province, produit: Produit, ctx_coop: RoleCtx, ctx_prod: RoleCtx):
    """Coopérative + producteur membre + producteur externe + lots."""
    tag = uuid.uuid4().hex[:8]
    coop = Cooperative.objects.create(
        code=f'COOP-RBAC-{tag}',
        nom=f'Coopérative Test RBAC {tag}',
        province=province,
        utilisateur_id=ctx_coop.user.id,
        actif=True,
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['coops'].append(coop.id)

    prod_own = Producteur.objects.create(
        code_producteur=f'PRD-OWN-{uuid.uuid4().hex[:6]}',
        nom='Producteur', prenoms='Propre',
        province=province,
        utilisateur_id=ctx_prod.user.id,
        cooperative=coop,
        statut='ACTIF',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['producteurs'].append(prod_own.id)

    prod_member = Producteur.objects.create(
        code_producteur=f'PRD-MEM-{uuid.uuid4().hex[:6]}',
        nom='Membre', prenoms='Coop',
        province=province,
        cooperative=coop,
        statut='ACTIF',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['producteurs'].append(prod_member.id)

    prod_other = Producteur.objects.create(
        code_producteur=f'PRD-OTH-{uuid.uuid4().hex[:6]}',
        nom='Autre', prenoms='Externe',
        province=province,
        statut='ACTIF',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['producteurs'].append(prod_other.id)

    lot_member = Lot.objects.create(
        code_lot=f'PNLF-RBAC-M-{uuid.uuid4().hex[:6]}',
        produit=produit,
        producteur=prod_member,
        cooperative=coop,
        date_collecte=date.today(),
        quantite=10,
        unite='KG',
        statut='BROUILLON',
        declare_par_id=ctx_coop.user.id,
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['lots'].append(lot_member.id)

    lot_other = Lot.objects.create(
        code_lot=f'PNLF-RBAC-O-{uuid.uuid4().hex[:6]}',
        produit=produit,
        producteur=prod_other,
        date_collecte=date.today(),
        quantite=5,
        unite='KG',
        statut='BROUILLON',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['lots'].append(lot_other.id)

    return {
        'coop': coop,
        'prod_own': prod_own,
        'prod_member': prod_member,
        'prod_other': prod_other,
        'lot_member': lot_member,
        'lot_other': lot_other,
    }


def cleanup():
    now = timezone.now()
    for lid in _cleanup['lots']:
        Lot.objects.filter(pk=lid).update(deleted_at=now, updated_at=now)
    for pid in _cleanup['producteurs']:
        Producteur.objects.filter(pk=pid).update(deleted_at=now, updated_at=now)
    for prid in _cleanup['produits']:
        Produit.objects.filter(pk=prid).update(actif=False, updated_at=now)
    for uid in _cleanup['users']:
        Utilisateur.objects.filter(pk=uid).update(deleted_at=now, statut='INACTIF', updated_at=now)
    # cooperatives : soft via actif=False si pas deleted_at
    Cooperative.objects.filter(id__in=_cleanup['coops']).update(actif=False, updated_at=now)


# ---------------------------------------------------------------------------
# Matrice attendue : (endpoint, method, role_key) -> status HTTP attendu
# ---------------------------------------------------------------------------
READ_ALL = {200}
WRITE_OK = {200, 201, 204}
WRITE_FORBIDDEN = {403}
READ_FORBIDDEN = {401, 403, 404}

# Endpoints lecture — tous profils (cadrage : consultation)
READ_ENDPOINTS = [
    ('GET', '/api/provinces/'),
    ('GET', '/api/categories-produits/'),
    ('GET', '/api/produits/'),
    ('GET', '/api/accounts/me/'),
]

# Écriture référentiel produits
PRODUIT_WRITE = {
    'admin': WRITE_OK,
    'agent_min': WRITE_OK,
    'agent_for': WRITE_FORBIDDEN,
    'producteur': WRITE_FORBIDDEN,
    'cooperative': WRITE_FORBIDDEN,
    'acheteur': WRITE_FORBIDDEN,
}

# Écriture producteurs (POST)
PRODUCTEUR_POST = {
    'admin': WRITE_OK,
    'agent_min': WRITE_OK,
    'agent_for': WRITE_OK,
    'producteur': WRITE_OK,
    'cooperative': WRITE_OK,
    'acheteur': WRITE_FORBIDDEN,
}

# Écriture lots (POST)
LOT_POST = {
    'admin': WRITE_OK,
    'agent_min': WRITE_OK,
    'agent_for': WRITE_OK,
    'producteur': WRITE_OK,  # pour son propre producteur
    'cooperative': WRITE_OK,
    'acheteur': WRITE_FORBIDDEN,
}

# Mouvements POST
MOUVEMENT_POST = {
    'admin': WRITE_OK,
    'agent_min': WRITE_OK,
    'agent_for': WRITE_OK,
    'producteur': WRITE_OK,
    'cooperative': WRITE_OK,
    'acheteur': WRITE_FORBIDDEN,
}


def run_matrix():
    client = APIClient()
    pre_cleanup()
    province = Province.objects.filter(actif=True).first()
    produit = Produit.objects.filter(actif=True, code__startswith='PFNL-').first()
    if not province or not produit:
        raise RuntimeError('Données référentielles manquantes — exécuter 04_seed_referentiel_gabon.sql')

    ctx_map = {r.key: r for r in ROLES}
    for r in ROLES:
        make_user(r)
        login(client, r)

    fx = setup_fixtures(province, produit, ctx_map['cooperative'], ctx_map['producteur'])

    print('\n=== UC-AUTH : Authentification ===')
    client.credentials()
    expect_status('UC-AUTH-01 sans token provinces', client.get('/api/provinces/'), 401)
    r = client.post('/api/auth/login/', {'email': 'rbac_admin@pnlf-test.local', 'password': 'wrong'}, format='json')
    expect_status('UC-AUTH-02 mauvais mot de passe', r, 400)
    r = client.post('/api/auth/login/', {'email': 'rbac_admin@pnlf-test.local', 'password': PWD}, format='json')
    expect_status('UC-AUTH-03 login valide', r, 200)

    print('\n=== UC-READ : Lecture référentiel (tous profils) ===')
    for role_key, ctx in ctx_map.items():
        auth_as(client, ctx)
        for method, url in READ_ENDPOINTS:
            r = client.get(url)
            expect_status(f'UC-READ-{role_key}-{url}', r, READ_ALL)

    print('\n=== UC-REF : Référentiel produits (écriture) ===')
    for role_key, expected in PRODUIT_WRITE.items():
        auth_as(client, ctx_map[role_key])
        code = f'RBAC-{role_key}-{uuid.uuid4().hex[:6]}'
        r = client.post('/api/produits/', {
            'code': code,
            'nom': f'Test RBAC {role_key} {uuid.uuid4().hex[:6]}',
            'categorie': str(produit.categorie_id),
            'unite_defaut': 'KG',
        }, format='json')
        if expect_status(f'UC-REF-POST-{role_key}', r, expected) and r.status_code in (200, 201):
            _cleanup['produits'].append(r.data['id'])

    print('\n=== UC-PROD : Producteurs ===')
    for role_key, expected in PRODUCTEUR_POST.items():
        auth_as(client, ctx_map[role_key])
        r = client.post('/api/producteurs/', {
            'code_producteur': f'RBAC-{role_key}-{uuid.uuid4().hex[:6]}',
            'nom': 'N', 'prenoms': 'P',
            'province': str(province.id),
            'statut': 'ACTIF',
        }, format='json')
        expect_status(f'UC-PROD-POST-{role_key}', r, expected)

    print('\n=== UC-PROD-SCOPE : Filtrage producteurs ===')
    auth_as(client, ctx_map['producteur'])
    r = client.get('/api/producteurs/')
    codes = [p['code_producteur'] for p in r.data.get('results', r.data)]
    expect_status('UC-PROD-SCOPE-prod-list', r, 200)
    if fx['prod_own'].code_producteur in codes and fx['prod_other'].code_producteur not in codes:
        ok('UC-PROD-SCOPE-prod-own-only')
    else:
        fail('UC-PROD-SCOPE-prod-own-only', 'own visible, other hidden', str(codes))

    auth_as(client, ctx_map['cooperative'])
    r = client.get('/api/producteurs/')
    codes = [p['code_producteur'] for p in r.data.get('results', r.data)]
    if fx['prod_member'].code_producteur in codes and fx['prod_other'].code_producteur not in codes:
        ok('UC-PROD-SCOPE-coop-members-only')
    else:
        fail('UC-PROD-SCOPE-coop-members-only', 'member visible', str(codes))

    auth_as(client, ctx_map['agent_for'])
    r = client.get('/api/producteurs/')
    if r.status_code == 200 and len(r.data.get('results', r.data)) >= 3:
        ok('UC-PROD-SCOPE-agent-all')
    else:
        fail('UC-PROD-SCOPE-agent-all', '>=3 producteurs', str(r.status_code))

    print('\n=== UC-PROD-ISO : Isolation modification producteur ===')
    auth_as(client, ctx_map['producteur'])
    r = client.patch(
        f"/api/producteurs/{fx['prod_other'].id}/",
        {'notes': 'hack'},
        format='json',
    )
    expect_status('UC-PROD-ISO-prod-patch-other', r, {403, 404})

    auth_as(client, ctx_map['acheteur'])
    r = client.patch(
        f"/api/producteurs/{fx['prod_own'].id}/",
        {'notes': 'hack'},
        format='json',
    )
    expect_status('UC-PROD-ISO-acheteur-patch', r, 403)

    auth_as(client, ctx_map['cooperative'])
    r = client.patch(
        f"/api/producteurs/{fx['prod_member'].id}/",
        {'notes': 'coop ok'},
        format='json',
    )
    expect_status('UC-PROD-ISO-coop-patch-member', r, 200)

    print('\n=== UC-LOT : Lots ===')
    for role_key, expected in LOT_POST.items():
        auth_as(client, ctx_map[role_key])
        target_prod = fx['prod_own'] if role_key == 'producteur' else fx['prod_member']
        payload = {
            'produit': str(produit.id),
            'producteur': str(target_prod.id),
            'date_collecte': str(date.today()),
            'quantite': '3.000',
            'unite': 'KG',
        }
        if role_key == 'cooperative':
            payload['cooperative'] = str(fx['coop'].id)
        r = client.post('/api/lots/', payload, format='json')
        if expect_status(f'UC-LOT-POST-{role_key}', r, expected) and r.status_code == 201:
            _cleanup['lots'].append(r.data['id'])

    # Producteur ne peut pas créer lot pour autre producteur
    auth_as(client, ctx_map['producteur'])
    r = client.post('/api/lots/', {
        'produit': str(produit.id),
        'producteur': str(fx['prod_other'].id),
        'date_collecte': str(date.today()),
        'quantite': '1',
        'unite': 'KG',
    }, format='json')
    expect_status('UC-LOT-ISO-prod-other', r, 403)

    print('\n=== UC-LOT-SCOPE : Filtrage lots ===')
    auth_as(client, ctx_map['producteur'])
    r = client.get('/api/lots/')
    ids = [x['id'] for x in r.data.get('results', r.data)]
    if str(fx['lot_other'].id) not in ids:
        ok('UC-LOT-SCOPE-prod-not-other')
    else:
        fail('UC-LOT-SCOPE-prod-not-other', 'lot_other hidden', str(ids))

    auth_as(client, ctx_map['cooperative'])
    r = client.get('/api/lots/')
    ids = [x['id'] for x in r.data.get('results', r.data)]
    if str(fx['lot_member'].id) in ids and str(fx['lot_other'].id) not in ids:
        ok('UC-LOT-SCOPE-coop-members')
    else:
        fail('UC-LOT-SCOPE-coop-members', 'member lot visible', str(ids))

    auth_as(client, ctx_map['acheteur'])
    r = client.get('/api/lots/')
    expect_status('UC-LOT-READ-acheteur', r, 200)

    auth_as(client, ctx_map['acheteur'])
    r = client.patch(f"/api/lots/{fx['lot_member'].id}/", {'observations': 'x'}, format='json')
    expect_status('UC-LOT-WRITE-acheteur-forbidden', r, 403)

    print('\n=== UC-MVT : Mouvements traçabilité ===')
    for role_key, expected in MOUVEMENT_POST.items():
        auth_as(client, ctx_map[role_key])
        lot_id = fx['lot_member'].id if role_key in ('cooperative', 'producteur', 'agent_for', 'agent_min', 'admin') else fx['lot_member'].id
        if role_key == 'producteur':
            # lot du producteur propre — créer un lot d'abord
            r_lot = client.post('/api/lots/', {
                'produit': str(produit.id),
                'producteur': str(fx['prod_own'].id),
                'date_collecte': str(date.today()),
                'quantite': '2',
                'unite': 'KG',
            }, format='json')
            if r_lot.status_code == 201:
                lot_id = r_lot.data['id']
                _cleanup['lots'].append(lot_id)
        r = client.post('/api/mouvements/', {
            'lot': str(lot_id),
            'type_mouvement': 'CONTROLE',
            'lieu_libelle': f'Test {role_key}',
            'quantite': '1',
            'unite': 'KG',
        }, format='json')
        expect_status(f'UC-MVT-POST-{role_key}', r, expected)

    auth_as(client, ctx_map['acheteur'])
    r = client.get('/api/mouvements/')
    expect_status('UC-MVT-READ-acheteur', r, 200)

    print('\n=== UC-TRACE : Endpoint traçabilité ===')
    for role_key in ctx_map:
        auth_as(client, ctx_map[role_key])
        r = client.get(f"/api/lots/{fx['lot_member'].id}/tracabilite/")
        if role_key in ('producteur',):
            # producteur ne voit pas lot_member → 404
            expect_status(f'UC-TRACE-{role_key}', r, {404, 403})
        elif role_key == 'cooperative':
            expect_status(f'UC-TRACE-{role_key}', r, 200)
        else:
            expect_status(f'UC-TRACE-{role_key}', r, 200)

    print('\n=== UC-DEL : Suppression (soft-delete) ===')
    # Acheteur interdit
    auth_as(client, ctx_map['acheteur'])
    r = client.delete(f"/api/lots/{fx['lot_member'].id}/")
    expect_status('UC-DEL-acheteur-lot', r, 403)

    # Admin autorisé
    auth_as(client, ctx_map['admin'])
    r = client.post('/api/lots/', {
        'produit': str(produit.id),
        'producteur': str(fx['prod_member'].id),
        'date_collecte': str(date.today()),
        'quantite': '1',
        'unite': 'KG',
    }, format='json')
    if r.status_code == 201:
        lid = r.data['id']
        r_del = client.delete(f'/api/lots/{lid}/')
        expect_status('UC-DEL-admin-lot', r_del, 204)

    print('\n=== UC-AGENT : Agent forestier terrain ===')
    auth_as(client, ctx_map['agent_for'])
    r = client.post('/api/producteurs/', {
        'code_producteur': f'AGF-{uuid.uuid4().hex[:6]}',
        'nom': 'Terrain', 'prenoms': 'Agent',
        'province': str(province.id),
        'statut': 'EN_VALIDATION',
    }, format='json')
    expect_status('UC-AGENT-POST-producteur', r, 201)
    r = client.post('/api/produits/', {
        'code': f'AGF-BAD-{uuid.uuid4().hex[:6]}',
        'nom': 'Interdit', 'categorie': str(produit.categorie_id), 'unite_defaut': 'KG',
    }, format='json')
    expect_status('UC-AGENT-POST-produit-deny', r, 403)


if __name__ == '__main__':
    print('TEST MATRICE RBAC — Note de cadrage PNLF §5.2')
    print('=' * 60)
    try:
        with override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1']):
            run_matrix()
    finally:
        print('\n--- Nettoyage ---')
        cleanup()

    print('\n' + '=' * 60)
    print(f'RESULTAT: {len(PASS)} OK | {len(FAIL)} FAIL | {len(SKIP)} SKIP')
    if FAIL:
        print('\nEchecs:')
        for f in FAIL:
            print(f'  - {f}')
        sys.exit(1)
    print('\nTous les cas d\'utilisation RBAC sont conformes.')
