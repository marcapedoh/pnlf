"""Génération de rapports PDF institutionnels PNLF-PFNL."""

from __future__ import annotations

import os
from datetime import datetime
from io import BytesIO
from pathlib import Path

from django.conf import settings
from django.http import HttpResponse
from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

GREEN = colors.HexColor('#146b3f')
GREEN_DARK = colors.HexColor('#0d3d24')
GOLD = colors.HexColor('#c9a227')
ROW_ALT = colors.HexColor('#f3f7f4')
BORDER = colors.HexColor('#d5ddd8')
TEXT = colors.HexColor('#1a1f1c')
MUTED = colors.HexColor('#5c6b63')

STATUT_LOT_FR = {
    'BROUILLON': 'Brouillon',
    'DECLARE': 'Déclaré',
    'VALIDE': 'Validé',
    'EN_TRANSIT': 'En transit',
    'TRANSFORME': 'Transformé',
    'COMMERCIALISE': 'Commercialisé',
    'ARCHIVE': 'Archivé',
    'ANNULE': 'Annulé',
}

ACTION_FR = {
    'CREATE': 'Création',
    'UPDATE': 'Modification',
    'DELETE': 'Suppression',
    'LOGIN': 'Connexion',
    'LOGOUT': 'Déconnexion',
    'EXPORT': 'Export',
    'IMPORT': 'Import',
    'PASSWORD_CHANGE': 'Changement de mot de passe',
    'VALIDATE': 'Validation',
    'REJECT': 'Rejet',
    'SYNC': 'Synchronisation',
}

TABLE_FR = {
    'lots': 'Lots',
    'utilisateurs': 'Utilisateurs',
    'audit_logs': 'Journal',
    'producteurs': 'Producteurs',
    'cooperatives': 'Coopératives',
    'certifications': 'Certifications',
    'offres': 'Offres',
    'zones_collecte': 'Zones de collecte',
    'mouvements': 'Mouvements',
    'notifications': 'Notifications',
}

_FONTS_READY = False
FONT = 'Helvetica'
FONT_BOLD = 'Helvetica-Bold'


def _register_fonts() -> None:
    """Enregistre une police TrueType avec accents français corrects, quel que soit l'OS.

    En développement (Windows) : Arial. En production (Docker/Linux, cf. backend/Dockerfile
    qui installe `fonts-dejavu-core`) : DejaVu Sans ou Liberation Sans. Si aucune police
    TrueType n'est trouvée, on reste sur Helvetica (base14 ReportLab, WinAnsiEncoding —
    supporte déjà la plupart des accents français, donc jamais de crash ni de blocage).
    """
    global _FONTS_READY, FONT, FONT_BOLD
    if _FONTS_READY:
        return
    windir = Path(os.environ.get('WINDIR', r'C:\Windows')) / 'Fonts'
    candidates = [
        (windir / 'arial.ttf', windir / 'arialbd.ttf'),
        (
            Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'),
            Path('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'),
        ),
        (
            Path('/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf'),
            Path('/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf'),
        ),
        (
            Path('/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf'),
            Path('/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf'),
        ),
    ]
    for regular, bold in candidates:
        if regular.is_file() and bold.is_file():
            try:
                pdfmetrics.registerFont(TTFont('PNLF', str(regular)))
                pdfmetrics.registerFont(TTFont('PNLF-Bold', str(bold)))
                FONT = 'PNLF'
                FONT_BOLD = 'PNLF-Bold'
                break
            except Exception:
                continue
    _FONTS_READY = True


def _logo_path() -> Path | None:
    candidates = [
        Path(settings.BASE_DIR).parent / 'frontend' / 'public' / 'assets' / 'brand' / 'logo-enef.jpg',
        Path(settings.BASE_DIR).parent / 'logo enef.jpg',
        Path(settings.BASE_DIR) / 'static' / 'brand' / 'logo-enef.jpg',
    ]
    for path in candidates:
        if path.is_file():
            return path
    return None


