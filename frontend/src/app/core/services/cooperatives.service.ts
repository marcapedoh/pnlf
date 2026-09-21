import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Cooperative } from '../models/producteur.model';

export interface CooperativeQueryParams {
  page?: number;
  page_size?: number;
  search?: string;
  province?: string;
  statut?: string;
  actif?: string;
}

@Injectable({ providedIn: 'root' })
export class CooperativesService {
  private readonly base = `${environment.apiUrl}/cooperatives/`;

  constructor(private readonly http: HttpClient) {}

  list(params: CooperativeQueryParams = {}): Observable<ApiListResponse<Cooperative>> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.get<ApiListResponse<Cooperative>>(this.base, { params: httpParams });
  }

  get(id: string): Observable<Cooperative> {
    return this.http.get<Cooperative>(`${this.base}${id}/`);
  }

  create(payload: Partial<Cooperative>): Observable<Cooperative> {
    return this.http.post<Cooperative>(this.base, payload);
  }

  update(id: string, payload: Partial<Cooperative>): Observable<Cooperative> {
    return this.http.patch<Cooperative>(`${this.base}${id}/`, payload);
  }

  valider(id: string): Observable<Cooperative> {
    return this.http.post<Cooperative>(`${this.base}${id}/valider/`, {});
  }

  rejeter(id: string, motif?: string): Observable<Cooperative> {
    return this.http.post<Cooperative>(`${this.base}${id}/rejeter/`, { motif });
  }

  desactiver(id: string): Observable<Cooperative> {
    return this.http.post<Cooperative>(`${this.base}${id}/desactiver/`, {});
  }

  activer(id: string): Observable<Cooperative> {
    return this.http.post<Cooperative>(`${this.base}${id}/activer/`, {});
  }

  uploadPhoto(id: string, file: File): Observable<Cooperative> {
    const form = new FormData();
    form.append('photo', file);
    return this.http.post<Cooperative>(`${this.base}${id}/photo/`, form);
  }

  membres(id: string): Observable<CooperativeMembre[]> {
    return this.http.get<CooperativeMembre[]>(`${this.base}${id}/membres/`);
  }

  ajouterMembre(id: string, payload: { producteur: string; date_adhesion?: string }): Observable<CooperativeMembre> {
    return this.http.post<CooperativeMembre>(`${this.base}${id}/membres/`, payload);
  }

  retirerMembre(id: string, producteur: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}${id}/membres/retirer/`, { producteur });
  }

  demanderAdhesion(id: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}${id}/demander-adhesion/`, {});
  }

  createFichePdfTicket(id: string): Observable<{ url: string }> {
    return this.http.post<{ url: string }>(`${this.base}${id}/pdf/`, {});
  }

  createListePdfTicket(params: CooperativeQueryParams = {}): Observable<{ url: string }> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.post<{ url: string }>(`${this.base}pdf-liste/`, {}, { params: httpParams });
  }
}

export interface CooperativeMembre {
  cooperative: string;
  producteur: string;
  producteur_nom: string;
  date_adhesion: string;
  actif: boolean;
  created_at: string;
}
