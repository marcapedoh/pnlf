"""Test end-to-end : photos de lot, fiche producteur publique enrichie, compteur notifications.

Usage:
  python backend/scripts/test_lot_photos_public.py
"""
from __future__ import annotations

import io
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

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import Utilisateur
from traceability.models import CategorieProduit, Lot, Producteur, Produit, Province

PASS: list[str] = []
FAIL: list[str] = []


def check(label: str, ok: bool, detail: str = '') -> None:
    if ok:
        PASS.append(label)
        print(f'  [OK] {label}')
    else:
        FAIL.append(label)
        print(f'  [FAIL] {label} {detail}')


def make_photo(color=(10, 120, 60)) -> SimpleUploadedFile:
    from PIL import Image

    buf = io.BytesIO()
    Image.new('RGB', (80, 80), color=color).save(buf, format='JPEG')
    buf.seek(0)
    return SimpleUploadedFile('photo.jpg', buf.read(), content_type='image/jpeg')


def get_or_create_admin() -> Utilisateur:
    admin = Utilisateur.objects.filter(email='lot_photo_test_admin@pnlf-test.local').first()
    if admin:
        if admin.deleted_at is not None or admin.statut != Utilisateur.Statut.ACTIF:
            admin.deleted_at = None
            admin.statut = Utilisateur.Statut.ACTIF
            admin.save(update_fields=['deleted_at', 'statut'])
        return admin
    admin = Utilisateur(
        id=uuid.uuid4(), email='lot_photo_test_admin@pnlf-test.local', telephone='074000001',
        role=Utilisateur.Role.ADMINISTRATEUR, statut=Utilisateur.Statut.ACTIF, nom='Test', prenoms='Admin',
        created_at=timezone.now(), updated_at=timezone.now(),
    )
    admin.set_password('AdminTest2026!')
    admin.save()
    return admin


