"""
Vérifie la connexion de chaque compte de démonstration (login réel + écran principal du rôle).

  python scripts/verifier_comptes_demo.py                               # en local, via Django
  python scripts/verifier_comptes_demo.py --base-url https://pfnl.onrender.com   # API déployée

En mode --base-url, les appels sont espacés pour respecter la limite de 8 connexions/minute.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from seed_demo_acteurs import DOMAINE, ETATS_COMPTES, MOT_DE_PASSE  # noqa: E402

ECRAN_PAR_ROLE = {
    'ADMINISTRATEUR': '/api/dashboard/a-traiter/',
    'AGENT_MINISTERE': '/api/dashboard/stats/',
    'AGENT_FORESTIER': '/api/lots/',
    'COOPERATIVE': '/api/producteurs/',
    'PRODUCTEUR': '/api/lots/',
    'ACHETEUR': '/api/offres-demandes/',
}
COMPTES_SUPPRIMES = ('producteur.rejete', 'coop.rejetee')


class ClientHttp:
    def __init__(self, base: str):
        self.base = base.rstrip('/')

    def requete(self, methode, chemin, data=None, jeton=None):
        corps = json.dumps(data).encode() if data is not None else None
        req = urllib.request.Request(self.base + chemin, data=corps, method=methode)
        req.add_header('Content-Type', 'application/json')
        if jeton:
            req.add_header('Authorization', f'Bearer {jeton}')
        try:
            with urllib.request.urlopen(req, timeout=60) as rep:
                return rep.status, json.loads(rep.read() or b'null')
        except urllib.error.HTTPError as exc:
            try:
                return exc.code, json.loads(exc.read() or b'null')
            except ValueError:
                return exc.code, None


class ClientDjango:
    def __init__(self):
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
        import django

        django.setup()
        from django.test.utils import override_settings
        from rest_framework.test import APIClient

        override_settings(SECURE_SSL_REDIRECT=False, ALLOWED_HOSTS=['*']).enable()
        self.client = APIClient()

    def requete(self, methode, chemin, data=None, jeton=None):
        from django.core.cache import cache

        cache.clear()
        self.client.credentials(**({'HTTP_AUTHORIZATION': f'Bearer {jeton}'} if jeton else {}))
        rep = getattr(self.client, methode.lower())(chemin, data, format='json') if data is not None \
            else getattr(self.client, methode.lower())(chemin)
        return rep.status_code, getattr(rep, 'data', None)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url')
    args = parser.parse_args()
    client = ClientHttp(args.base_url) if args.base_url else ClientDjango()
    pause = 8.5 if args.base_url else 0

    erreurs = 0
    comptes = list(ETATS_COMPTES.items()) + [(c, 'SUPPRIME') for c in COMPTES_SUPPRIMES]
    for i, (local, etat) in enumerate(comptes):
        if i and pause:
            time.sleep(pause)
        adresse = f'{local}@{DOMAINE}'
        code, rep = client.requete('POST', '/api/auth/login/', {'email': adresse, 'password': MOT_DE_PASSE})
        if etat == 'ACTIF':
            if code != 200:
                print(f'ECHEC  {adresse} : login HTTP {code} {rep}')
                erreurs += 1
                continue
            role = rep['user']['role']
            code_ecran, corps = client.requete('GET', ECRAN_PAR_ROLE[role], jeton=rep['access'])
            if rep['user'].get('doit_changer_mdp'):
                code_me, _ = client.requete('GET', '/api/accounts/me/', jeton=rep['access'])
                bloque = code_ecran == 403 and isinstance(corps, dict) and corps.get('code') == 'password_change_required'
                ok = bloque and code_me == 200
                extra = f' (changement de mot de passe exigé : écran bloqué, /api/accounts/me/ HTTP {code_me})'
            else:
                ok = code_ecran == 200
                extra = ''
            erreurs += 0 if ok else 1
            print(f'{"OK   " if ok else "ECHEC"}  {adresse} : connecté [{role}], écran {ECRAN_PAR_ROLE[role]} HTTP {code_ecran}{extra}')
        else:
            ok = code in (400, 401)
            erreurs += 0 if ok else 1
            message = rep.get('non_field_errors', rep.get('detail', rep)) if isinstance(rep, dict) else rep
            print(f'{"OK   " if ok else "ECHEC"}  {adresse} : refus attendu ({etat}) HTTP {code} {message}')
    print(f'\n{len(comptes) - erreurs}/{len(comptes)} vérifications conformes.')
    return 1 if erreurs else 0


if __name__ == '__main__':
    sys.exit(main())
