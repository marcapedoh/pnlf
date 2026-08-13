import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { LoadingService } from '../../core/loading/loading.service';

@Component({
  selector: 'pnlf-top-progress-bar',
  templateUrl: './top-progress-bar.component.html',
  styleUrl: './top-progress-bar.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TopProgressBarComponent {
  private readonly loading = inject(LoadingService);
  readonly isLoading = this.loading.isLoading;
}
