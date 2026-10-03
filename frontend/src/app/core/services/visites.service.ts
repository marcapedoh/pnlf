import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';

import { environment } from '../../../environments/environment';
import { SKIP_AUTH_REDIRECT, SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from '../http/http-context-tokens';

/**
 * Compteur de fréquentation des pages publiques, anonyme et agrégé côté serveur
 * (page, jour, type d'appareil) : aucun cookie, aucun identifiant, aucun service tiers.
 */
@Injectable({ providedIn: 'root' })
export class VisitesService {
  private readonly http = inject(HttpClient);
  private derniere = '';

  enregistrer(url: string): void {
    const page = url.split(/[?#]/, 1)[0] || '/';
    if (page === this.derniere || page.startsWith('/app')) return;
    this.derniere = page;
    const context = new HttpContext()
      .set(SKIP_LOADING_BAR, true)
      .set(SKIP_GLOBAL_ERROR_TOAST, true)
      .set(SKIP_AUTH_REDIRECT, true);
    this.http.post(`${environment.apiUrl}/public/visite/`, { page }, { context }).subscribe({ error: () => undefined });
  }
}
