"""Statistiques intégrées des rapports : connexions, présence, visites publiques, inscriptions et filière.

Aucune donnée n'est confiée à un service tiers : tout est calculé à partir des tables `public.connexions`,
`public.presences`, `public.visites_publiques` (évolution 16) et du journal d'audit.
"""

from __future__ import annotations

import re
from datetime import date, datetime, time, timedelta

from django.db import connection
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework.exceptions import ValidationError

from accounts.appareils import LIBELLES_APPAREIL, masquer_ip
from accounts.connexions import MOTIFS_ECHEC, seuil_en_ligne
from accounts.models import Utilisateur

PERIODE_PAR_DEFAUT_JOURS = 30
PERIODE_MAX_JOURS = 1096
LIBELLES_ROLE = dict(Utilisateur.Role.choices)
GRANULARITES = {'jour': 'day', 'semaine': 'week', 'mois': 'month'}

STATUTS_LOT = ('BROUILLON', 'VALIDE', 'COMMERCIALISE')
LIBELLES_STATUT_LOT = {'BROUILLON': 'Brouillon', 'VALIDE': 'Validé', 'COMMERCIALISE': 'Commercialisé'}

TYPES_DEMANDE = {
    'PRODUCTEUR': 'Producteur',
    'COLLECTEUR': 'Collecteur',
    'COOPERATIVE': 'Coopérative',
    'ACHETEUR': 'Acheteur',
}
STATUTS_DEMANDE = {'EN_ATTENTE': 'En attente', 'VALIDEE': 'Validée', 'REJETEE': 'Rejetée'}


