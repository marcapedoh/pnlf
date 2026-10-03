import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { AJAX_EXPORT_HEADERS } from '../http/download-file.util';
import { ApiListResponse } from '../models/common.model';
import { CandidatInvitation, Cooperative, InvitationCooperative } from '../models/producteur.model';

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

  /** Demandes d'adhésion en attente (coopérative titulaire, administrateur, agent du ministère). */
  demandesAdhesion(id: string): Observable<CooperativeMembre[]> {
    return this.http.get<CooperativeMembre[]>(`${this.base}${id}/demandes-adhesion/`);
  }

  refuserAdhesion(id: string, producteur: string, motif?: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}${id}/membres/refuser/`, { producteur, motif });
  }

  /** Producteurs actifs sans coopérative correspondant à la recherche (2 caractères minimum). */
  candidatsInvitation(id: string, search: string): Observable<CandidatInvitation[]> {
    return this.http.get<CandidatInvitation[]>(`${this.base}${id}/candidats-invitation/`, { params: { search } });
  }

  invitations(id: string): Observable<InvitationCooperative[]> {
    return this.http.get<InvitationCooperative[]>(`${this.base}${id}/invitations/`);
  }

  inviter(id: string, producteur: string, message?: string): Observable<InvitationCooperative> {
    return this.http.post<InvitationCooperative>(`${this.base}${id}/invitations/`, { producteur, message });
  }

  annulerInvitation(id: string, invitationId: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}${id}/invitations/${invitationId}/annuler/`, {});
  }

  /** Invitations en attente reçues par le producteur connecté. */
  invitationsRecues(): Observable<InvitationCooperative[]> {
    return this.http.get<InvitationCooperative[]>(`${this.base}invitations-recues/`);
  }

  accepterInvitation(invitationId: string): Observable<{ detail: string; cooperative: string }> {
    return this.http.post<{ detail: string; cooperative: string }>(
      `${this.base}invitations-recues/${invitationId}/accepter/`,
      {},
    );
  }

  refuserInvitation(invitationId: string, motif?: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}invitations-recues/${invitationId}/refuser/`, { motif });
  }

  /** Récupère la fiche PDF de cette coopérative en Blob authentifié. */
  fichePdfBlob(id: string): Observable<Blob> {
    return this.http.post(
      `${this.base}${id}/pdf/`,
      {},
      { responseType: 'blob', headers: AJAX_EXPORT_HEADERS },
    );
  }

  /** Récupère la liste PDF des coopératives visibles en Blob authentifié. */
  listePdfBlob(params: CooperativeQueryParams = {}): Observable<Blob> {
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

export interface CooperativeMembre {
  cooperative: string;
  producteur: string;
  producteur_nom: string;
  producteur_code?: string;
  producteur_statut?: string;
  date_adhesion: string;
  actif: boolean;
  created_at: string;
}