def _styles():
    _register_fonts()
    base = getSampleStyleSheet()
    return {
        'kicker': ParagraphStyle(
            'PNLFKicker', parent=base['Normal'], fontName=FONT_BOLD, fontSize=8,
            textColor=GOLD, spaceAfter=2, alignment=TA_LEFT,
        ),
        'org': ParagraphStyle(
            'PNLFOrg', parent=base['Normal'], fontName=FONT_BOLD, fontSize=11,
            textColor=colors.white, leading=14, alignment=TA_LEFT,
        ),
        'org_sub': ParagraphStyle(
            'PNLFOrgSub', parent=base['Normal'], fontName=FONT, fontSize=8,
            textColor=colors.HexColor('#dce8e0'), leading=11, alignment=TA_LEFT,
        ),
        'title': ParagraphStyle(
            'PNLFTitle', parent=base['Normal'], fontName=FONT_BOLD, fontSize=14,
            textColor=GREEN_DARK, leading=18, spaceBefore=8, spaceAfter=4, alignment=TA_LEFT,
        ),
        'meta': ParagraphStyle(
            'PNLFMeta', parent=base['Normal'], fontName=FONT, fontSize=8.5,
            textColor=MUTED, leading=12, alignment=TA_LEFT,
        ),
        'cell': ParagraphStyle(
            'PNLFCell', parent=base['Normal'], fontName=FONT, fontSize=7.5,
            textColor=TEXT, leading=10, alignment=TA_LEFT,
        ),
        'cell_center': ParagraphStyle(
            'PNLFCellCenter', parent=base['Normal'], fontName=FONT, fontSize=7.5,
            textColor=TEXT, leading=10, alignment=TA_CENTER,
        ),
        'th': ParagraphStyle(
            'PNLFTh', parent=base['Normal'], fontName=FONT_BOLD, fontSize=7.5,
            textColor=colors.white, leading=10, alignment=TA_LEFT,
        ),
        'empty': ParagraphStyle(
            'PNLFEmpty', parent=base['Normal'], fontName=FONT, fontSize=10,
            textColor=MUTED, alignment=TA_CENTER, spaceBefore=20,
        ),
        'footer': ParagraphStyle(
            'PNLFFooter', parent=base['Normal'], fontName=FONT, fontSize=7,
            textColor=MUTED, alignment=TA_CENTER,
        ),
    }


def _esc(value) -> str:
    text = '' if value is None else str(value)
    return (
        text.replace('&', '&amp;')
        .replace('<', '&lt;')
        .replace('>', '&gt;')
        .replace('\n', '<br/>')
    )


def _cell(text, style) -> Paragraph:
    return Paragraph(_esc(text) or '—', style)


def _header_table(styles, subtitle: str) -> Table:
    left_cell: Image | Paragraph = Paragraph('ENEF', styles['org'])
    logo = _logo_path()
    if logo:
        try:
            left_cell = Image(str(logo), width=18 * mm, height=18 * mm, kind='proportional')
        except Exception:
            pass
    right = [
        Paragraph('RÉPUBLIQUE GABONAISE', styles['kicker']),
        Paragraph('École Nationale des Eaux et Forêts', styles['org']),
        Paragraph(subtitle, styles['org_sub']),
    ]
    inner = Table(
        [[left_cell, right]],
        colWidths=[22 * mm, 250 * mm],
    )
    inner.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), GREEN_DARK),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (0, 0), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.white),
    ]))
    return inner


def _meta_table(styles, rows: list[tuple[str, str]]) -> Table:
    data = [[
        Paragraph(f'<b>{_esc(label)}</b><br/>{_esc(value)}', styles['meta'])
        for label, value in rows
    ]]
    col_w = 272 * mm / max(len(rows), 1)
    table = Table(data, colWidths=[col_w] * len(rows))
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#eef4f0')),
        ('BOX', (0, 0), (-1, -1), 0.4, GREEN),
        ('LINEBEFORE', (1, 0), (-1, -1), 0.3, BORDER),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    return table


