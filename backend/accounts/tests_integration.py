"""Tests d'intégration et sécurité API — tous rôles et scénarios principaux."""
import uuid
from datetime import date

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from accounts.models import Utilisateur
from traceability.models import Lot, Producteur, Produit, Province


def _make_user(email, role, password='TestPass123!'):
    import bcrypt
    pwd_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()
    return Utilisateur.objects.create(
        email=email,
        mot_de_passe_hash=pwd_hash,
        role=role,
        statut=Utilisateur.Statut.ACTIF,
        nom='Test',
        prenoms=role,
        created_at=timezone.now(),
        updated_at=timezone.now(),
    )


class AuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = _make_user('admin_test@pnlf.ga', Utilisateur.Role.ADMINISTRATEUR)

    def test_login_success(self):
        r = self.client.post('/api/auth/login/', {'email': 'admin_test@pnlf.ga', 'password': 'TestPass123!'})
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertIn('access', r.data)
        self.assertIn('user', r.data)

    def test_login_bad_password(self):
        r = self.client.post('/api/auth/login/', {'email': 'admin_test@pnlf.ga', 'password': 'wrong'})
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_protected_without_token(self):
        r = self.client.get('/api/provinces/')
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_with_token(self):
        login = self.client.post('/api/auth/login/', {'email': 'admin_test@pnlf.ga', 'password': 'TestPass123!'})
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        r = self.client.get('/api/accounts/me/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['role'], 'ADMINISTRATEUR')


class RBACTests(TestCase):
    """Matrice rôle × endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.province = Province.objects.filter(actif=True).first()
        self.produit = Produit.objects.filter(actif=True, code__startswith='PFNL-').first()
        self.roles = {
            'ADMINISTRATEUR': _make_user('admin_rbac@pnlf.ga', Utilisateur.Role.ADMINISTRATEUR),
            'AGENT_MINISTERE': _make_user('agent_min@pnlf.ga', Utilisateur.Role.AGENT_MINISTERE),
            'AGENT_FORESTIER': _make_user('agent_for@pnlf.ga', Utilisateur.Role.AGENT_FORESTIER),
            'PRODUCTEUR': _make_user('producteur@pnlf.ga', Utilisateur.Role.PRODUCTEUR),
            'COOPERATIVE': _make_user('coop@pnlf.ga', Utilisateur.Role.COOPERATIVE),
            'ACHETEUR': _make_user('acheteur@pnlf.ga', Utilisateur.Role.ACHETEUR),
        }
        self.password = 'TestPass123!'

    def _token(self, email):
        r = self.client.post('/api/auth/login/', {'email': email, 'password': self.password})
        return r.data['access']

    def test_acheteur_cannot_create_producteur(self):
        token = self._token('acheteur@pnlf.ga')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        r = self.client.post('/api/producteurs/', {
            'code_producteur': 'ACH-TEST-01',
            'nom': 'Dupont', 'prenoms': 'Jean',
            'province': str(self.province.id),
            'statut': 'ACTIF',
        }, format='json')
        self.assertIn(r.status_code, (status.HTTP_403_FORBIDDEN, status.HTTP_405_METHOD_NOT_ALLOWED))

    def test_acheteur_can_read_provinces(self):
        token = self._token('acheteur@pnlf.ga')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        r = self.client.get('/api/provinces/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)

    def test_producteur_sees_only_own_producteurs(self):
        prod_user = self.roles['PRODUCTEUR']
        Producteur.objects.create(
            code_producteur='PROD-OWN-01',
            nom='Moi', prenoms='Producteur',
            province=self.province,
            utilisateur_id=prod_user.id,
            statut='ACTIF',
            created_at=timezone.now(), updated_at=timezone.now(),
        )
        Producteur.objects.create(
            code_producteur='PROD-OTHER-01',
            nom='Autre', prenoms='Producteur',
            province=self.province,
            statut='ACTIF',
            created_at=timezone.now(), updated_at=timezone.now(),
        )
        token = self._token('producteur@pnlf.ga')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        r = self.client.get('/api/producteurs/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        codes = [p['code_producteur'] for p in r.data.get('results', r.data)]
        self.assertIn('PROD-OWN-01', codes)
        self.assertNotIn('PROD-OTHER-01', codes)

    def test_agent_ministere_can_create_produit(self):
        token = self._token('agent_min@pnlf.ga')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        cat = self.produit.categorie_id
        r = self.client.post('/api/produits/', {
            'code': f'TST-API-{uuid.uuid4().hex[:8]}',
            'nom': 'Produit test API',
            'categorie': str(cat),
            'unite_defaut': 'KG',
        }, format='json')
        self.assertIn(r.status_code, (status.HTTP_201_CREATED, status.HTTP_200_OK))

    def test_producteur_cannot_create_produit(self):
        token = self._token('producteur@pnlf.ga')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        r = self.client.post('/api/produits/', {
            'code': 'TST-FORBIDDEN',
            'nom': 'Interdit',
            'categorie': str(self.produit.categorie_id),
            'unite_defaut': 'KG',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)


class LotTraceabilityTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = _make_user('admin_lot@pnlf.ga', Utilisateur.Role.ADMINISTRATEUR)
        self.province = Province.objects.filter(actif=True).first()
        self.produit = Produit.objects.filter(actif=True).first()
        self.producteur = Producteur.objects.create(
            code_producteur='PROD-LOT-01',
            nom='Lot', prenoms='Test',
            province=self.province,
            statut='ACTIF',
            created_at=timezone.now(), updated_at=timezone.now(),
        )
        login = self.client.post('/api/auth/login/', {
            'email': 'admin_lot@pnlf.ga', 'password': 'TestPass123!'
        })
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_create_lot_with_mouvement(self):
        r = self.client.post('/api/lots/', {
            'produit': str(self.produit.id),
            'producteur': str(self.producteur.id),
            'date_collecte': str(date.today()),
            'quantite': '25.500',
            'unite': 'KG',
            'statut': 'BROUILLON',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertTrue(r.data.get('code_lot', '').startswith('PNLF-'))
        self.assertTrue(r.data.get('mouvements'))
        lot_id = r.data['id']
        r2 = self.client.get(f'/api/lots/{lot_id}/tracabilite/')
        self.assertEqual(r2.status_code, status.HTTP_200_OK)

    def test_soft_delete_lot(self):
        r = self.client.post('/api/lots/', {
            'produit': str(self.produit.id),
            'producteur': str(self.producteur.id),
            'date_collecte': str(date.today()),
            'quantite': '10',
            'unite': 'KG',
        }, format='json')
        lot_id = r.data['id']
        r_del = self.client.delete(f'/api/lots/{lot_id}/')
        self.assertEqual(r_del.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Lot.objects.filter(pk=lot_id, deleted_at__isnull=True).exists())
