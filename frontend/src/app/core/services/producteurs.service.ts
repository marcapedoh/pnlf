import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Producteur } from '../models/producteur.model';
import { MessagePublic } from '../models/public.model';

export interface ProducteurQueryParams {
  page?: number;
  page_size?: number;
  search?: string;
  province?: string;
  statut?: string;
  type_acteur?: string;
  cooperative?: string;
  candidats_adhesion?: string;
  hors_cooperative?: string;
}

@Injectable({ providedIn: 'root' })
export class ProducteursService {
  private readonly base = `${environment.apiUrl}/producteurs/`;

  constructor(private readonly http: HttpClient) {}

  list(params: ProducteurQueryParams = {}): Observable<ApiListResponse<Producteur>> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.get<ApiListResponse<Producteur>>(this.base, { params: httpParams });
  }

  get(id: string): Observable<Producteur> {
    return this.http.get<Producteur>(`${this.base}${id}/`);
  }

  create(payload: Partial<Producteur>): Observable<Producteur> {
    return this.http.post<Producteur>(this.base, payload);
  }

  update(id: string, payload: Partial<Producteur>): Observable<Producteur> {
    return this.http.patch<Producteur>(`${this.base}${id}/`, payload);
  }

  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}${id}/`);
  }

  valider(id: string): Observable<Producteur> {
    return this.http.post<Producteur>(`${this.base}${id}/valider/`, {});
  }

  rejeter(id: string, motif?: string): Observable<Producteur> {
    return this.http.post<Producteur>(`${this.base}${id}/rejeter/`, { motif });
  }

  desactiver(id: string): Observable<Producteur> {
    return this.http.post<Producteur>(`${this.base}${id}/desactiver/`, {});
  }

  activer(id: string): Observable<Producteur> {
    return this.http.post<Producteur>(`${this.base}${id}/activer/`, {});
  }

  uploadPhoto(id: string, file: File): Observable<Producteur> {
    const form = new FormData();
    form.append('photo', file);
    return this.http.post<Producteur>(`${this.base}${id}/photo/`, form);
  }

  messagesPublics(producteurId: string): Observable<ApiListResponse<MessagePublic>> {
    return this.http.get<ApiListResponse<MessagePublic>>(`${environment.apiUrl}/messages-publics/`, {
      params: { producteur: producteurId, page_size: '20' },
    });
  }

  marquerMessageTraite(messageId: string): Observable<MessagePublic> {
    return this.http.post<MessagePublic>(`${environment.apiUrl}/messages-publics/${messageId}/marquer_traite/`, {});
  }

  createFichePdfTicket(id: string): Observable<{ url: string }> {
    return this.http.post<{ url: string }>(`${this.base}${id}/pdf/`, {});
  }

  createListePdfTicket(params: ProducteurQueryParams = {}): Observable<{ url: string }> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.post<{ url: string }>(`${this.base}pdf-liste/`, {}, { params: httpParams });
  }
}