def _data_table(
    header: list,
    rows: list[list],
    col_widths: list[float],
    styles,
    center_cols: tuple[int, ...] = (0,),
) -> Table:
    head = [_cell(h, styles['th']) for h in header]
    body = []
    for row in rows:
        formatted = []
        for j, value in enumerate(row):
            style = styles['cell_center'] if j in center_cols else styles['cell']
            formatted.append(_cell(value, style))
        body.append(formatted)
    table = Table([head] + body, colWidths=col_widths, repeatRows=1)
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), FONT_BOLD),
        ('FONTSIZE', (0, 0), (-1, -1), 7.5),
        ('GRID', (0, 0), (-1, -1), 0.25, BORDER),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, ROW_ALT]),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LINEBELOW', (0, 0), (-1, 0), 1.2, GOLD),
    ]))
    return table


def _render_pdf(story, *, title: str, footer: str) -> bytes:
    _register_fonts()
    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=landscape(A4),
        leftMargin=12 * mm,
        rightMargin=12 * mm,
        topMargin=10 * mm,
        bottomMargin=16 * mm,
        title=title,
        author='École Nationale des Eaux et Forêts',
        subject='Plateforme PNLF-PFNL — rapport institutionnel',
        creator='PNLF-PFNL',
    )

    def on_page(canvas, document):
        canvas.saveState()
        width, height = landscape(A4)
        canvas.setFillColor(GOLD)
        canvas.rect(0, height - 2.8 * mm, width, 2.8 * mm, fill=1, stroke=0)
        canvas.setFillColor(GREEN_DARK)
        canvas.rect(0, 0, width, 11 * mm, fill=1, stroke=0)
        canvas.setFillColor(GOLD)
        canvas.rect(0, 11 * mm, width, 0.6 * mm, fill=1, stroke=0)
        canvas.setFillColor(colors.white)
        canvas.setFont(FONT, 7)
        canvas.drawString(12 * mm, 4.5 * mm, footer[:95])
        canvas.drawRightString(width - 12 * mm, 4.5 * mm, f'Page {document.page}')
        canvas.restoreState()

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    return buf.getvalue()


