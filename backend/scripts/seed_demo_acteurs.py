"""
Jeu de données de démonstration : un ou plusieurs acteurs par rôle et par cas d'utilisation.

Toutes les actions métier passent par l'API réelle (APIClient DRF) afin de produire
exactement les mêmes effets que l'application : statuts, mouvements, QR codes,
notifications, journal d'audit. L'ensemble est exécuté dans UNE transaction : en cas
d'anomalie, rien n'est écrit. Un marqueur ``public._data_ops`` rend le script idempotent.

Usage (depuis backend/) :
  python scripts/seed_demo_acteurs.py                  # base de la config Django (local : .env.local)
  python scripts/seed_demo_acteurs.py --dry-run        # exécute tout puis annule (validation)
  python scripts/seed_demo_acteurs.py --render-remote  # base Render depuis un poste (ignore .env.local)
  python scripts/seed_demo_acteurs.py --fichiers       # régénère seulement les fichiers media de démo

Sur Render, entrypoint.sh l'appelle à chaque démarrage : le jeu de données n'est créé
qu'une fois, puis seuls les fichiers media (disque éphémère) sont régénérés.
"""
from __future__ import annotations

import argparse
import io
import os
import sys
import tempfile
import uuid
from datetime import timedelta
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

OP_KEY = 'seed_demo_acteurs_v1'
DOMAINE = 'demo.pfnl.ga'
MOT_DE_PASSE = 'PfnlDemo#2026'
NAMESPACE = uuid.UUID('7f3c2a10-5d1e-4c55-9a4b-2f6e8d0c1b77')
ASSETS = BACKEND / 'scripts' / 'demo_assets'


def email(local: str) -> str:
    return f'{local}@{DOMAINE}'


def cle(nom: str) -> str:
    return str(uuid.uuid5(NAMESPACE, nom))


class SeedError(RuntimeError):
    pass


class _Annulation(Exception):
    pass


def preparer_django(*, render_remote: bool) -> None:
    if render_remote:
        # config/settings.py recharge .env.local en override : on l'ignore pour viser Render.
        import dotenv

        original = dotenv.load_dotenv

        def sans_env_local(dotenv_path=None, *args, **kwargs):
            if dotenv_path and Path(dotenv_path).name == '.env.local':
                return False
            return original(dotenv_path, *args, **kwargs)

        dotenv.load_dotenv = sans_env_local
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    import django

    django.setup()


# =============================================================================
# Images de démonstration (générées, aucune donnée personnelle réelle)
# =============================================================================

def _police(taille: int):
    from PIL import ImageFont

    for nom in (
        'DejaVuSans-Bold.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
        'arialbd.ttf',
        'C:/Windows/Fonts/arialbd.ttf',
    ):
        try:
            return ImageFont.truetype(nom, taille)
        except OSError:
            continue
    try:
        return ImageFont.load_default(size=taille)
    except TypeError:
        return ImageFont.load_default()


def _centrer(draw, boite, texte, police, couleur):
    x0, y0, x1, y1 = boite
    l, t, r, b = draw.textbbox((0, 0), texte, font=police)
    draw.text((x0 + (x1 - x0 - (r - l)) / 2 - l, y0 + (y1 - y0 - (b - t)) / 2 - t), texte, font=police, fill=couleur)


def avatar_jpeg(texte: str, couleur: tuple[int, int, int], taille: int = 480) -> bytes:
    from PIL import Image, ImageDraw

    img = Image.new('RGB', (taille, taille), couleur)
    draw = ImageDraw.Draw(img)
    marge = int(taille * 0.08)
    draw.ellipse((marge, marge, taille - marge, taille - marge), outline=(255, 255, 255), width=max(4, taille // 60))
    _centrer(draw, (0, 0, taille, taille), texte[:3].upper(), _police(int(taille * 0.34)), (255, 255, 255))
    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=88)
    return buf.getvalue()


def specimen_document_png(titre: str, titulaire: str, numero: str) -> bytes:
    from PIL import Image, ImageDraw

    largeur, hauteur = 1000, 630
    img = Image.new('RGB', (largeur, hauteur), (246, 248, 244))
    draw = ImageDraw.Draw(img)
    draw.rectangle((0, 0, largeur, 110), fill=(20, 98, 60))
    _centrer(draw, (0, 0, largeur, 60), 'RÉPUBLIQUE GABONAISE', _police(34), (255, 255, 255))
    _centrer(draw, (0, 55, largeur, 110), titre.upper(), _police(26), (255, 230, 120))
    police = _police(30)
    draw.text((60, 170), f'Titulaire : {titulaire}', font=police, fill=(30, 30, 30))
    draw.text((60, 230), f'Numéro : {numero}', font=police, fill=(30, 30, 30))
    draw.text((60, 290), 'Délivré pour la plateforme PFNL (données fictives)', font=_police(24), fill=(80, 80, 80))
    draw.rectangle((60, 360, largeur - 60, 560), outline=(200, 40, 40), width=6)
    _centrer(draw, (60, 360, largeur - 60, 560), 'SPÉCIMEN DE DÉMONSTRATION', _police(52), (200, 40, 40))
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return buf.getvalue()


def photo_produit_jpeg(code_produit: str) -> bytes | None:
    from PIL import Image

    chemin = ASSETS / f'{code_produit}.jpg'
    if not chemin.exists():
        return None
    with Image.open(chemin) as src:
        img = src.convert('RGB')
        img.thumbnail((1200, 1200))
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=85)
        return buf.getvalue()


COULEURS = [
    (20, 98, 60), (33, 87, 135), (140, 70, 30), (110, 50, 120),
    (170, 110, 20), (30, 120, 120), (150, 40, 60), (70, 90, 40),
]


def couleur_pour(texte: str) -> tuple[int, int, int]:
    return COULEURS[sum(map(ord, texte)) % len(COULEURS)]


def initiales(prenoms: str, nom: str) -> str:
    morceaux = [m for m in f'{prenoms} {nom}'.replace('-', ' ').split() if m]
    if not morceaux:
        return 'PF'
    if len(morceaux) == 1:
        return morceaux[0][:2]
    return morceaux[0][0] + morceaux[-1][0]


def sigle(nom: str) -> str:
    return ''.join(m[0] for m in nom.replace('’', ' ').split() if m[0].isupper())[:3] or 'CO'


# =============================================================================
# Moteur d'appels API
# =============================================================================

