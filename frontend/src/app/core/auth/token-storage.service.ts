import { Injectable } from '@angular/core';

const ACCESS_KEY = 'pnlf_access_token';
const REFRESH_KEY = 'pnlf_refresh_token';

/**
 * Encapsule le stockage des jetons JWT.
 * Isolé pour permettre une migration future vers un stockage plus sûr
 * (ex: cookie httpOnly côté backend) sans impacter le reste de l'app.
 */
@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  getAccessToken(): string | null {
    return localStorage.getItem(ACCESS_KEY);
  }

  getRefreshToken(): string | null {
    return localStorage.getItem(REFRESH_KEY);
  }

  setTokens(access: string, refresh?: string): void {
    localStorage.setItem(ACCESS_KEY, access);
    if (refresh) {
      localStorage.setItem(REFRESH_KEY, refresh);
    }
  }

  clear(): void {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  }

  hasSession(): boolean {
    return !!this.getRefreshToken();
  }
}