def pdf_file_response(pdf: bytes, filename: str) -> HttpResponse:
    """Réponse pour une navigation navigateur native (pas un XHR)."""
    ascii_name = filename.encode('ascii', 'ignore').decode('ascii') or 'export.pdf'
    response = HttpResponse(pdf, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="{ascii_name}"'
    response['Cache-Control'] = 'no-store'
    response['X-Content-Type-Options'] = 'nosniff'
    response['Content-Length'] = str(len(pdf))
    return response


def _build_pdf(story, *, filename: str, title: str, footer: str) -> HttpResponse:
    return pdf_file_response(_render_pdf(story, title=title, footer=footer), filename)


def lots_pdf_bytes(queryset) -> tuple[bytes, str]:
    response = export_lots_pdf(queryset)
    filename = f'PNLF-lots-{timezone.localtime():%Y%m%d-%H%M}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def journal_pdf_bytes(rows: list[dict], libelle: str) -> tuple[bytes, str]:
    response = export_journal_pdf(rows, libelle)
    filename = f'PNLF-journal-{timezone.localtime():%Y%m%d-%H%M}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def export_lots_pdf(queryset) -> HttpResponse:
    styles = _styles()
    now = timezone.localtime()
    lots = list(queryset.select_related('produit', 'producteur', 'producteur__province')[:800])

    story = [
        _header_table(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 8),
        Paragraph('Registre des lots de produits forestiers non ligneux', styles['title']),
        _meta_table(styles, [
            ('Date d’édition', now.strftime('%d/%m/%Y à %H:%M')),
            ('Nombre de lots', str(len(lots))),
            ('Périmètre', 'Lots visibles selon le profil connecté'),
            ('Document', 'Export officiel — usage interne'),
        ]),
        Spacer(1, 10),
    ]

    if not lots:
        story.append(Paragraph('Aucun lot à exporter pour ce périmètre.', styles['empty']))
    else:
        header = ['N°', 'Code lot', 'Produit', 'Producteur', 'Collecte', 'Quantité', 'Unité', 'Statut']
        rows = []
        for i, lot in enumerate(lots, start=1):
            producteur = ''
            if lot.producteur_id:
                producteur = f'{lot.producteur.prenoms} {lot.producteur.nom}'.strip()
            date_col = ''
            if lot.date_collecte:
                date_col = lot.date_collecte.strftime('%d/%m/%Y') if hasattr(lot.date_collecte, 'strftime') else str(lot.date_collecte)
            qte = lot.quantite
            qte_txt = f'{qte:.3f}'.rstrip('0').rstrip('.') if qte is not None else ''
            rows.append([
                str(i),
                lot.code_lot or '',
                lot.produit.nom if lot.produit_id else '',
                producteur,
                date_col,
                qte_txt,
                lot.unite or '',
                STATUT_LOT_FR.get(lot.statut, lot.statut or ''),
            ])
        widths = [12 * mm, 32 * mm, 52 * mm, 62 * mm, 28 * mm, 26 * mm, 20 * mm, 32 * mm]
        story.append(_data_table(header, rows, widths, styles, center_cols=(0, 4, 5, 6)))
        story.append(Spacer(1, 8))
        story.append(Paragraph(
            'Les statuts sont exprimés en français. Document généré automatiquement par la plateforme PNLF-PFNL.',
            styles['meta'],
        ))

    filename = f'PNLF-lots-{now:%Y%m%d-%H%M}.pdf'
    return _build_pdf(
        story,
        filename=filename,
        title='Registre des lots PFNL',
        footer='ENEF · République Gabonaise · Confidentiel — ne pas diffuser hors circuit institutionnel',
    )


STATUT_PRODUCTEUR_FR = {
    'EN_VALIDATION': 'En attente de validation',
    'ACTIF': 'Actif',
    'INACTIF': 'Inactif',
    'REJETE': 'Rejeté',
}

STATUT_COOPERATIVE_FR = {
    'EN_VALIDATION': 'En attente de validation',
    'ACTIF': 'Actif',
    'INACTIF': 'Inactif',
    'REJETE': 'Rejeté',
}


def _identite_table(styles, rows: list[tuple[str, str]]) -> Table:
    """Tableau 2 colonnes libellé/valeur — pour les fiches individuelles (portrait)."""
    data = [[Paragraph(f'<b>{_esc(label)}</b>', styles['cell']), _cell(value, styles['cell'])] for label, value in rows]
    table = Table(data, colWidths=[55 * mm, 130 * mm])
    table.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.25, BORDER),
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#eef4f0')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    return table


def _render_pdf_portrait(story, *, title: str, footer: str) -> bytes:
    """Variante portrait A4 de _render_pdf, pour les fiches individuelles."""
    _register_fonts()
    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=10 * mm,
        bottomMargin=16 * mm,
        title=title,
        author='École Nationale des Eaux et Forêts',
        subject='Plateforme PNLF-PFNL — fiche institutionnelle',
        creator='PNLF-PFNL',
    )

    def on_page(canvas, document):
        canvas.saveState()
        width, height = A4
        canvas.setFillColor(GOLD)
        canvas.rect(0, height - 2.8 * mm, width, 2.8 * mm, fill=1, stroke=0)
        canvas.setFillColor(GREEN_DARK)
        canvas.rect(0, 0, width, 11 * mm, fill=1, stroke=0)
        canvas.setFillColor(GOLD)
        canvas.rect(0, 11 * mm, width, 0.6 * mm, fill=1, stroke=0)
        canvas.setFillColor(colors.white)
        canvas.setFont(FONT, 7)
        canvas.drawString(16 * mm, 4.5 * mm, footer[:80])
        canvas.drawRightString(width - 16 * mm, 4.5 * mm, f'Page {document.page}')
        canvas.restoreState()

    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    return buf.getvalue()