class Seed:
    def __init__(self):
        from rest_framework.test import APIClient

        self.client = APIClient()
        self.nb_appels = 0

    # -- utilitaires ---------------------------------------------------------
    @staticmethod
    def utilisateur(adresse: str):
        from accounts.models import Utilisateur

        return Utilisateur.objects.get(email=adresse.lower(), deleted_at__isnull=True)

    def api(self, acteur: str | None, methode: str, url: str, data=None, *, multipart=False, attendu=(200, 201)):
        from django.core.cache import cache

        cache.clear()  # throttles DRF (inscriptions, contacts) basés sur le cache local
        self.client.force_authenticate(user=self.utilisateur(acteur) if acteur else None)
        if methode == 'get':
            resp = self.client.get(url, data or {})
        elif multipart:
            propre = {k: v for k, v in (data or {}).items() if v is not None}
            resp = getattr(self.client, methode)(url, propre, format='multipart')
        else:
            resp = getattr(self.client, methode)(url, data or {}, format='json')
        self.nb_appels += 1
        if resp.status_code not in attendu:
            detail = getattr(resp, 'data', None)
            if detail is None:
                detail = resp.content[:600]
            raise SeedError(f'{methode.upper()} {url} [{acteur or "visiteur"}] -> HTTP {resp.status_code} : {detail}')
        return getattr(resp, 'data', None)

    @staticmethod
    def province(code: str):
        from traceability.models import Province

        prov = Province.objects.filter(code=code, actif=True).first()
        if prov is None:
            prov = Province.objects.filter(actif=True).order_by('code').first()
            if prov is None:
                raise SeedError('Aucune province active : référentiel géographique absent.')
            print(f'  ! province {code} absente, remplacée par {prov.code}')
        return prov

    @staticmethod
    def localisation(code_province: str) -> dict:
        from traceability.models import Departement, Village

        prov = Seed.province(code_province)
        dep = Departement.objects.filter(province=prov, actif=True).order_by('nom').first()
        vil = Village.objects.filter(departement=dep, actif=True).order_by('nom').first() if dep else None
        return {
            'province': str(prov.id),
            'departement': str(dep.id) if dep else None,
            'village': str(vil.id) if vil else None,
        }

    @staticmethod
    def produit(code: str):
        from traceability.models import Produit

        prod = Produit.objects.filter(code=code, actif=True).first()
        if prod is None:
            prod = Produit.objects.filter(actif=True).exclude(code__startswith='TST-').order_by('code').first()
            if prod is None:
                raise SeedError('Aucun produit actif : référentiel produits absent.')
            print(f'  ! produit {code} absent, remplacé par {prod.code}')
        return prod

    @staticmethod
    def type_certif(code: str):
        from traceability.models import TypeCertification

        tc = TypeCertification.objects.filter(code=code, actif=True).first()
        if tc is None:
            tc = TypeCertification.objects.filter(actif=True).order_by('code').first()
            if tc is None:
                raise SeedError('Aucun type de certification actif.')
            print(f'  ! type de certification {code} absent, remplacé par {tc.code}')
        return tc

    @staticmethod
    def fiche(adresse: str):
        from traceability.models import Producteur

        return Producteur.objects.get(email__iexact=adresse, deleted_at__isnull=True)

    @staticmethod
    def coop(adresse: str):
        from traceability.models import Cooperative

        return Cooperative.objects.get(email__iexact=adresse)


# =============================================================================
# Définition des acteurs
# =============================================================================

COMPTES_STAFF = [
    # (local, rôle, prénoms, nom, téléphone, options)
    ('ministere.demo', 'AGENT_MINISTERE', 'Aline', 'NZIENGUI', '+241077000102', {}),
    ('ministere.nouveau', 'AGENT_MINISTERE', 'Hervé', 'MABIKA', '+241077000103', {'doit_changer_mdp': True}),
    ('forestier.demo', 'AGENT_FORESTIER', 'Rodrigue', 'ESSONO', '+241077000104', {}),
    ('forestier.suspendu', 'AGENT_FORESTIER', 'Patrice', 'KOUMBA', '+241077000105', {}),
    ('acheteur.local', 'ACHETEUR', 'Nadège', 'OYANE', '+241077000106', {}),
]

INSCRIPTIONS = [
    # (local, type, prénoms, nom, téléphone, province, extra)
    ('producteur.miel', 'PRODUCTEUR', 'Jean-Baptiste', 'NDONG', '+241077000201', 'NGO',
     {'date_naissance': '1979-04-12', 'communaute': 'Fougamou', 'latitude': '-1.2167000', 'longitude': '10.5833000',
      'message': 'Apiculteur traditionnel, 40 ruches en forêt.'}),
    ('producteur.kola', 'PRODUCTEUR', 'Marie-Claire', 'MOUSSAVOU', '+241077000202', 'OGO',
     {'date_naissance': '1985-09-03', 'communaute': 'Makokou', 'latitude': '0.5736000', 'longitude': '12.8642000'}),
    ('collecteur.ogooue', 'COLLECTEUR', 'Paul', 'OBIANG', '+241077000203', 'OGO',
     {'date_naissance': '1990-01-21', 'communaute': 'Booué', 'fiche_circuit': True}),
    ('producteur.independant', 'PRODUCTEUR', 'Sylvie', 'MBOUMBA', '+241077000204', 'WOL',
     {'date_naissance': '1988-06-30', 'communaute': 'Oyem', 'latitude': '1.5995000', 'longitude': '11.5793000'}),
    ('producteur.inactif', 'PRODUCTEUR', 'Fabrice', 'NGUEMA', '+241077000205', 'MOY',
     {'date_naissance': '1975-11-08', 'communaute': 'Lambaréné'}),
    ('producteur.rejete', 'PRODUCTEUR', 'Arnaud', 'BOUSSOUGOU', '+241077000206', 'NYA',
     {'date_naissance': '1993-02-14', 'communaute': 'Tchibanga'}),
    ('collecteur.attente', 'COLLECTEUR', 'Christelle', 'MAPANGOU', '+241077000207', 'HAO',
     {'date_naissance': '1991-07-19', 'communaute': 'Franceville', 'fiche_circuit': True,
      'message': 'Collectrice de champignons et de safou sur l’axe Franceville - Moanda.'}),
    ('producteur.attente', 'PRODUCTEUR', 'Ghislain', 'IKAPI', '+241077000208', 'OLR',
     {'date_naissance': '1982-12-01', 'communaute': 'Koulamoutou'}),
    ('coop.ivindo', 'COOPERATIVE', '', 'Coopérative des Saveurs de l’Ivindo', '+241077000301', 'OGO',
     {'adresse': 'Quartier Zoatab, Makokou', 'numero_agrement': 'AGR-OGO-2024-017', 'nagoya': True}),
    ('coop.ngounie', 'COOPERATIVE', '', 'Coopérative Miel et Forêt de la Ngounié', '+241077000302', 'NGO',
     {'adresse': 'Route de Fougamou, Mouila', 'numero_agrement': 'AGR-NGO-2023-009'}),
    ('coop.inactive', 'COOPERATIVE', '', 'Coopérative Rotin et Raphia de l’Estuaire', '+241077000303', 'EST',
     {'adresse': 'Kango centre', 'numero_agrement': 'AGR-EST-2022-004'}),
    ('coop.rejetee', 'COOPERATIVE', '', 'Groupement des Cueilleurs de Port-Gentil', '+241077000304', 'OMR',
     {'adresse': 'Port-Gentil, quartier Balise'}),
    ('coop.attente', 'COOPERATIVE', '', 'Coopérative des Femmes Productrices du Woleu-Ntem', '+241077000305', 'WOL',
     {'adresse': 'Bitam, quartier Mbéba', 'numero_agrement': 'AGR-WOL-2026-002',
      'message': 'Regroupe 35 productrices de nkumu et d’odika.'}),
    ('acheteur.export', 'ACHETEUR', 'Laurent', 'DIBANGA', '+241077000401', None,
     {'message': 'Société Gabon Export Bio : achat de PFNL certifiés pour l’export.'}),
    ('acheteur.attente', 'ACHETEUR', 'Estelle', 'MOUNGUENGUI', '+241077000402', None,
     {'message': 'Restauratrice à Libreville, recherche des produits forestiers réguliers.'}),
]

ZONES = [
    # (clé, code, libellé, province, lat, lon, description, créateur) : référentiel géré par l'administrateur seul.
    ('minkebe', 'DEMO-ZC-MINKEBE', 'Forêt de Minkébé, secteur de Makokou', 'OGO', '0.6100000', '12.7300000',
     'Massif forestier riche en noisettes (owala), kola et poivre de Guinée.', 'admin.demo'),
    ('lope', 'DEMO-ZC-LOPE', 'Lopé, lisière forêt-savane', 'OGO', '-0.2000000', '11.6000000',
     'Zone sous surveillance : espèces médicinales soumises à permis.', 'admin.demo'),
    ('waka', 'DEMO-ZC-WAKA', 'Massif de Waka, abords de Mouila', 'NGO', '-1.7500000', '11.1500000',
     'Forêt dense humide : miel, cire et chenilles.', 'admin.demo'),
    ('cristal', 'DEMO-ZC-CRISTAL', 'Monts de Cristal, versant de Kango', 'EST', '0.4500000', '10.2700000',
     'Rotin, raphia et feuilles de Marantacées.', 'admin.demo'),
    ('ruchers', 'DEMO-ZC-RUCHERS-FOUGAMOU', 'Ruchers forestiers de Fougamou', 'NGO', '-1.2100000', '10.6000000',
     'Zone ajoutée par l’administration à la demande du producteur.', 'admin.demo'),
]


