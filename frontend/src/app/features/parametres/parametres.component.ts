import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { ROLE_LABELS, STATUT_COMPTE_LABELS, StatutCompte } from '../../core/models/user.model';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';

@Component({
  selector: 'app-parametres',
  imports: [RouterLink, CardComponent, ButtonComponent],
  templateUrl: './parametres.component.html',
  styleUrl: './parametres.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ParametresComponent {
  readonly auth = inject(AuthService);
  readonly roleLabels = ROLE_LABELS;

  statutLabel(statut: string | undefined): string {
    if (!statut) return '—';
    return STATUT_COMPTE_LABELS[statut as StatutCompte] ?? statut;
  }
}
