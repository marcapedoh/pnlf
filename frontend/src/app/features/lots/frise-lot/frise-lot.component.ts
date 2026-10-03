import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { EvenementFrise, TypeEvenementFrise } from '../../../core/models/lot.model';
import { IconComponent, IconName } from '../../../design-system/icon/icon.component';
import { PnlfDatePipe, PnlfQuantitePipe } from '../../../shared/pipes/format.pipes';

const ICONES: Record<TypeEvenementFrise, IconName> = {
  COLLECTE: 'leaf',
  DECLARATION: 'file-text',
  MOUVEMENT: 'map-pin',
  VALIDATION: 'shield-check',
  COMMERCIALISATION: 'shopping-bag',
};

/**
 * Frise chronologique verticale d'un lot : collecte, déclaration, étapes, validation et
 * commercialisation. Utilisée par la fiche interne, la page publique du lot et la vérification QR.
 * En mode public, seules les données publiques fournies par le serveur sont affichées.
 */
@Component({
  selector: 'app-frise-lot',
  imports: [IconComponent, PnlfDatePipe, PnlfQuantitePipe],
  template: `
    @if (evenements().length === 0) {
      <p class="frise-vide">Aucun événement enregistré pour le moment.</p>
    } @else {
      <ol class="frise" [attr.aria-label]="titre()">
        @for (e of evenements(); track $index) {
          <li class="frise__item" [class]="'frise__item frise__item--' + e.type.toLowerCase()">
            <span class="frise__pastille" aria-hidden="true">
              <pnlf-icon [name]="icone(e.type)" [size]="16" />
            </span>
            <div class="frise__contenu">
              <p class="frise__titre">{{ e.libelle }}</p>
              <p class="frise__date">
                <time [attr.datetime]="e.date">{{ e.date | pnlfDate: (e.date_seule ? 'date' : 'datetime') }}</time>
              </p>
              @if (e.lieu || e.quantite || e.acteur) {
                <dl class="frise__details">
                  @if (e.lieu) {
                    <div><dt>Lieu</dt><dd>{{ e.lieu }}</dd></div>
                  }
                  @if (e.quantite) {
                    <div><dt>Quantité</dt><dd>{{ e.quantite | pnlfQuantite: e.unite }}</dd></div>
                  }
                  @if (e.acteur) {
                    <div><dt>Acteur</dt><dd>{{ e.acteur }}</dd></div>
                  }
                  @if (e.latitude && e.longitude) {
                    <div>
                      <dt>{{ mode() === 'public' ? 'Position approximative' : 'Position GPS' }}</dt>
                      <dd>{{ e.latitude }}, {{ e.longitude }}</dd>
                    </div>
                  }
                  @if (mode() === 'interne' && e.destinataire) {
                    <div><dt>Destinataire</dt><dd>{{ e.destinataire }}</dd></div>
                  }
                </dl>
              }
              @if (mode() === 'interne' && e.commentaire) {
                <p class="frise__commentaire">{{ e.commentaire }}</p>
              }
            </div>
          </li>
        }
      </ol>
    }
  `,
  styles: `
    :host {
      display: block;
    }

    .frise-vide {
      font-size: var(--fs-sm);
      color: var(--text-muted);
    }

    .frise {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
    }

    .frise__item {
      position: relative;
      display: grid;
      grid-template-columns: 2rem minmax(0, 1fr);
      gap: var(--space-3);
      padding-bottom: var(--space-5);
      break-inside: avoid;

      &::before {
        content: '';
        position: absolute;
        left: calc(1rem - 1px);
        top: 2rem;
        bottom: 0;
        width: 2px;
        background: var(--border-default);
      }

      &:last-child {
        padding-bottom: 0;

        &::before {
          display: none;
        }
      }
    }

    .frise__pastille {
      width: 2rem;
      height: 2rem;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: var(--gray-100, #f3f4f6);
      color: var(--text-secondary);
      border: 2px solid var(--surface, #fff);
      box-shadow: 0 0 0 1px var(--border-default);
    }

    .frise__item--collecte .frise__pastille {
      background: var(--pnlf-green-100);
      color: var(--pnlf-green-700);
    }

    .frise__item--validation .frise__pastille {
      background: var(--pnlf-green-600, #16a34a);
      color: #fff;
    }

    .frise__item--commercialisation .frise__pastille {
      background: var(--gold-100, #fef3c7);
      color: var(--gold-700, #a16207);
    }

    .frise__contenu {
      min-width: 0;
      padding-top: 0.2rem;
    }

    .frise__titre {
      margin: 0;
      font-weight: 700;
      font-size: var(--fs-sm);
      color: var(--text-primary);
    }

    .frise__date {
      margin: 2px 0 0;
      font-size: var(--fs-xs);
      color: var(--text-muted);
    }

    .frise__details {
      margin: var(--space-2) 0 0;
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-1) var(--space-4);
      font-size: var(--fs-xs);

      div {
        display: flex;
        gap: 0.35rem;
      }

      dt {
        color: var(--text-muted);
      }

      dt::after {
        content: ' :';
      }

      dd {
        margin: 0;
        font-weight: 600;
        color: var(--text-primary);
        overflow-wrap: anywhere;
      }
    }

    .frise__commentaire {
      margin: var(--space-2) 0 0;
      font-size: var(--fs-sm);
      color: var(--text-secondary);
      background: var(--gray-50);
      padding: var(--space-2) var(--space-3);
      border-radius: var(--radius-sm);
    }

    @media print {
      .frise__pastille {
        box-shadow: none;
        border: 1px solid #555;
        background: #fff !important;
        color: #000 !important;
      }

      .frise__item::before {
        background: #999;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FriseLotComponent {
  readonly evenements = input.required<EvenementFrise[]>();
  /** « public » : vérification QR et annuaire ; « interne » : fiche du lot dans l'application. */
  readonly mode = input<'public' | 'interne'>('public');
  readonly titre = input('Frise chronologique du lot');

  icone(type: TypeEvenementFrise): IconName {
    return ICONES[type] ?? 'clock';
  }
}
