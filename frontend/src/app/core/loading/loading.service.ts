import { Injectable, computed, signal } from '@angular/core';

/**
 * Compteur global de requêtes HTTP en cours, piloté par l'intercepteur de chargement.
 * Alimente la barre de progression institutionnelle du shell applicatif.
 */
@Injectable({ providedIn: 'root' })
export class LoadingService {
  private readonly _pending = signal(0);

  readonly isLoading = computed(() => this._pending() > 0);
  readonly pendingCount = this._pending.asReadonly();

  start(): void {
    this._pending.update((n) => n + 1);
  }

  stop(): void {
    this._pending.update((n) => Math.max(0, n - 1));
  }
}