def main() -> None:
    province = Province.objects.filter(actif=True).first()
    cat = CategorieProduit.objects.first()
    if not province or not cat:
        print('Référentiel de base manquant (province/catégorie) — impossible de tester.')
        sys.exit(1)

    admin = get_or_create_admin()
    client = APIClient()
    client.force_authenticate(user=admin)

    now = timezone.now()
    produit, _ = Produit.objects.get_or_create(
        code='TST-LOTPHOTO-01',
        defaults={
            'nom': 'Kola test photos', 'categorie': cat, 'unite_defaut': 'KG',
            'created_at': now, 'updated_at': now, 'actif': True,
        },
    )
    prod = Producteur.objects.create(
        id=uuid.uuid4(), code_producteur=f'PROD-PHOTO-{uuid.uuid4().hex[:6].upper()}',
        nom='Ondimba', prenoms='Alice', province=province, statut='ACTIF',
        notes='Test photos lot', sync_statut='SYNCED', sync_version=1,
        created_at=now, updated_at=now,
    )

    print('\n=== 1. Création du lot ===')
    resp = client.post('/api/lots/', {
        'produit': str(produit.id), 'producteur': str(prod.id),
        'date_collecte': str(date.today()), 'quantite': '12.500', 'unite': 'KG',
        'qualite_indicateur': '1er choix', 'prix_indicatif': '2500', 'devise': 'XAF',
        'observations': 'Récolte fraîche, séchage naturel.',
    }, format='json')
    check('POST /lots/ -> 201', resp.status_code == 201, str(resp.data) if resp.status_code != 201 else '')
    lot_id = resp.data['id']
    check('photos_urls vide à la création', resp.data.get('photos_urls') == [])

    print('\n=== 2. Upload de 2 photos ===')
    resp = client.post(
        f'/api/lots/{lot_id}/photos/',
        {'photos': [make_photo((10, 120, 60)), make_photo((200, 150, 10))]},
        format='multipart',
    )
    check('POST /lots/{id}/photos/ (2 fichiers) -> 200', resp.status_code == 200, str(resp.data) if resp.status_code != 200 else '')
    check('2 photos_urls renvoyées', len(resp.data.get('photos_urls', [])) == 2, str(resp.data.get('photos_urls')))

    print('\n=== 3. Upload au-delà de la capacité (2 emplacements déjà pleins) ===')
    resp = client.post(f'/api/lots/{lot_id}/photos/', {'photos': [make_photo()]}, format='multipart')
    check('POST photo supplémentaire alors que complet -> 400', resp.status_code == 400)

    print('\n=== 4. Suppression d\'une photo puis ré-upload ===')
    resp = client.delete(f'/api/lots/{lot_id}/photos/?index=1')
    check('DELETE /lots/{id}/photos/?index=1 -> 200', resp.status_code == 200, str(resp.data) if resp.status_code != 200 else '')
    check('1 photo restante après suppression', len(resp.data.get('photos_urls', [])) == 1, str(resp.data.get('photos_urls')))

    resp = client.post(f'/api/lots/{lot_id}/photos/', {'photos': [make_photo((5, 5, 200))]}, format='multipart')
    check('Ré-upload après suppression -> 200 et 2 photos', resp.status_code == 200 and len(resp.data.get('photos_urls', [])) == 2)

    print('\n=== 5. Fiche producteur publique enrichie (lots, prix, photos) ===')
    anon = APIClient()
    resp = anon.get(f'/api/public/producteurs/{prod.id}/')
    check('GET /public/producteurs/{id}/ -> 200', resp.status_code == 200, str(resp.data) if resp.status_code != 200 else '')
    lots = resp.data.get('lots', [])
    check('1 lot présent sur la fiche publique', len(lots) == 1, str(lots))
    if lots:
        lot_public = lots[0]
        check('prix_indicatif présent', str(lot_public.get('prix_indicatif')) == '2500.00', str(lot_public.get('prix_indicatif')))
        check('produit_nom présent', lot_public.get('produit_nom') == 'Kola test photos')
        check('2 photos_urls sur la fiche publique', len(lot_public.get('photos_urls', [])) == 2, str(lot_public.get('photos_urls')))
        check('observations (descriptif) présentes', bool(lot_public.get('observations')))

    print('\n=== 6. Recherche annuaire public par nom de produit (q) ===')
    resp = anon.get('/api/public/producteurs/', {'q': 'Kola test photos'})
    check('Recherche q= nom de produit -> retrouve le producteur', resp.status_code == 200 and resp.data['count'] >= 1, str(resp.data))

    print('\n=== 7. Compteur de notifications non lues (cloche) ===')
    resp = client.get('/api/notifications/non-lues/')
    check('GET /notifications/non-lues/ -> 200 avec compteur entier', resp.status_code == 200 and isinstance(resp.data.get('count'), int), str(resp.data))

    print('\n=== Nettoyage ===')
    # Table mouvements en écriture restreinte pour pnlf_app et lots protégé par FK RESTRICT :
    # on soft-delete plutôt que hard-delete (comme pour les autres scripts de test).
    Lot.objects.filter(id=lot_id).update(deleted_at=timezone.now())
    for i in (1, 2):
        from traceability.services import chemin_photo
        p = chemin_photo('lots', lot_id, suffixe=f'_{i}')
        if p.exists():
            p.unlink()
    Producteur.objects.filter(id=prod.id).update(deleted_at=timezone.now())
    Utilisateur.objects.filter(email='lot_photo_test_admin@pnlf-test.local').update(deleted_at=timezone.now())
    print('OK')

    print(f'\n=== RÉSUMÉ : {len(PASS)} OK / {len(FAIL)} ÉCHECS ===')
    if FAIL:
        print('Échecs :', FAIL)
        sys.exit(1)


if __name__ == '__main__':
    with override_settings(ALLOWED_HOSTS=['testserver', 'localhost', '127.0.0.1']):
        main()
