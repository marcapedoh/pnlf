"""Dashboard, exports, sync offline, notifications."""

from __future__ import annotations

import csv
import io
import uuid
from datetime import date, datetime, timedelta

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
    # Pas de Content-Disposition : ce fichier est récupéré en Blob via XHR/fetch
    # authentifié puis nommé côté client (voir triggerBrowserDownload). Ajouter cet
    # en-tête ferait intercepter la requête par les gestionnaires de téléchargement
    # tiers du navigateur (IDM, EagleGet...), qui renverraient une réponse vide.
    response = HttpResponse(content_type='text/csv; charset=utf-8')
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
    ws.title = 'Lots PFNL'
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
    return response


def export_lots_pdf(queryset) -> HttpResponse:
    from pnlf_platform.pdf_export import export_lots_pdf as _export_lots_pdf

    return _export_lots_pdf(queryset)


def _periode_bornes(granularite: str, date_ref):
    """Retourne (debut, fin exclusive, libelle) pour un jour / une semaine ISO / un mois."""
    from datetime import date, timedelta

    from django.utils.dateparse import parse_date

    if isinstance(date_ref, str):
        date_ref = parse_date(date_ref)
    if date_ref is None:
        date_ref = timezone.localdate()

    if granularite == 'semaine':
        debut = date_ref - timedelta(days=date_ref.weekday())
        fin = debut + timedelta(days=7)
        libelle = f'Semaine du {debut:%d/%m/%Y} au {(fin - timedelta(days=1)):%d/%m/%Y}'
    elif granularite == 'mois':
        debut = date(date_ref.year, date_ref.month, 1)
        if date_ref.month == 12:
            fin = date(date_ref.year + 1, 1, 1)
        else:
            fin = date(date_ref.year, date_ref.month + 1, 1)
        mois_fr = [
            '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
            'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
        ]
        libelle = f'{mois_fr[debut.month].capitalize()} {debut.year}'
    else:
        debut = date_ref
        fin = date_ref + timedelta(days=1)
        libelle = f'{debut:%d/%m/%Y}'
    return debut, fin, libelle


def _audit_rows(*, debut, fin, limit=2000, offset=0, utilisateur_id=None, action=None, q=None):
    """Liste paginée des événements d'audit, avec filtres optionnels (utilisateur, action, texte libre)."""
    where = ['a.created_at >= %s', 'a.created_at < %s']
    params: list = [debut, fin]
    if utilisateur_id:
        where.append('a.utilisateur_id = %s')
        params.append(utilisateur_id)
    if action:
        where.append('a.action = %s')
        params.append(action)
    if q:
        like = f'%{q.strip()}%'
        where.append(
            '(a.action ILIKE %s OR COALESCE(a.table_cible, \'\') ILIKE %s '
            'OR COALESCE(u.nom, \'\') ILIKE %s OR COALESCE(u.prenoms, \'\') ILIKE %s '
            'OR COALESCE(u.email::text, \'\') ILIKE %s)'
        )
        params.extend([like, like, like, like, like])
    where_sql = ' AND '.join(where)

    with connection.cursor() as cur:
        cur.execute(
            f"""
            SELECT a.id, a.created_at, a.action, a.table_cible, a.enregistrement_id,
                   a.ip_adresse::text, u.nom, u.prenoms, u.email, a.utilisateur_id
            FROM audit_logs a
            LEFT JOIN utilisateurs u ON u.id = a.utilisateur_id
            WHERE {where_sql}
            ORDER BY a.created_at DESC
            LIMIT %s OFFSET %s
            """,
            [*params, limit, offset],
        )
        cols = [
            'id', 'created_at', 'action', 'table_cible', 'enregistrement_id',
            'ip_adresse', 'nom', 'prenoms', 'email', 'utilisateur_id',
        ]
        rows = []
        for raw in cur.fetchall():
            item = dict(zip(cols, raw))
            nom = item.pop('nom')
            prenoms = item.pop('prenoms')
            email = item.pop('email')
            uid = item.pop('utilisateur_id')
            item['utilisateur'] = f'{prenoms or ""} {nom or ""}'.strip() or email or 'Système'
            item['utilisateur_id'] = str(uid) if uid else None
            if item['created_at']:
                item['created_at'] = timezone.localtime(item['created_at']).isoformat()
            if item['enregistrement_id']:
                item['enregistrement_id'] = str(item['enregistrement_id'])
            rows.append(item)
        cur.execute(
            f"""
            SELECT COUNT(*)
            FROM audit_logs a
            LEFT JOIN utilisateurs u ON u.id = a.utilisateur_id
            WHERE {where_sql}
            """,
            params,
        )
        total = cur.fetchone()[0]
    return rows, total


def journal_periodes(granularite: str, *, date_debut=None, date_fin=None, q=None) -> list[dict]:
    """Périodes disponibles ; filtres optionnels par plage de dates ou recherche textuelle sur le libellé."""
    from django.utils.dateparse import parse_date

    trunc = {'jour': 'day', 'semaine': 'week', 'mois': 'month'}.get(granularite, 'day')
    where = ['TRUE']
    params: list = [trunc]
    if date_debut:
        d = parse_date(date_debut) if isinstance(date_debut, str) else date_debut
        if d:
            where.append("(created_at AT TIME ZONE 'Africa/Libreville')::date >= %s")
            params.append(d)
    if date_fin:
        d = parse_date(date_fin) if isinstance(date_fin, str) else date_fin
        if d:
            where.append("(created_at AT TIME ZONE 'Africa/Libreville')::date <= %s")
            params.append(d)
    where_sql = ' AND '.join(where)

    with connection.cursor() as cur:
        cur.execute(
            f"""
            SELECT date_trunc(%s, created_at AT TIME ZONE 'Africa/Libreville')::date AS periode,
                   COUNT(*) AS nb_evenements,
                   COUNT(DISTINCT utilisateur_id) AS nb_utilisateurs
            FROM audit_logs
            WHERE {where_sql}
            GROUP BY 1
            ORDER BY 1 DESC
            LIMIT 120
            """,
            params,
        )
        out = []
        q_norm = (q or '').strip().lower()
        for periode, nb, nb_users in cur.fetchall():
            debut, fin, libelle = _periode_bornes(granularite, periode)
            if q_norm and q_norm not in libelle.lower() and q_norm not in debut.isoformat():
                continue
            out.append({
                'date': debut.isoformat(),
                'libelle': libelle,
                'nb_evenements': nb,
                'nb_utilisateurs': nb_users,
            })
    return out[:36]


