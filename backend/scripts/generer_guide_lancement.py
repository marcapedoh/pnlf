"""Génère le guide PDF de lancement des serveurs PNLF-PFNL."""
from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import ListFlowable, ListItem, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'Guide-lancement-serveurs-PNLF.pdf'
GREEN = colors.HexColor('#146b3f')
GREEN_DARK = colors.HexColor('#0d3d24')
GOLD = colors.HexColor('#c9a227')
MUTED = colors.HexColor('#5c6b63')


def styles():
    base = getSampleStyleSheet()
    return {
        'h1': ParagraphStyle('H1', parent=base['Title'], fontName='Times-Bold', fontSize=18,
                             textColor=GREEN_DARK, spaceAfter=6, alignment=TA_LEFT, leading=22),
        'h2': ParagraphStyle('H2', parent=base['Heading2'], fontName='Times-Bold', fontSize=13,
                             textColor=GREEN, spaceBefore=12, spaceAfter=6, leading=16),
        'body': ParagraphStyle('Body', parent=base['Normal'], fontName='Times-Roman', fontSize=10.5,
                               leading=14, alignment=TA_JUSTIFY, textColor=colors.HexColor('#1a1f1c')),
        'step': ParagraphStyle('Step', parent=base['Normal'], fontName='Times-Roman', fontSize=10.5,
                               leading=14, leftIndent=4),
        'code': ParagraphStyle('Code', parent=base['Normal'], fontName='Courier', fontSize=9,
                               leading=12, textColor=GREEN_DARK, backColor=colors.HexColor('#eef4f0'),
                               leftIndent=6, rightIndent=6, spaceBefore=4, spaceAfter=4),
        'meta': ParagraphStyle('Meta', parent=base['Normal'], fontName='Times-Italic', fontSize=9,
                               textColor=MUTED, alignment=TA_CENTER),
        'warn': ParagraphStyle('Warn', parent=base['Normal'], fontName='Times-Roman', fontSize=10.5,
                               leading=14, textColor=colors.HexColor('#7a3b00')),
    }


def header(canvas, doc):
    canvas.saveState()
    w, h = A4
    canvas.setFillColor(GREEN_DARK)
    canvas.rect(0, h - 18 * mm, w, 18 * mm, fill=1, stroke=0)
    canvas.setFillColor(GOLD)
    canvas.rect(0, h - 19 * mm, w, 1.2 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white)
    canvas.setFont('Times-Bold', 11)
    canvas.drawString(16 * mm, h - 11 * mm, 'PNLF-PFNL  ·  École Nationale des Eaux et Forêts')
    canvas.setFont('Times-Roman', 8)
    canvas.drawRightString(w - 16 * mm, h - 11 * mm, 'Guide opérateur')
    canvas.setFillColor(GREEN_DARK)
    canvas.rect(0, 0, w, 12 * mm, fill=1, stroke=0)
    canvas.setFillColor(colors.white)
    canvas.setFont('Times-Roman', 8)
    canvas.drawString(16 * mm, 5 * mm, 'Confidentiel — usage interne')
    canvas.drawRightString(w - 16 * mm, 5 * mm, f'Page {doc.page}')
    canvas.restoreState()


