import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from '../http/http-context-tokens';
import { AJAX_EXPORT_HEADERS } from '../http/download-file.util';
import {
  FiltresRapport,
  LigneConnexion,
  PageResultats,
  PresenceEnLigne,
  RapportExportable,
  ResumeTableauDeBord,
  StatistiquesConnexions,
  StatistiquesFiliere,
  StatistiquesInscriptions,
} from '../models/rapports.model';

export type FormatExport = 'csv' | 'xlsx' | 'pdf';

function nettoyer(params: object): Record<string, string> {
  const resultat: Record<string, string> = {};
  for (const [cle, valeur] of Object.entries(params)) {
    if (valeur !== undefined && valeur !== null && String(valeur).trim() !== '') resultat[cle] = String(valeur).trim();
  }
  return resultat;
}

/** Rapports statistiques intégrés (aucun service tiers) et synthèse du tableau de bord. */
@Injectable({ providedIn: 'root' })
export class RapportsService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/rapports`;

  connexions(filtres: FiltresRapport): Observable<StatistiquesConnexions> {
    return this.http.get<StatistiquesConnexions>(`${this.base}/connexions/`, { params: nettoyer(filtres) });
  }

  listeConnexions(
    filtres: FiltresRapport & { succes?: '1' | '0' | ''; page?: number; page_size?: number },
  ): Observable<PageResultats<LigneConnexion>> {
    return this.http.get<PageResultats<LigneConnexion>>(`${this.base}/connexions/liste/`, { params: nettoyer(filtres) });
  }

  enLigne(silencieux = false): Observable<PresenceEnLigne> {
    const context = silencieux
      ? new HttpContext().set(SKIP_LOADING_BAR, true).set(SKIP_GLOBAL_ERROR_TOAST, true)
      : undefined;
    return this.http.get<PresenceEnLigne>(`${this.base}/en-ligne/`, { context });
  }

  inscriptions(
    filtres: FiltresRapport & { type_demande?: string; statut?: string; page?: number; page_size?: number },
  ): Observable<StatistiquesInscriptions> {
    return this.http.get<StatistiquesInscriptions>(`${this.base}/inscriptions/`, { params: nettoyer(filtres) });
  }

  filiere(filtres: FiltresRapport & { province?: string; produit?: string }): Observable<StatistiquesFiliere> {
    return this.http.get<StatistiquesFiliere>(`${this.base}/filiere/`, { params: nettoyer(filtres) });
  }

  exportUrl(rapport: RapportExportable, format: Exclude<FormatExport, 'pdf'>, filtres: object): string {
    const params = new URLSearchParams({ ...nettoyer(filtres), export_format: format });
    return `${environment.apiUrl}/exports/rapports/${rapport}/?${params.toString()}`;
  }

  pdf(rapport: RapportExportable, filtres: object): Observable<Blob> {
    return this.http.post(`${environment.apiUrl}/exports/rapports/${rapport}/`, {}, {
      params: nettoyer(filtres),
      responseType: 'blob',
      headers: AJAX_EXPORT_HEADERS,
    });
  }

  lotsExportUrl(format: Exclude<FormatExport, 'pdf'>, filtres: object): string {
    const params = new URLSearchParams({ ...nettoyer(filtres), export_format: format });
    return `${environment.apiUrl}/exports/lots/?${params.toString()}`;
  }

  lotsPdf(filtres: object): Observable<Blob> {
    return this.http.post(`${environment.apiUrl}/exports/lots/ticket/`, nettoyer(filtres), {
      responseType: 'blob',
      headers: AJAX_EXPORT_HEADERS,
    });
  }

  resume(silencieux = false): Observable<ResumeTableauDeBord> {
    const context = silencieux
      ? new HttpContext().set(SKIP_LOADING_BAR, true).set(SKIP_GLOBAL_ERROR_TOAST, true)
      : undefined;
    return this.http.get<ResumeTableauDeBord>(`${environment.apiUrl}/dashboard/resume/`, { context });
  }
}
