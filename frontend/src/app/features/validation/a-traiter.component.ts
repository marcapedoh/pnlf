import { PnlfDatePipe, PnlfQuantitePipe } from '../../shared/pipes/format.pipes';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { DashboardService, InboxValidation } from '../../core/services/dashboard.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { toApiError } from '../../core/http/api-error.util';

@Component({
  selector: 'app-a-traiter',
  imports: [
    RouterLink,
    PnlfDatePipe,
    PnlfQuantitePipe,
    CardComponent,
    ButtonComponent,
    EmptyStateComponent,
    SkeletonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './a-traiter.component.html',
  styleUrl: './a-traiter.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ATraiterComponent {
  private readonly dashboard = inject(DashboardService);

  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly data = signal<InboxValidation | null>(null);

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.dashboard.aTraiter().subscribe({
      next: (d) => {
        this.data.set(d);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  nomActeur(a: { nom?: string | null; prenoms?: string | null }): string {
    return [a.prenoms, a.nom].filter((v) => !!v && String(v).trim()).join(' ');
  }

  total(): number {
    return this.data()?.total ?? 0;
  }

  enPlus(section: { count: number; results: unknown[] }): number {
    return Math.max(0, section.count - section.results.length);
  }
}
