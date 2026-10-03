import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { AJAX_EXPORT_HEADERS } from '../http/download-file.util';
import { ApiListResponse } from '../models/common.model';
import { DocumentInscription, Producteur, TypeDocumentInscription } from '../models/producteur.model';
import { MessagePublic } from '../models/public.model';

/** Charge utile d'écriture : les produits exploités s'envoient sous forme d'identifiants. */
export type ProducteurPayload = Omit<Partial<Producteur>, 'produits'> & { produits?: string[] };

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

  create(payload: ProducteurPayload): Observable<Producteur> {
    return this.http.post<Producteur>(this.base, payload);
  }

  update(id: string, payload: ProducteurPayload): Observable<Producteur> {
    return this.http.patch<Producteur>(`${this.base}${id}/`, payload);
  }

  documents(id: string): Observable<DocumentInscription[]> {
    return this.http.get<DocumentInscription[]>(`${this.base}${id}/documents/`);
  }

  /** Dépose ou remplace un justificatif (PDF, JPG ou PNG). Renvoie la liste à jour des documents. */
  uploadDocument(id: string, type: TypeDocumentInscription, file: File): Observable<DocumentInscription[]> {
    const form = new FormData();
    form.append('type_document', type);
    form.append('document', file);
    return this.http.post<DocumentInscription[]>(`${this.base}${id}/documents/`, form);
  }

  supprimerDocument(id: string, type: TypeDocumentInscription): Observable<DocumentInscription[]> {
    return this.http.delete<DocumentInscription[]>(`${this.base}${id}/documents/${type}/`);
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

  /** Récupère la fiche PDF de ce producteur/collecteur en Blob authentifié. */
  fichePdfBlob(id: string): Observable<Blob> {
    return this.http.post(
      `${this.base}${id}/pdf/`,
      {},
      { responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }

  /** Récupère la liste PDF des producteurs/collecteurs visibles en Blob authentifié. */
  listePdfBlob(params: ProducteurQueryParams = {}): Observable<Blob> {
    const httpParams: Record<string, string> = {};
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        httpParams[key] = String(value);
      }
    });
    return this.http.post(
      `${this.base}pdf-liste/`,
      {},
      { params: httpParams, responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }
}
