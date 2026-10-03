"""Fiches PDF individuelles (producteur/collecteur, coopérative) au format institutionnel ENEF."""

from __future__ import annotations

from datetime import datetime
from io import BytesIO
from pathlib import Path

from django.conf import settings
from django.db.models import Count, Q
from django.utils import timezone
from reportlab.graphics import renderPDF
from reportlab.graphics.barcode.qr import QrCodeWidget
from reportlab.graphics.shapes import Drawing
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.fonts import addMapping
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import (
    BaseDocTemplate,
    CondPageBreak,
    Flowable,
    Frame,
    KeepTogether,
    NextPageTemplate,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

from . import pdf_export as base

VERT_FONCE = colors.HexColor('#0d3d24')
VERT = colors.HexColor('#146b3f')
OR = colors.HexColor('#c9a227')
FOND = colors.HexColor('#f4f8f5')
BORDURE = colors.HexColor('#d5ddd8')
TEXTE = colors.HexColor('#1a1f1c')
GRIS = colors.HexColor('#5c6b63')
GRIS_CLAIR = colors.HexColor('#8b9791')

LARGEUR_PAGE, HAUTEUR_PAGE = A4
MARGE = 16 * mm
LARGEUR_UTILE = LARGEUR_PAGE - 2 * MARGE
HAUTEUR_ENTETE_1 = 36 * mm
HAUTEUR_ENTETE_N = 15 * mm
HAUTEUR_PIED = 14 * mm

MASQUE = 'Réservé aux personnes habilitées'
NON_RENSEIGNE = 'Non renseigné'

ROLE_FR = {
    'ADMINISTRATEUR': 'Administrateur',
    'AGENT_MINISTERE': 'Agent du ministère',
    'AGENT_FORESTIER': 'Agent forestier',
    'COOPERATIVE': 'Coopérative',
    'PRODUCTEUR': 'Producteur',
    'ACHETEUR': 'Acheteur',
}

TONS = {
    'succes': (colors.HexColor('#146b3f'), colors.HexColor('#e2f1e7')),
    'attente': (colors.HexColor('#8a5a00'), colors.HexColor('#fcf0d2')),
    'info': (colors.HexColor('#1d4f91'), colors.HexColor('#e3ecf8')),
    'neutre': (colors.HexColor('#4b5563'), colors.HexColor('#eceff1')),
    'danger': (colors.HexColor('#a12a2a'), colors.HexColor('#fbe3e3')),
}
TON_STATUT_FICHE = {'ACTIF': 'succes', 'EN_VALIDATION': 'attente', 'INACTIF': 'neutre', 'REJETE': 'danger'}
TON_STATUT_LOT = {
    'BROUILLON': 'neutre', 'DECLARE': 'info', 'VALIDE': 'succes', 'EN_TRANSIT': 'attente',
    'TRANSFORME': 'info', 'COMMERCIALISE': 'succes', 'ARCHIVE': 'neutre', 'ANNULE': 'danger',
}
STATUT_CERTIFICATION_FR = {
    'DEMANDEE': 'Demandée', 'EN_COURS': 'En cours', 'OBTENUE': 'Obtenue', 'REFUSEE': 'Refusée',
    'EXPIREE': 'Expirée', 'REVOQUEE': 'Révoquée',
}
TON_STATUT_CERTIFICATION = {
    'DEMANDEE': 'attente', 'EN_COURS': 'attente', 'OBTENUE': 'succes', 'REFUSEE': 'danger',
    'EXPIREE': 'neutre', 'REVOQUEE': 'danger',
}
DOCUMENTS_ATTENDUS = (
    ('CNI', 'Pièce d’identité'),
    ('FICHE_CIRCUIT', 'Fiche circuit'),
    ('AGREMENT_NAGOYA', 'Agrément CITES / Nagoya'),
)


# =============================================================================
# Outils
# =============================================================================

def _polices() -> tuple[str, str]:
    base._register_fonts()
    if base.FONT != 'Helvetica':
        addMapping(base.FONT, 0, 0, base.FONT)
        addMapping(base.FONT, 1, 0, base.FONT_BOLD)
        addMapping(base.FONT, 0, 1, base.FONT)
        addMapping(base.FONT, 1, 1, base.FONT_BOLD)
    return base.FONT, base.FONT_BOLD


def _esc(valeur) -> str:
    return base._esc(valeur)


def _date(valeur) -> str:
    if not valeur:
        return ''
    if isinstance(valeur, datetime) and timezone.is_aware(valeur):
        valeur = timezone.localtime(valeur)
    return valeur.strftime('%d/%m/%Y')


def _quantite(valeur, unite) -> str:
    if valeur is None:
        return ''
    texte = f'{valeur:,.3f}'.rstrip('0').rstrip('.').replace(',', '\u202f').replace('.', ',')
    return f'{texte} {unite or ""}'.strip()


def _nom_personne(prenoms: str | None, nom: str | None) -> str:
    prenoms, nom = (prenoms or '').strip(), (nom or '').strip()
    return f'{prenoms} {nom.upper()}'.strip() if prenoms else nom


def libelle_role(utilisateur) -> str:
    role = getattr(utilisateur, 'role', None)
    if role == 'PRODUCTEUR':
        from traceability.db_utils import get_optional_column
        from traceability.models import Producteur

        fiche = Producteur.objects.filter(utilisateur_id=utilisateur.id, deleted_at__isnull=True).first()
        if fiche and get_optional_column('producteurs', 'type_acteur', fiche.id, default='PRODUCTEUR') == 'COLLECTEUR':
            return 'Collecteur'
    return ROLE_FR.get(role, role or 'Utilisateur')


def mention_impression(utilisateur, *, feminin: bool = True) -> str:
    """« Imprimée par Prénom NOM (rôle) le JJ/MM/AAAA à HH:MM (heure de Libreville) »."""
    maintenant = timezone.localtime()
    quand = f'le {maintenant:%d/%m/%Y} à {maintenant:%H:%M} (heure de Libreville)'
    verbe = 'Imprimée' if feminin else 'Imprimé'
    if utilisateur is None or not getattr(utilisateur, 'id', None):
        return f'{verbe} {quand}'
    nom = _nom_personne(getattr(utilisateur, 'prenoms', ''), getattr(utilisateur, 'nom', '')) or utilisateur.email
    return f'{verbe} par {nom} ({libelle_role(utilisateur)}) {quand}'


def _image_recadree(chemin: Path | None, ratio: float) -> ImageReader | None:
    """Image recadrée au centre selon le ratio largeur/hauteur demandé, ou None si illisible."""
    if chemin is None:
        return None
    try:
        from PIL import Image as PILImage

        with PILImage.open(chemin) as img:
            img = img.convert('RGB')
            largeur, hauteur = img.size
            if largeur / hauteur > ratio:
                nouvelle = int(hauteur * ratio)
                gauche = (largeur - nouvelle) // 2
                img = img.crop((gauche, 0, gauche + nouvelle, hauteur))
            else:
                nouvelle = int(largeur / ratio)
                haut = (hauteur - nouvelle) // 2
                img = img.crop((0, haut, largeur, haut + nouvelle))
            img.thumbnail((600, 600))
            tampon = BytesIO()
            img.save(tampon, format='JPEG', quality=88)
            tampon.seek(0)
            return ImageReader(tampon)
    except Exception:
        return None


def _photo_locale(sous_dossier: str, entite_id) -> Path | None:
    from config import media_store

    rel = f'photos/{sous_dossier}/{entite_id}.jpg'
    chemin = Path(settings.MEDIA_ROOT) / rel
    if chemin.is_file() or media_store.assurer_local(rel):
        return chemin
    return None


def _initiales(texte: str) -> str:
    mots = [m for m in (texte or '').replace('’', ' ').replace("'", ' ').split() if m[:1].isalpha()]
    if not mots:
        return 'PF'
    if len(mots) == 1:
        return mots[0][:2].upper()
    return (mots[0][0] + mots[-1][0]).upper()


def _styles() -> dict:
    police, gras = _polices()
    return {
        'nom': ParagraphStyle('FicheNom', fontName=gras, fontSize=17, leading=20, textColor=VERT_FONCE),
        'sous': ParagraphStyle('FicheSous', fontName=police, fontSize=8.5, leading=11.5, textColor=GRIS),
        'label': ParagraphStyle('FicheLabel', fontName=gras, fontSize=6.6, leading=8.5, textColor=GRIS_CLAIR),
        'valeur': ParagraphStyle('FicheValeur', fontName=police, fontSize=9.5, leading=12.5, textColor=TEXTE),
        'element': ParagraphStyle('FicheElement', fontName=police, fontSize=9.2, leading=12, textColor=TEXTE),
        'detail': ParagraphStyle('FicheDetail', fontName=police, fontSize=7.8, leading=10.5, textColor=GRIS),
        'vide': ParagraphStyle('FicheVide', fontName=police, fontSize=8.8, leading=12, textColor=GRIS_CLAIR),
        'note': ParagraphStyle('FicheNote', fontName=police, fontSize=7.4, leading=10, textColor=GRIS, alignment=TA_LEFT),
    }


def _valeur(texte, *, masque: bool = False) -> str:
    if masque:
        return f'<font color="#8b9791">{MASQUE}</font>'
    if texte is None or str(texte).strip() == '':
        return f'<font color="#a3aea8">{NON_RENSEIGNE}</font>'
    return _esc(texte)


def _masquer_numero(numero: str | None) -> str | None:
    if not numero:
        return numero
    visibles = numero[-3:] if len(numero) > 4 else numero[-1:]
    return '\u2022' * max(len(numero) - len(visibles), 3) + visibles


def _qr(valeur: str, taille: float) -> Drawing:
    widget = QrCodeWidget(valeur, barLevel='M')
    x0, y0, x1, y1 = widget.getBounds()
    dessin = Drawing(taille, taille, transform=[taille / (x1 - x0), 0, 0, taille / (y1 - y0), 0, 0])
    dessin.add(widget)
    return dessin


# =============================================================================
# Éléments graphiques
# =============================================================================

class Pastille(Flowable):
    def __init__(self, texte: str, ton: str = 'neutre', taille: float = 7.2):
        super().__init__()
        self.texte = texte
        self.premier, self.fond = TONS.get(ton, TONS['neutre'])
        self.taille = taille
        self.police = _polices()[1]
        self.largeur = stringWidth(texte, self.police, taille) + 6 * mm
        self.hauteur = taille + 2.6 * mm

    def wrap(self, *_):
        return self.largeur, self.hauteur

    def draw(self):
        c = self.canv
        c.setFillColor(self.fond)
        c.roundRect(0, 0, self.largeur, self.hauteur, self.hauteur / 2, fill=1, stroke=0)
        c.setFillColor(self.premier)
        c.circle(2.3 * mm, self.hauteur / 2, 0.75 * mm, fill=1, stroke=0)
        c.setFont(self.police, self.taille)
        c.drawString(4.0 * mm, self.hauteur / 2 - self.taille * 0.35, self.texte)


class TitreSection(Flowable):
    def __init__(self, titre: str, complement: str = ''):
        super().__init__()
        self.titre = titre.upper()
        self.complement = complement

    def wrap(self, largeur, *_):
        self.largeur = largeur
        return largeur, 9.5 * mm

    def draw(self):
        police, gras = _polices()
        c = self.canv
        c.setFillColor(VERT_FONCE)
        c.setFont(gras, 9.2)
        c.drawString(0, 3.6 * mm, self.titre)
        fin = stringWidth(self.titre, gras, 9.2)
        if self.complement:
            c.setFillColor(GRIS)
            c.setFont(police, 7.6)
            c.drawString(fin + 2.5 * mm, 3.6 * mm, self.complement)
        c.setStrokeColor(BORDURE)
        c.setLineWidth(0.5)
        c.line(0, 1.6 * mm, self.largeur, 1.6 * mm)
        c.setStrokeColor(OR)
        c.setLineWidth(1.6)
        c.line(0, 1.6 * mm, 16 * mm, 1.6 * mm)


class CarteIdentite(Flowable):
    """Bandeau d'identité : photo (ou initiales), nom, pastilles, informations clés et QR de la fiche."""

    HAUTEUR = 52 * mm

    def __init__(self, *, image: ImageReader | None, initiales: str, surtitre: str, titre: str,
                 pastilles: list[Pastille], lignes: list[str], qr_valeur: str, qr_legende: str,
                 ratio_photo: float = 0.8):
        super().__init__()
        self.image = image
        self.initiales = initiales
        self.surtitre = surtitre
        self.titre = titre
        self.pastilles = pastilles
        self.lignes = lignes
        self.qr_valeur = qr_valeur
        self.qr_legende = qr_legende
        self.ratio_photo = ratio_photo

    def wrap(self, largeur, *_):
        self.largeur = largeur
        return largeur, self.HAUTEUR

    def draw(self):
        police, gras = _polices()
        styles = _styles()
        c = self.canv
        h, w = self.HAUTEUR, self.largeur
        c.setFillColor(FOND)
        c.setStrokeColor(BORDURE)
        c.setLineWidth(0.6)
        c.roundRect(0, 0, w, h, 3 * mm, fill=1, stroke=1)
        c.setFillColor(OR)
        c.rect(0, 6 * mm, 1.3 * mm, h - 12 * mm, fill=1, stroke=0)

        ph = h - 10 * mm
        pw = ph * self.ratio_photo
        px, py = 6 * mm, 5 * mm
        c.saveState()
        chemin = c.beginPath()
        chemin.roundRect(px, py, pw, ph, 2.2 * mm)
        c.clipPath(chemin, stroke=0, fill=0)
        if self.image is not None:
            c.drawImage(self.image, px, py, pw, ph)
        else:
            c.setFillColor(VERT)
            c.rect(px, py, pw, ph, fill=1, stroke=0)
            c.setFillColor(colors.HexColor('#1d8a54'))
            c.circle(px + pw, py + ph, pw * 0.55, fill=1, stroke=0)
            c.setFillColor(colors.white)
            c.setFont(gras, 26)
            c.drawCentredString(px + pw / 2, py + ph / 2 - 9, self.initiales)
        c.restoreState()
        c.setStrokeColor(colors.white)
        c.setLineWidth(1.6)
        c.roundRect(px, py, pw, ph, 2.2 * mm, fill=0, stroke=1)

        zone_qr = 31 * mm
        tx = px + pw + 7 * mm
        tw = w - tx - zone_qr - 4 * mm
        y = h - 9 * mm
        c.setFillColor(OR)
        c.setFont(gras, 7.6)
        c.drawString(tx, y, self.surtitre.upper())
        nom = Paragraph(_esc(self.titre), styles['nom'])
        _, nh = nom.wrap(tw, 30 * mm)
        y -= 2 * mm + nh
        nom.drawOn(c, tx, y)
        y -= 2.2 * mm
        x = tx
        for pastille in self.pastilles:
            pw_, ph_ = pastille.wrap()
            if x + pw_ > tx + tw:
                break
            pastille.drawOn(c, x, y - ph_)
            x += pw_ + 2 * mm
        y -= 7.5 * mm
        for ligne in self.lignes:
            para = Paragraph(ligne, styles['sous'])
            _, lh = para.wrap(tw, 20 * mm)
            y -= lh
            if y < 3.5 * mm:
                break
            para.drawOn(c, tx, y)
            y -= 0.6 * mm

        taille_qr = 23 * mm
        qx = w - zone_qr + (zone_qr - taille_qr) / 2 - 2 * mm
        qy = 12 * mm
        c.setFillColor(colors.white)
        c.setStrokeColor(BORDURE)
        c.roundRect(qx - 1.5 * mm, qy - 1.5 * mm, taille_qr + 3 * mm, taille_qr + 3 * mm, 1.6 * mm, fill=1, stroke=1)
        renderPDF.draw(_qr(self.qr_valeur, taille_qr), c, qx, qy)
        c.setFillColor(GRIS)
        c.setFont(police, 6.4)
        c.drawCentredString(qx + taille_qr / 2, qy - 5 * mm, 'Fiche en ligne')
        c.setFont(gras, 6.8)
        c.setFillColor(VERT_FONCE)
        c.drawCentredString(qx + taille_qr / 2, qy - 8 * mm, self.qr_legende[:24])


class BandeauIndicateurs(Flowable):
    def __init__(self, indicateurs: list[tuple[str, str]]):
        super().__init__()
        self.indicateurs = indicateurs

    def wrap(self, largeur, *_):
        self.largeur = largeur
        return largeur, 17 * mm

    def draw(self):
        police, gras = _polices()
        c = self.canv
        n = max(len(self.indicateurs), 1)
        ecart = 3 * mm
        lw = (self.largeur - ecart * (n - 1)) / n
        for i, (valeur, libelle) in enumerate(self.indicateurs):
            x = i * (lw + ecart)
            c.setFillColor(colors.white)
            c.setStrokeColor(BORDURE)
            c.setLineWidth(0.6)
            c.roundRect(x, 0, lw, 17 * mm, 2.2 * mm, fill=1, stroke=1)
            c.setFillColor(OR)
            c.rect(x + 4 * mm, 17 * mm - 0.9 * mm, 10 * mm, 0.9 * mm, fill=1, stroke=0)
            c.setFillColor(VERT_FONCE)
            c.setFont(gras, 15)
            c.drawString(x + 4 * mm, 7.2 * mm, str(valeur))
            c.setFillColor(GRIS)
            texte = libelle.upper()
            taille = 6.8
            while taille > 5.2 and stringWidth(texte, police, taille) > lw - 6 * mm:
                taille -= 0.2
            c.setFont(police, taille)
            c.drawString(x + 4 * mm, 3.2 * mm, texte)


def _grille(champs: list[tuple[str, str, bool]], styles) -> Table:
    """Grille de champs libellé/valeur sur deux colonnes, sans bordure (présentation de fiche)."""
    demi = LARGEUR_UTILE / 2
    lignes, spans, courant = [], [], []

    def cellule(libelle, valeur):
        return [Paragraph(_esc(libelle.upper()), styles['label']), Paragraph(valeur, styles['valeur'])]

    for libelle, valeur, pleine in champs:
        if pleine:
            if courant:
                lignes.append(courant + [''])
                courant = []
            spans.append(len(lignes))
            lignes.append([cellule(libelle, valeur), ''])
            continue
        courant.append(cellule(libelle, valeur))
        if len(courant) == 2:
            lignes.append(courant)
            courant = []
    if courant:
        lignes.append(courant + [''])
    table = Table(lignes, colWidths=[demi, demi])
    commandes = [
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 2.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4.5),
    ]
    commandes += [('SPAN', (0, i), (1, i)) for i in spans]
    table.setStyle(TableStyle(commandes))
    return table


