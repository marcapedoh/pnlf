import { Injectable } from '@angular/core';

/**
 * Stockage du jeton d'accès uniquement (sessionStorage).
 * Le refresh JWT est en cookie HttpOnly (SEC-04) — jamais accessible au JS.
 */
const ACCESS_KEY = 'pnlf_access_token';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  getAccessToken(): string | null {
    try {
      return sessionStorage.getItem(ACCESS_KEY);
    } catch {
      return null;
    }
  }

  /** @deprecated Le refresh n'est plus stocké côté client. */
  getRefreshToken(): string | null {
    return null;
  }

  setTokens(access: string, _refresh?: string): void {
    try {
      sessionStorage.setItem(ACCESS_KEY, access);
    } catch {
      /* private mode */
    }
  }

  clear(): void {
    try {
      sessionStorage.removeItem(ACCESS_KEY);
      localStorage.removeItem(ACCESS_KEY);
      localStorage.removeItem('pnlf_refresh_token');
    } catch {
      /* ignore */
    }
  }
}
