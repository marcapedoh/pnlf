"""Exports CSV / XLSX / PDF des rapports statistiques (connexions, inscriptions, filière, visites)."""

from __future__ import annotations

import csv
import io
import re
from datetime import datetime

from django.http import HttpResponse
from django.utils import timezone
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, Spacer

from pnlf_platform.pdf_export import (
    _data_table,
    _header_table,
    _meta_table,
    _render_pdf,
    _styles,
    pdf_file_response,
)
from pnlf_platform.services import ligne_sure

LARGEUR_UTILE_MM = 272
LIGNES_PDF_MAX = 1500
MIME_XLSX = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'


def nom_imprimeur(utilisateur) -> str:
    nom = ' '.join(p for p in ((getattr(utilisateur, 'prenoms', '') or '').strip(),
                               (getattr(utilisateur, 'nom', '') or '').strip()) if p)
    return nom or getattr(utilisateur, 'email', '') or 'Utilisateur de la plateforme'


def mention_impression(utilisateur, maintenant: datetime | None = None) -> str:
    maintenant = timezone.localtime(maintenant or timezone.now())
    return f'Imprimé par {nom_imprimeur(utilisateur)} le {maintenant:%d/%m/%Y} à {maintenant:%H:%M}'


def date_fr(valeur, avec_heure: bool = True) -> str:
    if not valeur:
        return ''
    if isinstance(valeur, str):
        try:
            valeur = datetime.fromisoformat(valeur)
        except ValueError:
            return valeur
    if isinstance(valeur, datetime):
        valeur = timezone.localtime(valeur) if timezone.is_aware(valeur) else valeur
        return valeur.strftime('%d/%m/%Y %H:%M' if avec_heure else '%d/%m/%Y')
    return valeur.strftime('%d/%m/%Y')


class Tableau:
    """Description d'un export : en-têtes, lignes, indicateurs de synthèse et contexte."""

    def __init__(self, *, titre: str, nom_fichier: str, colonnes: list[str], lignes: list[list],
                 periode: str, filtres: list[tuple[str, str]] | None = None,
                 indicateurs: list[tuple[str, str]] | None = None, poids: list[float] | None = None,
                 colonnes_centrees: tuple[int, ...] = ()):
        self.titre = titre
        self.nom_fichier = nom_fichier
        self.colonnes = colonnes
        self.lignes = lignes
        self.periode = periode
        self.filtres = [(cle, valeur) for cle, valeur in (filtres or []) if valeur]
        self.indicateurs = indicateurs or []
        self.poids = poids or [1] * len(colonnes)
        self.colonnes_centrees = colonnes_centrees


def tableau_lots(queryset, *, periode: str, filtres: list[tuple[str, str]]) -> Tableau:
    from pnlf_platform.pdf_export import STATUT_LOT_FR

    lots = list(queryset.select_related('produit', 'producteur', 'producteur__province').order_by('-date_collecte')[:5000])
    lignes = [
        [
            i,
            lot.code_lot or '',
            lot.produit.nom if lot.produit_id else '',
            f'{lot.producteur.prenoms} {lot.producteur.nom}'.strip() if lot.producteur_id else '',
            getattr(lot.producteur.province, 'nom', '') if lot.producteur_id and lot.producteur.province_id else '',
            date_fr(lot.date_collecte, avec_heure=False),
            float(lot.quantite) if lot.quantite is not None else '',
            lot.unite or '',
            STATUT_LOT_FR.get(lot.statut, lot.statut or ''),
        ]
        for i, lot in enumerate(lots, start=1)
    ]
    par_statut: dict[str, int] = {}
    for lot in lots:
        libelle = STATUT_LOT_FR.get(lot.statut, lot.statut or 'Inconnu')
        par_statut[libelle] = par_statut.get(libelle, 0) + 1
    return Tableau(
        titre='Registre des lots de produits forestiers non ligneux',
        nom_fichier=f'PFNL-lots-{timezone.localtime():%Y%m%d-%H%M}.pdf',
        colonnes=['N°', 'Code lot', 'Produit', 'Producteur', 'Province', 'Collecte', 'Quantité', 'Unité', 'Statut'],
        lignes=lignes,
        periode=periode,
        filtres=filtres,
        indicateurs=[('Lots', str(len(lots)))] + [(cle, str(n)) for cle, n in sorted(par_statut.items())],
        poids=[8, 26, 34, 40, 26, 18, 16, 12, 22],
        colonnes_centrees=(0, 5, 6, 7),
    )


def tableau_journal(rows: list[dict], *, periode: str, filtres: list[tuple[str, str]], total: int) -> Tableau:
    from pnlf_platform.pdf_export import libelle_action, libelle_table

    return Tableau(
        titre='Journal d’activité de la plateforme',
        nom_fichier=f'PFNL-journal-{timezone.localtime():%Y%m%d-%H%M}.pdf',
        colonnes=['Date et heure', 'Action', 'Élément concerné', 'Identifiant', 'Utilisateur', 'Adresse IP'],
        lignes=[
            [
                date_fr(r.get('created_at')),
                libelle_action(r.get('action')),
                libelle_table(r.get('table_cible')),
                r.get('enregistrement_id') or '',
                r.get('utilisateur') or 'Système',
                r.get('ip_adresse') or '',
            ]
            for r in rows
        ],
        periode=periode,
        filtres=filtres,
        indicateurs=[('Événements', str(total))],
        poids=[30, 32, 34, 56, 50, 28],
        colonnes_centrees=(0, 5),
    )


