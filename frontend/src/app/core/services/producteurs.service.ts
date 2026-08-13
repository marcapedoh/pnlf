import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Producteur } from '../models/producteur.model';

export interface ProducteurQueryParams {
  page?: number;
  page_size?: number;
  search?: string;
  province?: string;
  statut?: string;
  type_acteur?: string;
  cooperative?: string;
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
}