# =============================================================================
# Étapes du scénario
# =============================================================================

def etape_comptes(s: Seed) -> None:
    from django.utils import timezone

    from accounts.models import Utilisateur

    print('> Comptes institutionnels')
    now = timezone.now()
    admin = Utilisateur(
        id=uuid.uuid4(), email=email('admin.demo'), telephone='+241077000101',
        role=Utilisateur.Role.ADMINISTRATEUR, statut=Utilisateur.Statut.ACTIF,
        nom='MOUKAGNI', prenoms='Administrateur Démo', preferences_notif='EMAIL',
        created_at=now, updated_at=now,
    )
    admin.set_password(MOT_DE_PASSE)
    admin.save()

    for local, role, prenoms, nom, tel, options in COMPTES_STAFF:
        s.api(email('admin.demo'), 'post', '/api/accounts/utilisateurs/', {
            'email': email(local), 'telephone': tel, 'role': role, 'statut': 'ACTIF',
            'nom': nom, 'prenoms': prenoms, 'password': MOT_DE_PASSE,
            'preferences_notif': 'EMAIL',
        })
        # L'API force doit_changer_mdp=True à la création : état de démonstration rétabli ici.
        Utilisateur.objects.filter(email=email(local)).update(
            doit_changer_mdp=options.get('doit_changer_mdp', False),
        )
    suspendu = s.utilisateur(email('forestier.suspendu'))
    s.api(email('admin.demo'), 'post', f'/api/accounts/utilisateurs/{suspendu.id}/suspendre/')


def etape_zones(s: Seed) -> dict:
    print('> Zones de collecte')
    zones = {}
    for cle_zone, code, libelle, prov, lat, lon, desc, createur in ZONES:
        data = s.api(email(createur), 'post', '/api/zones-collecte/', {
            'code': code, 'libelle': libelle, 'province': str(s.province(prov).id),
            'description': desc, 'latitude': lat, 'longitude': lon, 'actif': True,
        })
        zones[cle_zone] = data['id']
    return zones


def _fichier(nom: str, contenu: bytes, type_mime: str):
    from django.core.files.uploadedfile import SimpleUploadedFile

    return SimpleUploadedFile(nom, contenu, content_type=type_mime)


def etape_inscriptions(s: Seed) -> None:
    print('> Inscriptions publiques (formulaire « Créer un compte »)')
    for local, type_demande, prenoms, nom, tel, prov, extra in INSCRIPTIONS:
        titulaire = f'{prenoms} {nom}'.strip()
        data = {
            'type_demande': type_demande, 'nom': nom, 'prenoms': prenoms, 'email': email(local),
            'telephone': tel, 'password': MOT_DE_PASSE, 'password_confirmation': MOT_DE_PASSE,
            'accepte_conditions': 'true', 'message': extra.get('message', ''),
            'date_naissance': extra.get('date_naissance'), 'communaute': extra.get('communaute'),
            'latitude': extra.get('latitude'), 'longitude': extra.get('longitude'),
            'adresse': extra.get('adresse'), 'numero_agrement': extra.get('numero_agrement'),
        }
        if prov:
            data.update(s.localisation(prov))
        if type_demande != 'ACHETEUR':
            texte = initiales(prenoms, nom) if prenoms else sigle(nom)
            data['photo'] = _fichier('photo.jpg', avatar_jpeg(texte, couleur_pour(local)), 'image/jpeg')
            data['document_cni'] = _fichier(
                'piece-identite.png',
                specimen_document_png('Carte nationale d’identité', titulaire, f'DEMO-CNI-{cle(local)[:6].upper()}'),
                'image/png',
            )
        if extra.get('fiche_circuit'):
            data['document_fiche_circuit'] = _fichier(
                'fiche-circuit.png', specimen_document_png('Fiche circuit de collecte', titulaire, 'DEMO-FC-2026'), 'image/png',
            )
        if extra.get('nagoya'):
            data['document_agrement_nagoya'] = _fichier(
                'agrement-nagoya.png', specimen_document_png('Agrément APA (Protocole de Nagoya)', titulaire, 'DEMO-APA-2026'),
                'image/png',
            )
        s.api(None, 'post', '/api/public/inscription/', data, multipart=True, attendu=(201,))


def etape_validations(s: Seed) -> None:
    print('> Instruction des dossiers (validation, rejet, désactivation)')
    ministere, admin, forestier = email('ministere.demo'), email('admin.demo'), email('forestier.demo')
    for local in ('producteur.miel', 'producteur.kola', 'producteur.independant', 'producteur.inactif'):
        s.api(ministere, 'post', f'/api/producteurs/{s.fiche(email(local)).id}/valider/')
    s.api(forestier, 'post', f'/api/producteurs/{s.fiche(email("collecteur.ogooue")).id}/valider/')
    s.api(admin, 'post', f'/api/producteurs/{s.fiche(email("producteur.rejete")).id}/rejeter/', {
        'motif': 'Pièce d’identité illisible et zone de collecte non renseignée.',
    })
    s.api(admin, 'post', f'/api/producteurs/{s.fiche(email("producteur.inactif")).id}/desactiver/')

    for local in ('coop.ivindo', 'coop.ngounie', 'coop.inactive'):
        s.api(admin, 'post', f'/api/cooperatives/{s.coop(email(local)).id}/valider/')
    s.api(ministere, 'post', f'/api/cooperatives/{s.coop(email("coop.rejetee")).id}/rejeter/', {
        'motif': 'Numéro d’agrément manquant et statuts de la coopérative non fournis.',
    })
    s.api(admin, 'post', f'/api/cooperatives/{s.coop(email("coop.inactive")).id}/desactiver/')

    acheteur = s.utilisateur(email('acheteur.export'))
    s.api(admin, 'post', f'/api/accounts/utilisateurs/{acheteur.id}/activer/')