def _header_table_portrait(styles, subtitle: str) -> Table:
    left_cell: Image | Paragraph = Paragraph('ENEF', styles['org'])
    logo = _logo_path()
    if logo:
        try:
            left_cell = Image(str(logo), width=18 * mm, height=18 * mm, kind='proportional')
        except Exception:
            pass
    right = [
        Paragraph('RÉPUBLIQUE GABONAISE', styles['kicker']),
        Paragraph('École Nationale des Eaux et Forêts', styles['org']),
        Paragraph(subtitle, styles['org_sub']),
    ]
    inner = Table([[left_cell, right]], colWidths=[22 * mm, 163 * mm])
    inner.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), GREEN_DARK),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (0, 0), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.white),
    ]))
    return inner


def export_producteur_fiche_pdf(producteur, request=None) -> HttpResponse:
    """Fiche individuelle imprimable d'un producteur/collecteur (portrait, 1 page utile)."""
    from traceability.models import Certification, Lot
    from traceability.services import photo_url as _prod_photo_url

    from traceability.db_utils import get_optional_column

    styles = _styles()

    type_acteur = 'Collecteur' if get_optional_column(
        'producteurs', 'type_acteur', producteur.id, default='PRODUCTEUR',
    ) == 'COLLECTEUR' else 'Producteur'

    story: list = [
        _header_table_portrait(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 10),
        Paragraph(f'Fiche {type_acteur.lower()} — {producteur.prenoms} {producteur.nom}', styles['title']),
    ]

    photo = None
    photo_rel_path = None
    try:
        photo_rel_path = _prod_photo_url('producteurs', producteur.id)
    except Exception:
        photo_rel_path = None
    if photo_rel_path:
        try:
            from django.conf import settings as _settings

            local_path = Path(_settings.MEDIA_ROOT) / photo_rel_path.replace('/media/', '', 1).lstrip('/')
            if local_path.is_file():
                photo = Image(str(local_path), width=30 * mm, height=30 * mm, kind='proportional')
        except Exception:
            photo = None

    localisation = ' / '.join(
        filter(None, [
            getattr(producteur.province, 'nom', None) if producteur.province_id else None,
            getattr(producteur.departement, 'nom', None) if producteur.departement_id else None,
            getattr(producteur.village, 'nom', None) if producteur.village_id else None,
        ])
    ) or '—'

    identite_rows = [
        ('Code', producteur.code_producteur or '—'),
        ('Type', type_acteur),
        ('Nom complet', f'{producteur.prenoms} {producteur.nom}'.strip()),
        ('Téléphone', producteur.telephone or '—'),
        ('E-mail', producteur.email or '—'),
        ('Localisation', localisation),
        ('Communauté', producteur.communaute or '—'),
        ('Statut', STATUT_PRODUCTEUR_FR.get(producteur.statut, producteur.statut or '—')),
        ('Inscrit le', producteur.created_at.strftime('%d/%m/%Y') if producteur.created_at else '—'),
    ]

    if photo:
        story.append(Spacer(1, 8))
        head_tbl = Table([[_identite_table(styles, identite_rows), photo]], colWidths=[150 * mm, 35 * mm])
        head_tbl.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP')]))
        story.append(head_tbl)
    else:
        story.append(Spacer(1, 8))
        story.append(_identite_table(styles, identite_rows))

    lots = list(
        Lot.objects.filter(producteur_id=producteur.id, deleted_at__isnull=True)
        .select_related('produit')
        .order_by('-date_collecte')[:15]
    )
    story.append(Spacer(1, 12))
    story.append(Paragraph('Lots déclarés (15 plus récents)', styles['title']))
    if not lots:
        story.append(Paragraph('Aucun lot déclaré à ce jour.', styles['empty']))
    else:
        header = ['Code lot', 'Produit', 'Date collecte', 'Quantité', 'Statut']
        rows = []
        for lot in lots:
            qte = lot.quantite
            qte_txt = f'{qte:.3f}'.rstrip('0').rstrip('.') if qte is not None else ''
            rows.append([
                lot.code_lot or '—',
                lot.produit.nom if lot.produit_id else '—',
                lot.date_collecte.strftime('%d/%m/%Y') if lot.date_collecte else '—',
                f'{qte_txt} {lot.unite or ""}'.strip(),
                STATUT_LOT_FR.get(lot.statut, lot.statut or '—'),
            ])
        story.append(_data_table(header, rows, [30 * mm, 45 * mm, 30 * mm, 35 * mm, 45 * mm], styles, center_cols=(2, 3)))

    certs = list(
        Certification.objects.filter(producteur_id=producteur.id)
        .select_related('type_certification')
        .order_by('-date_demande')[:10]
    )
    story.append(Spacer(1, 12))
    story.append(Paragraph('Certifications', styles['title']))
    if not certs:
        story.append(Paragraph('Aucune certification enregistrée.', styles['empty']))
    else:
        header = ['Type', 'N° certificat', 'Statut', 'Obtenue le', 'Expire le']
        rows = [
            [
                c.type_certification.libelle if c.type_certification_id else '—',
                c.numero_certificat or '—',
                c.statut or '—',
                c.date_obtention.strftime('%d/%m/%Y') if c.date_obtention else '—',
                c.date_expiration.strftime('%d/%m/%Y') if c.date_expiration else '—',
            ]
            for c in certs
        ]
        story.append(_data_table(header, rows, [40 * mm, 35 * mm, 30 * mm, 30 * mm, 30 * mm], styles, center_cols=(2, 3, 4)))

    filename = f'PNLF-fiche-{(producteur.code_producteur or str(producteur.id)[:8])}.pdf'
    return _build_pdf_portrait(
        story, filename=filename, title=f'Fiche producteur — {producteur.nom}',
        footer='ENEF · République Gabonaise · Document généré automatiquement',
    )


