import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import {
  CategorieProduit,
  Departement,
  Produit,
  Province,
  Village,
  ZoneCollecte,
} from '../models/reference.model';

@Injectable({ providedIn: 'root' })
export class ReferenceService {
  constructor(private readonly http: HttpClient) {}

  provinces(): Observable<ApiListResponse<Province>> {
    return this.http.get<ApiListResponse<Province>>(`${environment.apiUrl}/provinces/`, {
      params: { page_size: '50' },
    });
  }

  departements(provinceId?: string): Observable<ApiListResponse<Departement>> {
    return this.http.get<ApiListResponse<Departement>>(`${environment.apiUrl}/departements/`, {
      params: { page_size: '200', ...(provinceId ? { province: provinceId } : {}) },
    });
  }

  villages(departementId?: string): Observable<ApiListResponse<Village>> {
    return this.http.get<ApiListResponse<Village>>(`${environment.apiUrl}/villages/`, {
      params: { page_size: '500', ...(departementId ? { departement: departementId } : {}) },
    });
  }

  categories(): Observable<ApiListResponse<CategorieProduit>> {
    return this.http.get<ApiListResponse<CategorieProduit>>(
      `${environment.apiUrl}/categories-produit/`,
      { params: { page_size: '100' } },
    );
  }

  produits(): Observable<ApiListResponse<Produit>> {
    return this.http.get<ApiListResponse<Produit>>(`${environment.apiUrl}/produits/`, {
      params: { page_size: '200', actif: 'true' },
    });
  }

  zonesCollecte(params: Record<string, string> = {}): Observable<ApiListResponse<ZoneCollecte>> {
    return this.http.get<ApiListResponse<ZoneCollecte>>(`${environment.apiUrl}/zones-collecte/`, {
      params: { page_size: '50', ...params },
    });
  }
}