def etape_fiches_terrain(s: Seed) -> dict:
    from traceability.models import Producteur

    print('> Fiches créées par les agents et les coopératives (acteurs sans compte)')
    forestier, ministere = email('forestier.demo'), email('ministere.demo')
    fiches = {}
    definitions = [
        ('t01', forestier, {
            'code_producteur': 'DEMO-PRD-T01', 'nom': 'ONDO MBA', 'prenoms': 'Célestin', 'date_naissance': '1968-03-25',
            'type_acteur': 'PRODUCTEUR', 'type_piece_identite': 'CNI', 'numero_piece': 'DEMO-CNI-T01',
            'telephone': '+241066000501', 'communaute': 'Village Ntsiété', 'latitude': '0.5500000',
            'longitude': '12.7000000', 'visible_public': True, 'loc': 'OGO',
            'notes': 'Recensé lors de la tournée terrain de mars ; ne dispose pas de smartphone.',
        }),
        ('t02', forestier, {
            'code_producteur': 'DEMO-PRD-T02', 'nom': 'NZÉ', 'prenoms': 'Bertrand', 'date_naissance': '1972-08-17',
            'type_acteur': 'COLLECTEUR', 'type_piece_identite': 'CNI', 'numero_piece': 'DEMO-CNI-T02',
            'telephone': '+241066000502', 'communaute': 'Mitzic', 'visible_public': False, 'loc': 'WOL',
            'notes': 'Collecteur itinérant, fiche masquée de l’annuaire public à sa demande.',
        }),
        ('t03', forestier, {
            'code_producteur': 'DEMO-PRD-T03', 'nom': 'MAGANGA', 'prenoms': 'Rosine', 'date_naissance': '1980-05-09',
            'type_acteur': 'PRODUCTEUR', 'type_piece_identite': 'PASSEPORT', 'numero_piece': 'DEMO-PP-T03',
            'telephone': '+241066000503', 'communaute': 'Ndendé', 'visible_public': True, 'loc': 'NGO',
            'notes': 'Dossier en attente de la copie du passeport.',
        }),
        ('c01', email('coop.ivindo'), {
            'code_producteur': 'DEMO-PRD-C01', 'nom': 'MINKO', 'prenoms': 'Odette', 'date_naissance': '1987-10-02',
            'type_acteur': 'PRODUCTEUR', 'type_piece_identite': 'CNI', 'numero_piece': 'DEMO-CNI-C01',
            'telephone': '+241066000504', 'communaute': 'Mékambo', 'visible_public': True, 'loc': 'OGO',
            'cooperative': str(s.coop(email('coop.ivindo')).id),
            'notes': 'Membre enregistrée par la coopérative.',
        }),
    ]
    for code, auteur, champs in definitions:
        champs = dict(champs)
        loc = s.localisation(champs.pop('loc'))
        data = s.api(auteur, 'post', '/api/producteurs/', {**champs, **loc, 'client_uuid': cle(f'fiche-{code}')})
        fiches[code] = data['id']
        if data.get('code_producteur') != champs['code_producteur']:
            # Seuls les agents choisissent le code : la fiche saisie par la coopérative
            # garde son code de démonstration pour être retrouvée par assurer_fichiers().
            Producteur.objects.filter(pk=data['id']).update(code_producteur=champs['code_producteur'])
    for code in ('t01', 't02', 'c01'):
        s.api(ministere, 'post', f'/api/producteurs/{fiches[code]}/valider/')
    return fiches


def etape_membres(s: Seed, fiches: dict) -> None:
    print('> Coopératives : membres et demande d’adhésion')
    ivindo, ngounie = s.coop(email('coop.ivindo')), s.coop(email('coop.ngounie'))
    aujourd_hui = _aujourdhui()
    for adresse, jours in (('producteur.kola', 210), ('collecteur.ogooue', 150)):
        s.api(email(adresse), 'post', f'/api/cooperatives/{ivindo.id}/demander-adhesion/')
        s.api(email('coop.ivindo'), 'post', f'/api/cooperatives/{ivindo.id}/membres/', {
            'producteur': str(s.fiche(email(adresse)).id), 'date_adhesion': str(aujourd_hui - timedelta(days=jours)),
        })
    s.api(email('coop.ivindo'), 'post', f'/api/cooperatives/{ivindo.id}/membres/', {
        'producteur': fiches['c01'], 'date_adhesion': str(aujourd_hui - timedelta(days=90)),
    })
    s.api(email('admin.demo'), 'post', f'/api/cooperatives/{ngounie.id}/membres/', {
        'producteur': str(s.fiche(email('producteur.miel')).id), 'date_adhesion': str(aujourd_hui - timedelta(days=400)),
    })
    s.api(email('producteur.independant'), 'post', f'/api/cooperatives/{ivindo.id}/demander-adhesion/')


def _aujourdhui():
    from django.utils import timezone

    return timezone.localdate()


def etape_lots(s: Seed, zones: dict, fiches: dict) -> dict:
    print('> Lots et traçabilité (brouillon, validé, commercialisé)')
    aujourd_hui = _aujourdhui()
    f = lambda adresse: str(s.fiche(email(adresse)).id)  # noqa: E731
    lots_def = [
        # clé, acteur, producteur, produit, zone, jours, quantité, unité, qualité, prix, (inutilisé)
        ('L01', 'producteur.miel', f('producteur.miel'), 'PFNL-MIEL-SAUV', 'ruchers', 75, '120', 'KG', 'Premier choix', '6500', False),
        ('L02', 'producteur.miel', f('producteur.miel'), 'PFNL-CIRE', 'waka', 40, '15', 'KG', 'Cire brute filtrée', '4000', False),
        ('L03', 'producteur.miel', f('producteur.miel'), 'PFNL-PROPOLIS', 'ruchers', 3, '2.5', 'KG', None, None, True),
        ('L04', 'producteur.kola', f('producteur.kola'), 'PFNL-KOLA', 'minkebe', 60, '300', 'KG', 'Noix fraîches', '1800', False),
        ('L05', 'coop.ivindo', f('collecteur.ogooue'), 'PFNL-COULA', 'minkebe', 20, '80', 'KG', 'Calibre moyen', '2500', False),
        ('L06', 'collecteur.ogooue', f('collecteur.ogooue'), 'PFNL-CHENILLES', 'minkebe', 50, '40', 'KG', 'Séchées au feu de bois', '9000', False),
        ('L07', 'producteur.independant', f('producteur.independant'), 'PFNL-SAFOU', None, 12, '200', 'KG', 'Fruits mûrs', '1200', False),
        ('L08', 'producteur.independant', f('producteur.independant'), 'PFNL-ODIKA', None, 90, '50', 'KG', None, '3500', False),
        ('L09', 'producteur.kola', f('producteur.kola'), 'PFNL-CHAMP', 'minkebe', 120, '10', 'KG', 'Frais', '5000', False),
        ('L10', 'forestier.demo', fiches['t01'], 'PFNL-IBOGA', 'lope', 30, '25', 'KG', 'Écorce de racine séchée', None, False),
        ('L11', 'forestier.demo', fiches['t01'], 'PFNL-MOABI-HUILE', 'minkebe', 35, '60', 'LITRE', 'Pressage artisanal', '7000', False),
        ('L12', 'coop.ivindo', fiches['c01'], 'PFNL-NKUMU', 'minkebe', 8, '60', 'KG', 'Feuilles fraîches', '2000', False),
        ('L13', 'producteur.miel', f('producteur.miel'), 'PFNL-MARANTACEES', 'waka', 5, '150', 'BOTTE', None, '500', False),
        ('L14', 'collecteur.ogooue', f('collecteur.ogooue'), 'PFNL-POIVRE-G', 'minkebe', 25, '18', 'KG', 'Graines sèches', '6000', False),
    ]
    lots = {}
    for code, acteur, producteur_id, produit, zone, jours, qte, unite, qualite, prix, _ in lots_def:
        payload = {
            'produit': str(s.produit(produit).id), 'producteur': producteur_id,
            'zone_collecte': zones.get(zone) if zone else None,
            'date_collecte': str(aujourd_hui - timedelta(days=jours)), 'quantite': qte, 'unite': unite,
            'qualite_indicateur': qualite, 'prix_indicatif': prix, 'devise': 'XAF',
            'observations': f'Lot de démonstration {code}.', 'client_uuid': cle(f'lot-{code}'),
        }
        data = s.api(email(acteur), 'post', '/api/lots/', payload)
        lots[code] = {'id': data['id'], 'code_lot': data['code_lot'], 'quantite': qte, 'unite': unite}

    def mvt(acteur, code, type_mvt, lieu, destinataire=None, commentaire=None):
        lot = lots[code]
        s.api(email(acteur), 'post', '/api/mouvements/', {
            'lot': lot['id'], 'type_mouvement': type_mvt, 'lieu_libelle': lieu,
            'quantite': lot['quantite'], 'unite': lot['unite'],
            'destinataire_libelle': destinataire, 'commentaire': commentaire,
        })

    def valider(acteur, code):
        s.api(email(acteur), 'post', f'/api/lots/{lots[code]["id"]}/valider/')

    mvt('coop.ngounie', 'L01', 'RECEPTION_COOPERATIVE', 'Magasin de la coopérative, Mouila', commentaire='Pesée et contrôle visuel conformes.')
    valider('ministere.demo', 'L01')
    mvt('coop.ngounie', 'L01', 'TRANSFERT', 'Mouila vers Owendo (RN1)', 'Entrepôt Gabon Export Bio, Owendo')
    mvt('coop.ngounie', 'L01', 'VENTE', 'Owendo', 'Société Gabon Export Bio', 'Facture DEMO-FV-0012.')
    mvt('forestier.demo', 'L02', 'CONTROLE', 'Poste forestier de Mouila', commentaire='Contrôle de conformité : RAS.')
    valider('forestier.demo', 'L02')
    mvt('coop.ivindo', 'L04', 'RECEPTION_COOPERATIVE', 'Magasin de la coopérative, Makokou')
    valider('forestier.demo', 'L04')
    mvt('coop.ivindo', 'L04', 'TRANSFORMATION', 'Atelier de séchage, Makokou', commentaire='Séchage, tri et calibrage.')
    valider('ministere.demo', 'L06')
    mvt('coop.ivindo', 'L06', 'TRANSFERT', 'Makokou vers Libreville', 'Transitaire agréé, Libreville')
    mvt('coop.ivindo', 'L06', 'EXPORT', 'Port d’Owendo', 'Client export, Douala (Cameroun)', 'Certificat phytosanitaire DEMO-PHY-221.')
    mvt('forestier.demo', 'L07', 'CONTROLE', 'Brigade forestière d’Oyem', commentaire='Contrôle qualité et origine validés.')
    valider('forestier.demo', 'L07')
    valider('ministere.demo', 'L09')
    valider('forestier.demo', 'L11')
    mvt('forestier.demo', 'L11', 'TRANSFERT', 'Makokou vers Franceville', 'Huilerie artisanale, Franceville')
    mvt('coop.ivindo', 'L14', 'RECEPTION_COOPERATIVE', 'Magasin de la coopérative, Makokou')
    valider('admin.demo', 'L14')

    # Lot saisi par erreur : supprimé par son producteur tant qu'il est en brouillon.
    s.api(email('producteur.independant'), 'delete', f'/api/lots/{lots["L08"]["id"]}/', attendu=(204,))
    return lots


