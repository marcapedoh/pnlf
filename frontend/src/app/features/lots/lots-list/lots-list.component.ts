import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { unwrapCount, unwrapList } from '../../../core/models/common.model';
import { Lot, STATUT_LOT_LABELS, StatutLot } from '../../../core/models/lot.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';

@Component({
  selector: 'app-lots-list',
  imports: [RouterLink, FormsModule, ButtonComponent, StatusBadgeComponent, PaginationComponent, EmptyStateComponent, SkeletonComponent],
  templateUrl: './lots-list.component.html',
  styleUrl: './lots-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotsListComponent {
  private readonly service = inject(LotsService);
  private readonly auth = inject(AuthService);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Lot[]>([]);
  readonly loading = signal(true);
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 15;

  readonly search = signal('');
  readonly statutFilter = signal('');
  readonly statutLabels = STATUT_LOT_LABELS;
  readonly allStatuts = Object.values(StatutLot);
  readonly tone = lotStatusTone;

  readonly canCreate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  constructor() {
    this.search$.pipe(debounceTime(350), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  onSearchInput(value: string): void {
    this.search.set(value);
    this.search$.next();
  }

  onFilterChange(): void {
    this.page.set(1);
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service
      .list({ page: this.page(), page_size: this.pageSize, search: this.search(), statut: this.statutFilter() })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }
}
