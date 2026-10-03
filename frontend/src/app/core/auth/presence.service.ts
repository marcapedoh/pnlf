import { DOCUMENT } from '@angular/common';
import { HttpClient, HttpContext } from '@angular/common/http';
import { DestroyRef, Injectable, inject } from '@angular/core';

import { environment } from '../../../environments/environment';
import { SKIP_AUTH_REDIRECT, SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from '../http/http-context-tokens';

const INTERVALLE_MS = 60_000;

/**
 * Signal de présence (statistiques « utilisateurs en ligne ») : un appel léger toutes les 60 secondes,
 * uniquement lorsque l'onglet est visible. Aucun cookie ni service tiers.
 */
@Injectable({ providedIn: 'root' })
export class PresenceService {
  private readonly http = inject(HttpClient);
  private readonly document = inject(DOCUMENT);
  private timer: ReturnType<typeof setInterval> | null = null;
  private dernierEnvoi = 0;
  private readonly onVisibilite = () => {
    if (this.document.visibilityState === 'visible' && Date.now() - this.dernierEnvoi >= INTERVALLE_MS / 2) {
      this.signaler();
    }
  };

  constructor() {
    inject(DestroyRef).onDestroy(() => this.arreter());
  }

  demarrer(): void {
    if (this.timer) return;
    this.document.addEventListener('visibilitychange', this.onVisibilite);
    this.timer = setInterval(() => {
      if (this.document.visibilityState === 'visible') this.signaler();
    }, INTERVALLE_MS);
  }

  arreter(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    this.document.removeEventListener('visibilitychange', this.onVisibilite);
  }

  private signaler(): void {
    this.dernierEnvoi = Date.now();
    const context = new HttpContext()
      .set(SKIP_LOADING_BAR, true)
      .set(SKIP_GLOBAL_ERROR_TOAST, true)
      .set(SKIP_AUTH_REDIRECT, true);
    this.http.post(`${environment.apiUrl}/accounts/presence/`, {}, { context }).subscribe({ error: () => undefined });
  }
}