class Periode:
    """Période inclusive [debut, fin] exprimée en jours civils (fuseau de la plateforme)."""

    def __init__(self, debut: date, fin: date, granularite: str):
        self.debut = debut
        self.fin = fin
        self.granularite = granularite

    @property
    def debut_dt(self) -> datetime:
        return timezone.make_aware(datetime.combine(self.debut, time.min))

    @property
    def fin_dt(self) -> datetime:
        return timezone.make_aware(datetime.combine(self.fin + timedelta(days=1), time.min))

    def libelle(self) -> str:
        return f'du {self.debut:%d/%m/%Y} au {self.fin:%d/%m/%Y}'

    def as_dict(self) -> dict:
        return {
            'date_debut': self.debut.isoformat(),
            'date_fin': self.fin.isoformat(),
            'granularite': self.granularite,
            'libelle': self.libelle(),
        }

    def etapes(self) -> list[date]:
        """Points de la série temporelle, pour combler les jours sans activité."""
        points = []
        courant = _tronquer(self.debut, self.granularite)
        while courant <= self.fin:
            points.append(courant)
            if self.granularite == 'jour':
                courant += timedelta(days=1)
            elif self.granularite == 'semaine':
                courant += timedelta(days=7)
            else:
                courant = date(courant.year + (courant.month // 12), courant.month % 12 + 1, 1)
        return points


def _tronquer(jour: date, granularite: str) -> date:
    if granularite == 'semaine':
        return jour - timedelta(days=jour.weekday())
    if granularite == 'mois':
        return jour.replace(day=1)
    return jour


def lire_periode(params) -> Periode:
    """Lit date_debut / date_fin / granularite ; par défaut les 30 derniers jours."""
    aujourd_hui = timezone.localdate()

    def _date(nom):
        texte = (params.get(nom) or '').strip()
        if not texte:
            return None
        try:
            valeur = parse_date(texte)
        except ValueError:
            valeur = None
        if valeur is None:
            raise ValidationError({nom: 'Date invalide : utilisez le format AAAA-MM-JJ.'})
        return valeur

    fin = _date('date_fin') or aujourd_hui
    debut = _date('date_debut') or (fin - timedelta(days=PERIODE_PAR_DEFAUT_JOURS - 1))
    if debut > fin:
        raise ValidationError({'date_fin': 'La date de fin doit être postérieure ou égale à la date de début.'})
    if (fin - debut).days >= PERIODE_MAX_JOURS:
        raise ValidationError({'date_debut': 'La période ne peut pas dépasser trois ans : réduisez l’intervalle.'})

    granularite = (params.get('granularite') or '').strip().lower()
    if granularite and granularite not in GRANULARITES:
        raise ValidationError({'granularite': 'Granularité inconnue (jour, semaine ou mois).'})
    if not granularite:
        duree = (fin - debut).days + 1
        granularite = 'jour' if duree <= 92 else ('semaine' if duree <= 366 else 'mois')
    return Periode(debut, fin, granularite)


def _fuseau() -> str:
    return timezone.get_current_timezone_name()


def _lignes(sql: str, params) -> list[dict]:
    with connection.cursor() as cur:
        cur.execute(sql, params)
        colonnes = [c[0] for c in cur.description]
        return [dict(zip(colonnes, ligne)) for ligne in cur.fetchall()]


def _serie(periode: Periode, lignes: list[dict], champs: tuple[str, ...]) -> list[dict]:
    index = {}
    for ligne in lignes:
        cle = ligne['periode']
        cle = cle.date() if isinstance(cle, datetime) else cle
        index[cle] = ligne
    return [
        {'periode': point.isoformat(), **{champ: int((index.get(point) or {}).get(champ) or 0) for champ in champs}}
        for point in periode.etapes()
    ]


def _nom_complet(prenoms, nom) -> str:
    return ' '.join(p for p in ((prenoms or '').strip(), (nom or '').strip()) if p)


def _iso(valeur):
    return valeur.isoformat() if valeur else None


# --------------------------------------------------------------------------- connexions

def _filtre_connexions(periode: Periode, q: str | None, succes: bool | None = None):
    clauses = ['c.created_at >= %s', 'c.created_at < %s']
    params: list = [periode.debut_dt, periode.fin_dt]
    if q:
        motif = f'%{q}%'
        clauses.append(
            "(c.email_saisi ILIKE %s OR u.nom ILIKE %s OR u.prenoms ILIKE %s OR c.navigateur ILIKE %s "
            "OR c.systeme ILIKE %s OR c.role ILIKE %s OR CONCAT_WS(' ', u.prenoms, u.nom) ILIKE %s)"
        )
        params += [motif] * 7
    if succes is not None:
        clauses.append('c.succes = %s')
        params.append(succes)
    return ' AND '.join(clauses), params


def statistiques_connexions(periode: Periode, q: str | None = None) -> dict:
    where, params = _filtre_connexions(periode, q)
    base = f'FROM connexions c LEFT JOIN utilisateurs u ON u.id = c.utilisateur_id WHERE {where}'

    totaux = _lignes(
        f"""
        SELECT COUNT(*) FILTER (WHERE c.succes) AS connexions,
               COUNT(*) FILTER (WHERE NOT c.succes) AS echecs,
               COUNT(DISTINCT c.utilisateur_id) FILTER (WHERE c.succes) AS utilisateurs_uniques,
               COUNT(DISTINCT c.empreinte_appareil) FILTER (WHERE c.succes) AS appareils_distincts
        {base}
        """,
        params,
    )[0]
    serie = _lignes(
        f"""
        SELECT DATE_TRUNC(%s, c.created_at AT TIME ZONE %s)::date AS periode,
               COUNT(*) FILTER (WHERE c.succes) AS connexions,
               COUNT(*) FILTER (WHERE NOT c.succes) AS echecs,
               COUNT(DISTINCT c.utilisateur_id) FILTER (WHERE c.succes) AS utilisateurs
        {base}
        GROUP BY 1
        """,
        [GRANULARITES[periode.granularite], _fuseau(), *params],
    )

    def repartition(colonne: str, libelles: dict | None = None, defaut: str = 'Non identifié'):
        lignes = _lignes(
            f"""
            SELECT {colonne} AS cle, COUNT(*) AS connexions, COUNT(DISTINCT c.empreinte_appareil) AS appareils
            {base} AND c.succes
            GROUP BY 1 ORDER BY 2 DESC
            """,
            params,
        )
        return [
            {
                'cle': ligne['cle'] or 'INCONNU',
                'libelle': (libelles or {}).get(ligne['cle'], ligne['cle']) if ligne['cle'] else defaut,
                'connexions': ligne['connexions'],
                'appareils': ligne['appareils'],
            }
            for ligne in lignes
        ]

    echecs = _lignes(
        f"""
        SELECT COALESCE(c.motif_echec, 'IDENTIFIANTS') AS cle, COUNT(*) AS nombre
        {base} AND NOT c.succes
        GROUP BY 1 ORDER BY 2 DESC
        """,
        params,
    )
    return {
        'periode': periode.as_dict(),
        'totaux': {cle: int(valeur or 0) for cle, valeur in totaux.items()},
        'serie': _serie(periode, serie, ('connexions', 'echecs', 'utilisateurs')),
        'par_appareil': repartition('c.appareil', LIBELLES_APPAREIL, 'Inconnu'),
        'par_systeme': repartition('c.systeme'),
        'par_navigateur': repartition('c.navigateur'),
        'par_role': repartition('c.role', LIBELLES_ROLE, 'Rôle inconnu'),
        'echecs_par_motif': [
            {'cle': e['cle'], 'libelle': MOTIFS_ECHEC.get(e['cle'], e['cle']), 'nombre': e['nombre']}
            for e in echecs
        ],
    }


def liste_connexions(periode: Periode, q: str | None = None, succes: bool | None = None,
                     limit: int = 25, offset: int = 0) -> tuple[int, list[dict]]:
    where, params = _filtre_connexions(periode, q, succes)
    base = f'FROM connexions c LEFT JOIN utilisateurs u ON u.id = c.utilisateur_id WHERE {where}'
    with connection.cursor() as cur:
        cur.execute(f'SELECT COUNT(*) {base}', params)
        total = cur.fetchone()[0]
    lignes = _lignes(
        f"""
        SELECT c.id, c.created_at, c.utilisateur_id, c.email_saisi, c.role, c.succes, c.motif_echec,
               HOST(c.ip_adresse) AS ip, c.appareil, c.systeme, c.navigateur, u.nom, u.prenoms
        {base}
        ORDER BY c.created_at DESC
        LIMIT %s OFFSET %s
        """,
        [*params, limit, offset],
    )
    return total, [
        {
            'id': ligne['id'],
            'date': _iso(ligne['created_at']),
            'utilisateur_id': str(ligne['utilisateur_id']) if ligne['utilisateur_id'] else None,
            'utilisateur': _nom_complet(ligne['prenoms'], ligne['nom']) or ligne['email_saisi'] or 'Compte inconnu',
            'email': ligne['email_saisi'],
            'role': ligne['role'],
            'role_libelle': LIBELLES_ROLE.get(ligne['role'], 'Non identifié') if ligne['role'] else 'Non identifié',
            'succes': ligne['succes'],
            'motif_echec': MOTIFS_ECHEC.get(ligne['motif_echec']) if not ligne['succes'] else None,
            'appareil': ligne['appareil'],
            'appareil_libelle': LIBELLES_APPAREIL.get(ligne['appareil'], 'Inconnu'),
            'systeme': ligne['systeme'],
            'navigateur': ligne['navigateur'],
            'ip_masquee': masquer_ip(ligne['ip']),
        }
        for ligne in lignes
    ]


def presence_en_ligne() -> dict:
    """Utilisateurs actifs dans les 2 dernières minutes (signal envoyé par l'onglet visible)."""
    lignes = _lignes(
        """
        SELECT p.utilisateur_id, p.appareil, p.systeme, p.navigateur, HOST(p.ip_adresse) AS ip,
               p.debut_at, p.derniere_activite, u.nom, u.prenoms, u.role
        FROM presences p
        JOIN utilisateurs u ON u.id = p.utilisateur_id AND u.deleted_at IS NULL
        WHERE p.derniere_activite >= %s
        ORDER BY p.derniere_activite DESC
        """,
        [seuil_en_ligne()],
    )
    par_appareil: dict[str, int] = {}
    par_role: dict[str, set] = {}
    for ligne in lignes:
        par_appareil[ligne['appareil']] = par_appareil.get(ligne['appareil'], 0) + 1
        par_role.setdefault(ligne['role'], set()).add(ligne['utilisateur_id'])
    return {
        'genere_at': timezone.now().isoformat(),
        'fenetre_minutes': 2,
        'utilisateurs': len({ligne['utilisateur_id'] for ligne in lignes}),
        'appareils': len(lignes),
        'par_appareil': [
            {'cle': cle, 'libelle': LIBELLES_APPAREIL.get(cle, cle), 'nombre': nombre}
            for cle, nombre in sorted(par_appareil.items(), key=lambda kv: -kv[1])
        ],
        'par_role': [
            {'cle': cle, 'libelle': LIBELLES_ROLE.get(cle, cle), 'nombre': len(ids)}
            for cle, ids in sorted(par_role.items(), key=lambda kv: -len(kv[1]))
        ],
        'liste': [
            {
                'utilisateur_id': str(ligne['utilisateur_id']),
                'utilisateur': _nom_complet(ligne['prenoms'], ligne['nom']),
                'role': ligne['role'],
                'role_libelle': LIBELLES_ROLE.get(ligne['role'], ligne['role']),
                'appareil': ligne['appareil'],
                'appareil_libelle': LIBELLES_APPAREIL.get(ligne['appareil'], 'Inconnu'),
                'systeme': ligne['systeme'],
                'navigateur': ligne['navigateur'],
                'ip_masquee': masquer_ip(ligne['ip']),
                'connecte_depuis': _iso(ligne['debut_at']),
                'derniere_activite': _iso(ligne['derniere_activite']),
            }
            for ligne in lignes[:200]
        ],
    }


# --------------------------------------------------------------------------- visites publiques

def statistiques_visites(periode: Periode, q: str | None = None) -> dict:
    clauses = 'jour >= %s AND jour <= %s'
    params: list = [periode.debut, periode.fin]
    if q:
        clauses += ' AND page ILIKE %s'
        params.append(f'%{q}%')
    total = _lignes(f'SELECT COALESCE(SUM(visites), 0) AS total FROM visites_publiques WHERE {clauses}', params)[0]
    serie = _lignes(
        f"""
        SELECT DATE_TRUNC(%s, jour)::date AS periode, SUM(visites) AS visites
        FROM visites_publiques WHERE {clauses} GROUP BY 1
        """,
        [GRANULARITES[periode.granularite], *params],
    )
    pages = _lignes(
        f"""
        SELECT page, SUM(visites) AS visites FROM visites_publiques WHERE {clauses}
        GROUP BY 1 ORDER BY 2 DESC, 1 LIMIT 20
        """,
        params,
    )
    appareils = _lignes(
        f"""
        SELECT appareil, SUM(visites) AS visites FROM visites_publiques WHERE {clauses}
        GROUP BY 1 ORDER BY 2 DESC
        """,
        params,
    )
    return {
        'periode': periode.as_dict(),
        'total': int(total['total']),
        'serie': _serie(periode, serie, ('visites',)),
        'par_page': [{'page': p['page'], 'libelle': libelle_page(p['page']), 'visites': int(p['visites'])} for p in pages],
        'par_appareil': [
            {'cle': a['appareil'], 'libelle': LIBELLES_APPAREIL.get(a['appareil'], 'Inconnu'), 'visites': int(a['visites'])}
            for a in appareils
        ],
    }


PAGES_PUBLIQUES = {
    '/': 'Accueil',
    '/annuaire': 'Annuaire des acteurs',
    '/annuaire/:id': 'Fiche publique d’un acteur',
    '/annuaire/lot/:id': 'Fiche publique d’un lot',
    '/offres-demandes': 'Offres et demandes',
    '/offres-demandes/:id': 'Détail d’une annonce',
    '/verifier': 'Vérification d’un lot',
    '/verifier/:id': 'Résultat de vérification',
    '/inscription': 'Demande d’inscription',
    '/connexion': 'Connexion',
    '/faq': 'Questions fréquentes',
    '/politique-confidentialite': 'Politique de confidentialité',
    '/politique-cookies': 'Politique de cookies',
    '/conditions-utilisation': 'Conditions d’utilisation',
    '/autre': 'Autres pages publiques',
}

_SEGMENT_IDENTIFIANT = re.compile(
    r'^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|\d+|[A-Z0-9]{2,}[-_][A-Z0-9-_]+|PNLF-.+)$',
    re.I,
)


def normaliser_page(chemin: str | None) -> str:
    """Ramène une URL publique à son gabarit (identifiants remplacés par :id), sans paramètres."""
    texte = (chemin or '/').split('?', 1)[0].split('#', 1)[0].strip()[:300]
    segments = [s for s in texte.split('/') if s]
    gabarit = '/' + '/'.join(':id' if _SEGMENT_IDENTIFIANT.match(s) else s.lower() for s in segments)
    if gabarit not in PAGES_PUBLIQUES and len(segments) >= 1:
        parent = '/' + '/'.join(s.lower() for s in segments[:-1])
        candidat = f'{parent.rstrip("/")}/:id'
        gabarit = candidat if candidat in PAGES_PUBLIQUES else gabarit
    return gabarit if gabarit in PAGES_PUBLIQUES else '/autre'


def enregistrer_visite(chemin: str | None, appareil: str) -> str:
    page = normaliser_page(chemin)
    with connection.cursor() as cur:
        cur.execute(
            """
            INSERT INTO visites_publiques (jour, page, appareil, visites) VALUES (%s, %s, %s, 1)
            ON CONFLICT (jour, page, appareil) DO UPDATE SET visites = visites_publiques.visites + 1
            """,
            [timezone.localdate(), page, appareil],
        )
    return page


def libelle_page(page: str) -> str:
    return PAGES_PUBLIQUES.get(page, page)


# --------------------------------------------------------------------------- inscriptions

_SQL_INSCRIPTIONS = """
WITH demandes AS (
    SELECT i.created_at, i.table_cible, i.enregistrement_id,
           COALESCE(i.nouvelles_valeurs->>'type_demande', CASE i.table_cible
               WHEN 'cooperatives' THEN 'COOPERATIVE' WHEN 'utilisateurs' THEN 'ACHETEUR' ELSE 'PRODUCTEUR' END
           ) AS type_demande,
           i.nouvelles_valeurs->>'email' AS email
    FROM audit_logs i
    WHERE i.action = 'INSCRIPTION_PUBLIQUE' AND i.created_at >= %s AND i.created_at < %s
)
SELECT d.created_at, d.table_cible, d.enregistrement_id, d.type_demande, d.email,
       dec.action AS decision, dec.created_at AS decide_at, dec.motif, dec.decideur,
       COALESCE(
           NULLIF(CONCAT_WS(' ', p.prenoms, p.nom), ''), c.nom, NULLIF(CONCAT_WS(' ', ua.prenoms, ua.nom), '')
       ) AS demandeur,
       p.statut AS statut_producteur, p.notes AS notes_producteur, p.valide_at AS valide_at_producteur,
       c.statut AS statut_cooperative, ua.statut AS statut_utilisateur
FROM demandes d
LEFT JOIN LATERAL (
    SELECT a.action, a.created_at, a.nouvelles_valeurs->>'motif' AS motif,
           NULLIF(CONCAT_WS(' ', u.prenoms, u.nom), '') AS decideur
    FROM audit_logs a
    LEFT JOIN utilisateurs u ON u.id = a.utilisateur_id
    WHERE a.table_cible = d.table_cible AND a.enregistrement_id = d.enregistrement_id
      AND a.action IN ('VALIDATE', 'ACTIVATE', 'REJECT') AND a.created_at >= d.created_at
    ORDER BY a.created_at
    LIMIT 1
) dec ON TRUE
LEFT JOIN producteurs p ON d.table_cible = 'producteurs' AND p.id = d.enregistrement_id
LEFT JOIN cooperatives c ON d.table_cible = 'cooperatives' AND c.id = d.enregistrement_id
LEFT JOIN utilisateurs ua ON d.table_cible = 'utilisateurs' AND ua.id = d.enregistrement_id
ORDER BY d.created_at DESC
LIMIT 5000
"""


def _demande(ligne: dict) -> dict:
    decision = ligne['decision']
    decide_at = ligne['decide_at']
    if decision in ('VALIDATE', 'ACTIVATE'):
        statut = 'VALIDEE'
    elif decision == 'REJECT':
        statut = 'REJETEE'
    elif ligne['statut_producteur'] == 'ACTIF' or ligne['statut_cooperative'] == 'ACTIF' \
            or ligne['statut_utilisateur'] == 'ACTIF':
        statut = 'VALIDEE'
        decide_at = ligne['valide_at_producteur']
    elif ligne['statut_producteur'] == 'REJETE' or ligne['statut_cooperative'] == 'REJETE':
        statut = 'REJETEE'
        decide_at = ligne['valide_at_producteur']
    else:
        statut = 'EN_ATTENTE'
    motif = ligne['motif']
    if statut == 'REJETEE' and not motif and ligne['statut_producteur'] == 'REJETE':
        motif = ligne['notes_producteur']
    delai = None
    if statut != 'EN_ATTENTE' and decide_at and decide_at >= ligne['created_at']:
        delai = round((decide_at - ligne['created_at']).total_seconds() / 3600, 2)
    return {
        'date': _iso(ligne['created_at']),
        'type_demande': ligne['type_demande'],
        'type_libelle': TYPES_DEMANDE.get(ligne['type_demande'], ligne['type_demande']),
        'demandeur': ligne['demandeur'] or ligne['email'] or 'Demandeur supprimé',
        'email': ligne['email'],
        'statut': statut,
        'statut_libelle': STATUTS_DEMANDE[statut],
        'decide_at': _iso(decide_at),
        'decideur': ligne['decideur'],
        'delai_heures': delai,
        'motif': motif if statut == 'REJETEE' else None,
        'table_cible': ligne['table_cible'],
        'enregistrement_id': str(ligne['enregistrement_id']) if ligne['enregistrement_id'] else None,
    }


def demandes_inscription(periode: Periode, *, q: str | None = None, type_demande: str | None = None,
                         statut: str | None = None) -> list[dict]:
    if type_demande and type_demande not in TYPES_DEMANDE:
        raise ValidationError({'type_demande': 'Type de demande inconnu.'})
    if statut and statut not in STATUTS_DEMANDE:
        raise ValidationError({'statut': 'Statut de demande inconnu (EN_ATTENTE, VALIDEE ou REJETEE).'})
    demandes = [_demande(ligne) for ligne in _lignes(_SQL_INSCRIPTIONS, [periode.debut_dt, periode.fin_dt])]
    if q:
        recherche = q.lower()
        demandes = [
            d for d in demandes
            if recherche in (d['demandeur'] or '').lower() or recherche in (d['email'] or '').lower()
            or recherche in (d['motif'] or '').lower() or recherche in d['type_libelle'].lower()
        ]
    if type_demande:
        demandes = [d for d in demandes if d['type_demande'] == type_demande]
    if statut:
        demandes = [d for d in demandes if d['statut'] == statut]
    return demandes


def _moyenne(valeurs: list[float]) -> float | None:
    return round(sum(valeurs) / len(valeurs), 2) if valeurs else None


def statistiques_inscriptions(periode: Periode, demandes: list[dict]) -> dict:
    def compter(sous_ensemble):
        delais = [d['delai_heures'] for d in sous_ensemble if d['delai_heures'] is not None]
        return {
            'recues': len(sous_ensemble),
            'en_attente': sum(1 for d in sous_ensemble if d['statut'] == 'EN_ATTENTE'),
            'validees': sum(1 for d in sous_ensemble if d['statut'] == 'VALIDEE'),
            'rejetees': sum(1 for d in sous_ensemble if d['statut'] == 'REJETEE'),
            'delai_moyen_heures': _moyenne(delais),
        }

    par_periode: dict[date, dict] = {}
    for d in demandes:
        jour = timezone.localtime(datetime.fromisoformat(d['date'])).date()
        cle = _tronquer(jour, periode.granularite)
        bloc = par_periode.setdefault(cle, {'periode': cle, 'recues': 0, 'validees': 0, 'rejetees': 0, 'en_attente': 0})
        bloc['recues'] += 1
        bloc[{'VALIDEE': 'validees', 'REJETEE': 'rejetees', 'EN_ATTENTE': 'en_attente'}[d['statut']]] += 1

    motifs: dict[str, int] = {}
    for d in demandes:
        if d['statut'] == 'REJETEE':
            libelle = (d['motif'] or 'Motif non renseigné').strip()[:120]
            motifs[libelle] = motifs.get(libelle, 0) + 1

    return {
        'periode': periode.as_dict(),
        'totaux': compter(demandes),
        'par_type': [
            {'cle': cle, 'libelle': libelle, **compter([d for d in demandes if d['type_demande'] == cle])}
            for cle, libelle in TYPES_DEMANDE.items()
        ],
        'serie': _serie(periode, list(par_periode.values()), ('recues', 'validees', 'rejetees', 'en_attente')),
        'motifs_rejet': [
            {'motif': motif, 'nombre': nombre} for motif, nombre in sorted(motifs.items(), key=lambda kv: -kv[1])[:10]
        ],
    }


# --------------------------------------------------------------------------- filière / lots

def statistiques_filiere(periode: Periode, *, q: str | None = None, province=None, produit=None,
                         lots_qs=None) -> dict:
    """Lots collectés sur la période (3 statuts du cycle), par produit, province et période."""
    from django.db.models import Count, Q, Sum
    from django.db.models.functions import TruncDay, TruncMonth, TruncWeek

    from pnlf_platform.models import OffreDemande
    from pnlf_platform.offre_statut import ids_par_statut
    from traceability.models import Certification, Cooperative, Lot, Producteur

    lots = (lots_qs if lots_qs is not None else Lot.objects.all()).filter(
        deleted_at__isnull=True, date_collecte__gte=periode.debut, date_collecte__lte=periode.fin,
    )
    if province:
        lots = lots.filter(producteur__province_id=province)
    if produit:
        lots = lots.filter(produit_id=produit)
    if q:
        lots = lots.filter(
            Q(code_lot__icontains=q) | Q(produit__nom__icontains=q) | Q(producteur__nom__icontains=q)
            | Q(producteur__prenoms__icontains=q) | Q(producteur__province__nom__icontains=q)
        )

    par_statut = dict(lots.values_list('statut').annotate(n=Count('id')).values_list('statut', 'n'))
    tronque = {'jour': TruncDay, 'semaine': TruncWeek, 'mois': TruncMonth}[periode.granularite]
    serie_brute: dict[date, dict] = {}
    for ligne in lots.annotate(p=tronque('date_collecte')).values('p', 'statut').annotate(n=Count('id')):
        cle = ligne['p'].date() if isinstance(ligne['p'], datetime) else ligne['p']
        bloc = serie_brute.setdefault(cle, {'periode': cle, **{s.lower(): 0 for s in STATUTS_LOT}})
        if ligne['statut'] in STATUTS_LOT:
            bloc[ligne['statut'].lower()] += ligne['n']

    par_produit = [
        {
            'produit': ligne['produit__nom'] or 'Produit inconnu',
            'unite': ligne['unite'],
            'lots': ligne['n'],
            'quantite': float(ligne['quantite'] or 0),
            **{s.lower(): ligne[s.lower()] for s in STATUTS_LOT},
        }
        for ligne in lots.values('produit__nom', 'unite').annotate(
            n=Count('id'), quantite=Sum('quantite'),
            **{s.lower(): Count('id', filter=Q(statut=s)) for s in STATUTS_LOT},
        ).order_by('-n', 'produit__nom')[:50]
    ]
    par_province = [
        {'province': ligne['producteur__province__nom'] or 'Province non renseignée', 'lots': ligne['n']}
        for ligne in lots.values('producteur__province__nom').annotate(n=Count('id')).order_by('-n')
    ]

    producteurs = Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF')
    if province:
        producteurs = producteurs.filter(province_id=province)
    aujourd_hui = timezone.localdate()
    return {
        'periode': periode.as_dict(),
        'totaux': {
            'lots': sum(par_statut.values()),
            **{f'lots_{s.lower()}': par_statut.get(s, 0) for s in STATUTS_LOT},
            'producteurs_actifs': producteurs.count(),
            'cooperatives_actives': Cooperative.objects.filter(statut='ACTIF').count(),
            'certifications_valides': Certification.objects.filter(statut='OBTENUE').filter(
                Q(date_expiration__isnull=True) | Q(date_expiration__gte=aujourd_hui)
            ).count(),
            'annonces_publiees': OffreDemande.objects.filter(
                id__in=ids_par_statut('OUVERTE'), created_at__gte=periode.debut_dt, created_at__lt=periode.fin_dt,
            ).count(),
        },
        'par_statut': [
            {'cle': s, 'libelle': LIBELLES_STATUT_LOT[s], 'nombre': par_statut.get(s, 0)} for s in STATUTS_LOT
        ],
        'serie': _serie(periode, list(serie_brute.values()), tuple(s.lower() for s in STATUTS_LOT)),
        'par_produit': par_produit,
        'par_province': par_province,
    }
