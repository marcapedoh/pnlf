import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../../../environments/environment';
import { Utilisateur } from '../models/user.model';

export interface ChangePasswordResponse {
  detail: string;
  access: string;
  user: Utilisateur;
}

@Injectable({ providedIn: 'root' })
export class PasswordService {
  constructor(private readonly http: HttpClient) {}

  requestReset(email: string) {
    return this.http.post(`${environment.apiUrl}/accounts/password-reset/`, { email });
  }

  confirmReset(token: string, nouveau_mot_de_passe: string) {
    return this.http.post(`${environment.apiUrl}/accounts/password-reset/confirm/`, {
      token,
      nouveau_mot_de_passe,
    });
  }

  /** Renvoie une nouvelle session : l'ancienne est révoquée par le changement de mot de passe. */
  changePassword(ancien_mot_de_passe: string, nouveau_mot_de_passe: string) {
    return this.http.post<ChangePasswordResponse>(
      `${environment.apiUrl}/accounts/change-password/`,
      { ancien_mot_de_passe, nouveau_mot_de_passe },
      { withCredentials: true },
    );
  }
}
