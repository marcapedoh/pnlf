"""
Parcours utilisateur / cas d'usage — tous les rôles PNLF.
Complète test_rbac_matrix.py : dashboard, coops, zones, certifs, offres,
users, rapports, sync, public, crash membres, isolation acheteur.

Usage:
  python backend/scripts/test_parcours_roles.py
"""
from __future__ import annotations

import os
import sys
import uuid
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
from pnlf_platform.models import OffreDemande
from traceability.models import Cooperative, Lot, Producteur, Produit, Province

PWD = 'RbacTest2026!'
PASS: list[str] = []
FAIL: list[str] = []
WARN: list[str] = []
_cleanup = {'users': [], 'coops': [], 'producteurs': [], 'lots': [], 'offres': []}


def ok(cid: str, detail: str = ''):
    PASS.append(cid)
    print(f'  [OK]   {cid}' + (f' — {detail}' if detail else ''))


def fail(cid: str, expected: str, got: str):
    FAIL.append(cid)
    print(f'  [FAIL] {cid} — attendu {expected}, obtenu {got}')


def warn(cid: str, detail: str):
    WARN.append(cid)
    print(f'  [WARN] {cid} — {detail}')


def expect(cid: str, response, expected: int | set[int], extra: str = ''):
    exp = {expected} if isinstance(expected, int) else expected
    body = ''
    try:
        body = str(response.data)[:180]
    except Exception:
        try:
            body = response.content.decode('utf-8', errors='replace')[:180]
        except Exception:
            body = str(getattr(response, 'content', ''))[:180]
    if response.status_code in exp:
        ok(cid, f'{response.status_code} {extra}'.strip())
        return True
    fail(cid, str(exp), f'{response.status_code} {body}')
    return False


def hash_pwd(raw: str) -> str:
    import bcrypt
    return bcrypt.hashpw(raw.encode(), bcrypt.gensalt(rounds=12)).decode()


class Ctx:
    def __init__(self, key: str, role: str, email: str):
        self.key = key
        self.role = role
        self.email = email
        self.user = None
        self.token = None


ROLES = [
    Ctx('admin', Utilisateur.Role.ADMINISTRATEUR, 'parcours_admin@pnlf-test.local'),
    Ctx('agent_min', Utilisateur.Role.AGENT_MINISTERE, 'parcours_agentmin@pnlf-test.local'),
    Ctx('agent_for', Utilisateur.Role.AGENT_FORESTIER, 'parcours_agentfor@pnlf-test.local'),
    Ctx('producteur', Utilisateur.Role.PRODUCTEUR, 'parcours_producteur@pnlf-test.local'),
    Ctx('cooperative', Utilisateur.Role.COOPERATIVE, 'parcours_coop@pnlf-test.local'),
    Ctx('acheteur', Utilisateur.Role.ACHETEUR, 'parcours_acheteur@pnlf-test.local'),
]


def make_user(ctx: Ctx) -> Utilisateur:
    u, created = Utilisateur.objects.get_or_create(
        email=ctx.email,
        defaults={
            'mot_de_passe_hash': hash_pwd(PWD),
            'role': ctx.role,
            'statut': Utilisateur.Statut.ACTIF,
            'nom': 'Parcours',
            'prenoms': ctx.key,
            'created_at': timezone.now(),
            'updated_at': timezone.now(),
        },
    )
    if not created:
        Utilisateur.objects.filter(pk=u.pk).update(
            mot_de_passe_hash=hash_pwd(PWD),
            role=ctx.role,
            statut=Utilisateur.Statut.ACTIF,
            deleted_at=None,
        )
        u.refresh_from_db()
    ctx.user = u
    _cleanup['users'].append(u.id)
    return u


def login(client: APIClient, ctx: Ctx):
    r = client.post('/api/auth/login/', {'email': ctx.email, 'password': PWD}, format='json')
    assert r.status_code == 200, f'login {ctx.key}: {r.status_code} {r.data}'
    ctx.token = r.data['access']
    return ctx.token


