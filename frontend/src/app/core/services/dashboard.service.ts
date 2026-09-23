import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { AJAX_EXPORT_HEADERS } from '../http/download-file.util';
import { DashboardStats } from '../models/dashboard.model';

export type JournalGranularite = 'jour' | 'semaine' | 'mois';
export type ExportFormat = 'csv' | 'xlsx' | 'pdf';

export interface JournalPeriode {
  date: string;
  libelle: string;
  nb_evenements: number;
  nb_utilisateurs: number;
}

export interface JournalEvent {
  id: number;
  created_at: string;
  action: string;
  table_cible: string | null;
  enregistrement_id: string | null;
  ip_adresse: string | null;
  utilisateur: string;
  utilisateur_id?: string | null;
}

export interface JournalFiltres {
  utilisateur_id?: string;
  action?: string;
  q?: string;
  date_debut?: string;
  date_fin?: string;
}

export interface JournalDetail {
  granularite: JournalGranularite;
  date: string;
  date_fin?: string;
  libelle: string;
  count: number;
  results: JournalEvent[];
  filtres?: JournalFiltres;
}

@Injectable({ providedIn: 'root' })
export class DashboardService {
  constructor(private readonly http: HttpClient) {}

  stats(params: Record<string, string> = {}): Observable<DashboardStats> {
    return this.http.get<DashboardStats>(`${environment.apiUrl}/dashboard/stats/`, { params });
  }

  exportUrl(format: ExportFormat): string {
    return `${environment.apiUrl}/exports/lots/?export_format=${format}`;
  }

  journalPeriodes(
    granularite: JournalGranularite,
    filtres: Pick<JournalFiltres, 'date_debut' | 'date_fin' | 'q'> = {},
  ): Observable<{ granularite: string; results: JournalPeriode[] }> {
    const params: Record<string, string> = { granularite };
    if (filtres.date_debut) params['date_debut'] = filtres.date_debut;
    if (filtres.date_fin) params['date_fin'] = filtres.date_fin;
    if (filtres.q) params['q'] = filtres.q;
    return this.http.get<{ granularite: string; results: JournalPeriode[] }>(
      `${environment.apiUrl}/rapports/journal/`,
      { params },
    );
  }

  journalDetail(
    granularite: JournalGranularite,
    date: string | null,
    page = 1,
    pageSize = 25,
    filtres: JournalFiltres = {},
  ): Observable<JournalDetail> {
    const params: Record<string, string> = {
      granularite,
      page: String(page),
      page_size: String(pageSize),
    };
    if (date) params['date'] = date;
    this._appendFiltres(params, filtres);
    return this.http.get<JournalDetail>(`${environment.apiUrl}/rapports/journal/detail/`, { params });
  }

  journalExportUrl(
    granularite: JournalGranularite,
    date: string | null,
    format: ExportFormat,
    filtres: JournalFiltres = {},
  ): string {
    const params = new URLSearchParams({ granularite, export_format: format });
    if (date) params.set('date', date);
    if (filtres.utilisateur_id) params.set('utilisateur_id', filtres.utilisateur_id);
    if (filtres.action) params.set('action', filtres.action);
    if (filtres.q) params.set('q', filtres.q);
    if (filtres.date_debut) params.set('date_debut', filtres.date_debut);
    if (filtres.date_fin) params.set('date_fin', filtres.date_fin);
    return `${environment.apiUrl}/exports/journal/?${params.toString()}`;
  }

  /** Récupère le PDF des lots en Blob authentifié (pour aperçu via PdfPreviewService). */
  lotsPdfBlob(): Observable<Blob> {
    return this.http.post(
      `${environment.apiUrl}/exports/lots/ticket/`,
      {},
      { responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }

  /** Récupère le PDF du journal en Blob authentifié (pour aperçu via PdfPreviewService). */
  journalPdfBlob(
    granularite: JournalGranularite,
    date: string | null,
    filtres: JournalFiltres = {},
  ): Observable<Blob> {
    const body: Record<string, string> = { granularite };
    if (date) body['date'] = date;
    if (filtres.utilisateur_id) body['utilisateur_id'] = filtres.utilisateur_id;
    if (filtres.action) body['action'] = filtres.action;
    if (filtres.q) body['q'] = filtres.q;
    if (filtres.date_debut) body['date_debut'] = filtres.date_debut;
    if (filtres.date_fin) body['date_fin'] = filtres.date_fin;
    return this.http.post(
      `${environment.apiUrl}/exports/journal/ticket/`,
      body,
      { responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }

  aTraiter(): Observable<InboxValidation> {
    return this.http.get<InboxValidation>(`${environment.apiUrl}/dashboard/a-traiter/`);
  }

  private _appendFiltres(params: Record<string, string>, filtres: JournalFiltres): void {
    if (filtres.utilisateur_id) params['utilisateur_id'] = filtres.utilisateur_id;
    if (filtres.action) params['action'] = filtres.action;
    if (filtres.q) params['q'] = filtres.q;
    if (filtres.date_debut) params['date_debut'] = filtres.date_debut;
    if (filtres.date_fin) params['date_fin'] = filtres.date_fin;
  }
}

export interface InboxItem {
  id: string;
  nom?: string;
  prenoms?: string;
  code_producteur?: string;
  code?: string;
  titre?: string;
  type_annonce?: string;
  type_libelle?: string;
  producteur_nom?: string;
  statut?: string;
  created_at: string;
}

export interface InboxValidation {
  producteurs: { count: number; results: InboxItem[] };
  cooperatives: { count: number; results: InboxItem[] };
  certifications: { count: number; results: InboxItem[] };
  offres: { count: number; results: InboxItem[] };
  acheteurs?: { count: number; results: InboxItem[] };
}