def _resolve_journal_bornes(granularite, date_ref, date_debut=None, date_fin=None):
    """Résout la plage [debut, fin) et le libellé : plage libre ou granularité classique."""
    from django.utils.dateparse import parse_date

    if date_debut or date_fin:
        d0 = parse_date(date_debut) if isinstance(date_debut, str) else date_debut
        d1 = parse_date(date_fin) if isinstance(date_fin, str) else date_fin
        if d0 is None and d1 is None:
            return _periode_bornes(granularite, date_ref)
        if d0 is None:
            d0 = d1
        if d1 is None:
            d1 = d0
        if d1 < d0:
            d0, d1 = d1, d0
        # fin exclusive = lendemain de la date de fin inclusive
        fin = d1 + timedelta(days=1)
        if d0 == d1:
            libelle = f'{d0:%d/%m/%Y}'
        else:
            libelle = f'Du {d0:%d/%m/%Y} au {d1:%d/%m/%Y}'
        return d0, fin, libelle
    return _periode_bornes(granularite, date_ref)


def journal_detail(
    granularite: str,
    date_ref,
    *,
    page=1,
    page_size=25,
    utilisateur_id=None,
    action=None,
    q=None,
    date_debut=None,
    date_fin=None,
):
    debut, fin, libelle = _resolve_journal_bornes(granularite, date_ref, date_debut, date_fin)
    debut_dt = timezone.make_aware(datetime.combine(debut, datetime.min.time()))
    fin_dt = timezone.make_aware(datetime.combine(fin, datetime.min.time()))
    offset = (page - 1) * page_size
    rows, total = _audit_rows(
        debut=debut_dt, fin=fin_dt, limit=page_size, offset=offset,
        utilisateur_id=utilisateur_id, action=action, q=q,
    )
    return {
        'granularite': granularite,
        'date': debut.isoformat(),
        'date_fin': (fin - timedelta(days=1)).isoformat(),
        'libelle': libelle,
        'count': total,
        'results': rows,
        'filtres': {
            'utilisateur_id': str(utilisateur_id) if utilisateur_id else None,
            'action': action or None,
            'q': q or None,
        },
    }


def export_journal(
    granularite: str,
    date_ref,
    fmt: str,
    *,
    utilisateur_id=None,
    action=None,
    q=None,
    date_debut=None,
    date_fin=None,
) -> HttpResponse:
    debut, fin, libelle = _resolve_journal_bornes(granularite, date_ref, date_debut, date_fin)
    debut_dt = timezone.make_aware(datetime.combine(debut, datetime.min.time()))
    fin_dt = timezone.make_aware(datetime.combine(fin, datetime.min.time()))
    rows, _total = _audit_rows(
        debut=debut_dt, fin=fin_dt, limit=5000, offset=0,
        utilisateur_id=utilisateur_id, action=action, q=q,
    )
    headers = ['Date/heure', 'Action', 'Table', 'Enregistrement', 'Utilisateur', 'IP']

    def _line(r):
        created = r['created_at']
        try:
            created = datetime.fromisoformat(created).strftime('%d/%m/%Y %H:%M')
        except Exception:
            pass
        return [
            created,
            r.get('action') or '',
            r.get('table_cible') or '',
            r.get('enregistrement_id') or '',
            r.get('utilisateur') or '',
            r.get('ip_adresse') or '',
        ]

    if fmt == 'xlsx':
        from openpyxl import Workbook

        wb = Workbook()
        ws = wb.active
        ws.title = 'Journal'
        ws.append([libelle])
        ws.append(headers)
        for r in rows:
            ws.append(_line(r))
        buf = io.BytesIO()
        wb.save(buf)
        buf.seek(0)
        response = HttpResponse(
            buf.read(),
            content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
        return response

    if fmt == 'pdf':
        from pnlf_platform.pdf_export import export_journal_pdf

        return export_journal_pdf(rows, libelle)

    # Pas de Content-Disposition (voir export_lots_csv) : fichier récupéré en Blob XHR.
    response = HttpResponse(content_type='text/csv; charset=utf-8')
    response.write('\ufeff')
    w = csv.writer(response)
    w.writerow([libelle])
    w.writerow(headers)
    for r in rows:
        w.writerow(_line(r))
    return response


def generer_qr_offre(offre) -> str:
    """Génère le QR de vérification publique d'une offre/demande validée. Retourne le chemin relatif media."""
    from pathlib import Path

    from django.conf import settings

    payload = offre.qr_payload or f'PNLF-OD:{offre.uuid_public}'
    qr_dir = Path(settings.MEDIA_ROOT) / 'qr'
    qr_dir.mkdir(parents=True, exist_ok=True)
    filename = f'od-{offre.uuid_public}.png'
    filepath = qr_dir / filename

    import qrcode
    img = qrcode.make(payload)
    img.save(filepath)
    return f'qr/{filename}'


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
