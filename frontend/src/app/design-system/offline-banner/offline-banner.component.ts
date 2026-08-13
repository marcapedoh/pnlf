import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { ConnectivityService } from '../../core/network/connectivity.service';

@Component({
  selector: 'pnlf-offline-banner',
  templateUrl: './offline-banner.component.html',
  styleUrl: './offline-banner.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OfflineBannerComponent {
  private readonly connectivity = inject(ConnectivityService);
  readonly isOnline = this.connectivity.isOnline;
}
