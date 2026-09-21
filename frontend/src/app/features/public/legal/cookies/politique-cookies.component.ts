import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { CookieConsentService } from '../../../../core/services/cookie-consent.service';
import { ButtonComponent } from '../../../../design-system/button/button.component';
import { IconComponent } from '../../../../design-system/icon/icon.component';
import { ToastService } from '../../../../design-system/toast/toast.service';

@Component({
  selector: 'app-politique-cookies',
  standalone: true,
  imports: [IconComponent, ButtonComponent],
  templateUrl: './politique-cookies.component.html',
  styleUrl: './politique-cookies.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PolitiqueCookiesComponent {
  private readonly consent = inject(CookieConsentService);
  private readonly toast = inject(ToastService);

  readonly derniereMiseAJour = '21 septembre 2026';
  readonly choice = this.consent.choice;

  rouvrirChoix(): void {
    this.consent.reset();
    this.toast.success('Préférences réinitialisées', 'Le bandeau de consentement va réapparaître.');
  }
}
