"""Impression PDF d'une conversation complète (supervision réservée à l'administrateur)."""

from __future__ import annotations

from io import BytesIO

from django.utils import timezone
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas as rl_canvas
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from pnlf_platform import pdf_export as base

MESSAGES_MAX = 5000

JOURS_FR = ('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche')
MOIS_FR = (
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
)
STATUT_OFFRE_FR = {
    'EN_VALIDATION': 'En attente de validation',
    'OUVERTE': 'Publiée',
    'CLOTUREE': 'Clôturée',
    'REJETEE': 'Rejetée',
    'ANNULEE': 'Annulée',
}
FORMAT_AUDIO_FR = {'.webm': 'WebM', '.ogg': 'Ogg', '.m4a': 'M4A', '.mp4': 'M4A', '.aac': 'AAC', '.mp3': 'MP3', '.wav': 'WAV'}


def _jour_long(d) -> str:
    texte = f'{JOURS_FR[d.weekday()]} {d.day} {MOIS_FR[d.month - 1]} {d.year}'
    return texte[0].upper() + texte[1:]


def _date_heure(value) -> str:
    return timezone.localtime(value).strftime('%d/%m/%Y à %H:%M') if value else '-'


def _canvas_numerote(pied: str):
    """Canvas qui connaît le nombre total de pages (« Page x sur y ») et dessine le bandeau ENEF."""

    class CanvasNumerote(rl_canvas.Canvas):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._etats_pages = []

        def showPage(self):
            self._etats_pages.append(dict(self.__dict__))
            self._startPage()

        def save(self):
            total = len(self._etats_pages)
            for etat in self._etats_pages:
                self.__dict__.update(etat)
                self._decorer(total)
                super().showPage()
            super().save()

        def _decorer(self, total: int) -> None:
            width, height = A4
            self.saveState()
            self.setFillColor(base.GOLD)
            self.rect(0, height - 2.8 * mm, width, 2.8 * mm, fill=1, stroke=0)
            self.setFillColor(base.GREEN_DARK)
            self.rect(0, 0, width, 11 * mm, fill=1, stroke=0)
            self.setFillColor(base.GOLD)
            self.rect(0, 11 * mm, width, 0.6 * mm, fill=1, stroke=0)
            self.setFillColor(colors.white)
            self.setFont(base.FONT, 7)
            self.drawString(16 * mm, 4.5 * mm, pied[:115])
            self.drawRightString(width - 16 * mm, 4.5 * mm, f'Page {self._pageNumber} sur {total}')
            self.restoreState()

    return CanvasNumerote


def _styles_messages(styles):
    return {
        'jour': ParagraphStyle(
            'PNLFJour', parent=styles['cell'], fontName=base.FONT_BOLD, fontSize=8,
            textColor=base.GREEN_DARK, leading=10,
        ),
        'heure': ParagraphStyle('PNLFHeure', parent=styles['cell_center'], textColor=base.MUTED),
        'auteur': ParagraphStyle('PNLFAuteur', parent=styles['cell'], leading=10),
        'texte': ParagraphStyle('PNLFTexte', parent=styles['cell'], fontSize=8, leading=11),
    }


def _contexte(conv, ctx, offre) -> str:
    if ctx is not None and ctx.est_groupe:
        return 'Groupe de coopérative'
    if offre is not None or conv.offre_id:
        return 'Échange lié à une annonce'
    if ctx is not None and ctx.producteur_id:
        return 'Discussion ouverte depuis une fiche producteur'
    if ctx is not None and ctx.cooperative_id:
        return 'Discussion ouverte depuis une fiche coopérative'
    return 'Discussion privée'


