import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { AnnoncesFiltres, paramsAnnonces } from '../models/annonce.model';
import { ApiListResponse } from '../models/common.model';
import { OffreDemande } from '../models/notification.model';
import { Cooperative, Producteur } from '../models/producteur.model';

/** Annuaire interne : deux listes paginées côté serveur (`liste` permet de n'en recharger qu'une). */
export interface AnnuaireResponse {
  page_size: number;
  producteurs?: Producteur[];
  producteurs_count?: number;
  page_producteurs?: number;
  cooperatives?: Cooperative[];
  cooperatives_count?: number;
  page_cooperatives?: number;
}

export interface AnnuaireParams {
  q?: string;
  province?: string;
  page_producteurs?: number;
  page_cooperatives?: number;
  page_size?: number;
  liste?: 'producteurs' | 'cooperatives';
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

  annuaire(params: AnnuaireParams = {}): Observable<AnnuaireResponse> {
    const query: Record<string, string> = {};
    for (const [cle, valeur] of Object.entries(params)) {
      if (valeur !== undefined && valeur !== null && String(valeur).trim() !== '') query[cle] = String(valeur).trim();
    }
    return this.http.get<AnnuaireResponse>(`${environment.apiUrl}/annuaire/`, { params: query });
  }

  offres(params: Record<string, string> = {}): Observable<ApiListResponse<OffreDemande>> {
    return this.http.get<ApiListResponse<OffreDemande>>(this.base, {
      params: { page_size: '12', ...params },
    });
  }

  rechercher(filtres: AnnoncesFiltres): Observable<ApiListResponse<OffreDemande>> {
    return this.http.get<ApiListResponse<OffreDemande>>(this.base, { params: paramsAnnonces(filtres) });
  }

  get(id: string): Observable<OffreDemande> {
    return this.http.get<OffreDemande>(`${this.base}${id}/`);
  }

  creerOffre(payload: Partial<OffreDemande>): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(this.base, payload);
  }

  modifierOffre(id: string, payload: Partial<OffreDemande>): Observable<OffreDemande> {
    return this.http.patch<OffreDemande>(`${this.base}${id}/`, payload);
  }

  uploadPhotos(id: string, files: File[]): Observable<OffreDemande> {
    const form = new FormData();
    files.forEach((f) => form.append('photos', f));
    return this.http.post<OffreDemande>(`${this.base}${id}/photos/`, form);
  }

  supprimerPhoto(id: string, numero: number): Observable<OffreDemande> {
    return this.http.post<OffreDemande>(`${this.base}${id}/photos/supprimer/`, { numero });
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
