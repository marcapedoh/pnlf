import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { OffreDemande } from '../models/notification.model';
import { Cooperative, Producteur } from '../models/producteur.model';

export interface AnnuaireResponse {
  producteurs: Producteur[];
  cooperatives: Cooperative[];
}

@Injectable({ providedIn: 'root' })
export class MarketplaceService {
  constructor(private readonly http: HttpClient) {}

  annuaire(params: Record<string, string> = {}): Observable<AnnuaireResponse> {
    return this.http.get<AnnuaireResponse>(`${environment.apiUrl}/annuaire/`, { params });
  }

  offres(params: Record<string, string> = {}): Observable<ApiListResponse<OffreDemande>> {
    return this.http.get<ApiListResponse<OffreDemande>>(`${environment.apiUrl}/offres-demandes/`, {
      params: { page_size: '50', ...params },
    });
  }

  creerOffre(payload: Partial<OffreDemande>): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(`${environment.apiUrl}/offres-demandes/`, payload);
  }
}
