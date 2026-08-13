import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../../../environments/environment';

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

  changePassword(ancien_mot_de_passe: string, nouveau_mot_de_passe: string) {
    return this.http.post(`${environment.apiUrl}/accounts/change-password/`, {
      ancien_mot_de_passe,
      nouveau_mot_de_passe,
    });
  }
}
