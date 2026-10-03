import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Certification, TypeCertification } from '../models/certification.model';

@Injectable({ providedIn: 'root' })
export class CertificationsService {
  private readonly base = `${environment.apiUrl}/certifications/`;

  constructor(private readonly http: HttpClient) {}

  list(params: Record<string, string> = {}): Observable<ApiListResponse<Certification>> {
    return this.http.get<ApiListResponse<Certification>>(this.base, {
      params: { page_size: '50', ...params },
    });
  }

  types(): Observable<ApiListResponse<TypeCertification>> {
    return this.http.get<ApiListResponse<TypeCertification>>(
      `${environment.apiUrl}/types-certification/`,
      { params: { page_size: '50' } },
    );
  }

  create(payload: Partial<Certification>): Observable<Certification> {
    return this.http.post<Certification>(this.base, payload);
  }

  /** Demande accompagnée de pièces justificatives (multipart : ``pieces`` et ``intitules`` dans le même ordre). */
  createAvecPieces(
    payload: Record<string, string>,
    pieces: { fichier: File; intitule: string }[],
  ): Observable<Certification> {
    const form = new FormData();
    for (const [cle, valeur] of Object.entries(payload)) {
      if (valeur) form.append(cle, valeur);
    }
    this.ajouterAuFormulaire(form, pieces);
    return this.http.post<Certification>(this.base, form);
  }

  ajouterPieces(id: string, pieces: { fichier: File; intitule: string }[]): Observable<Certification> {
    const form = new FormData();
    this.ajouterAuFormulaire(form, pieces);
    return this.http.post<Certification>(`${this.base}${id}/pieces/`, form);
  }

  retirerPiece(id: string, pieceId: string): Observable<Certification> {
    return this.http.delete<Certification>(`${this.base}${id}/pieces/${pieceId}/`);
  }

  private ajouterAuFormulaire(form: FormData, pieces: { fichier: File; intitule: string }[]): void {
    for (const piece of pieces) {
      form.append('pieces', piece.fichier, piece.fichier.name);
      form.append('intitules', piece.intitule.trim());
    }
  }

  valider(id: string, numeroCertificat?: string): Observable<Certification> {
    return this.http.post<Certification>(`${this.base}${id}/valider/`, {
      numero_certificat: numeroCertificat || '',
    });
  }

  refuser(id: string, motif?: string): Observable<Certification> {
    return this.http.post<Certification>(`${this.base}${id}/refuser/`, { motif: motif || '' });
  }

  update(id: string, payload: Partial<Certification>): Observable<Certification> {
    return this.http.patch<Certification>(`${this.base}${id}/`, payload);
  }

  get(id: string): Observable<Certification> {
    return this.http.get<Certification>(`${this.base}${id}/`);
  }

  uploadDocument(id: string, file: File): Observable<Certification> {
    const form = new FormData();
    form.append('document', file);
    return this.http.post<Certification>(`${this.base}${id}/document/`, form);
  }
}
