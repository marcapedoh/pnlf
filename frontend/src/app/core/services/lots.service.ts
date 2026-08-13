import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Lot, LotVerification, Mouvement } from '../models/lot.model';

export interface LotQueryParams {
  page?: number;
  page_size?: number;
  search?: string;
  statut?: string;
  produit?: string;
  producteur?: string;
}

@Injectable({ providedIn: 'root' })
export class LotsService {
  private readonly base = `${environment.apiUrl}/lots/`;

  constructor(private readonly http: HttpClient) {}

  list(params: LotQueryParams = {}): Observable<ApiListResponse<Lot>> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.get<ApiListResponse<Lot>>(this.base, { params: httpParams });
  }

  get(id: string): Observable<Lot> {
    return this.http.get<Lot>(`${this.base}${id}/`);
  }

  create(payload: Partial<Lot>): Observable<Lot> {
    return this.http.post<Lot>(this.base, payload);
  }

  update(id: string, payload: Partial<Lot>): Observable<Lot> {
    return this.http.patch<Lot>(`${this.base}${id}/`, payload);
  }

  changerStatut(id: string, statut: string, force = false): Observable<Lot> {
    return this.http.post<Lot>(`${this.base}${id}/changer-statut/`, { statut, force });
  }

  qrDownloadUrl(id: string): string {
    return `${this.base}${id}/qr/`;
  }

  ajouterMouvement(lotId: string, payload: Partial<Mouvement>): Observable<Mouvement> {
    return this.http.post<Mouvement>(`${environment.apiUrl}/mouvements/`, {
      ...payload,
      lot: lotId,
    });
  }

  verifyPublic(uuid: string): Observable<LotVerification> {
    return this.http.get<LotVerification>(`${environment.apiUrl}/verify/${uuid}/`);
  }
}