def main() -> None:
    s = styles()
    story = [
        Paragraph('Guide de lancement des serveurs', s['h1']),
        Paragraph('Plateforme numérique de traçabilité des PFNL — comment tout démarrer, à chaque fois.', s['meta']),
        Spacer(1, 8),
        Paragraph(
            'L’application a <b>trois pièces</b> : PostgreSQL (les données), Django (l’API, port 8000) '
            'et Angular (l’écran, port 4200). Sans les trois, la page ne s’ouvre pas ou affiche une erreur.',
            s['body'],
        ),
        Paragraph('1. Le moyen le plus simple (à utiliser en premier)', s['h2']),
        Paragraph(
            'À la racine du projet se trouve le fichier <b>start-pnlf.bat</b>. Double-cliquez dessus. '
            'Il vérifie PostgreSQL, ouvre Django, ouvre Angular, puis le navigateur sur '
            '<b>http://localhost:4200</b>. Laissez les deux fenêtres noires ouvertes tant que vous travaillez. '
            'Pour tout arrêter proprement : double-cliquez sur <b>stop-pnlf.bat</b> (la base n’est pas arrêtée).',
            s['body'],
        ),
        Paragraph(r'Emplacement : C:\Users\DELL\Desktop\Projet PNLF\start-pnlf.bat', s['code']),
        Paragraph('2. Au démarrage de Windows (après extinction ou redémarrage)', s['h2']),
        ListFlowable([
            ListItem(Paragraph('Allumez le PC et attendez la session Windows.', s['step'])),
            ListItem(Paragraph('Vérifiez PostgreSQL : menu Démarrer → tapez <b>Services</b> → cherchez un service dont le nom contient <b>postgresql</b> → état <b>En cours d’exécution</b>. Sinon : clic droit → Démarrer. (Souvent le service est déjà en « Automatique ».)', s['step'])),
            ListItem(Paragraph('Double-cliquez sur <b>start-pnlf.bat</b>.', s['step'])),
            ListItem(Paragraph('Attendez le message Angular « Local: http://localhost:4200 » (15 à 40 secondes la première fois).', s['step'])),
            ListItem(Paragraph('Connectez-vous dans le navigateur. Si une ancienne page est ouverte : <b>Ctrl + F5</b>.', s['step'])),
        ], bulletType='1', start='1', leftIndent=12),
        Paragraph('3. Depuis Cursor (deux terminaux)', s['h2']),
        Paragraph('Terminal 1 — API :', s['body']),
        Paragraph(r'.\.venv\Scripts\python.exe backend\manage.py runserver 127.0.0.1:8000', s['code']),
        Paragraph('Terminal 2 — interface :', s['body']),
        Paragraph(r'cd frontend', s['code']),
        Paragraph('npm start', s['code']),
        Paragraph(
            'La commande <b>npm start</b> lance déjà le bon mode : port 4200, toutes les cartes réseau '
            '(0.0.0.0), et le proxy vers Django. N’utilisez pas un simple <i>ng serve</i> sans proxy : '
            'les PDF et l’API cassent.',
            s['body'],
        ),
        Paragraph('4. Autres appareils (téléphone, autre PC, même Wi-Fi)', s['h2']),
        Paragraph(
            'Sur le PC serveur, lancez <b>start-pnlf.bat</b>. Sur l’autre appareil, ouvrez '
            '<b>http://ADRESSE-IP:4200</b> (exemple : http://192.168.1.24:4200). L’adresse IPv4 du PC se voit '
            'avec la commande <b>ipconfig</b> (invite de commandes). Le pare-feu Windows doit autoriser le port <b>4200</b>. '
            'Vous n’avez pas à ouvrir le 8000 depuis le téléphone : Angular relaie l’API.',
            s['body'],
        ),
        Paragraph('5. Que faire si ça ne démarre pas', s['h2']),
    ]
    rows = [
        [Paragraph('<b>Symptôme</b>', s['step']), Paragraph('<b>Cause fréquente</b>', s['step']), Paragraph('<b>Action</b>', s['step'])],
        [Paragraph('Port already in use / 8000 ou 4200', s['step']), Paragraph('Un ancien serveur tourne encore', s['step']), Paragraph('Double-cliquez stop-pnlf.bat, puis start-pnlf.bat', s['step'])],
        [Paragraph('Impossible de joindre le serveur / Failed to fetch', s['step']), Paragraph('Django arrêté ou mauvais onglet 127.0.0.1 vs localhost', s['step']), Paragraph('Relancez Django. Ouvrez http://localhost:4200 (pas uniquement 127.0.0.1 si un des deux refuse)', s['step'])],
        [Paragraph('Erreur base / connection refused 5432', s['step']), Paragraph('PostgreSQL éteint', s['step']), Paragraph('Services Windows → postgresql → Démarrer', s['step'])],
        [Paragraph('Page blanche Angular', s['step']), Paragraph('Compilation pas finie ou cache', s['step']), Paragraph('Attendre « Application bundle generation complete », puis Ctrl+F5', s['step'])],
        [Paragraph('PDF qui ne s’ouvre pas', s['step']), Paragraph('Fenêtre pop-up bloquée', s['step']), Paragraph('Autoriser les pop-ups pour localhost:4200, ou cliquer « Ouvrir le PDF »', s['step'])],
        [Paragraph('npm n’est pas reconnu', s['step']), Paragraph('Node.js pas dans le PATH', s['step']), Paragraph('Ouvrir un nouveau terminal, ou réinstaller Node LTS, puis npm start dans frontend', s['step'])],
    ]
    table = Table(rows, colWidths=[48 * mm, 55 * mm, 67 * mm])
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f7faf8')),
        ('GRID', (0, 0), (-1, -1), 0.3, colors.HexColor('#d5ddd8')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
    ]))
    story.extend([
        table,
        Paragraph('6. Ordre à retenir dans toutes les situations', s['h2']),
        Paragraph(
            '<b>1.</b> PostgreSQL &nbsp;&nbsp; <b>2.</b> Django (8000) &nbsp;&nbsp; <b>3.</b> Angular (4200) &nbsp;&nbsp; '
            '<b>4.</b> Navigateur http://localhost:4200. '
            'Ne fermez jamais les fenêtres noires pendant que vous utilisez l’application. '
            'Un redémarrage PC = recommencer à l’étape 1 (ou un seul double-clic sur start-pnlf.bat).',
            s['body'],
        ),
        Spacer(1, 8),
        Paragraph(
            'Astuce : créez un raccourci Bureau vers start-pnlf.bat (clic droit → Envoyer vers → Bureau). '
            'C’est le geste unique à retenir.',
            s['warn'],
        ),
    ])
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=24 * mm,
        bottomMargin=16 * mm,
        title='Guide de lancement des serveurs PNLF-PFNL',
        author='École Nationale des Eaux et Forêts',
    )
    doc.build(story, onFirstPage=header, onLaterPages=header)
    print(OUT)


if __name__ == '__main__':
    main()