def _ajouter_jours(d, jours):
    return d + timedelta(days=jours)


def etape_certifs(s: Seed, lots: dict, fiches: dict) -> None:
    from accounts.models import Utilisateur
    from traceability.models import Certification

    print('> Certifications (demandée, en cours, obtenue, refusée, expirée)')
    ministere, admin = email('ministere.demo'), email('admin.demo')
    aujourd_hui = _aujourdhui()

    c_bio = s.api(email('producteur.miel'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('BIO').id), 'observations': 'Ruchers situés hors zone agricole.',
    })
    s.api(admin, 'post', f'/api/certifications/{c_bio["id"]}/valider/', {'numero_certificat': 'BIO-GA-2026-0142'})
    Certification.objects.filter(pk=c_bio['id']).update(date_expiration=_ajouter_jours(aujourd_hui, 365))
    # Producteur désormais certifié : il valide lui-même son lot (auto-validation).
    s.api(email('producteur.miel'), 'post', f'/api/lots/{lots["L13"]["id"]}/valider/')

    s.api(email('producteur.kola'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('ORIGINE').id), 'observations': 'Demande d’indication d’origine « Kola de l’Ivindo ».',
    })

    titulaire_qual = 'Collecteur Ogooué-Ivindo'
    c_qual = s.api(email('coop.ivindo'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('QUALITE').id),
        'producteur': str(s.fiche(email('collecteur.ogooue')).id),
        'observations': 'Demande portée par la coopérative pour son collecteur.',
        'pieces': [
            _fichier('fiche-controle-qualite.png',
                     specimen_document_png('FICHE DE CONTRÔLE QUALITÉ', titulaire_qual, 'DEMO-FCQ-0451'), 'image/png'),
            _fichier('attestation-cooperative.png',
                     specimen_document_png('ATTESTATION DE LA COOPÉRATIVE', titulaire_qual, 'DEMO-ATT-0088'), 'image/png'),
        ],
        'intitules': ['Fiche de contrôle qualité', 'Attestation de la coopérative'],
    }, multipart=True)
    Certification.objects.filter(pk=c_qual['id']).update(
        statut='EN_COURS', observations='Demande portée par la coopérative. Instruction en cours : visite terrain programmée.',
    )

    c_ref = s.api(email('producteur.independant'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('BIO').id),
    })
    s.api(admin, 'post', f'/api/certifications/{c_ref["id"]}/refuser/', {
        'motif': 'Plan de gestion durable de la ressource non fourni.',
    })

    c_cites = s.api(email('forestier.demo'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('CITES').id), 'lot': lots['L10']['id'], 'producteur': fiches['t01'],
        'observations': 'Iboga : permis requis avant toute commercialisation.',
    })
    s.api(admin, 'post', f'/api/certifications/{c_cites["id"]}/valider/', {'numero_certificat': 'CITES-GA-2026-0007'})
    Certification.objects.filter(pk=c_cites['id']).update(date_expiration=_ajouter_jours(aujourd_hui, 180))

    c_exp = s.api(email('producteur.miel'), 'post', '/api/certifications/', {
        'date_demande': str(aujourd_hui),
        'type_certification': str(s.type_certif('QUALITE').id),
    })
    Certification.objects.filter(pk=c_exp['id']).update(
        statut='EXPIREE', numero_certificat='QUA-GA-2025-0031',
        date_demande=_ajouter_jours(aujourd_hui, -430), date_obtention=_ajouter_jours(aujourd_hui, -420),
        date_expiration=_ajouter_jours(aujourd_hui, -55),
        valide_par_id=Utilisateur.objects.get(email=admin).id,
        observations='Certificat arrivé à échéance : renouvellement à demander.',
    )


def etape_offres(s: Seed) -> dict:
    from django.utils import timezone

    print('> Offres et demandes (validées, en attente, rejetée, clôturée)')
    expire = (timezone.now() + timedelta(days=60)).isoformat()
    definitions = [
        ('O1', 'producteur.miel', 'OFFRE', 'PFNL-MIEL-SAUV', 'NGO', '100', 'KG', '6500',
         'Miel sauvage de la Ngounié, 100 kg disponibles',
         'Miel de forêt récolté de façon traditionnelle, filtré à froid, conditionné en seaux de 25 kg.', False),
        ('O2', 'coop.ivindo', 'OFFRE', 'PFNL-KOLA', 'OGO', '250', 'KG', '1800',
         'Noix de kola calibrées, 250 kg',
         'Noix séchées et triées par la coopérative. Enlèvement possible à Makokou.', False),
        ('O3', 'acheteur.export', 'DEMANDE', 'PFNL-COULA', 'OGO', '500', 'KG', '2500',
         'Recherche 500 kg de noisettes owala certifiées',
         'Achat régulier pour l’export. Certification exigée, paiement à la livraison.', True),
        ('O4', 'acheteur.local', 'DEMANDE', 'PFNL-CHENILLES', 'EST', '30', 'KG', '9000',
         'Achat de chenilles séchées pour restauration',
         'Livraison souhaitée à Libreville, 10 kg par mois.', False),
        ('O5', 'collecteur.ogooue', 'OFFRE', 'PFNL-CHAMP', 'OGO', '15', 'KG', '5000',
         'Champignons forestiers frais', 'Récolte du jour.', False),
        ('O6', 'producteur.independant', 'OFFRE', 'PFNL-SAFOU', 'WOL', '200', 'KG', '1200',
         'Safou d’Oyem, récolte de saison', 'Fruits mûrs, cagettes de 20 kg.', False),
        ('O7', 'producteur.kola', 'OFFRE', 'PFNL-POIVRE-G', 'OGO', '20', 'KG', '6000',
         'Poivre de Guinée séché', 'Graines séchées au soleil, sacs de 5 kg.', False),
    ]
    offres = {}
    for code, auteur, type_annonce, produit, prov, qte, unite, prix, titre, desc, certif in definitions:
        data = s.api(email(auteur), 'post', '/api/offres-demandes/', {
            'type_annonce': type_annonce, 'produit_id': str(s.produit(produit).id),
            'province_id': str(s.province(prov).id), 'quantite': qte, 'unite': unite,
            'prix_unitaire': prix, 'devise': 'XAF', 'titre': titre, 'description': desc,
            'certification_requise': certif, 'expire_at': expire,
        })
        offres[code] = data['id']
    ministere, admin = email('ministere.demo'), email('admin.demo')
    s.api(ministere, 'post', f'/api/offres-demandes/{offres["O1"]}/valider/')
    s.api(admin, 'post', f'/api/offres-demandes/{offres["O2"]}/valider/')
    s.api(ministere, 'post', f'/api/offres-demandes/{offres["O3"]}/valider/')
    s.api(ministere, 'post', f'/api/offres-demandes/{offres["O5"]}/rejeter/', {
        'motif': 'Produit périssable : précisez le conditionnement et la date de récolte.',
    })
    s.api(admin, 'post', f'/api/offres-demandes/{offres["O6"]}/valider/')
    s.api(email('producteur.independant'), 'post', f'/api/offres-demandes/{offres["O6"]}/cloturer/')
    return offres


