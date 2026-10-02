import { Injectable } from '@angular/core';

/**
 * Stockage du jeton d'accès uniquement (sessionStorage).
 * Le refresh JWT est en cookie HttpOnly (SEC-04), jamais accessible au JS : un simple
 * indicateur en localStorage signale qu'une session a été ouverte dans ce navigateur,
 * afin de ne pas appeler /auth/refresh/ pour chaque visiteur anonyme.
 */
const ACCESS_KEY = 'pnlf_access_token';
const SESSION_HINT_KEY = 'pnlf_session';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  getAccessToken(): string | null {
    try {
      return sessionStorage.getItem(ACCESS_KEY);
    } catch {
      return null;
    }
  }

  hasSessionHint(): boolean {
    try {
      return localStorage.getItem(SESSION_HINT_KEY) === '1';
    } catch {
      return true;
    }
  }

  /** @deprecated Le refresh n'est plus stocké côté client. */
  getRefreshToken(): string | null {
    return null;
  }

  setTokens(access: string, _refresh?: string): void {
    try {
      sessionStorage.setItem(ACCESS_KEY, access);
      localStorage.setItem(SESSION_HINT_KEY, '1');
    } catch {
      /* private mode */
    }
  }

  clear(): void {
    try {
      sessionStorage.removeItem(ACCESS_KEY);
      localStorage.removeItem(ACCESS_KEY);
      localStorage.removeItem(SESSION_HINT_KEY);
      localStorage.removeItem('pnlf_refresh_token');
    } catch {
      /* ignore */
    }
  }
}
