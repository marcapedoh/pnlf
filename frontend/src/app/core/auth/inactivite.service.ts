import { DOCUMENT } from '@angular/common';
import { Injectable, inject, signal } from '@angular/core';

export const DELAI_INACTIVITE_MS = 8 * 60_000;
const AVERTISSEMENT_MS = 60_000;
const INTERVALLE_VERIFICATION_MS = 1_000;
const INTERVALLE_ENREGISTREMENT_MS = 5_000;
// Partagée entre onglets : une activité dans l'un maintient la session des autres.
const CLE_ACTIVITE = 'pnlf_derniere_activite';
const EVENEMENTS = ['pointerdown', 'pointermove', 'keydown', 'wheel', 'scroll', 'touchstart'] as const;

function lireActivite(): number {
  try {
    return Number(localStorage.getItem(CLE_ACTIVITE)) || 0;
  } catch {
    return 0;
  }
}

/**
 * Déconnexion automatique après 8 minutes sans interaction (souris, clavier, toucher, défilement).
 * Un avertissement est affiché pendant la dernière minute ; seul le bouton « Rester connecté » le referme.
 */
@Injectable({ providedIn: 'root' })
export class InactiviteService {
  private readonly document = inject(DOCUMENT);
  private timer: ReturnType<typeof setInterval> | null = null;
  private derniereActivite = 0;
  private onExpiration: (() => void) | null = null;

  /** Secondes avant déconnexion pendant l'avertissement, sinon null. */
  readonly secondesRestantes = signal<number | null>(null);

  private readonly onActivite = () => {
    if (this.secondesRestantes() === null) this.noter(false);
  };
  private readonly onVisibilite = () => {
    if (this.document.visibilityState === 'visible') this.verifier();
  };

  /** Vrai si la dernière activité enregistrée dans ce navigateur dépasse le délai (navigateur fermé puis rouvert). */
  sessionExpiree(): boolean {
    const derniere = lireActivite();
    return derniere > 0 && Date.now() - derniere >= DELAI_INACTIVITE_MS;
  }

  demarrer(onExpiration: () => void): void {
    this.onExpiration = onExpiration;
    if (this.timer) return;
    this.noter(true);
    for (const evenement of EVENEMENTS) {
      this.document.addEventListener(evenement, this.onActivite, { passive: true, capture: true });
    }
    this.document.addEventListener('visibilitychange', this.onVisibilite);
    this.timer = setInterval(() => this.verifier(), INTERVALLE_VERIFICATION_MS);
  }

  arreter(): void {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    for (const evenement of EVENEMENTS) {
      this.document.removeEventListener(evenement, this.onActivite, { capture: true });
    }
    this.document.removeEventListener('visibilitychange', this.onVisibilite);
    this.secondesRestantes.set(null);
  }

  prolonger(): void {
    this.noter(true);
    this.secondesRestantes.set(null);
  }

  private noter(force: boolean): void {
    const maintenant = Date.now();
    if (!force && maintenant - this.derniereActivite < INTERVALLE_ENREGISTREMENT_MS) return;
    this.derniereActivite = maintenant;
    try {
      localStorage.setItem(CLE_ACTIVITE, String(maintenant));
    } catch {
      /* navigation privée : le suivi reste propre à l'onglet */
    }
  }

  private verifier(): void {
    if (!this.timer) return;
    const inactif = Date.now() - Math.max(this.derniereActivite, lireActivite());
    if (inactif >= DELAI_INACTIVITE_MS) {
      const expiration = this.onExpiration;
      this.arreter();
      expiration?.();
      return;
    }
    const restant = DELAI_INACTIVITE_MS - inactif;
    this.secondesRestantes.set(restant <= AVERTISSEMENT_MS ? Math.ceil(restant / 1000) : null);
  }
}