def exporter(tableau: Tableau, fmt: str, utilisateur) -> HttpResponse:
    if fmt == 'xlsx':
        return _xlsx(tableau, utilisateur)
    if fmt == 'pdf':
        return _pdf(tableau, utilisateur)
    return _csv(tableau)


def _texte(valeur) -> str:
    if valeur is None:
        return ''
    if isinstance(valeur, bool):
        return 'Oui' if valeur else 'Non'
    return str(valeur)


def _csv(tableau: Tableau) -> HttpResponse:
    # Pas de Content-Disposition : le fichier est récupéré en Blob puis nommé côté client.
    response = HttpResponse(content_type='text/csv; charset=utf-8')
    response.write('\ufeff')
    w = csv.writer(response, delimiter=';')
    w.writerow(tableau.colonnes)
    for ligne in tableau.lignes:
        w.writerow(ligne_sure([_texte(v) for v in ligne]))
    response['Cache-Control'] = 'no-store'
    return response


def _xlsx(tableau: Tableau, utilisateur) -> HttpResponse:
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter

    wb = Workbook()
    ws = wb.active
    ws.title = re.sub(r'[\[\]:*?/\\]', ' ', tableau.titre)[:31].strip() or 'Rapport'
    ws.append([tableau.titre])
    ws['A1'].font = Font(bold=True, size=14, color='0D3D24')
    ws.append([f'Période : {tableau.periode}'])
    for cle, valeur in tableau.filtres:
        ws.append([f'{cle} : {valeur}'])
    ws.append([mention_impression(utilisateur)])
    if tableau.indicateurs:
        ws.append([])
        for cle, valeur in tableau.indicateurs:
            ws.append(ligne_sure([cle, valeur]))
    ws.append([])
    entete = ws.max_row + 1
    ws.append(tableau.colonnes)
    remplissage = PatternFill('solid', fgColor='146B3F')
    for cellule in ws[entete]:
        cellule.font = Font(bold=True, color='FFFFFF')
        cellule.fill = remplissage
        cellule.alignment = Alignment(vertical='center', wrap_text=True)
    for ligne in tableau.lignes:
        ws.append(ligne_sure([v if isinstance(v, (int, float)) and not isinstance(v, bool) else _texte(v) for v in ligne]))
        for cellule in ws[ws.max_row]:
            if isinstance(cellule.value, str):
                cellule.data_type = 's'
    ws.freeze_panes = ws.cell(row=entete + 1, column=1)
    for index, titre in enumerate(tableau.colonnes, start=1):
        largeur = max([len(str(titre))] + [len(_texte(l[index - 1])) for l in tableau.lignes[:500] if len(l) >= index])
        ws.column_dimensions[get_column_letter(index)].width = min(max(largeur + 2, 10), 60)
    buf = io.BytesIO()
    wb.save(buf)
    response = HttpResponse(buf.getvalue(), content_type=MIME_XLSX)
    response['Cache-Control'] = 'no-store'
    return response


def _pdf(tableau: Tableau, utilisateur) -> HttpResponse:
    styles = _styles()
    mention = mention_impression(utilisateur)
    lignes = tableau.lignes[:LIGNES_PDF_MAX]
    meta = [('Période', tableau.periode), ('Éléments', str(len(tableau.lignes))), ('Édition', mention)]
    story = [
        _header_table(styles, 'Plateforme de traçabilité des PFNL'),
        Spacer(1, 8),
        Paragraph(tableau.titre, styles['title']),
        _meta_table(styles, meta),
    ]
    if tableau.filtres:
        story += [Spacer(1, 4), _meta_table(styles, tableau.filtres[:5])]
    if tableau.indicateurs:
        for debut in range(0, len(tableau.indicateurs), 6):
            story += [Spacer(1, 4), _meta_table(styles, tableau.indicateurs[debut:debut + 6])]
    story.append(Spacer(1, 10))
    if not lignes:
        story.append(Paragraph('Aucune donnée sur cette période avec les filtres choisis.', styles['empty']))
    else:
        total = sum(tableau.poids) or 1
        largeurs = [LARGEUR_UTILE_MM * mm * p / total for p in tableau.poids]
        story.append(_data_table(
            tableau.colonnes, [[_texte(v) for v in ligne] for ligne in lignes], largeurs, styles,
            center_cols=tableau.colonnes_centrees,
        ))
        if len(tableau.lignes) > LIGNES_PDF_MAX:
            story += [Spacer(1, 6), Paragraph(
                f'Seules les {LIGNES_PDF_MAX} premières lignes figurent dans ce PDF : '
                'utilisez l’export Excel ou CSV pour obtenir la liste complète.', styles['meta'],
            )]
    pdf = _render_pdf(story, title=tableau.titre, footer=f'{mention} · ENEF · Document à usage institutionnel')
    return pdf_file_response(pdf, tableau.nom_fichier)
