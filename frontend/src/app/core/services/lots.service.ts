import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Lot, LotPublicComplet, Mouvement } from '../models/lot.model';

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

  /** Tout lot est créé en brouillon : il devient vérifiable publiquement après validation. */
  create(payload: Partial<Lot>): Observable<Lot> {
    return this.http.post<Lot>(this.base, payload);
  }

  update(id: string, payload: Partial<Lot>): Observable<Lot> {
    return this.http.patch<Lot>(`${this.base}${id}/`, payload);
  }

  /** Brouillon vers Validé : autorité habilitée, ou titulaire disposant d'une certification active. */
  valider(id: string): Observable<Lot> {
    return this.http.post<Lot>(`${this.base}${id}/valider/`, {});
  }

  /** Validé vers Commercialisé : titulaire du lot ou autorité. */
  commercialiser(id: string, motif?: string): Observable<Lot> {
    return this.http.post<Lot>(`${this.base}${id}/commercialiser/`, motif ? { motif } : {});
  }

  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}${id}/`);
  }

  qrDownloadUrl(id: string): string {
    return `${this.base}${id}/qr/`;
  }

  uploadPhotos(id: string, files: File[]): Observable<Lot> {
    const form = new FormData();
    files.slice(0, 2).forEach((file) => form.append('photos', file));
    return this.http.post<Lot>(`${this.base}${id}/photos/`, form);
  }

  deletePhoto(id: string, photoUrl: string): Observable<Lot> {
    const match = photoUrl.match(/_(\d)\.jpg(?:$|\?)/);
    const index = match ? match[1] : '1';
    return this.http.delete<Lot>(`${this.base}${id}/photos/`, { params: { index } });
  }

  ajouterMouvement(lotId: string, payload: Partial<Mouvement>): Observable<Mouvement> {
    return this.http.post<Mouvement>(`${environment.apiUrl}/mouvements/`, {
      ...payload,
      lot: lotId,
    });
  }

  /** Vérification publique par QR code (lots validés ou commercialisés). */
  verifyPublic(uuid: string): Observable<LotPublicComplet> {
    return this.http.get<LotPublicComplet>(`${environment.apiUrl}/verify/${uuid}/`);
  }
}