def export_producteurs_liste_pdf(queryset) -> HttpResponse:
    """Liste imprimable des producteurs/collecteurs (paysage)."""
    styles = _styles()
    now = timezone.localtime()
    items = list(queryset.select_related('province')[:1000])

    story = [
        _header_table(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 8),
        Paragraph('Registre des producteurs et collecteurs', styles['title']),
        _meta_table(styles, [
            ('Date d’édition', now.strftime('%d/%m/%Y à %H:%M')),
            ('Nombre d’acteurs', str(len(items))),
            ('Périmètre', 'Selon le profil connecté'),
            ('Document', 'Export officiel — usage interne'),
        ]),
        Spacer(1, 10),
    ]
    if not items:
        story.append(Paragraph('Aucun producteur à exporter pour ce périmètre.', styles['empty']))
    else:
        header = ['N°', 'Code', 'Nom complet', 'Téléphone', 'Province', 'Statut']
        rows = [
            [
                str(i),
                p.code_producteur or '—',
                f'{p.prenoms} {p.nom}'.strip(),
                p.telephone or '—',
                getattr(p.province, 'nom', None) or '—',
                STATUT_PRODUCTEUR_FR.get(p.statut, p.statut or '—'),
            ]
            for i, p in enumerate(items, start=1)
        ]
        widths = [12 * mm, 32 * mm, 62 * mm, 36 * mm, 46 * mm, 42 * mm]
        story.append(_data_table(header, rows, widths, styles, center_cols=(0,)))

    filename = f'PNLF-producteurs-{now:%Y%m%d-%H%M}.pdf'
    return _build_pdf(
        story, filename=filename, title='Registre des producteurs',
        footer='ENEF · République Gabonaise · Confidentiel — ne pas diffuser hors circuit institutionnel',
    )


