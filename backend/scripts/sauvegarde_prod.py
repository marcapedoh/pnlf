"""
Sauvegarde de la production (base Render + médias R2) vers ce poste, puis copie dans la base locale.

Étapes :
  1. pg_dump de la base Render -> sauvegardes/base/pfnl_prod_AAAAMMJJ_HHMMSS.dump (rotation)
  2. miroir incrémental du bucket R2 -> sauvegardes/medias/ puis backend/media/
  3. restauration du dump dans une base temporaire, contrôle, puis bascule :
     la base locale actuelle devient <nom>_precedente, la base restaurée prend son nom.
     En cas d'échec avant la bascule, la base locale n'est pas modifiée.

Usage (depuis backend/) :
  python scripts/sauvegarde_prod.py                      # tout
  python scripts/sauvegarde_prod.py --sans-restauration  # dump + médias, base locale inchangée
  python scripts/sauvegarde_prod.py --sans-medias
  python scripts/sauvegarde_prod.py --dump-existant sauvegardes/base/xxx.dump   # restaure une sauvegarde précise

Configuration lue dans backend/.env (base Render : DB_*) et backend/.env.local :
  BACKUP_LOCAL_PG_USER / BACKUP_LOCAL_PG_PASSWORD   superutilisateur PostgreSQL local (obligatoire pour restaurer)
  BACKUP_R2_BUCKET, BACKUP_R2_ENDPOINT_URL, BACKUP_R2_ACCESS_KEY_ID, BACKUP_R2_SECRET_ACCESS_KEY, BACKUP_R2_PREFIX
  BACKUP_DIR (défaut : <projet>/sauvegardes), BACKUP_RETENTION (défaut : 30 dumps), BACKUP_PG_BIN
  BACKUP_SOURCE_DB_HOST/PORT/NAME/USER/PASSWORD, BACKUP_SOURCE_SSLMODE pour surcharger la source
"""
from __future__ import annotations

import argparse
import glob
import logging
import os
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
PROJET = BACKEND.parent

log = logging.getLogger('sauvegarde')


class SauvegardeError(RuntimeError):
    pass


@dataclass
class Base:
    host: str
    port: str
    nom: str
    user: str
    password: str

    def env(self, sslmode: str | None = None) -> dict:
        env = dict(os.environ, PGPASSWORD=self.password, PGCONNECT_TIMEOUT='20')
        if sslmode:
            env['PGSSLMODE'] = sslmode
        return env

    def args(self) -> list[str]:
        return ['-h', self.host, '-p', str(self.port), '-U', self.user]


def charger_config() -> dict:
    from dotenv import dotenv_values

    prod = {k: v or '' for k, v in dotenv_values(BACKEND / '.env').items()}
    local = {k: v or '' for k, v in dotenv_values(BACKEND / '.env.local').items()}

    def lire(cle, defaut=''):
        return os.environ.get(cle) or local.get(cle) or defaut

    source = Base(
        host=lire('BACKUP_SOURCE_DB_HOST', prod.get('DB_HOST', '')),
        port=lire('BACKUP_SOURCE_DB_PORT', prod.get('DB_PORT', '5432')),
        nom=lire('BACKUP_SOURCE_DB_NAME', prod.get('DB_NAME', '')),
        user=lire('BACKUP_SOURCE_DB_USER', prod.get('DB_USER', '')),
        password=lire('BACKUP_SOURCE_DB_PASSWORD', prod.get('DB_PASSWORD', '')),
    )
    cible = Base(
        host=lire('BACKUP_LOCAL_PG_HOST', local.get('DB_HOST', '127.0.0.1')),
        port=lire('BACKUP_LOCAL_PG_PORT', local.get('DB_PORT', '5432')),
        nom=lire('BACKUP_LOCAL_DB_NAME', local.get('DB_NAME', 'pnlf')),
        user=lire('BACKUP_LOCAL_PG_USER', 'postgres'),
        password=lire('BACKUP_LOCAL_PG_PASSWORD'),
    )
    return {
        'source': source,
        'source_sslmode': lire('BACKUP_SOURCE_SSLMODE', 'require'),
        'cible': cible,
        'app_user': lire('BACKUP_LOCAL_APP_USER', local.get('DB_USER', 'pnlf_app')),
        'dossier': Path(lire('BACKUP_DIR', str(PROJET / 'sauvegardes'))),
        'retention': int(lire('BACKUP_RETENTION', '30')),
        'pg_bin': lire('BACKUP_PG_BIN'),
        'r2': {
            'bucket': lire('BACKUP_R2_BUCKET'),
            'endpoint': lire('BACKUP_R2_ENDPOINT_URL'),
            'key': lire('BACKUP_R2_ACCESS_KEY_ID'),
            'secret': lire('BACKUP_R2_SECRET_ACCESS_KEY'),
            'prefixe': lire('BACKUP_R2_PREFIX', 'media/'),
        },
    }


