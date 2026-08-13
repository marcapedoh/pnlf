"""Dashboard, exports, sync offline, notifications."""

from __future__ import annotations

import csv
import io
import uuid
from datetime import datetime

from django.db import connection
from django.http import HttpResponse
from django.utils import timezone

from traceability.models import Lot, Producteur, Produit


def dashboard_stats(*, province_id=None, produit_id=None, date_debut=None, date_fin=None) -> dict:
    """Agrégats dashboard — vues SQL si disponibles, sinon ORM."""
    lots_rows, prod_rows, mvt_rows = [], [], []
    try:
        params: list = []
        clauses_lots = ['1=1']
        if province_id:
            clauses_lots.append('province_id = %s')
            params.append(str(province_id))
        if produit_id:
            clauses_lots.append('produit_id = %s')
            params.append(str(produit_id))
        where = ' AND '.join(clauses_lots)
        with connection.cursor() as cur:
            cur.execute(
                f'SELECT province_nom, produit_nom, statut, periode_mois, nb_lots, quantite_totale, unite '
                f'FROM v_dashboard_lots WHERE {where} ORDER BY periode_mois DESC LIMIT 500',
                params,
            )
            lots_rows = [
                {'province': r[0], 'produit': r[1], 'statut': r[2],
                 'periode': r[3].isoformat() if r[3] else None,
                 'nb_lots': r[4], 'quantite': float(r[5]), 'unite': r[6]}
                for r in cur.fetchall()
            ]
            cur.execute('SELECT province_nom, type_acteur, statut, nombre FROM v_dashboard_producteurs ORDER BY province_nom')
            prod_rows = [
                {'province': r[0], 'type_acteur': r[1], 'statut': r[2], 'nombre': r[3]}
                for r in cur.fetchall()
            ]
            cur.execute(
                'SELECT type_mouvement, periode_mois, nb_mouvements FROM v_dashboard_mouvements ORDER BY periode_mois DESC LIMIT 200'
            )
            mvt_rows = [
                {'type': r[0], 'periode': r[1].isoformat() if r[1] else None, 'nombre': r[2]}
                for r in cur.fetchall()
            ]
    except Exception:
        from django.db.models import Count, Sum
        from traceability.models import Mouvement

        qs_lots = Lot.objects.filter(deleted_at__isnull=True)
        if province_id:
            qs_lots = qs_lots.filter(producteur__province_id=province_id)
        if produit_id:
            qs_lots = qs_lots.filter(produit_id=produit_id)
        lots_rows = list(
            qs_lots.values('producteur__province__nom', 'produit__nom', 'statut')
            .annotate(nb_lots=Count('id'), quantite_totale=Sum('quantite'))[:100]
        )
        prod_rows = list(
            Producteur.objects.filter(deleted_at__isnull=True)
            .values('province__nom', 'statut')
            .annotate(nombre=Count('id'))
        )
        mvt_rows = list(
            Mouvement.objects.filter(lot__deleted_at__isnull=True)
            .values('type_mouvement').annotate(nombre=Count('id'))[:50]
        )

    return {
        'producteurs': prod_rows,
        'lots': lots_rows,
        'mouvements': mvt_rows,
        'totaux': {
            'producteurs_actifs': Producteur.objects.filter(deleted_at__isnull=True, statut='ACTIF').count(),
            'lots_actifs': Lot.objects.filter(deleted_at__isnull=True).count(),
            'produits_referentiel': Produit.objects.filter(actif=True).count(),
        },
    }


def export_lots_csv(queryset) -> HttpResponse:
    response = HttpResponse(content_type='text/csv; charset=utf-8')
    response['Content-Disposition'] = f'attachment; filename="lots_pnlf_{datetime.now():%Y%m%d}.csv"'
    response.write('\ufeff')
    w = csv.writer(response)
    w.writerow(['code_lot', 'uuid_public', 'produit', 'producteur', 'date_collecte', 'quantite', 'unite', 'statut'])
    for lot in queryset.select_related('produit', 'producteur'):
        w.writerow([
            lot.code_lot, lot.uuid_public, lot.produit.nom,
            f'{lot.producteur.prenoms} {lot.producteur.nom}',
            lot.date_collecte, lot.quantite, lot.unite, lot.statut,
        ])
    return response


def export_lots_xlsx(queryset) -> HttpResponse:
    from openpyxl import Workbook

    wb = Workbook()
    ws = wb.active
    ws.title = 'Lots PNLF'
    ws.append(['code_lot', 'uuid_public', 'produit', 'producteur', 'date_collecte', 'quantite', 'unite', 'statut'])
    for lot in queryset.select_related('produit', 'producteur'):
        ws.append([
            lot.code_lot, str(lot.uuid_public), lot.produit.nom,
            f'{lot.producteur.prenoms} {lot.producteur.nom}',
            str(lot.date_collecte), float(lot.quantite), lot.unite, lot.statut,
        ])
    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    response = HttpResponse(
        buf.read(),
        content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    )
    response['Content-Disposition'] = f'attachment; filename="lots_pnlf_{datetime.now():%Y%m%d}.xlsx"'
    return response


def export_lots_pdf(queryset) -> HttpResponse:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas

    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    y = 800
    c.setFont('Helvetica-Bold', 14)
    c.drawString(40, y, 'Export lots PNLF')
    y -= 30
    c.setFont('Helvetica', 9)
    for lot in queryset.select_related('produit', 'producteur')[:100]:
        line = f'{lot.code_lot} | {lot.produit.nom} | {lot.quantite} {lot.unite} | {lot.statut}'
        c.drawString(40, y, line[:110])
        y -= 14
        if y < 60:
            c.showPage()
            y = 800
    c.save()
    buf.seek(0)
    response = HttpResponse(buf.read(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="lots_pnlf_{datetime.now():%Y%m%d}.pdf"'
    return response


def creer_notification(destinataire_id, titre: str, corps: str, *, metadata=None) -> uuid.UUID:
    nid = uuid.uuid4()
    now = timezone.now()
    with connection.cursor() as cur:
        cur.execute(
            """
            INSERT INTO notifications (id, destinataire_id, type_notif, titre, corps, metadata, created_at)
            VALUES (%s, %s, 'INTERNE', %s, %s, %s::jsonb, %s)
            """,
            [str(nid), str(destinataire_id), titre, corps, __import__('json').dumps(metadata or {}), now],
        )
    return nid