def export_cooperative_fiche_pdf(cooperative, request=None) -> HttpResponse:
    """Fiche individuelle imprimable d'une coopérative (portrait)."""
    from traceability.models import CooperativeMembre

    styles = _styles()

    identite_rows = [
        ('Code', cooperative.code or '—'),
        ('Nom', cooperative.nom or '—'),
        ('N° agrément', cooperative.numero_agrement or '—'),
        ('Téléphone', cooperative.telephone or '—'),
        ('E-mail', cooperative.email or '—'),
        ('Adresse', cooperative.adresse or '—'),
        ('Province', getattr(cooperative.province, 'nom', None) or '—'),
        ('Statut', STATUT_COOPERATIVE_FR.get(cooperative.statut, cooperative.statut or '—')),
        ('Créée le', cooperative.created_at.strftime('%d/%m/%Y') if cooperative.created_at else '—'),
    ]

    story: list = [
        _header_table_portrait(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 10),
        Paragraph(f'Fiche coopérative — {cooperative.nom}', styles['title']),
        Spacer(1, 8),
        _identite_table(styles, identite_rows),
    ]

    membres = list(
        CooperativeMembre.objects.filter(cooperative_id=cooperative.id, actif=True)
        .select_related('producteur')
        .order_by('producteur__nom')[:100]
    )
    story.append(Spacer(1, 12))
    story.append(Paragraph(f'Membres actifs ({len(membres)})', styles['title']))
    if not membres:
        story.append(Paragraph('Aucun membre actif enregistré.', styles['empty']))
    else:
        header = ['Nom complet', 'Téléphone', 'Statut', 'Adhésion']
        rows = [
            [
                str(m.producteur),
                getattr(m.producteur, 'telephone', None) or '—',
                STATUT_PRODUCTEUR_FR.get(getattr(m.producteur, 'statut', None), getattr(m.producteur, 'statut', None) or '—'),
                m.date_adhesion.strftime('%d/%m/%Y') if m.date_adhesion else '—',
            ]
            for m in membres
        ]
        story.append(_data_table(header, rows, [70 * mm, 36 * mm, 38 * mm, 30 * mm], styles, center_cols=(2, 3)))

    filename = f'PNLF-fiche-coop-{(cooperative.code or str(cooperative.id)[:8])}.pdf'
    return _build_pdf_portrait(
        story, filename=filename, title=f'Fiche coopérative — {cooperative.nom}',
        footer='ENEF · République Gabonaise · Document généré automatiquement',
    )


def export_cooperatives_liste_pdf(queryset) -> HttpResponse:
    """Liste imprimable des coopératives (paysage)."""
    from traceability.models import CooperativeMembre
    from django.db.models import Count

    styles = _styles()
    now = timezone.localtime()
    items = list(queryset.select_related('province')[:1000])
    nb_membres = dict(
        CooperativeMembre.objects.filter(actif=True, cooperative_id__in=[c.id for c in items])
        .values('cooperative_id').annotate(n=Count('producteur_id')).values_list('cooperative_id', 'n')
    )

    story = [
        _header_table(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 8),
        Paragraph('Registre des coopératives', styles['title']),
        _meta_table(styles, [
            ('Date d’édition', now.strftime('%d/%m/%Y à %H:%M')),
            ('Nombre de coopératives', str(len(items))),
            ('Périmètre', 'Selon le profil connecté'),
            ('Document', 'Export officiel — usage interne'),
        ]),
        Spacer(1, 10),
    ]
    if not items:
        story.append(Paragraph('Aucune coopérative à exporter pour ce périmètre.', styles['empty']))
    else:
        header = ['N°', 'Code', 'Nom', 'Téléphone', 'Province', 'Membres', 'Statut']
        rows = [
            [
                str(i),
                c.code or '—',
                c.nom or '—',
                c.telephone or '—',
                getattr(c.province, 'nom', None) or '—',
                str(nb_membres.get(c.id, 0)),
                STATUT_COOPERATIVE_FR.get(c.statut, c.statut or '—'),
            ]
            for i, c in enumerate(items, start=1)
        ]
        widths = [10 * mm, 28 * mm, 52 * mm, 32 * mm, 40 * mm, 22 * mm, 42 * mm]
        story.append(_data_table(header, rows, widths, styles, center_cols=(0, 5)))

    filename = f'PNLF-cooperatives-{now:%Y%m%d-%H%M}.pdf'
    return _build_pdf(
        story, filename=filename, title='Registre des coopératives',
        footer='ENEF · République Gabonaise · Confidentiel — ne pas diffuser hors circuit institutionnel',
    )