def outil(nom: str, pg_bin: str) -> str:
    exe = f'{nom}.exe' if os.name == 'nt' else nom
    if pg_bin:
        chemin = Path(pg_bin) / exe
        if chemin.is_file():
            return str(chemin)
    candidats = sorted(
        glob.glob(rf'C:\Program Files\PostgreSQL\*\bin\{exe}'),
        key=lambda p: int(Path(p).parents[1].name) if Path(p).parents[1].name.isdigit() else 0,
    )
    if candidats:
        return candidats[-1]
    trouve = shutil.which(nom)
    if trouve:
        return trouve
    raise SauvegardeError(f'{nom} introuvable : installez PostgreSQL ou renseignez BACKUP_PG_BIN.')


def executer(cmd: list[str], env: dict, etape: str, timeout: int = 1800) -> None:
    sans_fenetre = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    res = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=timeout, creationflags=sans_fenetre)
    if res.returncode != 0:
        detail = (res.stderr or res.stdout or '').strip()[-1500:]
        raise SauvegardeError(f'{etape} a échoué (code {res.returncode}) : {detail}')


# -----------------------------------------------------------------------------
# 1. Dump de la base de production
# -----------------------------------------------------------------------------

def dump_prod(cfg: dict) -> Path:
    src: Base = cfg['source']
    if not (src.host and src.nom and src.user and src.password):
        raise SauvegardeError('Connexion à la base Render incomplète (DB_* dans backend/.env).')
    dossier = cfg['dossier'] / 'base'
    dossier.mkdir(parents=True, exist_ok=True)
    fichier = dossier / f'pfnl_prod_{datetime.now():%Y%m%d_%H%M%S}.dump'
    partiel = fichier.with_suffix('.dump.part')
    log.info('Dump de la base Render %s@%s ...', src.nom, src.host)
    executer(
        [outil('pg_dump', cfg['pg_bin']), *src.args(), '-d', src.nom, '-Fc', '--no-owner', '--no-privileges',
         '-f', str(partiel)],
        src.env(sslmode=cfg['source_sslmode']), 'pg_dump',
    )
    executer([outil('pg_restore', cfg['pg_bin']), '-l', str(partiel)], dict(os.environ), 'Contrôle du dump')
    partiel.replace(fichier)
    log.info('Dump enregistré : %s (%.1f Mo)', fichier, fichier.stat().st_size / 1e6)

    dumps = sorted(dossier.glob('pfnl_prod_*.dump'))
    for ancien in dumps[:-cfg['retention']] if cfg['retention'] > 0 else []:
        ancien.unlink(missing_ok=True)
        log.info('Ancien dump supprimé (rotation) : %s', ancien.name)
    return fichier


# -----------------------------------------------------------------------------
# 2. Médias (bucket R2)
# -----------------------------------------------------------------------------