def etape_contacts_publics(s: Seed, offres: dict, fiches: dict) -> None:
    print('> Contacts publics (visiteurs non connectés)')
    s.api(None, 'post', f'/api/public/offres-demandes/{offres["O1"]}/contact/', {
        'nom': 'Hôtel Le Méridien Libreville (démo)', 'email': email('visiteur.hotel'), 'telephone': '+241011000001',
        'message': 'Bonjour, nous souhaitons commander 20 kg de miel par mois. Pouvez-vous nous rappeler ?',
    })
    s.api(None, 'post', f'/api/public/producteurs/{fiches["t01"]}/contact/', {
        'nom_visiteur': 'Association Tradipraticiens (démo)', 'email_visiteur': email('visiteur.asso'),
        'telephone_visiteur': '+241011000002',
        'message': 'Nous cherchons un fournisseur d’écorces médicinales disposant des permis requis.',
    }, attendu=(201,))
    msg = s.api(None, 'post', f'/api/public/producteurs/{s.fiche(email("producteur.miel")).id}/contact/', {
        'nom_visiteur': 'Épicerie fine Akanda (démo)', 'email_visiteur': email('visiteur.epicerie'),
        'message': 'Vendez-vous du miel en pots de 500 g ? Merci de nous indiquer vos tarifs.',
    }, attendu=(201,))
    s.api(email('producteur.miel'), 'post', f'/api/messages-publics/{msg["id"]}/marquer_traite/')


def etape_messagerie(s: Seed, offres: dict, lots: dict) -> None:
    print('> Messagerie (fils directs, groupe de coopérative, échanges avec les agents)')

    def fil(auteur, payload):
        return s.api(email(auteur), 'post', '/api/conversations/', payload)['id']

    def ecrire(auteur, conv_id, *textes):
        for texte in textes:
            s.api(email(auteur), 'post', f'/api/conversations/{conv_id}/messages/', {'contenu': texte})

    c1 = fil('acheteur.export', {'offre_id': offres['O1']})
    ecrire('acheteur.export', c1, 'Bonjour, votre miel est-il disponible pour un enlèvement à Mouila en fin de mois ?')
    ecrire('producteur.miel', c1, 'Bonjour, oui. Les 100 kg sont prêts et la récolte est certifiée biologique.')
    ecrire('acheteur.export', c1, 'Parfait. Pouvez-vous m’indiquer le code du lot pour une vérification par QR code ?')
    ecrire('producteur.miel', c1, f'Bien sûr : lot {lots["L01"]["code_lot"]}. Vous pouvez le vérifier sur la page publique.')

    c2 = fil('acheteur.local', {'cooperative_id': str(s.coop(email('coop.ivindo')).id)})
    ecrire('acheteur.local', c2, 'Bonjour, livrez-vous des noix de kola à Libreville ?')
    ecrire('coop.ivindo', c2, 'Bonjour Madame, oui : une livraison groupée chaque premier lundi du mois.')

    c3 = fil('acheteur.export', {'producteur_id': str(s.fiche(email('producteur.kola')).id)})
    ecrire('acheteur.export', c3, 'Bonjour, seriez-vous intéressée par un contrat annuel pour la kola ?')

    c4 = fil('coop.ivindo', {'est_groupe': True, 'cooperative_id': str(s.coop(email('coop.ivindo')).id),
                             'sujet': 'Groupe des membres, Saveurs de l’Ivindo'})
    ecrire('coop.ivindo', c4, 'Bonjour à tous : collecte groupée samedi au magasin de Makokou.')
    ecrire('producteur.kola', c4, 'Bien noté, j’apporte environ 80 kg de kola.')
    ecrire('collecteur.ogooue', c4, 'Je serai présent avec les noisettes de Minkébé.')

    c5 = fil('ministere.demo', {'destinataire_id': str(s.utilisateur(email('producteur.miel')).id)})
    ecrire('ministere.demo', c5, 'Bonjour, votre certification biologique a été validée. Pensez à joindre le certificat signé.')
    ecrire('producteur.miel', c5, 'Merci beaucoup, je le dépose dès cette semaine.')

    c6 = fil('forestier.demo', {'destinataire_id': str(s.utilisateur(email('coop.ngounie')).id)})
    ecrire('forestier.demo', c6, 'Bonjour, contrôle de routine prévu à votre magasin de Mouila mardi prochain.')


def etape_synchronisation(s: Seed, fiches: dict) -> None:
    from traceability.models import Producteur

    print('> Synchronisation terrain (appareil, conflits)')
    forestier = email('forestier.demo')
    device = 'DEMO-TABLETTE-MAKOKOU-01'
    s.api(forestier, 'post', '/api/appareils-sync/', {'device_id': device, 'libelle': 'Tablette terrain, Makokou'})
    t01 = Producteur.objects.get(pk=fiches['t01'])
    t02 = Producteur.objects.get(pk=fiches['t02'])
    for fiche in (t01, t02):
        rep = s.api(forestier, 'post', '/api/sync/push/', {
            'device_id': device, 'libelle': 'Tablette terrain, Makokou',
            'producteurs': [{'client_uuid': str(fiche.client_uuid), 'sync_version': 0, 'nom': fiche.nom}],
        })
        if rep['synced']['conflits'] != 1:
            raise SeedError(f'Conflit de synchronisation attendu, obtenu : {rep}')
    rep = s.api(forestier, 'post', '/api/sync/push/', {
        'device_id': device, 'libelle': 'Tablette terrain, Makokou',
        'producteurs': [{'client_uuid': str(t01.client_uuid), 'sync_version': 5, 'nom': t01.nom}],
    })
    if rep['synced']['producteurs'] != 1:
        raise SeedError(f'Synchronisation attendue, obtenue : {rep}')
    s.api(forestier, 'get', '/api/sync/pull/')
    conflits = s.api(email('admin.demo'), 'get', '/api/sync-conflicts/')
    lignes = conflits['results'] if isinstance(conflits, dict) else conflits
    cible = next((c for c in lignes if c['client_uuid'] == str(t02.client_uuid)), None)
    if cible is None:
        raise SeedError('Conflit de synchronisation introuvable pour la fiche T02.')
    s.api(email('admin.demo'), 'post', f'/api/sync-conflicts/{cible["id"]}/resoudre/', {
        'resolution': 'Version serveur conservée : fiche validée plus récente que la saisie hors ligne.',
    })