def _liste(elements: list[tuple[str, str, Pastille | None]], styles, vide: str):
    """Liste soignée : intitulé en gras, détail discret, pastille de statut alignée à droite."""
    if not elements:
        return Paragraph(vide, styles['vide'])
    largeur_pastille = 34 * mm
    lignes = [
        [[Paragraph(titre, styles['element']), Paragraph(detail, styles['detail'])], pastille or '']
        for titre, detail, pastille in elements
    ]
    table = Table(lignes, colWidths=[LARGEUR_UTILE - largeur_pastille, largeur_pastille])
    commandes = [
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('LEFTPADDING', (0, 0), (0, -1), 3 * mm),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LINEBEFORE', (0, 0), (0, -1), 1.2, colors.HexColor('#cfe3d6')),
    ]
    for i in range(len(lignes) - 1):
        commandes.append(('LINEBELOW', (0, i), (-1, i), 0.4, BORDURE, 0, (1, 2)))
    table.setStyle(TableStyle(commandes))
    return table


def _section(titre: str, contenu, complement: str = '') -> list:
    return [CondPageBreak(30 * mm), KeepTogether([TitreSection(titre, complement), Spacer(1, 2.5 * mm), contenu]),
            Spacer(1, 6 * mm)]


# =============================================================================
# Mise en page
# =============================================================================

