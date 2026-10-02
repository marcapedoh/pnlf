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

export interface ConversationResume {
  id: string;
  sujet?: string | null;
  offre_id?: string | null;
  interlocuteur_nom?: string;
  dernier_message?: string | null;
  dernier_at?: string | null;
  non_lus?: number;
}

@Injectable({ providedIn: 'root' })
export class MarketplaceService {
  private readonly base = `${environment.apiUrl}/offres-demandes/`;

  constructor(private readonly http: HttpClient) {}

  annuaire(params: Record<string, string> = {}): Observable<AnnuaireResponse> {
    return this.http.get<AnnuaireResponse>(`${environment.apiUrl}/annuaire/`, { params });
  }

  offres(params: Record<string, string> = {}): Observable<ApiListResponse<OffreDemande>> {
    return this.http.get<ApiListResponse<OffreDemande>>(this.base, {
      params: { page_size: '12', ...params },
    });
  }

  get(id: string): Observable<OffreDemande> {
    return this.http.get<OffreDemande>(`${this.base}${id}/`);
  }

  creerOffre(payload: Partial<OffreDemande>): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(this.base, payload);
  }

  uploadPhotos(id: string, files: File[]): Observable<OffreDemande> {
    const form = new FormData();
    files.forEach((f) => form.append('photos', f));
    return this.http.post<OffreDemande>(`${this.base}${id}/photos/`, form);
  }

  valider(id: string): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(`${this.base}${id}/valider/`, {});
  }

  rejeter(id: string, motif?: string): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(`${this.base}${id}/rejeter/`, { motif });
  }

  cloturer(id: string): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(`${this.base}${id}/cloturer/`, {});
  }

  ouvrirConversation(payload: { sujet?: string; offre_id?: string; producteur_id?: string; destinataire_id?: string }): Observable<{ id: string }> {
    return this.http.post<{ id: string }>(`${environment.apiUrl}/conversations/`, payload);
  }

  conversations(params: Record<string, string> = {}): Observable<ApiListResponse<ConversationResume>> {
    return this.http.get<ApiListResponse<ConversationResume>>(
      `${environment.apiUrl}/conversations/`,
      { params },
    );
  }

  messages(conversationId: string): Observable<{ id: string; contenu: string | null; expediteur_id: string; created_at: string; piece_type?: string | null; piece_url?: string | null }[]> {
    return this.http.get<{ id: string; contenu: string | null; expediteur_id: string; created_at: string; piece_type?: string | null; piece_url?: string | null }[]>(
      `${environment.apiUrl}/conversations/${conversationId}/messages/`,
    );
  }

  envoyerMessage(conversationId: string, contenu: string): Observable<unknown> {
    return this.http.post(`${environment.apiUrl}/conversations/${conversationId}/messages/`, { contenu });
  }
}