def etape_verifications(s: Seed) -> None:
    """Contrôle que chaque rôle actif accède bien à ses écrans principaux."""
    print('> Vérification des accès par rôle')
    controles = [
        ('admin.demo', ['/api/dashboard/stats/', '/api/dashboard/a-traiter/', '/api/accounts/utilisateurs/',
                        '/api/rapports/journal/', '/api/conversations/supervision/']),
        ('ministere.demo', ['/api/dashboard/stats/', '/api/producteurs/', '/api/certifications/', '/api/offres-demandes/']),
        ('forestier.demo', ['/api/dashboard/a-traiter/', '/api/lots/', '/api/zones-collecte/', '/api/appareils-sync/']),
        ('coop.ivindo', ['/api/producteurs/', '/api/lots/', '/api/messages-publics/', '/api/conversations/membres-coop/']),
        ('producteur.miel', ['/api/lots/', '/api/certifications/', '/api/notifications/', '/api/messages-publics/']),
        ('collecteur.ogooue', ['/api/lots/', '/api/conversations/']),
        ('acheteur.export', ['/api/lots/', '/api/offres-demandes/', '/api/annuaire/', '/api/conversations/']),
        ('acheteur.local', ['/api/offres-demandes/', '/api/conversations/contacts/']),
    ]
    for local, urls in controles:
        for url in urls:
            s.api(email(local), 'get', url, attendu=(200,))
    s.api(None, 'get', '/api/public/offres-demandes/', attendu=(200,))
    s.api(None, 'get', '/api/public/producteurs/', attendu=(200,))


# =============================================================================
# Fichiers media (photos, QR, documents) : régénérés si absents (disque éphémère Render)
# =============================================================================

def assurer_fichiers() -> dict:
    from django.conf import settings
    from django.db.models import Q

    from accounts.models import Utilisateur
    from pnlf_platform.models import OffreDemande
    from traceability.db_utils import column_exists, get_optional_column
    from traceability.models import Cooperative, DocumentInscription, Lot, Producteur, Produit
    from traceability.services import chemin_photo, generer_qr_image

    media = Path(settings.MEDIA_ROOT)
    stats = {'photos': 0, 'qr': 0, 'documents': 0}

    def ecrire(chemin: Path, contenu: bytes | None, cle_stat: str) -> None:
        if contenu is None or chemin.exists():
            return
        chemin.parent.mkdir(parents=True, exist_ok=True)
        chemin.write_bytes(contenu)
        stats[cle_stat] += 1

    domaine = f'@{DOMAINE}'
    users = list(Utilisateur.objects.filter(email__iendswith=domaine, deleted_at__isnull=True))
    for u in users:
        ecrire(chemin_photo('utilisateurs', u.id), avatar_jpeg(initiales(u.prenoms, u.nom), couleur_pour(u.email)), 'photos')

    fiches = list(Producteur.objects.filter(
        Q(email__iendswith=domaine) | Q(code_producteur__startswith='DEMO-'), deleted_at__isnull=True,
    ))
    for p in fiches:
        ecrire(chemin_photo('producteurs', p.id), avatar_jpeg(initiales(p.prenoms, p.nom), couleur_pour(p.code_producteur)), 'photos')

    coops = list(Cooperative.objects.filter(email__iendswith=domaine))
    for c in coops:
        ecrire(chemin_photo('cooperatives', c.id), avatar_jpeg(sigle(c.nom), couleur_pour(c.code)), 'photos')

    codes_produits = dict(Produit.objects.values_list('id', 'code'))
    for lot in Lot.objects.filter(producteur__in=fiches, deleted_at__isnull=True):
        ecrire(chemin_photo('lots', lot.id, suffixe='_1'), photo_produit_jpeg(codes_produits.get(lot.produit_id, '')), 'photos')
        if lot.qr_image_path and not (media / lot.qr_image_path).exists():
            generer_qr_image(lot)
            stats['qr'] += 1

    offres = OffreDemande.objects.filter(auteur_id__in=[u.id for u in users])
    for offre in offres:
        ecrire(chemin_photo('offres', offre.id, suffixe='_1'), photo_produit_jpeg(codes_produits.get(offre.produit_id, '')), 'photos')
        if column_exists('offres_demandes', 'qr_image_path'):
            rel = get_optional_column('offres_demandes', 'qr_image_path', offre.id)
            payload = get_optional_column('offres_demandes', 'qr_payload', offre.id)
            if rel and payload and not (media / rel).exists():
                import qrcode

                (media / rel).parent.mkdir(parents=True, exist_ok=True)
                qrcode.make(payload).save(media / rel)
                stats['qr'] += 1

    ids = [p.id for p in fiches] + [c.id for c in coops] + [u.id for u in users]
    libelles = {'CNI': 'Carte nationale d’identité', 'FICHE_CIRCUIT': 'Fiche circuit de collecte',
                'AGREMENT_NAGOYA': 'Agrément APA (Protocole de Nagoya)'}
    for doc in DocumentInscription.objects.filter(entite_id__in=ids):
        chemin = media / doc.chemin
        if chemin.suffix.lower() == '.png':
            ecrire(chemin, specimen_document_png(libelles.get(doc.type_document, 'Document'), 'Acteur de démonstration',
                                                 f'DEMO-{doc.type_document}'), 'documents')
    return stats


# =============================================================================
# Marqueur d'idempotence
# =============================================================================

def marqueur_present() -> bool:
    from django.db import connection

    with connection.cursor() as cur:
        cur.execute("SELECT to_regclass('public._data_ops')")
        if cur.fetchone()[0] is None:
            return False
        cur.execute('SELECT 1 FROM public._data_ops WHERE op_key = %s', [OP_KEY])
        return cur.fetchone() is not None


