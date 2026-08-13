import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { ROLE_LABELS } from '../../core/models/user.model';
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
}