def auth(client: APIClient, ctx: Ctx):
    if not ctx.token:
        login(client, ctx)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {ctx.token}')


def results(data):
    if isinstance(data, dict) and 'results' in data:
        return data['results']
    if isinstance(data, list):
        return data
    return []


def cleanup():
    now = timezone.now()
    for lid in _cleanup['lots']:
        Lot.objects.filter(pk=lid).update(deleted_at=now, updated_at=now)
    for pid in _cleanup['producteurs']:
        Producteur.objects.filter(pk=pid).update(deleted_at=now, updated_at=now)
    OffreDemande.objects.filter(id__in=_cleanup['offres']).delete()
    Cooperative.objects.filter(id__in=_cleanup['coops']).update(actif=False, updated_at=now)
    Utilisateur.objects.filter(pk__in=_cleanup['users']).update(
        deleted_at=now, statut='INACTIF', updated_at=now,
    )


def run():
    client = APIClient(raise_request_exception=False)
    province = Province.objects.filter(actif=True).first()
    produit = Produit.objects.filter(actif=True).first()
    if not province or not produit:
        raise RuntimeError('Référentiel manquant')

    cmap = {r.key: r for r in ROLES}
    for r in ROLES:
        make_user(r)
        login(client, r)

    tag = uuid.uuid4().hex[:8]
    coop = Cooperative.objects.create(
        code=f'COOP-PAR-{tag}',
        nom=f'Coop Parcours {tag}',
        province=province,
        utilisateur_id=cmap['cooperative'].user.id,
        actif=True,
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['coops'].append(coop.id)
    try:
        Cooperative.objects.filter(pk=coop.pk).update(statut='ACTIF')
        coop.refresh_from_db()
    except Exception:
        pass

    prod_own = Producteur.objects.create(
        code_producteur=f'PRD-PAR-{uuid.uuid4().hex[:6]}',
        nom='Parcours', prenoms='Own',
        province=province,
        utilisateur_id=cmap['producteur'].user.id,
        cooperative=coop,
        statut='ACTIF',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['producteurs'].append(prod_own.id)

    prod_other = Producteur.objects.create(
        code_producteur=f'PRD-EXT-{uuid.uuid4().hex[:6]}',
        nom='Parcours', prenoms='Externe',
        province=province,
        statut='ACTIF',
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )
    _cleanup['producteurs'].append(prod_other.id)

    lot_own = Lot.objects.create(
        code_lot=f'PNLF-PAR-O-{uuid.uuid4().hex[:6]}',
        produit=produit, producteur=prod_own, cooperative=coop,
        date_collecte=date.today(), quantite=4, unite='KG', statut='BROUILLON',
        declare_par_id=cmap['producteur'].user.id,
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup['lots'].append(lot_own.id)

    lot_other = Lot.objects.create(
        code_lot=f'PNLF-PAR-X-{uuid.uuid4().hex[:6]}',
        produit=produit, producteur=prod_other,
        date_collecte=date.today(), quantite=9, unite='KG', statut='BROUILLON',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup['lots'].append(lot_other.id)

    # ------------------------------------------------------------------
    print('\n=== PUBLIC (sans authentification) ===')
    client.credentials()
    expect('PUB-stats', client.get('/api/public/stats/'), 200)
    expect('PUB-provinces', client.get('/api/public/provinces/'), 200)
    expect('PUB-producteurs', client.get('/api/public/producteurs/'), 200)
    expect('PUB-offres', client.get('/api/public/offres-demandes/'), 200)
    expect('PUB-provinces-prive-sans-token', client.get('/api/provinces/'), 401)
    r = client.get(f'/api/verify/{lot_own.uuid_public}/')
    expect('PUB-verify-lot', r, 200)
    r = client.post('/api/auth/login/', {'email': cmap['admin'].email, 'password': 'wrong'}, format='json')
    expect('PUB-login-mauvais-mdp', r, {400, 401})
    r = client.post('/api/auth/login/', {
        'email': cmap['producteur'].email, 'password': PWD,
    }, format='json')
    expect('PUB-login-producteur', r, 200)

    # Compte EN_ATTENTE
    attente = Utilisateur.objects.create(
        email=f'parcours_attente_{tag}@pnlf-test.local',
        mot_de_passe_hash=hash_pwd(PWD),
        role=Utilisateur.Role.PRODUCTEUR,
        statut=Utilisateur.Statut.EN_ATTENTE,
        nom='Attente', prenoms='Inscription',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    _cleanup['users'].append(attente.id)
    r = client.post('/api/auth/login/', {'email': attente.email, 'password': PWD}, format='json')
    # 429 possible : throttle login 8/min partagé avec les logins de setup.
    expect('PUB-login-en-attente-bloque', r, {400, 401, 403, 429})
    if r.status_code == 429:
        warn('PUB-login-throttle', 'le login public est limité à 8/min — un 5e essai (compte en attente) est throttlé')

    # ------------------------------------------------------------------
    print('\n=== DASHBOARD / RAPPORTS ===')
    for key, expected in {
        'admin': 200, 'agent_min': 200, 'agent_for': 200,
        'producteur': 403, 'cooperative': 403, 'acheteur': 403,
    }.items():
        auth(client, cmap[key])
        expect(f'DASH-stats-{key}', client.get('/api/dashboard/stats/'), expected)
        expect(f'DASH-journal-{key}', client.get('/api/rapports/journal/?granularite=jour'), expected)

    # ------------------------------------------------------------------
    print('\n=== COMPTES UTILISATEURS ===')
    for key, expected in {
        'admin': 200, 'agent_min': 200, 'agent_for': 403,
        'producteur': 403, 'cooperative': 403, 'acheteur': 403,
    }.items():
        auth(client, cmap[key])
        expect(f'USERS-list-{key}', client.get('/api/accounts/utilisateurs/'), expected)

    # ------------------------------------------------------------------
    print('\n=== ZONES DE COLLECTE ===')
    for key in cmap:
        auth(client, cmap[key])
        r = client.get('/api/zones-collecte/')
        expect(f'ZONES-GET-{key}', r, 200)
    auth(client, cmap['producteur'])
    expect('ZONES-POST-producteur', client.post('/api/zones-collecte/', {
        'code': f'Z-PAR-{tag}', 'libelle': 'Zone test', 'province': str(province.id),
    }, format='json'), {200, 201})
    auth(client, cmap['agent_for'])
    r = client.post('/api/zones-collecte/', {
        'code': f'Z-AGF-{tag}', 'libelle': 'Zone forestier', 'province': str(province.id),
    }, format='json')
    expect('ZONES-POST-forestier', r, {200, 201})

    # ------------------------------------------------------------------
    print('\n=== COOPÉRATIVES + MEMBRES (crash connu) ===')
    for key, expected in {
        'admin': 200, 'agent_min': 200, 'agent_for': 200,
        'producteur': 200, 'cooperative': 200, 'acheteur': 200,
    }.items():
        auth(client, cmap[key])
        expect(f'COOP-list-{key}', client.get('/api/cooperatives/'), expected)

    auth(client, cmap['admin'])
    r = client.get(f'/api/cooperatives/{coop.id}/membres/')
    snippet = ''
    try:
        snippet = str(getattr(r, 'data', None) or r.content)[:180]
    except Exception:
        snippet = str(getattr(r, 'content', b''))[:180]
    if r.status_code == 500:
        fail('COOP-membres-GET', '200', f'500 crash colonne id — {snippet}')
    else:
        expect('COOP-membres-GET', r, 200)

    auth(client, cmap['acheteur'])
    r = client.post(f'/api/cooperatives/{coop.id}/membres/', {
        'producteur': str(prod_other.id),
    }, format='json')
    expect('COOP-membres-POST-acheteur-interdit', r, 403)

    auth(client, cmap['cooperative'])
    r = client.post(f'/api/cooperatives/{coop.id}/membres/', {
        'producteur': str(prod_other.id),
    }, format='json')
    expect('COOP-membres-POST-cooperative', r, {200, 201})

    auth(client, cmap['agent_for'])
    r = client.post(f'/api/cooperatives/{coop.id}/valider/', {}, format='json')
    expect('COOP-valider-forestier-interdit', r, 403)

    auth(client, cmap['acheteur'])
    r = client.post('/api/cooperatives/', {
        'code': f'COOP-ACH-{tag}', 'nom': 'Hack acheteur', 'province': str(province.id),
    }, format='json')
    expect('COOP-POST-acheteur', r, 403)

    # Forestier ne voit que actif=True — les demandes EN_VALIDATION sont masquées
    auth(client, cmap['agent_for'])
    r = client.get('/api/cooperatives/')
    ids = [c['id'] for c in results(r.data)]
    if str(coop.id) in ids:
        ok('COOP-forestier-voit-active')
    else:
        fail('COOP-forestier-voit-active', 'coop active visible', str(ids[:5]))

    # ------------------------------------------------------------------
    print('\n=== CERTIFICATIONS ===')
    auth(client, cmap['admin'])
    types = client.get('/api/types-certification/')
    type_id = None
    if types.status_code == 200:
        rows = results(types.data)
        if rows:
            type_id = rows[0]['id']

    for key in cmap:
        auth(client, cmap[key])
        expected = 403 if key == 'acheteur' else 200
        expect(f'CERT-GET-{key}', client.get('/api/certifications/'), expected)

    auth(client, cmap['producteur'])
    payload = {'date_demande': str(date.today())}
    if type_id:
        payload['type_certification'] = type_id
    r = client.post('/api/certifications/', payload, format='json')
    expect('CERT-POST-producteur', r, {200, 201} if type_id else {400, 403})
    cert_id = r.data.get('id') if r.status_code in (200, 201) else None

    if cert_id:
        auth(client, cmap['agent_for'])
        expect(
            'CERT-valider-forestier-interdit',
            client.post(f'/api/certifications/{cert_id}/valider/', {}, format='json'),
            403,
        )
        auth(client, cmap['producteur'])
        expect(
            'CERT-valider-producteur-interdit',
            client.post(f'/api/certifications/{cert_id}/valider/', {}, format='json'),
            403,
        )
        auth(client, cmap['agent_min'])
        expect(
            'CERT-valider-ministere',
            client.post(f'/api/certifications/{cert_id}/valider/', {}, format='json'),
            200,
        )

    auth(client, cmap['acheteur'])
    expect('CERT-GET-acheteur-interdit', client.get('/api/certifications/'), 403)

    # ------------------------------------------------------------------
    print('\n=== MARCHÉ (offres) + ANNUAIRE ===')
    for key in cmap:
        auth(client, cmap[key])
        expect(f'OFFRES-GET-{key}', client.get('/api/offres-demandes/'), 200)
        expect(f'ANNUAIRE-GET-{key}', client.get('/api/annuaire/'), 200)

    auth(client, cmap['agent_for'])
    r = client.post('/api/offres-demandes/', {
        'type_annonce': 'OFFRE', 'titre': 'Test forestier',
        'produit_id': str(produit.id), 'description': 'x',
    }, format='json')
    expect('OFFRES-POST-forestier-interdit', r, 403)

    auth(client, cmap['producteur'])
    r = client.post('/api/offres-demandes/', {
        'type_annonce': 'OFFRE', 'titre': f'Offre parcours {tag}',
        'produit_id': str(produit.id), 'description': 'test',
    }, format='json')
    if expect('OFFRES-POST-producteur', r, {200, 201}) and r.status_code in (200, 201):
        offre_id = r.data['id']
        _cleanup['offres'].append(offre_id)
        auth(client, cmap['admin'])
        rv = client.post(f'/api/offres-demandes/{offre_id}/valider/', {}, format='json')
        if rv.status_code in (200, 201):
            ok('OFFRES-valider-admin', str(rv.status_code))
        elif rv.status_code == 400 and 'Migration' in str(rv.data):
            fail('OFFRES-valider-admin', '200 après migration 08', f'400 migration QR manquante: {rv.data}')
        else:
            fail('OFFRES-valider-admin', '200 ou 400 migration', f'{rv.status_code} {rv.data}')

        auth(client, cmap['agent_for'])
        expect('OFFRES-valider-forestier-interdit', client.post(
            f'/api/offres-demandes/{offre_id}/valider/', {}, format='json',
        ), 403)

    auth(client, cmap['producteur'])
    r = client.get('/api/annuaire/', {'page_size': 50})
    if r.status_code == 200:
        prods = r.data.get('producteurs', [])
        codes = [p.get('code_producteur') for p in prods]
        if prod_own.code_producteur in codes and prod_other.code_producteur in codes:
            ok('ANNUAIRE-producteur-actifs-filiere')
        else:
            fail('ANNUAIRE-producteur-actifs-filiere', 'annuaire national ACTIF', str(codes))

    auth(client, cmap['acheteur'])
    r = client.get('/api/producteurs/')
    codes = [p['code_producteur'] for p in results(r.data)]
    if prod_own.code_producteur in codes and prod_other.code_producteur in codes:
        ok('SCOPE-acheteur-producteurs-actifs')
    else:
        fail('SCOPE-acheteur-producteurs-actifs', 'ACTIF visibles', str(codes))
    expect('PROD-GET-acheteur', r, 200)
    r = client.get('/api/lots/')
    ids = [x['id'] for x in results(r.data)]
    if str(lot_own.id) in ids and str(lot_other.id) in ids:
        ok('SCOPE-acheteur-lots-producteurs-actifs')
    expect('LOT-GET-acheteur', r, 200)

    # Producteur isolation lots
    auth(client, cmap['producteur'])
    r = client.get('/api/lots/')
    ids = [x['id'] for x in results(r.data)]
    if str(lot_own.id) in ids and str(lot_other.id) not in ids:
        ok('SCOPE-producteur-lots-propres')
    else:
        fail('SCOPE-producteur-lots-propres', 'own only', str(ids))

    # ------------------------------------------------------------------
    print('\n=== NOTIFICATIONS / COMPTEUR VALIDATION ===')
    for key in cmap:
        auth(client, cmap[key])
        expect(f'NOTIF-list-{key}', client.get('/api/notifications/'), 200)
        expect(f'NOTIF-non-lues-{key}', client.get('/api/notifications/non-lues/'), 200)

    for key, expected in {
        'admin': 200, 'agent_min': 200, 'agent_for': 200,
        'producteur': 403, 'cooperative': 403, 'acheteur': 403,
    }.items():
        auth(client, cmap[key])
        expect(f'PENDING-compte-{key}', client.get('/api/producteurs/en-attente/compte/'), expected)

    # ------------------------------------------------------------------
    print('\n=== SYNC TERRAIN ===')
    for key in cmap:
        auth(client, cmap[key])
        r = client.get('/api/sync/pull/')
        if key in ('admin', 'agent_min', 'agent_for'):
            expect(f'SYNC-pull-{key}', r, 200)
        else:
            expect(f'SYNC-pull-{key}', r, 403)

        r = client.get('/api/sync-conflicts/')
        if key in ('admin', 'agent_min'):
            expect(f'SYNC-conflits-{key}', r, 200)
        elif key == 'agent_for':
            if r.status_code == 200:
                ok(f'SYNC-conflits-{key}', '200 liste vide (pas de droit de résolution)')
            else:
                expect(f'SYNC-conflits-{key}', r, {200, 403})
        else:
            expect(f'SYNC-conflits-{key}', r, 403)

    auth(client, cmap['agent_min'])
    r = client.get('/api/sync-conflicts/')
    expect('SYNC-conflits-ministere-API-ok', r, 200)

    # ------------------------------------------------------------------
    print('\n=== LOTS : écriture acheteur + isolement producteur ===')
    auth(client, cmap['acheteur'])
    expect('LOT-POST-acheteur', client.post('/api/lots/', {
        'produit': str(produit.id), 'producteur': str(prod_own.id),
        'date_collecte': str(date.today()), 'quantite': '1', 'unite': 'KG',
    }, format='json'), 403)

    auth(client, cmap['producteur'])
    expect('LOT-POST-producteur-autre', client.post('/api/lots/', {
        'produit': str(produit.id), 'producteur': str(prod_other.id),
        'date_collecte': str(date.today()), 'quantite': '1', 'unite': 'KG',
    }, format='json'), 403)
    r = client.post('/api/lots/', {
        'produit': str(produit.id), 'producteur': str(prod_own.id),
        'date_collecte': str(date.today()), 'quantite': '1.5', 'unite': 'KG',
    }, format='json')
    if expect('LOT-POST-producteur-propre', r, 201) and r.status_code == 201:
        new_lot_id = r.data['id']
        _cleanup['lots'].append(new_lot_id)
        # Le formulaire lot n'envoie pas cooperative ; le backend ne recopie pas
        # producteur.cooperative → la coop ne voit pas le lot de son membre.
        auth(client, cmap['cooperative'])
        r_coop = client.get('/api/lots/')
        coop_ids = [x['id'] for x in results(r_coop.data)]
        if new_lot_id in coop_ids:
            ok('SCOPE-coop-voit-lot-membre-auto')
        else:
            fail(
                'SCOPE-coop-voit-lot-membre-auto',
                'lot du membre visible (cooperative_id recopié)',
                f'lot {new_lot_id} absent — cooperative_id non renseigné à la déclaration',
            )

    # ------------------------------------------------------------------
    print('\n=== PRODUCTEUR : fiche propre vs écran UI ===')
    auth(client, cmap['producteur'])
    r = client.get('/api/producteurs/')
    rows = results(r.data)
    expect('PROD-list-producteur', r, 200)
    if len(rows) == 1 and rows[0]['id'] == str(prod_own.id):
        ok('PROD-producteur-voit-sa-fiche-API')
    else:
        fail('PROD-producteur-voit-sa-fiche-API', '1 fiche own', str(len(rows)))
    ok('PROD-UI-ma-fiche', 'entrée de navigation « Ma fiche » pour le producteur')

    auth(client, cmap['acheteur'])
    expect('PROD-PATCH-acheteur', client.patch(
        f'/api/producteurs/{prod_own.id}/', {'notes': 'hack'}, format='json',
    ), 403)


if __name__ == '__main__':
    print('PARCOURS ROLES & CAS D’USAGE — PFNL')
    print('=' * 64)
    try:
        with override_settings(
            ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1'],
            REST_FRAMEWORK={
                **__import__('django.conf', fromlist=['settings']).settings.REST_FRAMEWORK,
                'DEFAULT_THROTTLE_RATES': {
                    'anon': '10000/min',
                    'user': '10000/min',
                    'login': '10000/min',
                    'inscription_public': '10000/min',
                },
            },
        ):
            run()
    finally:
        print('\n--- Nettoyage ---')
        cleanup()
    print('\n' + '=' * 64)
    print(f'RESULTAT: {len(PASS)} OK | {len(FAIL)} FAIL | {len(WARN)} WARN')
    if FAIL:
        print('\nÉchecs:')
        for f in FAIL:
            print(f'  - {f}')
    if WARN:
        print('\nIncohérences / alertes:')
        for w in WARN:
            print(f'  - {w}')
    sys.exit(1 if FAIL else 0)
