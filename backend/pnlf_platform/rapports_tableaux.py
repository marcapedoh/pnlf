"""Mise en forme tabulaire des rapports statistiques pour les exports CSV / XLSX / PDF."""

from __future__ import annotations

from django.utils import timezone

from pnlf_platform import statistiques
from pnlf_platform.rapports_export import Tableau, date_fr


def _nom_fichier(prefixe: str) -> str:
    return f'PFNL-{prefixe}-{timezone.localtime():%Y%m%d-%H%M}.pdf'


def _nombre(valeur) -> str:
    return f'{int(valeur or 0):,}'.replace(',', ' ')


def _heures(valeur) -> str:
    if valeur is None:
        return 'Non calculable'
    if valeur < 1:
        return f'{max(1, round(valeur * 60))} min'
    if valeur < 48:
        return f'{valeur:.1f} h'.replace('.', ',')
    return f'{valeur / 24:.1f} jours'.replace('.', ',')


def tableau_connexions(request) -> Tableau:
    from pnlf_platform.views_rapports import param_succes, recherche

    periode = statistiques.lire_periode(request.query_params)
    q = recherche(request)
    succes = param_succes(request)
    stats = statistiques.statistiques_connexions(periode, q)
    _total, lignes = statistiques.liste_connexions(periode, q, succes, limit=5000, offset=0)
    totaux = stats['totaux']
    return Tableau(
        titre='Statistiques de connexion à la plateforme',
        nom_fichier=_nom_fichier('connexions'),
        colonnes=['Date et heure', 'Utilisateur', 'Rôle', 'Résultat', 'Appareil', 'Système', 'Navigateur', 'Adresse IP'],
        lignes=[
            [
                date_fr(l['date']), l['utilisateur'], l['role_libelle'],
                'Réussie' if l['succes'] else f"Échec : {l['motif_echec'] or 'motif inconnu'}",
                l['appareil_libelle'], l['systeme'] or 'Non identifié', l['navigateur'] or 'Non identifié',
                l['ip_adresse'] or 'Non renseignée',
            ]
            for l in lignes
        ],
        periode=periode.libelle(),
        filtres=[
            ('Recherche', q or ''),
            ('Résultat', '' if succes is None else ('Connexions réussies' if succes else 'Tentatives échouées')),
        ],
        indicateurs=[
            ('Connexions réussies', _nombre(totaux['connexions'])),
            ('Utilisateurs uniques', _nombre(totaux['utilisateurs_uniques'])),
            ('Appareils distincts', _nombre(totaux['appareils_distincts'])),
            ('Tentatives échouées', _nombre(totaux['echecs'])),
        ] + [(f"Sur {r['libelle'].lower()}", _nombre(r['connexions'])) for r in stats['par_appareil'][:2]],
        poids=[26, 44, 26, 40, 20, 22, 22, 22],
        colonnes_centrees=(0, 4, 7),
    )


def tableau_dernieres_connexions(request) -> Tableau:
    from pnlf_platform.views_rapports import param_succes, recherche

    periode = statistiques.lire_periode(request.query_params)
    q = recherche(request)
    succes = param_succes(request)
    total, lignes = statistiques.liste_connexions(periode, q, succes, limit=5000, offset=0)
    reussies = sum(1 for l in lignes if l['succes'])
    return Tableau(
        titre='Dernières connexions à la plateforme',
        nom_fichier=_nom_fichier('dernieres-connexions'),
        colonnes=['Date et heure', 'Utilisateur', 'E-mail saisi', 'Rôle', 'Résultat', 'Appareil', 'Adresse IP'],
        lignes=[
            [
                date_fr(l['date']), l['utilisateur'], l['email'] or '', l['role_libelle'],
                'Réussie' if l['succes'] else f"Échec : {l['motif_echec'] or 'motif inconnu'}",
                ' · '.join(x for x in (l['appareil_libelle'], l['systeme'], l['navigateur']) if x),
                l['ip_adresse'] or 'Non renseignée',
            ]
            for l in lignes
        ],
        periode=periode.libelle(),
        filtres=[
            ('Recherche', q or ''),
            ('Résultat', '' if succes is None else ('Connexions réussies' if succes else 'Tentatives échouées')),
        ],
        indicateurs=[
            ('Connexions listées', _nombre(total)),
            ('Réussies', _nombre(reussies)),
            ('Échouées', _nombre(len(lignes) - reussies)),
        ],
        poids=[26, 38, 44, 24, 36, 40, 30],
        colonnes_centrees=(0, 6),
    )


def tableau_en_ligne(request) -> Tableau:
    donnees = statistiques.presence_en_ligne()
    return Tableau(
        titre='Utilisateurs en ligne',
        nom_fichier=_nom_fichier('en-ligne'),
        colonnes=['Utilisateur', 'Rôle', 'Appareil', 'Système', 'Navigateur', 'Connecté depuis', 'Dernière activité', 'Adresse IP'],
        lignes=[
            [
                l['utilisateur'], l['role_libelle'], l['appareil_libelle'], l['systeme'] or 'Non identifié',
                l['navigateur'] or 'Non identifié', date_fr(l['connecte_depuis']), date_fr(l['derniere_activite']),
                l['ip_adresse'] or 'Non renseignée',
            ]
            for l in donnees['liste']
        ],
        periode=f'Instantané du {date_fr(donnees["genere_at"])} (activité des 2 dernières minutes)',
        indicateurs=[
            ('Utilisateurs en ligne', _nombre(donnees['utilisateurs'])),
            ('Appareils connectés', _nombre(donnees['appareils'])),
        ] + [(r['libelle'], _nombre(r['nombre'])) for r in donnees['par_appareil'][:3]],
        poids=[44, 26, 20, 22, 22, 26, 26, 22],
        colonnes_centrees=(2, 5, 6, 7),
    )


