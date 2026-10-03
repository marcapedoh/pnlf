"""Test critique : login, seed minimal, création lot + mouvement + audit."""
import json
import os
import sys
import uuid
from pathlib import Path

import django
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
ROOT = BACKEND.parent
sys.path.insert(0, str(BACKEND))
load_dotenv(BACKEND / '.env')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from accounts.models import Utilisateur
from traceability.models import CategorieProduit, Lot, Mouvement, Producteur, Produit, Province

# Mot de passe admin depuis password_pnlf.txt
pwd = None
for line in (ROOT / 'password_pnlf.txt').read_text(encoding='utf-8').splitlines():
    if 'TonMotDePasseAdmin' in line:
        pwd = line.split('=')[-1].strip()
        break
assert pwd, 'mdp admin introuvable'

admin = Utilisateur.objects.get(email='admin@pnlf.ga')
assert admin.check_password(pwd), 'check_password admin KO'
print('OK auth password')

province = Province.objects.first()
cat = CategorieProduit.objects.first()
assert province and cat

produit, _ = Produit.objects.get_or_create(
    code='TST-MIEL-01',
    defaults={
        'nom': 'Miel test PNLF',
        'categorie': cat,
        'unite_defaut': 'KG',
        'created_at': timezone.now(),
        'updated_at': timezone.now(),
        'actif': True,
    },
)

prod, _ = Producteur.objects.get_or_create(
    code_producteur='PROD-TEST-01',
    defaults={
        'nom': 'Test',
        'prenoms': 'Producteur',
        'province': province,
        'statut': 'ACTIF',
        'utilisateur_id': admin.id,
        'created_at': timezone.now(),
        'updated_at': timezone.now(),
        'sync_statut': 'SYNCED',
    },
)
print('OK seed produit/producteur')

# Simuler perform_create lot
now = timezone.now()
lot = Lot.objects.create(
    code_lot='',
    produit=produit,
    producteur=prod,
    date_collecte=timezone.localdate(),
    quantite=12.5,
    unite='KG',
    statut='BROUILLON',
    declare_par_id=admin.id,
    sync_statut='SYNCED',
    created_at=now,
    updated_at=now,
)
lot.refresh_from_db()
assert lot.code_lot and lot.code_lot.startswith('PNLF-'), f'code_lot invalid: {lot.code_lot!r}'
lot.qr_payload = f'PNLF:{lot.uuid_public}'
lot.save(update_fields=['qr_payload'])

mvt = Mouvement.objects.create(
    lot=lot,
    type_mouvement='COLLECTE',
    date_mouvement=now,
    lieu_libelle='Test',
    quantite=lot.quantite,
    unite=lot.unite,
    acteur_utilisateur_id=admin.id,
    acteur_producteur_id=prod.id,
    created_at=now,
    sync_statut='SYNCED',
)
print('OK lot', lot.code_lot, 'mouvement', mvt.id)

from accounts.audit import write_audit
write_audit(
    utilisateur_id=admin.id,
    action='LOGIN',
    table_cible='utilisateurs',
    enregistrement_id=admin.id,
    nouvelles_valeurs={'test': True},
)
from django.db import connection
with connection.cursor() as cur:
    cur.execute('select count(*) from audit_logs')
    print('OK audit_logs count', cur.fetchone()[0])

# soft delete lot
lot.deleted_at = timezone.now()
lot.updated_at = timezone.now()
lot.save(update_fields=['deleted_at', 'updated_at'])
assert Lot.objects.filter(pk=lot.pk, deleted_at__isnull=True).count() == 0
print('OK soft-delete lot')
print('ALL CRITICAL CHECKS PASSED')
