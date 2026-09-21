import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ButtonComponent } from '../../../design-system/button/button.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';

@Component({
  selector: 'app-access-denied',
  imports: [RouterLink, EmptyStateComponent, ButtonComponent],
  template: `
    <pnlf-empty-state
      icon="lock"
      title="Accès non autorisé"
      description="Votre profil ne dispose pas des droits nécessaires pour consulter cette section. Contactez un administrateur si vous pensez qu’il s’agit d’une erreur."
    >
      <a pnlfButton routerLink="/app/tableau-de-bord" variant="primary">Retour au tableau de bord</a>
      <a pnlfButton routerLink="/" variant="ghost">Retour au site public</a>
    </pnlf-empty-state>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccessDeniedComponent {}
