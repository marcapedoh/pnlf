"""
Restauration de la base Render à partir d'une sauvegarde locale (sens inverse de sauvegarde_prod.py).

À utiliser en cas de perte ou de corruption des données en ligne, ou pour alimenter une nouvelle
base Render (ancienne base expirée, changement d'offre). Les médias ne sont pas concernés :
ils vivent dans le bucket R2, qui n'est pas effacé par les déploiements.

Sécurités :
  - une sauvegarde de l'état actuel de Render est faite juste avant (sauf --sans-sauvegarde-prealable) ;
  - la restauration est une seule transaction : en cas d'erreur, la base Render reste telle quelle ;
  - les extensions (postgis, pgcrypto) et la table spatial_ref_sys, gérées par Render, ne sont pas touchées ;
  - confirmation obligatoire par saisie du nom de la base cible (sauf --oui, pour usage scripté).

Usage (depuis backend/) :
  python scripts/restaurer_prod.py --simulation                       # liste ce qui serait restauré, n'écrit rien
  python scripts/restaurer_prod.py                                    # dernière sauvegarde de sauvegardes/base/
  python scripts/restaurer_prod.py --dump sauvegardes/base/pfnl_prod_20261006_130002.dump

La base cible est celle de backend/.env (DB_*), surchargeable par RESTORE_TARGET_DB_HOST/PORT/NAME/USER/PASSWORD.
"""
from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sauvegarde_prod import (  # noqa: E402
    Base,
    SauvegardeError,
    charger_config,
    configurer_journal,
    dump_prod,
    executer,
    log,
    outil,
)

EXTENSIONS_REQUISES = ('pgcrypto', 'postgis')
# Entrées du dump laissées à Render : extensions, schéma public (préexistant) et table de PostGIS.
_EXCLUSIONS = (' EXTENSION ', ' COMMENT - EXTENSION ', ' SCHEMA - public ')


def cible_depuis(cfg: dict) -> Base:
    src: Base = cfg['source']

    def lire(cle, defaut):
        return os.environ.get(cle) or defaut

    return Base(
        host=lire('RESTORE_TARGET_DB_HOST', src.host),
        port=lire('RESTORE_TARGET_DB_PORT', src.port),
        nom=lire('RESTORE_TARGET_DB_NAME', src.nom),
        user=lire('RESTORE_TARGET_DB_USER', src.user),
        password=lire('RESTORE_TARGET_DB_PASSWORD', src.password),
    )


def derniere_sauvegarde(cfg: dict) -> Path:
    dumps = sorted((cfg['dossier'] / 'base').glob('pfnl_prod_*.dump'))
    if not dumps:
        raise SauvegardeError('Aucune sauvegarde dans sauvegardes/base/ : lancez d’abord scripts/sauvegarde_prod.py.')
    return dumps[-1]


def liste_filtree(cfg: dict, dump: Path) -> tuple[Path, int, int]:
    """Table des matières du dump sans les objets gérés par Render."""
    import subprocess

    toc = subprocess.run(
        [outil('pg_restore', cfg['pg_bin']), '-l', str(dump)], capture_output=True, text=True, check=True,
    ).stdout.splitlines()
    gardees, exclues = [], 0
    for ligne in toc:
        if ligne.startswith(';') or not ligne.strip():
            gardees.append(ligne)
            continue
        if any(motif in ligne for motif in _EXCLUSIONS) or 'spatial_ref_sys' in ligne:
            exclues += 1
            continue
        gardees.append(ligne)
    fichier = Path(tempfile.gettempdir()) / f'{dump.stem}.liste'
    fichier.write_text('\n'.join(gardees) + '\n', encoding='utf-8')
    return fichier, sum(1 for l in gardees if l and not l.startswith(';')), exclues


def _extensions(cible: Base, sslmode: str) -> None:
    import psycopg

    with psycopg.connect(
        host=cible.host, port=cible.port, user=cible.user, password=cible.password, dbname=cible.nom,
        autocommit=True, connect_timeout=20, sslmode=sslmode,
    ) as conn:
        for ext in EXTENSIONS_REQUISES:
            conn.execute(f'CREATE EXTENSION IF NOT EXISTS {ext}')
        conn.execute('CREATE SCHEMA IF NOT EXISTS pnlf')


def _compter(cible: Base, sslmode: str) -> dict:
    import psycopg

    with psycopg.connect(
        host=cible.host, port=cible.port, user=cible.user, password=cible.password, dbname=cible.nom,
        connect_timeout=20, sslmode=sslmode,
    ) as conn:
        resultat = {}
        for table in ('utilisateurs', 'producteurs', 'cooperatives', 'lots'):
            try:
                resultat[table] = conn.execute(f'SELECT count(*) FROM pnlf.{table}').fetchone()[0]
            except Exception:
                conn.rollback()
                resultat[table] = 'absente'
        return resultat


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--dump', type=Path, help='sauvegarde à restaurer (défaut : la plus récente)')
    parser.add_argument('--simulation', action='store_true', help='affiche le plan sans rien écrire')
    parser.add_argument('--sans-sauvegarde-prealable', action='store_true', help='ne sauvegarde pas Render avant')
    parser.add_argument('--oui', action='store_true', help='pas de question de confirmation')
    args = parser.parse_args()

    cfg = charger_config()
    configurer_journal(cfg['dossier'])
    cible = cible_depuis(cfg)
    sslmode = cfg['source_sslmode']
    try:
        dump = args.dump.resolve() if args.dump else derniere_sauvegarde(cfg)
        if not dump.is_file():
            raise SauvegardeError(f'Fichier introuvable : {dump}')
        liste, nb_objets, nb_exclus = liste_filtree(cfg, dump)
        log.info('Sauvegarde source : %s (%.1f Mo)', dump.name, dump.stat().st_size / 1e6)
        log.info('Cible : base %s sur %s', cible.nom, cible.host)
        log.info('%s objets à restaurer, %s laissés à Render (extensions, schéma public, spatial_ref_sys)',
                 nb_objets, nb_exclus)
        if args.simulation:
            log.info('Simulation : état actuel de la cible %s ; aucune écriture effectuée.', _compter(cible, sslmode))
            return 0

        if not args.oui:
            print(f'\nATTENTION : les données actuelles de la base « {cible.nom} » seront remplacées par {dump.name}.')
            if input(f'Pour confirmer, saisissez le nom de la base ({cible.nom}) : ').strip() != cible.nom:
                log.info('Restauration annulée par l’utilisateur.')
                return 1

        if not args.sans_sauvegarde_prealable:
            log.info('Sauvegarde préalable de l’état actuel de la cible ...')
            dump_prod(dict(cfg, source=cible, retention=0))

        _extensions(cible, sslmode)
        log.info('Restauration en une seule transaction ...')
        executer(
            [outil('pg_restore', cfg['pg_bin']), *cible.args(), '-d', cible.nom, '--clean', '--if-exists',
             '--no-owner', '--no-privileges', '--single-transaction', '--exit-on-error', '-L', str(liste), str(dump)],
            cible.env(sslmode=sslmode), 'pg_restore', timeout=3600,
        )
        log.info('Restauration terminée. Contenu de la cible : %s', _compter(cible, sslmode))
        return 0
    except Exception as exc:
        log.error('Restauration interrompue, base cible inchangée : %s', exc)
        return 1


if __name__ == '__main__':
    sys.exit(main())