def _rendre(story: list, *, titre: str, type_document: str, reference: str, mention: str) -> bytes:
    police, gras = _polices()
    tampon = BytesIO()
    logo = base._logo_path()

    def pied(c, doc):
        c.setFillColor(VERT_FONCE)
        c.rect(0, 0, LARGEUR_PAGE, HAUTEUR_PIED, fill=1, stroke=0)
        c.setFillColor(OR)
        c.rect(0, HAUTEUR_PIED, LARGEUR_PAGE, 0.6 * mm, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont(police, 7.2)
        c.drawString(MARGE, 8.2 * mm, mention[:150])
        c.setFillColor(colors.HexColor('#b9cfc2'))
        c.setFont(police, 6.4)
        c.drawString(
            MARGE, 4.2 * mm,
            f'ENEF · Plateforme PFNL · {reference} · Document à usage institutionnel, ne pas diffuser '
            'hors du circuit habilité',
        )
        c.setFillColor(colors.white)
        c.setFont(gras, 7.2)
        c.drawRightString(LARGEUR_PAGE - MARGE, 8.2 * mm, f'Page {doc.page}')

    def logo_sur(c, x, y, taille):
        c.setFillColor(colors.white)
        c.roundRect(x, y, taille, taille, 2 * mm, fill=1, stroke=0)
        if logo:
            try:
                c.drawImage(str(logo), x + 1.2 * mm, y + 1.2 * mm, taille - 2.4 * mm, taille - 2.4 * mm,
                            preserveAspectRatio=True, anchor='c', mask='auto')
            except Exception:
                pass

    def premiere_page(c, doc):
        c.saveState()
        haut = HAUTEUR_PAGE - HAUTEUR_ENTETE_1
        c.setFillColor(VERT_FONCE)
        c.rect(0, haut, LARGEUR_PAGE, HAUTEUR_ENTETE_1, fill=1, stroke=0)
        c.setFillColor(colors.HexColor('#124d2f'))
        c.circle(LARGEUR_PAGE - 28 * mm, HAUTEUR_PAGE + 4 * mm, 34 * mm, fill=1, stroke=0)
        c.setFillColor(OR)
        c.rect(0, haut - 1.1 * mm, LARGEUR_PAGE, 1.1 * mm, fill=1, stroke=0)
        logo_sur(c, MARGE, haut + 6 * mm, 24 * mm)
        tx = MARGE + 30 * mm
        c.setFillColor(OR)
        c.setFont(gras, 7.6)
        c.drawString(tx, haut + 24.5 * mm, 'RÉPUBLIQUE GABONAISE')
        c.setFillColor(colors.white)
        c.setFont(gras, 13)
        c.drawString(tx, haut + 18 * mm, 'École Nationale des Eaux et Forêts')
        c.setFillColor(colors.HexColor('#cfe0d6'))
        c.setFont(police, 7.8)
        c.drawString(tx, haut + 13 * mm, 'Plateforme nationale de traçabilité')
        c.drawString(tx, haut + 9.4 * mm, 'des produits forestiers non ligneux (PFNL)')
        c.setFillColor(colors.white)
        c.setFont(gras, 10.5)
        c.drawRightString(LARGEUR_PAGE - MARGE, haut + 20 * mm, type_document.upper())
        c.setFillColor(OR)
        c.setFont(gras, 8.4)
        c.drawRightString(LARGEUR_PAGE - MARGE, haut + 14.5 * mm, f'Réf. {reference}')
        c.setFillColor(colors.HexColor('#cfe0d6'))
        c.setFont(police, 7)
        maintenant = timezone.localtime()
        c.drawRightString(LARGEUR_PAGE - MARGE, haut + 10 * mm, f'Édition du {maintenant:%d/%m/%Y}')
        pied(c, doc)
        c.restoreState()

    def pages_suivantes(c, doc):
        c.saveState()
        haut = HAUTEUR_PAGE - HAUTEUR_ENTETE_N
        c.setFillColor(VERT_FONCE)
        c.rect(0, haut, LARGEUR_PAGE, HAUTEUR_ENTETE_N, fill=1, stroke=0)
        c.setFillColor(OR)
        c.rect(0, haut - 0.8 * mm, LARGEUR_PAGE, 0.8 * mm, fill=1, stroke=0)
        logo_sur(c, MARGE, haut + 2.5 * mm, 10 * mm)
        c.setFillColor(colors.white)
        c.setFont(gras, 9)
        c.drawString(MARGE + 13 * mm, haut + 6 * mm, titre[:80])
        c.setFillColor(OR)
        c.setFont(gras, 7.6)
        c.drawRightString(LARGEUR_PAGE - MARGE, haut + 6 * mm, f'{type_document} · Réf. {reference}')
        pied(c, doc)
        c.restoreState()

    bas = HAUTEUR_PIED + 7 * mm
    cadre_1 = Frame(MARGE, bas, LARGEUR_UTILE, HAUTEUR_PAGE - HAUTEUR_ENTETE_1 - 8 * mm - bas,
                    leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id='premiere')
    cadre_n = Frame(MARGE, bas, LARGEUR_UTILE, HAUTEUR_PAGE - HAUTEUR_ENTETE_N - 8 * mm - bas,
                    leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id='suite')
    doc = BaseDocTemplate(
        tampon, pagesize=A4, title=titre, author='École Nationale des Eaux et Forêts',
        subject=f'Plateforme PFNL : {type_document.lower()}', creator='PFNL',
    )
    doc.addPageTemplates([
        PageTemplate(id='premiere', frames=[cadre_1], onPage=premiere_page),
        PageTemplate(id='suite', frames=[cadre_n], onPage=pages_suivantes),
    ])
    doc.build([NextPageTemplate('suite')] + story)
    return tampon.getvalue()


def _note_finale(styles, mention: str) -> Paragraph:
    return Paragraph(
        'Fiche établie à partir des données enregistrées sur la plateforme PFNL à la date d’impression. '
        f'{_esc(mention)}. Toute modification ultérieure de la fiche rend ce document caduc.',
        styles['note'],
    )


def _url_frontend(chemin: str) -> str:
    return f"{getattr(settings, 'PNLF_FRONTEND_URL', '').rstrip('/')}{chemin}"


def _documents_par_type(entite_type: str, entite_id) -> dict:
    from traceability.models import DocumentInscription

    docs = {}
    for doc in DocumentInscription.objects.filter(entite_type=entite_type, entite_id=entite_id):
        docs.setdefault(doc.type_document, doc)
    return docs


def _ligne_documents(docs: dict, *, libelle_cni: str | None = None) -> str:
    morceaux = []
    for code, libelle in DOCUMENTS_ATTENDUS:
        if code == 'CNI' and libelle_cni:
            libelle = libelle_cni
        doc = docs.get(code)
        if doc:
            fmt = doc.chemin.rsplit('.', 1)[-1].upper() if '.' in doc.chemin else ''
            morceaux.append(
                f'<font color="#146b3f">\u25cf</font> {_esc(libelle)} : fourni'
                f'{f" ({fmt}, le {_date(doc.created_at)})" if fmt else ""}'
            )
        else:
            morceaux.append(f'<font color="#c9a227">\u25cb</font> {_esc(libelle)} : non fourni')
    return '<br/>'.join(morceaux)


def _elements_certifications(certs) -> list:
    aujourd_hui = timezone.localdate()
    elements = []
    for cert in certs:
        statut = cert.statut
        if statut == 'OBTENUE' and cert.date_expiration and cert.date_expiration < aujourd_hui:
            statut = 'EXPIREE'
        details = []
        if cert.numero_certificat:
            details.append(f'N° {cert.numero_certificat}')
        if cert.date_obtention:
            details.append(f'obtenue le {_date(cert.date_obtention)}')
        if cert.date_expiration:
            details.append(f'valable jusqu’au {_date(cert.date_expiration)}')
        if not details:
            details.append(f'demandée le {_date(cert.date_demande)}')
        titre = f'<b>{_esc(cert.type_certification.libelle)}</b>'
        if getattr(cert, 'producteur_id', None) and getattr(cert, '_afficher_titulaire', False):
            titre += f' · {_esc(_nom_personne(cert.producteur.prenoms, cert.producteur.nom))}'
        elements.append((
            titre, _esc(' · '.join(details)),
            Pastille(STATUT_CERTIFICATION_FR.get(statut, statut), TON_STATUT_CERTIFICATION.get(statut, 'neutre')),
        ))
    return elements


def _elements_lots(lots, *, avec_producteur: bool = False) -> list:
    elements = []
    for lot in lots:
        titre = f'<b>{_esc(lot.code_lot or "Lot sans code")}</b> · {_esc(lot.produit.nom)}'
        details = [_quantite(lot.quantite, lot.unite), f'collecté le {_date(lot.date_collecte)}']
        if lot.zone_collecte_id:
            details.append(lot.zone_collecte.libelle)
        if avec_producteur:
            details.append(_nom_personne(lot.producteur.prenoms, lot.producteur.nom))
        elements.append((
            titre, _esc(' · '.join(d for d in details if d)),
            Pastille(base.STATUT_LOT_FR.get(lot.statut, lot.statut), TON_STATUT_LOT.get(lot.statut, 'neutre')),
        ))
    return elements


def _certifs_valides(qs) -> int:
    return qs.filter(statut='OBTENUE').filter(
        Q(date_expiration__isnull=True) | Q(date_expiration__gte=timezone.localdate())
    ).count()


# =============================================================================
# Fiche producteur / collecteur
# =============================================================================

def fiche_producteur_pdf(producteur, *, masquer_contacts: bool, masquer_piece: bool, utilisateur=None) -> bytes:
    from traceability.db_utils import get_optional_column
    from traceability.models import Certification, CooperativeMembre, Lot, ProducteurProduit
    from traceability.serializers import LIBELLES_PIECE_IDENTITE

    styles = _styles()
    mention = mention_impression(utilisateur)
    type_acteur = get_optional_column('producteurs', 'type_acteur', producteur.id, default='PRODUCTEUR')
    libelle_type = 'Collecteur' if type_acteur == 'COLLECTEUR' else 'Producteur'
    visible = bool(get_optional_column('producteurs', 'visible_public', producteur.id, default=True))
    nom_complet = _nom_personne(producteur.prenoms, producteur.nom)

    lots_qs = Lot.objects.filter(producteur_id=producteur.id, deleted_at__isnull=True)
    nb_lots = lots_qs.count()
    nb_commercialises = lots_qs.filter(statut='COMMERCIALISE').count()
    lots_recents = list(
        lots_qs.select_related('produit', 'zone_collecte').order_by('-date_collecte', '-created_at')[:8]
    )
    produits = list(
        ProducteurProduit.objects.filter(producteur_id=producteur.id)
        .order_by('-principal', 'produit__nom').values_list('produit__nom', flat=True)
    )
    for nom in lots_qs.order_by('produit__nom').values_list('produit__nom', flat=True).distinct():
        if nom not in produits:
            produits.append(nom)
    certs_qs = Certification.objects.filter(producteur_id=producteur.id)
    certs = list(certs_qs.select_related('type_certification').order_by('-date_demande')[:8])
    adhesion = CooperativeMembre.objects.filter(
        producteur_id=producteur.id, cooperative_id=producteur.cooperative_id, actif=True,
    ).first() if producteur.cooperative_id else None
    docs = _documents_par_type('PRODUCTEUR', producteur.id)

    statut = base.STATUT_PRODUCTEUR_FR.get(producteur.statut, producteur.statut)
    pastilles = [Pastille(statut, TON_STATUT_FICHE.get(producteur.statut, 'neutre'))]
    if producteur.cooperative_id:
        pastilles.append(Pastille('Membre de coopérative', 'info'))
    else:
        pastilles.append(Pastille('Indépendant', 'neutre'))
    lignes = [f'Code <b>{_esc(producteur.code_producteur)}</b> · inscrit le {_date(producteur.created_at)}']
    if producteur.cooperative_id:
        lignes.append(f'Coopérative : <b>{_esc(producteur.cooperative.nom)}</b>')
    lieu = ', '.join(filter(None, [
        producteur.communaute,
        getattr(producteur.village, 'nom', None) if producteur.village_id else None,
        getattr(producteur.province, 'nom', None),
    ]))
    if lieu:
        lignes.append(_esc(lieu))

    public = producteur.statut == 'ACTIF' and visible
    qr = _url_frontend(f'/annuaire/{producteur.id}' if public else f'/app/producteurs/{producteur.id}')
    story: list = [
        CarteIdentite(
            image=_image_recadree(_photo_locale('producteurs', producteur.id), 0.8),
            initiales=_initiales(f'{producteur.prenoms} {producteur.nom}'),
            surtitre=f'Fiche {libelle_type.lower()}', titre=nom_complet, pastilles=pastilles,
            lignes=lignes, qr_valeur=qr, qr_legende=producteur.code_producteur,
        ),
        Spacer(1, 5 * mm),
        BandeauIndicateurs([
            (nb_lots, 'Lots enregistrés'),
            (nb_commercialises, 'Lots commercialisés'),
            (len(produits), 'Produits exploités'),
            (_certifs_valides(certs_qs), 'Certifications valides'),
        ]),
        Spacer(1, 7 * mm),
    ]

    naissance = None
    if producteur.date_naissance:
        today = timezone.localdate()
        age = today.year - producteur.date_naissance.year - (
            (today.month, today.day) < (producteur.date_naissance.month, producteur.date_naissance.day)
        )
        naissance = f'{_date(producteur.date_naissance)} ({age} ans)'
    story += _section('Identité', _grille([
        ('Nom', _valeur(producteur.nom.upper()), False),
        ('Prénoms', _valeur(producteur.prenoms), False),
        ('Date de naissance', _valeur(naissance, masque=masquer_contacts), False),
        ('Type d’acteur', _valeur(libelle_type), False),
        ('Téléphone', _valeur(producteur.telephone, masque=masquer_contacts), False),
        ('Adresse e-mail', _valeur(producteur.email, masque=masquer_contacts), False),
    ], styles))

    story += _section('Activité', _grille([
        ('Statut de la fiche', _valeur(statut), False),
        ('Validée le', _valeur(_date(producteur.valide_at)), False),
        ('Produits exploités', _valeur(', '.join(produits)), True),
        ('Annuaire public', _valeur('Fiche visible' if public else 'Fiche non publiée'), False),
        ('Inscrite le', _valeur(_date(producteur.created_at)), False),
    ], styles))

    if producteur.latitude is not None and producteur.longitude is not None:
        if masquer_contacts:
            gps = f'{round(producteur.latitude, 2)}, {round(producteur.longitude, 2)} (position approximative)'
        else:
            gps = f'Latitude {producteur.latitude:.6f} · Longitude {producteur.longitude:.6f}'
    else:
        gps = None
    story += _section('Localisation', _grille([
        ('Province', _valeur(getattr(producteur.province, 'nom', None)), False),
        ('Département', _valeur(getattr(producteur.departement, 'nom', None) if producteur.departement_id else None), False),
        ('Village', _valeur(getattr(producteur.village, 'nom', None) if producteur.village_id else None), False),
        ('Communauté / lieu d’usage', _valeur(producteur.communaute), False),
        ('Coordonnées GPS', _valeur(gps), True),
    ], styles))

    if producteur.cooperative_id:
        coop = producteur.cooperative
        champs_coop = [
            ('Coopérative', _valeur(coop.nom), False),
            ('Code', _valeur(coop.code), False),
            ('Membre depuis le', _valeur(_date(adhesion.date_adhesion) if adhesion else None), False),
            ('Agrément de la coopérative', _valeur(coop.numero_agrement), False),
        ]
    else:
        champs_coop = [('Rattachement', _valeur('Aucune coopérative (acteur indépendant)'), True)]
    story += _section('Coopérative', _grille(champs_coop, styles))

    numero = producteur.numero_piece
    if numero and masquer_piece:
        numero = _masquer_numero(numero)
    type_piece = LIBELLES_PIECE_IDENTITE.get(producteur.type_piece_identite, producteur.type_piece_identite)
    story += _section('Pièce d’identité et justificatifs', _grille([
        ('Type de pièce', _valeur(type_piece, masque=masquer_contacts), False),
        ('Numéro', _valeur(numero, masque=masquer_contacts), False),
        ('Pièces justificatives', _valeur(None, masque=True) if masquer_contacts else _ligne_documents(docs), True),
    ], styles))

    story += _section(
        'Certifications', _liste(_elements_certifications(certs), styles, 'Aucune certification enregistrée.'),
    )
    story += _section(
        'Lots récents',
        _liste(_elements_lots(lots_recents), styles, 'Aucun lot déclaré à ce jour.'),
        complement=f'{len(lots_recents)} sur {nb_lots} lot{"s" if nb_lots > 1 else ""} de ce '
                   f'{libelle_type.lower()}' if nb_lots else '',
    )
    story.append(_note_finale(styles, mention))
    return _rendre(
        story, titre=f'Fiche {libelle_type.lower()} : {nom_complet}',
        type_document=f'Fiche {libelle_type.lower()}', reference=producteur.code_producteur, mention=mention,
    )


# =============================================================================
# Fiche coopérative
# =============================================================================

def fiche_cooperative_pdf(cooperative, *, masquer_contacts: bool, utilisateur=None) -> bytes:
    from accounts.models import Utilisateur
    from traceability.db_utils import get_optional_column
    from traceability.models import Certification, CooperativeMembre, Lot, ProducteurProduit

    styles = _styles()
    mention = mention_impression(utilisateur)
    membres = list(
        CooperativeMembre.objects.filter(
            cooperative_id=cooperative.id, actif=True, producteur__deleted_at__isnull=True,
        ).select_related('producteur', 'producteur__province').order_by('producteur__nom', 'producteur__prenoms')
    )
    ids_membres = [m.producteur_id for m in membres]
    lots_qs = Lot.objects.filter(deleted_at__isnull=True).filter(
        Q(cooperative_id=cooperative.id) | Q(producteur__cooperative_id=cooperative.id)
    )
    nb_lots = lots_qs.count()
    nb_commercialises = lots_qs.filter(statut='COMMERCIALISE').count()
    lots_recents = list(
        lots_qs.select_related('produit', 'producteur', 'zone_collecte').order_by('-date_collecte', '-created_at')[:8]
    )
    produits = []
    for nom in lots_qs.values('produit__nom').annotate(n=Count('id')).order_by('-n', 'produit__nom').values_list(
        'produit__nom', flat=True,
    ):
        produits.append(nom)
    for nom in ProducteurProduit.objects.filter(producteur_id__in=ids_membres).order_by('produit__nom').values_list(
        'produit__nom', flat=True,
    ).distinct():
        if nom not in produits:
            produits.append(nom)
    certs_qs = Certification.objects.filter(
        Q(producteur_id__in=ids_membres) | Q(lot__in=lots_qs)
    ).distinct()
    certs = list(certs_qs.select_related('type_certification', 'producteur').order_by('-date_demande')[:8])
    for cert in certs:
        cert._afficher_titulaire = True
    responsable = Utilisateur.objects.filter(pk=cooperative.utilisateur_id).first() if cooperative.utilisateur_id else None
    docs = _documents_par_type('COOPERATIVE', cooperative.id)

    statut = base.STATUT_COOPERATIVE_FR.get(cooperative.statut, cooperative.statut)
    if cooperative.statut == 'ACTIF':
        statut = 'Active'
    elif cooperative.statut == 'INACTIF':
        statut = 'Inactive'
    elif cooperative.statut == 'REJETE':
        statut = 'Rejetée'
    pastilles = [Pastille(statut, TON_STATUT_FICHE.get(cooperative.statut, 'neutre'))]
    if cooperative.numero_agrement:
        pastilles.append(Pastille('Agréée', 'info'))
    lignes = [f'Code <b>{_esc(cooperative.code)}</b> · créée le {_date(cooperative.created_at)}']
    siege = ', '.join(filter(None, [cooperative.adresse, getattr(cooperative.province, 'nom', None)]))
    if siege:
        lignes.append(f'Siège : {_esc(siege)}')
    lignes.append(f'<b>{len(membres)}</b> membre{"s" if len(membres) > 1 else ""} actif{"s" if len(membres) > 1 else ""}')

    story: list = [
        CarteIdentite(
            image=_image_recadree(_photo_locale('cooperatives', cooperative.id), 1.0),
            initiales=_initiales(cooperative.nom), surtitre='Fiche coopérative', titre=cooperative.nom,
            pastilles=pastilles, lignes=lignes, qr_valeur=_url_frontend(f'/app/cooperatives/{cooperative.id}'),
            qr_legende=cooperative.code, ratio_photo=1.0,
        ),
        Spacer(1, 5 * mm),
        BandeauIndicateurs([
            (len(membres), 'Membres actifs'),
            (nb_lots, 'Lots coopérative et membres'),
            (nb_commercialises, 'Lots commercialisés'),
            (_certifs_valides(certs_qs), 'Certifications valides'),
        ]),
        Spacer(1, 7 * mm),
    ]

    story += _section('Identité', _grille([
        ('Dénomination', _valeur(cooperative.nom), True),
        ('Code', _valeur(cooperative.code), False),
        ('Numéro d’agrément', _valeur(cooperative.numero_agrement), False),
        ('Statut', _valeur(statut), False),
        ('Créée le', _valeur(_date(cooperative.created_at)), False),
    ], styles))
    story += _section('Siège et contact', _grille([
        ('Adresse du siège', _valeur(cooperative.adresse), True),
        ('Province', _valeur(getattr(cooperative.province, 'nom', None)), False),
        ('Téléphone', _valeur(cooperative.telephone), False),
        ('Adresse e-mail', _valeur(cooperative.email), False),
        ('Dernière mise à jour', _valeur(_date(cooperative.updated_at)), False),
    ], styles))
    if responsable is not None:
        nom_responsable = _nom_personne(responsable.prenoms, responsable.nom)
        champs_responsable = [
            ('Compte gestionnaire', _valeur(nom_responsable), False),
            ('Adresse e-mail du compte', _valeur(responsable.email, masque=masquer_contacts), False),
            ('Téléphone du compte', _valeur(responsable.telephone, masque=masquer_contacts), False),
            ('Compte créé le', _valeur(_date(responsable.created_at)), False),
        ]
    else:
        champs_responsable = [('Compte gestionnaire', _valeur('Aucun compte lié à cette coopérative'), True)]
    story += _section('Responsable', _grille(champs_responsable, styles))
    story += _section('Agrément et justificatifs', _grille([
        ('Numéro d’agrément', _valeur(cooperative.numero_agrement), False),
        ('Statut du dossier', _valeur(statut), False),
        ('Pièces justificatives', _valeur(None, masque=True) if masquer_contacts else _ligne_documents(
            docs, libelle_cni='Pièce d’identité du responsable',
        ), True),
    ], styles))
    story += _section('Produits', Paragraph(
        _valeur(', '.join(produits)) if produits else
        '<font color="#a3aea8">Aucun produit déclaré par la coopérative ou ses membres.</font>',
        styles['valeur'],
    ))

    elements_membres = []
    for m in membres[:60]:
        p = m.producteur
        type_m = get_optional_column('producteurs', 'type_acteur', p.id, default='PRODUCTEUR')
        details = [
            'Collecteur' if type_m == 'COLLECTEUR' else 'Producteur',
            ', '.join(filter(None, [p.communaute, getattr(p.province, 'nom', None)])),
            f'membre depuis le {_date(m.date_adhesion)}',
        ]
        if not masquer_contacts and p.telephone:
            details.append(p.telephone)
        elements_membres.append((
            f'<b>{_esc(_nom_personne(p.prenoms, p.nom))}</b> · {_esc(p.code_producteur)}',
            _esc(' · '.join(d for d in details if d)),
            Pastille(base.STATUT_PRODUCTEUR_FR.get(p.statut, p.statut), TON_STATUT_FICHE.get(p.statut, 'neutre')),
        ))
    complement = f'{len(membres)} membre{"s" if len(membres) > 1 else ""} actif{"s" if len(membres) > 1 else ""}'
    if len(membres) > 60:
        complement += ' (60 premiers affichés)'
    story += _section('Membres', _liste(elements_membres, styles, 'Aucun membre actif enregistré.'),
                      complement=complement if membres else '')
    story += _section(
        'Certifications', _liste(_elements_certifications(certs), styles, 'Aucune certification enregistrée.'),
    )
    story += _section(
        'Lots récents',
        _liste(_elements_lots(lots_recents, avec_producteur=True), styles, 'Aucun lot enregistré à ce jour.'),
        complement=f'{len(lots_recents)} sur {nb_lots} lot{"s" if nb_lots > 1 else ""} de la coopérative '
                   'et de ses membres' if nb_lots else '',
    )
    story.append(_note_finale(styles, mention))
    return _rendre(
        story, titre=f'Fiche coopérative : {cooperative.nom}', type_document='Fiche coopérative',
        reference=cooperative.code, mention=mention,
    )
