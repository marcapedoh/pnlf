import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { CookieConsentService } from '../../core/services/cookie-consent.service';
import { ButtonComponent } from '../button/button.component';

@Component({
  selector: 'pnlf-cookie-consent',
  standalone: true,
  imports: [RouterLink, ButtonComponent],
  templateUrl: './cookie-consent.component.html',
  styleUrl: './cookie-consent.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CookieConsentComponent {
  private readonly consent = inject(CookieConsentService);

  readonly hasChoice = this.consent.hasChoice.bind(this.consent);

  /** Seuls des cookies essentiels sont déposés : une simple prise de connaissance suffit. */
  acknowledge(): void {
    this.consent.acceptEssentialOnly();
  }
}