def miroir_medias(cfg: dict) -> None:
    r2 = cfg['r2']
    if not (r2['bucket'] and r2['key'] and r2['secret']):
        log.warning('Médias ignorés : BACKUP_R2_* non renseignés dans backend/.env.local.')
        return
    import boto3

    client = boto3.client(
        's3', endpoint_url=r2['endpoint'] or None, aws_access_key_id=r2['key'],
        aws_secret_access_key=r2['secret'], region_name='auto',
    )
    miroir = cfg['dossier'] / 'medias'
    media_local = BACKEND / 'media'
    stats = {'distants': 0, 'telecharges': 0, 'copies_locales': 0}
    pages = client.get_paginator('list_objects_v2').paginate(Bucket=r2['bucket'], Prefix=r2['prefixe'])
    for page in pages:
        for obj in page.get('Contents', []):
            rel = obj['Key'][len(r2['prefixe']):]
            if not rel or rel.endswith('/') or '..' in rel.split('/'):
                continue
            stats['distants'] += 1
            dest = miroir / rel
            if not (dest.is_file() and dest.stat().st_size == obj['Size']):
                dest.parent.mkdir(parents=True, exist_ok=True)
                partiel = dest.with_name(dest.name + '.part')
                client.download_file(r2['bucket'], obj['Key'], str(partiel))
                partiel.replace(dest)
                stats['telecharges'] += 1
            copie = media_local / rel
            if not (copie.is_file() and copie.stat().st_size == dest.stat().st_size):
                copie.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(dest, copie)
                stats['copies_locales'] += 1
    log.info('Médias : %s', stats)


# -----------------------------------------------------------------------------
# 3. Restauration dans la base locale (base temporaire puis bascule)
# -----------------------------------------------------------------------------

def _connexion(cible: Base, base: str):
    import psycopg

    return psycopg.connect(
        host=cible.host, port=cible.port, user=cible.user, password=cible.password, dbname=base,
        autocommit=True, connect_timeout=15,
    )


def _droits(cible: Base, base: str, app_user: str) -> None:
    """Reproduit la répartition locale : public appartient à l'application, pnlf au superutilisateur."""
    from psycopg import sql

    app = sql.Identifier(app_user)
    with _connexion(cible, base) as conn:
        conn.execute(sql.SQL('GRANT USAGE, CREATE ON SCHEMA public TO {}').format(app))
        conn.execute(sql.SQL('GRANT USAGE ON SCHEMA pnlf TO {}').format(app))
        conn.execute(sql.SQL('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pnlf TO {}').format(app))
        conn.execute(sql.SQL('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pnlf, public TO {}').format(app))
        conn.execute(sql.SQL('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pnlf TO {}').format(app))
        relations = conn.execute(
            """
            SELECT c.relname, c.relkind
              FROM pg_class c
              JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p', 'v', 'm')
               AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = c.oid AND d.deptype = 'e')
            """
        ).fetchall()
        genres = {'r': 'TABLE', 'p': 'TABLE', 'v': 'VIEW', 'm': 'MATERIALIZED VIEW'}
        for nom, genre in relations:
            conn.execute(sql.SQL('ALTER {} public.{} OWNER TO {}').format(
                sql.SQL(genres[genre]), sql.Identifier(nom), app,
            ))


def _controler(cible: Base, base: str) -> None:
    with _connexion(cible, base) as conn:
        nb = conn.execute('SELECT count(*) FROM pnlf.utilisateurs').fetchone()[0]
        lots = conn.execute('SELECT count(*) FROM pnlf.lots').fetchone()[0]
    if nb == 0:
        raise SauvegardeError('Base restaurée vide (aucun utilisateur) : bascule annulée.')
    log.info('Contrôle base restaurée : %s utilisateurs, %s lots', nb, lots)