def _build_pdf_portrait(story, *, filename: str, title: str, footer: str) -> HttpResponse:
    return pdf_file_response(_render_pdf_portrait(story, title=title, footer=footer), filename)


def producteur_fiche_pdf_bytes(producteur) -> tuple[bytes, str]:
    response = export_producteur_fiche_pdf(producteur)
    filename = f'PNLF-fiche-{producteur.code_producteur or str(producteur.id)[:8]}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def producteurs_liste_pdf_bytes(queryset) -> tuple[bytes, str]:
    response = export_producteurs_liste_pdf(queryset)
    filename = f'PNLF-producteurs-{timezone.localtime():%Y%m%d-%H%M}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def cooperative_fiche_pdf_bytes(cooperative) -> tuple[bytes, str]:
    response = export_cooperative_fiche_pdf(cooperative)
    filename = f'PNLF-fiche-coop-{cooperative.code or str(cooperative.id)[:8]}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def cooperatives_liste_pdf_bytes(queryset) -> tuple[bytes, str]:
    response = export_cooperatives_liste_pdf(queryset)
    filename = f'PNLF-cooperatives-{timezone.localtime():%Y%m%d-%H%M}.pdf'
    disposition = response.get('Content-Disposition') or ''
    if 'filename="' in disposition:
        filename = disposition.split('filename="', 1)[1].split('"', 1)[0]
    return bytes(response.content), filename


def export_journal_pdf(rows: list[dict], libelle: str) -> HttpResponse:
    styles = _styles()
    now = timezone.localtime()
    data_rows = rows[:800]

    story = [
        _header_table(styles, 'Plateforme numérique de traçabilité des PFNL'),
        Spacer(1, 8),
        Paragraph('Journal d’activité de la plateforme', styles['title']),
        _meta_table(styles, [
            ('Période', libelle),
            ('Événements', str(len(data_rows))),
            ('Date d’édition', now.strftime('%d/%m/%Y à %H:%M')),
            ('Document', 'Audit interne'),
        ]),
        Spacer(1, 10),
    ]

    if not data_rows:
        story.append(Paragraph('Aucun événement d’audit sur cette période.', styles['empty']))
    else:
        header = ['Date / heure', 'Action', 'Cible', 'Référence', 'Utilisateur', 'Adresse IP']
        body = []
        for r in data_rows:
            created = r.get('created_at') or ''
            try:
                created = datetime.fromisoformat(str(created)).strftime('%d/%m/%Y %H:%M')
            except Exception:
                created = str(created)[:16]
            table_cible = r.get('table_cible') or ''
            action = r.get('action') or ''
            body.append([
                created,
                ACTION_FR.get(action, action.replace('_', ' ').capitalize() if action else '—'),
                TABLE_FR.get(table_cible, table_cible or '—'),
                str(r.get('enregistrement_id') or '—'),
                r.get('utilisateur') or 'Système',
                r.get('ip_adresse') or '—',
            ])
        widths = [36 * mm, 36 * mm, 38 * mm, 58 * mm, 62 * mm, 34 * mm]
        story.append(_data_table(header, body, widths, styles, center_cols=(0, 5)))

    filename = f'PNLF-journal-{now:%Y%m%d-%H%M}.pdf'
    return _build_pdf(
        story,
        filename=filename,
        title=f'Journal d’activité — {libelle}',
        footer='ENEF · République Gabonaise · Journal d’audit — usage institutionnel uniquement',
    )
