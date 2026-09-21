import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Utilisateur } from '../models/user.model';

@Injectable({ providedIn: 'root' })
export class UsersAdminService {
  private readonly base = `${environment.apiUrl}/accounts/utilisateurs/`;

  constructor(private readonly http: HttpClient) {}

  list(params: Record<string, string> = {}): Observable<ApiListResponse<Utilisateur>> {
    return this.http.get<ApiListResponse<Utilisateur>>(this.base, {
      params: { page_size: '10', ...params },
    });
  }

  get(id: string): Observable<Utilisateur> {
    return this.http.get<Utilisateur>(`${this.base}${id}/`);
  }

  create(payload: Partial<Utilisateur> & { password?: string }): Observable<Utilisateur> {
    return this.http.post<Utilisateur>(this.base, payload);
  }

  update(id: string, payload: Partial<Utilisateur>): Observable<Utilisateur> {
    return this.http.patch<Utilisateur>(`${this.base}${id}/`, payload);
  }

  activer(id: string): Observable<Utilisateur> {
    return this.http.post<Utilisateur>(`${this.base}${id}/activer/`, {});
  }

  suspendre(id: string): Observable<Utilisateur> {
    return this.http.post<Utilisateur>(`${this.base}${id}/suspendre/`, {});
  }

  envoyerReinitialisation(id: string): Observable<{ detail: string }> {
    return this.http.post<{ detail: string }>(`${this.base}${id}/envoyer-reinitialisation/`, {});
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}${id}/`);
  }

  uploadPhoto(id: string, file: File): Observable<Utilisateur> {
    const form = new FormData();
    form.append('photo', file);
    return this.http.post<Utilisateur>(`${this.base}${id}/photo/`, form);
  }
}