def tableau_inscriptions(request) -> Tableau:
    from pnlf_platform.views_rapports import filtres_inscriptions

    periode = statistiques.lire_periode(request.query_params)
    filtres = filtres_inscriptions(request)
    demandes = statistiques.demandes_inscription(periode, **filtres)
    stats = statistiques.statistiques_inscriptions(periode, demandes)
    totaux = stats['totaux']
    return Tableau(
        titre='Demandes d’inscription',
        nom_fichier=_nom_fichier('inscriptions'),
        colonnes=['Reçue le', 'Type', 'Demandeur', 'E-mail', 'Statut', 'Décision le', 'Par', 'Délai', 'Motif du rejet'],
        lignes=[
            [
                date_fr(d['date']), d['type_libelle'], d['demandeur'], d['email'] or '', d['statut_libelle'],
                date_fr(d['decide_at']) if d['decide_at'] else '', d['decideur'] or '',
                _heures(d['delai_heures']) if d['delai_heures'] is not None else '', d['motif'] or '',
            ]
            for d in demandes
        ],
        periode=periode.libelle(),
        filtres=[
            ('Recherche', filtres['q'] or ''),
            ('Type', statistiques.TYPES_DEMANDE.get(filtres['type_demande'] or '', '')),
            ('Statut', statistiques.STATUTS_DEMANDE.get(filtres['statut'] or '', '')),
        ],
        indicateurs=[
            ('Reçues', _nombre(totaux['recues'])),
            ('En attente', _nombre(totaux['en_attente'])),
            ('Validées', _nombre(totaux['validees'])),
            ('Rejetées', _nombre(totaux['rejetees'])),
            ('Délai moyen de traitement', _heures(totaux['delai_moyen_heures'])),
        ],
        poids=[24, 20, 40, 44, 18, 24, 32, 16, 54],
        colonnes_centrees=(0, 4, 5, 7),
    )


def tableau_filiere(request) -> Tableau:
    from pnlf_platform.views_rapports import filiere, recherche

    donnees = filiere(request)
    totaux = donnees['totaux']
    return Tableau(
        titre='Filière PFNL : lots collectés par produit',
        nom_fichier=_nom_fichier('filiere'),
        colonnes=['Produit', 'Unité', 'Lots', 'Brouillons', 'Validés', 'Commercialisés', 'Quantité totale'],
        lignes=[
            [
                p['produit'], p['unite'] or '', p['lots'], p['brouillon'], p['valide'], p['commercialise'],
                f"{p['quantite']:,.2f}".replace(',', ' ').replace('.', ','),
            ]
            for p in donnees['par_produit']
        ],
        periode=statistiques.lire_periode(request.query_params).libelle(),
        filtres=[('Recherche', recherche(request) or '')],
        indicateurs=[
            ('Lots collectés', _nombre(totaux['lots'])),
            ('Brouillons', _nombre(totaux['lots_brouillon'])),
            ('Validés', _nombre(totaux['lots_valide'])),
            ('Commercialisés', _nombre(totaux['lots_commercialise'])),
            ('Producteurs actifs', _nombre(totaux['producteurs_actifs'])),
            ('Certifications valides', _nombre(totaux['certifications_valides'])),
        ],
        poids=[60, 18, 16, 20, 20, 24, 30],
        colonnes_centrees=(1, 2, 3, 4, 5),
    )


def tableau_visites(request) -> Tableau:
    from pnlf_platform.views_rapports import recherche

    periode = statistiques.lire_periode(request.query_params)
    q = recherche(request)
    donnees = statistiques.statistiques_visites(periode, q)
    return Tableau(
        titre='Fréquentation des pages publiques',
        nom_fichier=_nom_fichier('visites'),
        colonnes=['Page', 'Adresse', 'Visites'],
        lignes=[[p['libelle'], p['page'], p['visites']] for p in donnees['par_page']],
        periode=periode.libelle(),
        filtres=[('Recherche', q or '')],
        indicateurs=[('Visites', _nombre(donnees['total']))]
        + [(a['libelle'], _nombre(a['visites'])) for a in donnees['par_appareil'][:3]],
        poids=[60, 50, 20],
        colonnes_centrees=(2,),
    )


CONSTRUCTEURS = {
    'connexions': tableau_connexions,
    'dernieres-connexions': tableau_dernieres_connexions,
    'en-ligne': tableau_en_ligne,
    'inscriptions': tableau_inscriptions,
    'filiere': tableau_filiere,
    'visites': tableau_visites,
}


def construire(rapport: str, request) -> Tableau:
    return CONSTRUCTEURS[rapport](request)
