import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { InactiviteService } from '../../core/auth/inactivite.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { ModalA11yDirective } from '../../design-system/modal/modal-a11y.directive';

@Component({
  selector: 'app-session-inactivite',
  imports: [ButtonComponent, ModalA11yDirective],
  templateUrl: './session-inactivite.component.html',
  styleUrl: './session-inactivite.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionInactiviteComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  readonly inactivite = inject(InactiviteService);

  rester(): void {
    this.inactivite.prolonger();
  }

  deconnecter(): void {
    this.auth.logout();
    void this.router.navigate(['/connexion']);
  }
}