def _bloc_annonce(styles, offre) -> list:
    from accounts.models import Utilisateur
    from pnlf_platform.chat import nom_utilisateur
    from pnlf_platform.offre_statut import read_statut
    from traceability.models import Produit

    produit = Produit.objects.filter(pk=offre.produit_id).values_list('nom', flat=True).first()
    auteur = Utilisateur.objects.filter(pk=offre.auteur_id).first()
    quantite = ''
    if offre.quantite is not None:
        quantite = f'{offre.quantite:.3f}'.rstrip('0').rstrip('.') + (f' {offre.unite}' if offre.unite else '')
    prix = f'{offre.prix_unitaire:,.0f}'.replace(',', ' ') + f' {offre.devise}' if offre.prix_unitaire is not None else ''
    statut = read_statut(offre)
    rows = [
        ('Type', 'Offre de vente' if offre.type_annonce == 'OFFRE' else 'Demande d’achat'),
        ('Titre', offre.titre),
        ('Produit', produit or 'Non renseigné'),
        ('Quantité', quantite or 'Non renseignée'),
        ('Prix unitaire', prix or 'Non renseigné'),
        ('Statut', STATUT_OFFRE_FR.get(statut, statut or '-')),
        ('Auteur', nom_utilisateur(auteur) if auteur else 'Compte supprimé'),
        ('Publiée le', _date_heure(offre.created_at)),
    ]
    return [
        Spacer(1, 10),
        Paragraph('Annonce liée', styles['title']),
        base._identite_table(styles, rows),
    ]


