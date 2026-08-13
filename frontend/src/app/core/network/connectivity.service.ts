import { Injectable, NgZone, OnDestroy, signal } from '@angular/core';

/**
 * Suit l'état de connectivité réseau du poste client.
 * Sert de socle au mode hors ligne terrain exigé par la note de cadrage (§6 — collecte agents forestiers).
 */
@Injectable({ providedIn: 'root' })
export class ConnectivityService implements OnDestroy {
  private readonly _online = signal(navigator.onLine);
  readonly isOnline = this._online.asReadonly();

  private readonly onlineHandler = () => this.zone.run(() => this._online.set(true));
  private readonly offlineHandler = () => this.zone.run(() => this._online.set(false));

  constructor(private readonly zone: NgZone) {
    window.addEventListener('online', this.onlineHandler);
    window.addEventListener('offline', this.offlineHandler);
  }

  ngOnDestroy(): void {
    window.removeEventListener('online', this.onlineHandler);
    window.removeEventListener('offline', this.offlineHandler);
  }
}
