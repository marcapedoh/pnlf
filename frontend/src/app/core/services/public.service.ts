import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import {
  ContactPublicPayload,
  InscriptionPubliquePayload,
  InscriptionPubliqueResponse,
  MessagePublic,
  PublicDepartement,
  PublicLotDetail,
  PublicOffreDemande,
  PublicOffresResponse,
  PublicProducteur,
  PublicProducteursResponse,
  PublicProduit,
  PublicProvince,
  PublicStats,
  PublicVillage,
} from '../models/public.model';

export interface PublicProducteurQuery {
  province?: string;
  type_acteur?: string;
  produit?: string;
  q?: string;
  page?: number;
  page_size?: number;
}

@Injectable({ providedIn: 'root' })
export class PublicService {
  private readonly base = `${environment.apiUrl}/public`;

  constructor(private readonly http: HttpClient) {}

  stats(): Observable<PublicStats> {
    return this.http.get<PublicStats>(`${this.base}/stats/`);
  }

  provinces(): Observable<PublicProvince[]> {
    return this.http.get<PublicProvince[]>(`${this.base}/provinces/`);
  }

  produits(): Observable<PublicProduit[]> {
    return this.http.get<PublicProduit[]>(`${this.base}/produits/`);
  }

  producteurs(params: PublicProducteurQuery = {}): Observable<PublicProducteursResponse> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') httpParams[key] = String(value);
    });
    return this.http.get<PublicProducteursResponse>(`${this.base}/producteurs/`, { params: httpParams });
  }

  producteur(id: string): Observable<PublicProducteur> {
    return this.http.get<PublicProducteur>(`${this.base}/producteurs/${id}/`);
  }

  lot(id: string): Observable<PublicLotDetail> {
    return this.http.get<PublicLotDetail>(`${this.base}/lots/${id}/`);
  }

  offres(params: {
    q?: string;
    type_annonce?: string;
    province?: string;
    produit?: string;
    page?: number;
    page_size?: number;
  } = {}): Observable<PublicOffresResponse> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') httpParams[key] = String(value);
    });
    return this.http.get<PublicOffresResponse>(`${this.base}/offres-demandes/`, { params: httpParams });
  }

  offre(id: string): Observable<PublicOffreDemande> {
    return this.http.get<PublicOffreDemande>(`${this.base}/offres-demandes/${id}/`);
  }

  contacter(producteurId: string, payload: ContactPublicPayload): Observable<MessagePublic> {
    return this.http.post<MessagePublic>(`${this.base}/producteurs/${producteurId}/contact/`, payload);
  }

  contacterOffre(offreId: string, payload: { nom: string; email: string; telephone?: string; message: string; site_web?: string }): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}/offres-demandes/${offreId}/contact/`, payload);
  }

  departements(provinceId: string): Observable<PublicDepartement[]> {
    return this.http.get<PublicDepartement[]>(`${this.base}/departements/`, { params: { province: provinceId } });
  }

  villages(departementId: string): Observable<PublicVillage[]> {
    return this.http.get<PublicVillage[]>(`${this.base}/villages/`, { params: { departement: departementId } });
  }

  inscrire(payload: InscriptionPubliquePayload): Observable<InscriptionPubliqueResponse> {
    const form = new FormData();
    Object.entries(payload).forEach(([key, value]) => {
      if (value === undefined || value === null || value === '') return;
      form.append(key, value instanceof File ? value : String(value));
    });
    return this.http.post<InscriptionPubliqueResponse>(`${this.base}/inscription/`, form);
  }
}
