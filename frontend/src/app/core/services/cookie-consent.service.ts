import { Injectable, signal } from '@angular/core';

const STORAGE_KEY = 'pnlf_cookie_consent_v1';

export type CookieConsentChoice = 'accepted' | 'essential_only';

interface StoredConsent {
  choice: CookieConsentChoice;
  at: string;
}

/**
 * Gère le consentement aux cookies (bandeau RGPD-like).
 * Seuls des cookies techniques essentiels (session, préférences) sont utilisés
 * par la plateforme ; aucun traceur publicitaire tiers n'est déposé.
 */
@Injectable({ providedIn: 'root' })
export class CookieConsentService {
  private readonly _choice = signal<CookieConsentChoice | null>(this.readStored());
  readonly choice = this._choice.asReadonly();

  hasChoice(): boolean {
    return this._choice() !== null;
  }

  acceptAll(): void {
    this.store('accepted');
  }

  acceptEssentialOnly(): void {
    this.store('essential_only');
  }

  /** Permet de rouvrir le choix depuis la politique de cookies. */
  reset(): void {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      /* stockage indisponible (mode privé) : on ignore */
    }
    this._choice.set(null);
  }

  private store(choice: CookieConsentChoice): void {
    const payload: StoredConsent = { choice, at: new Date().toISOString() };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    } catch {
      /* stockage indisponible (mode privé) : le choix reste valable pour la session en mémoire */
    }
    this._choice.set(choice);
  }

  private readStored(): CookieConsentChoice | null {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as StoredConsent;
      return parsed.choice ?? null;
    } catch {
      return null;
    }
  }
}
