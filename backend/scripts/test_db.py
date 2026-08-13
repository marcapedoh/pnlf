"""Test connexion DB via variables .env (sans mot de passe en dur)."""
import os
import sys
from pathlib import Path

import django
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))
load_dotenv(BACKEND_DIR / '.env')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection
from accounts.models import Utilisateur

with connection.cursor() as cur:
    cur.execute('select count(*) from provinces')
    print('provinces:', cur.fetchone()[0])

admin = Utilisateur.objects.filter(email='admin@pnlf.ga').first()
print('admin:', admin)
if admin:
    # Ne pas afficher le résultat du mot de passe en clair dans les logs sensibles
    print('hash prefix:', (admin.mot_de_passe_hash or '')[:7])
print('OK django+db')
