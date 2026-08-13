import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';

@Component({
  selector: 'app-access-denied',
  imports: [RouterLink, EmptyStateComponent],
  template: `
    <pnlf-empty-state icon="lock" title="Accès non autorisé">
      Votre profil ne dispose pas des droits nécessaires pour consulter cette section de la
      plateforme. Contactez votre administrateur si vous pensez qu'il s'agit d'une erreur.
      <a routerLink="/app/tableau-de-bord" style="margin-top: 1rem; display:inline-block; font-weight:600; color: var(--color-link);">
        ← Retour au tableau de bord
      </a>
    </pnlf-empty-state>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccessDeniedComponent {}
