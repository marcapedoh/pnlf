import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse, Paginated } from '../models/common.model';
import { ChatContact, ChatMessage, ContactFiltreRole, Conversation, CoopGroupeOption } from '../models/chat.model';
import { AJAX_EXPORT_HEADERS } from '../http/download-file.util';
import { SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from '../http/http-context-tokens';

@Injectable({ providedIn: 'root' })
export class ChatService {
  private readonly base = `${environment.apiUrl}/conversations`;
  private readonly quiet = new HttpContext().set(SKIP_LOADING_BAR, true).set(SKIP_GLOBAL_ERROR_TOAST, true);

  constructor(private readonly http: HttpClient) {}

  list(params: Record<string, string> = {}): Observable<ApiListResponse<Conversation>> {
    return this.http.get<ApiListResponse<Conversation>>(`${this.base}/`, { params });
  }

  supervision(q: string): Observable<ApiListResponse<Conversation> & { lecture_seule?: boolean }> {
    return this.http.get<ApiListResponse<Conversation> & { lecture_seule?: boolean }>(
      `${this.base}/supervision/`,
      { params: q.trim() ? { q: q.trim() } : {} },
    );
  }

  supervisionLire(conversationId: string): Observable<{
    conversation_id: string;
    lecture_seule: boolean;
    results: ChatMessage[];
  }> {
    return this.http.get<{ conversation_id: string; lecture_seule: boolean; results: ChatMessage[] }>(
      `${this.base}/${conversationId}/supervision-lire/`,
      { context: this.quiet },
    );
  }

  ouvrir(payload: {
    sujet?: string;
    offre_id?: string;
    producteur_id?: string;
    cooperative_id?: string;
    destinataire_id?: string;
    est_groupe?: boolean;
    participants?: string[];
  }): Observable<Conversation> {
    return this.http.post<Conversation>(`${this.base}/`, payload);
  }

  supprimer(conversationId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/${conversationId}/`);
  }

  /** Comptes actifs joignables, triés alphabétiquement, recherche et filtre côté serveur. */
  contacts(params: { q?: string; role?: ContactFiltreRole; page?: number; page_size?: number } = {}): Observable<Paginated<ChatContact>> {
    const query: Record<string, string> = { page: String(params.page ?? 1), page_size: String(params.page_size ?? 30) };
    if (params.q?.trim()) query['q'] = params.q.trim();
    if (params.role) query['role'] = params.role;
    return this.http.get<Paginated<ChatContact>>(`${this.base}/contacts/`, { params: query, context: this.quiet });
  }

  /** PDF de la conversation entière (supervision administrateur), récupéré en Blob authentifié. */
  supervisionPdfBlob(conversationId: string): Observable<Blob> {
    return this.http.post(`${this.base}/${conversationId}/supervision-pdf/`, {}, {
      responseType: 'blob',
      headers: AJAX_EXPORT_HEADERS,
    });
  }

  membresCoop(): Observable<CoopGroupeOption[]> {
    return this.http.get<CoopGroupeOption[]>(`${this.base}/membres-coop/`);
  }

  nonLus(quiet = true): Observable<{ count: number }> {
    return this.http.get<{ count: number }>(`${this.base}/non-lus/`, {
      context: quiet ? this.quiet : undefined,
    });
  }

  messages(conversationId: string, since?: string): Observable<ChatMessage[]> {
    const params: Record<string, string> = {};
    if (since) params['since'] = since;
    return this.http.get<ChatMessage[]>(`${this.base}/${conversationId}/messages/`, {
      params,
      context: this.quiet,
    });
  }

  envoyer(conversationId: string, payload: { contenu?: string; piece?: File }): Observable<ChatMessage> {
    if (payload.piece) {
      const form = new FormData();
      if (payload.contenu?.trim()) form.append('contenu', payload.contenu.trim());
      form.append('piece', payload.piece);
      return this.http.post<ChatMessage>(`${this.base}/${conversationId}/messages/`, form);
    }
    return this.http.post<ChatMessage>(`${this.base}/${conversationId}/messages/`, {
      contenu: payload.contenu ?? '',
    });
  }
}