def poser_marqueur(note: str) -> None:
    from django.db import connection

    with connection.cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS public._data_ops (
                op_key VARCHAR(100) PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                note TEXT
            )
            """
        )
        cur.execute(
            """
            INSERT INTO public._data_ops (op_key, note) VALUES (%s, %s)
            ON CONFLICT (op_key) DO UPDATE SET applied_at = NOW(), note = EXCLUDED.note
            """,
            [OP_KEY, note],
        )


def bilan() -> None:
    from django.db import connection

    requetes = [
        ('Comptes de démo par rôle/statut',
         "SELECT role::text, statut::text, count(*) FROM utilisateurs WHERE email ILIKE %s AND deleted_at IS NULL "
         "GROUP BY 1, 2 ORDER BY 1, 2", [f'%@{DOMAINE}']),
        ('Producteurs/collecteurs par statut', 'SELECT statut::text, count(*) FROM producteurs GROUP BY 1 ORDER BY 1', []),
        ('Coopératives par statut', 'SELECT statut::text, count(*) FROM cooperatives GROUP BY 1 ORDER BY 1', []),
        ('Lots par statut', 'SELECT statut::text, count(*) FROM lots WHERE deleted_at IS NULL GROUP BY 1 ORDER BY 1', []),
        ('Certifications par statut', 'SELECT statut::text, count(*) FROM certifications GROUP BY 1 ORDER BY 1', []),
        ('Conversations / messages', 'SELECT (SELECT count(*) FROM conversations), (SELECT count(*) FROM messages)', []),
    ]
    with connection.cursor() as cur:
        for titre, sql, params in requetes:
            cur.execute(sql, params)
            print(f'  {titre} : ' + ', '.join(' '.join(str(v) for v in r) for r in cur.fetchall()))


def creer_jeu(s: Seed) -> None:
    from django.db import connection

    # Répare les lots avec code vide (bloque la contrainte UNIQUE en prod) au format standard
    # PNLF-AAAAMMJJ-XXXXXXXXXX ; les anciens codes « PNLF-FIX-… » de cette réparation sont renommés.
    with connection.cursor() as cur:
        cur.execute(
            """
            UPDATE lots
               SET code_lot = 'PNLF-' || TO_CHAR(COALESCE(created_at, NOW()), 'YYYYMMDD') || '-'
                              || UPPER(SUBSTRING(REPLACE(id::text, '-', '') FROM 1 FOR 10))
             WHERE code_lot IS NULL OR code_lot = '' OR code_lot LIKE 'PNLF-FIX-%%'
            """
        )
        if cur.rowcount:
            print(f'> {cur.rowcount} lot(s) au code vide réparé(s)')

    etape_comptes(s)
    etape_inscriptions(s)
    etape_validations(s)
    zones = etape_zones(s)
    fiches = etape_fiches_terrain(s)
    etape_membres(s, fiches)
    lots = etape_lots(s, zones, fiches)
    etape_certifs(s, lots, fiches)
    offres = etape_offres(s)
    etape_contacts_publics(s, offres, fiches)
    etape_messagerie(s, offres, lots)
    etape_synchronisation(s, fiches)
    etape_verifications(s)
    verifier_etats(s, lots, offres)


ETATS_COMPTES = {
    'admin.demo': 'ACTIF', 'ministere.demo': 'ACTIF', 'ministere.nouveau': 'ACTIF', 'forestier.demo': 'ACTIF',
    'forestier.suspendu': 'SUSPENDU', 'coop.ivindo': 'ACTIF', 'coop.ngounie': 'ACTIF', 'coop.inactive': 'INACTIF',
    'coop.attente': 'EN_ATTENTE', 'producteur.miel': 'ACTIF', 'producteur.kola': 'ACTIF',
    'collecteur.ogooue': 'ACTIF', 'producteur.independant': 'ACTIF', 'producteur.inactif': 'INACTIF',
    'producteur.attente': 'EN_ATTENTE', 'collecteur.attente': 'EN_ATTENTE', 'acheteur.export': 'ACTIF',
    'acheteur.local': 'ACTIF', 'acheteur.attente': 'EN_ATTENTE',
}
ETATS_COOPS = {
    'coop.ivindo': 'ACTIF', 'coop.ngounie': 'ACTIF', 'coop.inactive': 'INACTIF',
    'coop.rejetee': 'REJETE', 'coop.attente': 'EN_VALIDATION',
}
ETATS_FICHES = {
    'producteur.miel': 'ACTIF', 'producteur.kola': 'ACTIF', 'collecteur.ogooue': 'ACTIF',
    'producteur.independant': 'ACTIF', 'producteur.inactif': 'INACTIF', 'producteur.rejete': 'REJETE',
    'producteur.attente': 'EN_VALIDATION', 'collecteur.attente': 'EN_VALIDATION',
}
ETATS_LOTS = {
    'L01': 'COMMERCIALISE', 'L02': 'VALIDE', 'L03': 'BROUILLON', 'L04': 'VALIDE', 'L05': 'BROUILLON',
    'L06': 'COMMERCIALISE', 'L07': 'VALIDE', 'L08': 'SUPPRIME', 'L09': 'VALIDE', 'L10': 'BROUILLON',
    'L11': 'VALIDE', 'L12': 'BROUILLON', 'L13': 'VALIDE', 'L14': 'VALIDE',
}
ETATS_OFFRES = {
    'O1': 'OUVERTE', 'O2': 'OUVERTE', 'O3': 'OUVERTE', 'O4': 'EN_VALIDATION',
    'O5': 'REJETEE', 'O6': 'CLOTUREE', 'O7': 'EN_VALIDATION',
}


def verifier_etats(s: Seed, lots: dict, offres: dict) -> None:
    from accounts.models import Utilisateur
    from pnlf_platform.models import OffreDemande
    from pnlf_platform.offre_statut import read_statut
    from traceability.models import Lot

    print('> Contrôle final des statuts attendus')
    ecarts = []

    def comparer(libelle, obtenu, attendu):
        if obtenu != attendu:
            ecarts.append(f'{libelle} : {obtenu} au lieu de {attendu}')

    for local, attendu in ETATS_COMPTES.items():
        u = Utilisateur.objects.filter(email=email(local), deleted_at__isnull=True).first()
        comparer(f'compte {local}', u.statut if u else 'ABSENT', attendu)
    for local in ('producteur.rejete', 'coop.rejetee'):
        if Utilisateur.objects.filter(email=email(local)).exists():
            ecarts.append(f'compte {local} : devrait être supprimé après rejet')
    u = Utilisateur.objects.get(email=email('ministere.nouveau'))
    comparer('ministere.nouveau doit_changer_mdp', u.doit_changer_mdp, True)
    for local, attendu in ETATS_COOPS.items():
        comparer(f'coopérative {local}', s.coop(email(local)).statut, attendu)
    for local, attendu in ETATS_FICHES.items():
        comparer(f'fiche {local}', s.fiche(email(local)).statut, attendu)
    for code, attendu in ETATS_LOTS.items():
        lot = Lot.objects.get(pk=lots[code]['id'])
        comparer(f'lot {code}', 'SUPPRIME' if lot.deleted_at else lot.statut, attendu)
    for code, attendu in ETATS_OFFRES.items():
        comparer(f'annonce {code}', read_statut(OffreDemande.objects.get(pk=offres[code])), attendu)
    if ecarts:
        raise SeedError('Statuts inattendus :\n  - ' + '\n  - '.join(ecarts))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--dry-run', action='store_true', help='exécute tout puis annule la transaction')
    parser.add_argument('--render-remote', action='store_true', help='cible la base Render depuis un poste')
    parser.add_argument('--fichiers', action='store_true', help='régénère uniquement les fichiers media')
    args = parser.parse_args()

    preparer_django(render_remote=args.render_remote)

    from django.conf import settings
    from django.db import connection, transaction
    from django.test.utils import override_settings

    cible = connection.settings_dict.get('HOST') or 'local'
    print(f'Base ciblée : {connection.settings_dict.get("NAME")} @ {cible}')

    if args.fichiers:
        print('Fichiers media régénérés :', assurer_fichiers())
        return 0

    if marqueur_present():
        print(f'Jeu de démonstration déjà présent (marqueur {OP_KEY}).')
        print('Fichiers media régénérés :', assurer_fichiers())
        return 0

    from accounts.models import Utilisateur

    if Utilisateur.objects.filter(email__iendswith=f'@{DOMAINE}').exists():
        raise SeedError(f'Des comptes @{DOMAINE} existent sans marqueur {OP_KEY} : vérifiez la base avant de relancer.')

    reglages = {
        'EMAIL_BACKEND': 'django.core.mail.backends.locmem.EmailBackend',
        'TWILIO_ACCOUNT_SID': '', 'TWILIO_AUTH_TOKEN': '', 'TWILIO_FROM_NUMBER': '',
        'SECURE_SSL_REDIRECT': False, 'ALLOWED_HOSTS': ['*'],
    }
    media_temporaire = None
    if args.dry_run:
        media_temporaire = tempfile.TemporaryDirectory(prefix='pfnl-seed-')
        reglages['MEDIA_ROOT'] = media_temporaire.name

    s = Seed()
    try:
        with override_settings(**reglages):
            with transaction.atomic():
                creer_jeu(s)
                poser_marqueur(f'Jeu de démonstration créé ({s.nb_appels} appels API).')
                print('> Bilan')
                bilan()
                if args.dry_run:
                    raise _Annulation()
            print('Fichiers media :', assurer_fichiers())
    except _Annulation:
        print(f'DRY-RUN réussi ({s.nb_appels} appels API) : transaction annulée, rien n’a été écrit.')
        return 0
    finally:
        if media_temporaire is not None:
            media_temporaire.cleanup()

    print(f'Jeu de démonstration créé avec succès ({s.nb_appels} appels API). Mot de passe commun : {MOT_DE_PASSE}')
    print(f'MEDIA_ROOT = {settings.MEDIA_ROOT}')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except SeedError as exc:
        print(f'ÉCHEC : {exc}', file=sys.stderr)
        print('Aucune donnée n’a été écrite (transaction annulée).', file=sys.stderr)
        sys.exit(1)