def conversation_pdf_bytes(conv, *, imprime_par) -> tuple[bytes, str]:
    from pathlib import Path

    from accounts.models import Utilisateur
    from pnlf_platform.chat import PLACEHOLDERS, nom_utilisateur, profils_utilisateurs
    from pnlf_platform.models import (
        ConversationContext, ConversationParticipant, Message, MessagePiece, OffreDemande,
    )
    from traceability.models import Cooperative, Producteur

    styles = base._styles()
    styles_msg = _styles_messages(styles)
    now = timezone.localtime()

    participations = list(
        ConversationParticipant.objects.filter(conversation=conv).order_by('joined_at')
    )
    messages = list(Message.objects.filter(conversation=conv).order_by('created_at', 'id')[:MESSAGES_MAX + 1])
    tronque = len(messages) > MESSAGES_MAX
    messages = messages[:MESSAGES_MAX]
    pieces = {
        p.message_id: p
        for p in MessagePiece.objects.filter(message_id__in=[m.id for m in messages])
    }
    ids = {p.utilisateur_id for p in participations} | {m.expediteur_id for m in messages}
    users = {u.id: u for u in Utilisateur.objects.filter(id__in=list(ids) + [imprime_par.id])}
    profils = profils_utilisateurs(users.values())
    ctx = ConversationContext.objects.filter(conversation=conv).first()
    offre = OffreDemande.objects.filter(pk=conv.offre_id).first() if conv.offre_id else None

    profil_imprimeur = profils.get(str(imprime_par.id), {})
    imprime = (
        f'Imprimé par {nom_utilisateur(imprime_par)} ({profil_imprimeur.get("role_libelle", "Administrateur")}) '
        f'le {now:%d/%m/%Y} à {now:%H:%M}'
    )
    if messages:
        periode = f'Du {_date_heure(messages[0].created_at)} au {_date_heure(messages[-1].created_at)}'
    else:
        periode = 'Aucun message échangé'

    story: list = [
        base._header_table_portrait(styles, 'Supervision de la messagerie interne'),
        Spacer(1, 10),
        Paragraph(f'Conversation : {base._esc(conv.sujet or "Sans objet")}', styles['title']),
        base._identite_table(styles, [
            ('Nature', _contexte(conv, ctx, offre)),
            ('Ouverte le', _date_heure(conv.created_at)),
            ('Période des échanges', periode),
            ('Nombre de messages', str(len(messages)) + (' (limite d’impression atteinte)' if tronque else '')),
            ('Référence', str(conv.id)),
            ('Édition', imprime),
        ]),
    ]

    if ctx is not None and (ctx.producteur_id or ctx.cooperative_id):
        fiche = None
        if ctx.producteur_id:
            prod = Producteur.objects.filter(pk=ctx.producteur_id).first()
            fiche = f'Fiche producteur : {prod.prenoms} {prod.nom}'.strip() if prod else None
        if ctx.cooperative_id:
            coop = Cooperative.objects.filter(pk=ctx.cooperative_id).first()
            fiche = f'Coopérative : {coop.nom}' if coop else fiche
        if fiche:
            story.extend([Spacer(1, 4), Paragraph(base._esc(fiche), styles['meta'])])

    story.extend([Spacer(1, 10), Paragraph(f'Participants ({len(participations)})', styles['title'])])
    lignes_participants = []
    for p in participations:
        user = users.get(p.utilisateur_id)
        profil = profils.get(str(p.utilisateur_id), {})
        lignes_participants.append([
            nom_utilisateur(user) if user else 'Compte supprimé',
            profil.get('role_libelle') or '-',
            profil.get('organisation') or '-',
            _date_heure(p.joined_at),
        ])
    if lignes_participants:
        story.append(base._data_table(
            ['Nom', 'Rôle', 'Organisation', 'Dans la discussion depuis'],
            lignes_participants, [55 * mm, 35 * mm, 55 * mm, 33 * mm], styles, center_cols=(3,),
        ))
    else:
        story.append(Paragraph('Aucun participant enregistré.', styles['empty']))

    if offre is not None:
        story.extend(_bloc_annonce(styles, offre))

    story.extend([Spacer(1, 10), Paragraph('Messages, dans l’ordre chronologique', styles['title'])])
    if not messages:
        story.append(Paragraph('Aucun message dans cette conversation.', styles['empty']))
    else:
        entete = [base._cell(h, styles['th']) for h in ('Heure', 'Auteur', 'Message')]
        data = [entete]
        separateurs = []
        jour_courant = None
        for m in messages:
            local = timezone.localtime(m.created_at)
            if local.date() != jour_courant:
                jour_courant = local.date()
                separateurs.append(len(data))
                data.append([Paragraph(_jour_long(jour_courant), styles_msg['jour']), '', ''])
            user = users.get(m.expediteur_id)
            profil = profils.get(str(m.expediteur_id), {})
            auteur = (
                f'<b>{base._esc(nom_utilisateur(user) if user else "Compte supprimé")}</b>'
                f'<br/><font color="#5c6b63" size="6.5">{base._esc(profil.get("role_libelle") or "")}</font>'
            )
            morceaux = []
            piece = pieces.get(m.id)
            if piece is not None:
                if piece.piece_type == 'IMAGE':
                    morceaux.append('<font color="#5c6b63">[Photo jointe]</font>')
                else:
                    fmt = FORMAT_AUDIO_FR.get(Path(piece.piece_path).suffix.lower(), 'audio')
                    morceaux.append(f'<font color="#5c6b63">[Message vocal, format {fmt}]</font>')
            if m.contenu and m.contenu not in PLACEHOLDERS:
                morceaux.append(base._esc(m.contenu))
            data.append([
                Paragraph(local.strftime('%H:%M'), styles_msg['heure']),
                Paragraph(auteur, styles_msg['auteur']),
                Paragraph('<br/>'.join(morceaux) or '-', styles_msg['texte']),
            ])
        table = Table(data, colWidths=[16 * mm, 44 * mm, 118 * mm], repeatRows=1)
        commandes = [
            ('BACKGROUND', (0, 0), (-1, 0), base.GREEN),
            ('LINEBELOW', (0, 0), (-1, 0), 1.2, base.GOLD),
            ('GRID', (0, 0), (-1, -1), 0.25, base.BORDER),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 4),
            ('RIGHTPADDING', (0, 0), (-1, -1), 4),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]
        for ligne in separateurs:
            commandes.extend([
                ('SPAN', (0, ligne), (-1, ligne)),
                ('BACKGROUND', (0, ligne), (-1, ligne), colors.HexColor('#eef4f0')),
            ])
        table.setStyle(TableStyle(commandes))
        story.append(table)
        if tronque:
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                f'Seuls les {MESSAGES_MAX} premiers messages figurent dans ce document.', styles['meta'],
            ))

    story.extend([
        Spacer(1, 10),
        Paragraph(
            'Document confidentiel issu de la supervision de la messagerie interne. '
            'Les pièces jointes (photos, messages vocaux) sont mentionnées mais non reproduites.',
            styles['meta'],
        ),
    ])

    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf, pagesize=A4,
        leftMargin=16 * mm, rightMargin=16 * mm, topMargin=10 * mm, bottomMargin=16 * mm,
        title=f'Conversation : {conv.sujet or "Sans objet"}',
        author='École Nationale des Eaux et Forêts',
        subject='Plateforme PFNL : supervision de la messagerie',
        creator='PFNL',
    )
    doc.build(story, canvasmaker=_canvas_numerote(f'ENEF · Confidentiel · {imprime}'))
    filename = f'PFNL-conversation-{str(conv.id)[:8]}-{now:%Y%m%d-%H%M}.pdf'
    return buf.getvalue(), filename