def restaurer(cfg: dict, dump: Path) -> None:
    from psycopg import sql

    cible: Base = cfg['cible']
    if not cible.password:
        raise SauvegardeError(
            'BACKUP_LOCAL_PG_PASSWORD absent de backend/.env.local : restauration locale impossible '
            '(le dump est tout de même conservé).'
        )
    temp, precedente = f'{cible.nom}_restauration', f'{cible.nom}_precedente'
    ident = sql.Identifier

    log.info('Restauration dans la base temporaire %s ...', temp)
    with _connexion(cible, 'postgres') as conn:
        conn.execute(sql.SQL('DROP DATABASE IF EXISTS {} WITH (FORCE)').format(ident(temp)))
        conn.execute(sql.SQL('CREATE DATABASE {} TEMPLATE template0 ENCODING {}').format(ident(temp), sql.Literal('UTF8')))
    try:
        executer(
            [outil('pg_restore', cfg['pg_bin']), *cible.args(), '-d', temp, '--no-owner', '--no-privileges',
             '--exit-on-error', str(dump)],
            cible.env(), 'pg_restore',
        )
        _droits(cible, temp, cfg['app_user'])
        _controler(cible, temp)
    except Exception:
        with _connexion(cible, 'postgres') as conn:
            conn.execute(sql.SQL('DROP DATABASE IF EXISTS {} WITH (FORCE)').format(ident(temp)))
        raise

    log.info('Bascule : %s -> %s, %s -> %s', cible.nom, precedente, temp, cible.nom)
    with _connexion(cible, 'postgres') as conn:
        existe = conn.execute('SELECT 1 FROM pg_database WHERE datname = %s', [cible.nom]).fetchone()
        conn.execute(sql.SQL('DROP DATABASE IF EXISTS {} WITH (FORCE)').format(ident(precedente)))
        if existe:
            conn.execute(sql.SQL('ALTER DATABASE {} WITH ALLOW_CONNECTIONS false').format(ident(cible.nom)))
            try:
                for tentative in range(5):
                    conn.execute(
                        'SELECT pg_terminate_backend(pid) FROM pg_stat_activity '
                        'WHERE datname = %s AND pid <> pg_backend_pid()', [cible.nom],
                    )
                    try:
                        conn.execute(sql.SQL('ALTER DATABASE {} RENAME TO {}').format(ident(cible.nom), ident(precedente)))
                        break
                    except Exception:
                        if tentative == 4:
                            raise
                        time.sleep(1)
            except Exception:
                conn.execute(sql.SQL('ALTER DATABASE {} WITH ALLOW_CONNECTIONS true').format(ident(cible.nom)))
                raise
        try:
            conn.execute('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = %s', [temp])
            conn.execute(sql.SQL('ALTER DATABASE {} RENAME TO {}').format(ident(temp), ident(cible.nom)))
        except Exception:
            if existe:
                conn.execute(sql.SQL('ALTER DATABASE {} RENAME TO {}').format(ident(precedente), ident(cible.nom)))
                conn.execute(sql.SQL('ALTER DATABASE {} WITH ALLOW_CONNECTIONS true').format(ident(cible.nom)))
            raise
        if existe:
            conn.execute(sql.SQL('ALTER DATABASE {} WITH ALLOW_CONNECTIONS true').format(ident(precedente)))
    log.info('Base locale %s remplacée par la copie de production (ancienne version : %s).', cible.nom, precedente)


def configurer_journal(dossier: Path) -> None:
    dossier.mkdir(parents=True, exist_ok=True)
    if log.handlers:
        return
    fmt = logging.Formatter('%(asctime)s %(levelname)s %(message)s', '%Y-%m-%d %H:%M:%S')
    handlers = [logging.FileHandler(dossier / 'journal.log', encoding='utf-8')]
    if sys.stdout is not None:  # None sous pythonw (tâche planifiée sans console)
        handlers.append(logging.StreamHandler(sys.stdout))
    for handler in handlers:
        handler.setFormatter(fmt)
        log.addHandler(handler)
    log.setLevel(logging.INFO)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--sans-restauration', action='store_true', help='ne modifie pas la base locale')
    parser.add_argument('--sans-medias', action='store_true', help='ne télécharge pas les médias')
    parser.add_argument('--dump-existant', type=Path, help='restaure ce fichier au lieu de faire un nouveau dump')
    args = parser.parse_args()

    cfg = charger_config()
    configurer_journal(cfg['dossier'])
    log.info('=== Sauvegarde production -> local ===')
    erreurs = []

    dump = None
    try:
        if args.dump_existant:
            dump = args.dump_existant.resolve()
            if not dump.is_file():
                raise SauvegardeError(f'Fichier introuvable : {dump}')
        else:
            dump = dump_prod(cfg)
    except Exception as exc:
        erreurs.append(f'base : {exc}')
        log.error('Échec du dump : %s', exc)

    if not args.sans_medias:
        try:
            miroir_medias(cfg)
        except Exception as exc:
            erreurs.append(f'médias : {exc}')
            log.error('Échec de la copie des médias : %s', exc)

    if dump and not args.sans_restauration:
        try:
            restaurer(cfg, dump)
        except Exception as exc:
            erreurs.append(f'restauration : {exc}')
            log.error('Échec de la restauration locale (base locale inchangée) : %s', exc)

    if erreurs:
        log.error('Sauvegarde terminée avec %s erreur(s).', len(erreurs))
        return 1
    log.info('Sauvegarde terminée avec succès.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
