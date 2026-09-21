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
}

export interface JournalDetail {
  granularite: JournalGranularite;
  date: string;
  libelle: string;
  count: number;
  results: JournalEvent[];
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

  journalPeriodes(granularite: JournalGranularite): Observable<{ granularite: string; results: JournalPeriode[] }> {
    return this.http.get<{ granularite: string; results: JournalPeriode[] }>(
      `${environment.apiUrl}/rapports/journal/`,
      { params: { granularite } },
    );
  }

  journalDetail(granularite: JournalGranularite, date: string, page = 1, pageSize = 25): Observable<JournalDetail> {
    return this.http.get<JournalDetail>(`${environment.apiUrl}/rapports/journal/detail/`, {
      params: { granularite, date, page: String(page), page_size: String(pageSize) },
    });
  }

  journalExportUrl(granularite: JournalGranularite, date: string, format: ExportFormat): string {
    return `${environment.apiUrl}/exports/journal/?granularite=${granularite}&date=${date}&export_format=${format}`;
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
  journalPdfBlob(granularite: JournalGranularite, date: string): Observable<Blob> {
    return this.http.post(
      `${environment.apiUrl}/exports/journal/ticket/`,
      { granularite, date },
      { responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }

  aTraiter(): Observable<InboxValidation> {
    return this.http.get<InboxValidation>(`${environment.apiUrl}/dashboard/a-traiter/`);
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
