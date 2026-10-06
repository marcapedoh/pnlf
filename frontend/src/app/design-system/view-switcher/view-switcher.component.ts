import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';

import { IconComponent } from '../icon/icon.component';

export type VueAffichage = 'liste' | 'grille' | 'tableau';

export const VUES_AFFICHAGE: { value: VueAffichage; label: string; icon: 'list' | 'grid' | 'table' }[] = [
  { value: 'liste', label: 'Liste', icon: 'list' },
  { value: 'grille', label: 'Grille', icon: 'grid' },
  { value: 'tableau', label: 'Tableau compact', icon: 'table' },
];

export function lireVueMemorisee(cle: string, defaut: VueAffichage): VueAffichage {
  try {
    const valeur = localStorage.getItem(cle);
    return VUES_AFFICHAGE.some((v) => v.value === valeur) ? (valeur as VueAffichage) : defaut;
  } catch {
    return defaut;
  }
}

export function lireTailleMemorisee(cle: string, options: number[], defaut: number): number {
  try {
    const valeur = Number(localStorage.getItem(cle));
    return options.includes(valeur) ? valeur : defaut;
  } catch {
    return defaut;
  }
}

export function memoriser(cle: string, valeur: string | number): void {
  try {
    localStorage.setItem(cle, String(valeur));
  } catch {
    /* stockage indisponible (navigation privée) : le choix reste valable pour la session en cours */
  }
}

/** Bascule liste / grille / tableau, au même rendu que la barre des offres et demandes. */
@Component({
  selector: 'pnlf-view-switcher',
  imports: [IconComponent],
  template: `
    <div class="vues" role="group" [attr.aria-label]="label()">
      @for (v of vues; track v.value) {
        <button
          type="button"
          class="vues__btn"
          [class.is-active]="vue() === v.value"
          [attr.aria-pressed]="vue() === v.value"
          [attr.aria-label]="'Affichage ' + v.label.toLowerCase()"
          [title]="v.label"
          (click)="vue.set(v.value)"
        >
          <pnlf-icon [name]="v.icon" [size]="18" />
        </button>
      }
    </div>
  `,
  styles: `
    :host {
      display: inline-flex;
    }

    .vues {
      display: inline-flex;
      border: 1.5px solid var(--border-default);
      border-radius: var(--radius-md);
      overflow: hidden;
      background: var(--surface-raised);
    }

    .vues__btn {
      border: 0;
      background: transparent;
      padding: 0.45rem 0.6rem;
      color: var(--text-secondary);
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;

      & + & {
        border-left: 1px solid var(--border-subtle);
      }

      &:hover {
        background: var(--pnlf-green-50);
      }

      &.is-active {
        background: var(--pnlf-green-700);
        color: var(--white);
      }

      &:focus-visible {
        outline: 2px solid var(--pnlf-green-500);
        outline-offset: -2px;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ViewSwitcherComponent {
  readonly vue = model.required<VueAffichage>();
  readonly label = input('Mode d’affichage');
  readonly vues = VUES_AFFICHAGE;
}
