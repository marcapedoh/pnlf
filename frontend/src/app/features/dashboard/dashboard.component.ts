import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgApexchartsModule, ApexOptions } from 'ng-apexcharts';

import { AuthService } from '../../core/auth/auth.service';
import { DashboardService } from '../../core/services/dashboard.service';
import { LotsService } from '../../core/services/lots.service';
import { ProducteursService } from '../../core/services/producteurs.service';
import { DashboardStats } from '../../core/models/dashboard.model';
import { Lot, STATUT_LOT_LABELS, StatutLot } from '../../core/models/lot.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { KpiCardComponent } from '../../design-system/kpi-card/kpi-card.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { lotStatusTone } from '../../core/ui/status-tone.util';

const CHART_PALETTE = ['#146b3f', '#e4b91a', '#3260a3', '#6bc48a', '#a4650a', '#ab2626'];

@Component({
  selector: 'app-dashboard',
  imports: [
    RouterLink,
    NgApexchartsModule,
    CardComponent,
    KpiCardComponent,
    SkeletonComponent,
    EmptyStateComponent,
    ButtonComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardComponent {
  private readonly auth = inject(AuthService);
  private readonly dashboardService = inject(DashboardService);
  private readonly lotsService = inject(LotsService);
  private readonly producteursService = inject(ProducteursService);

  readonly user = this.auth.currentUser;
  readonly isInstitutional = computed(() =>
    this.auth.hasRole(
      RoleUtilisateur.ADMINISTRATEUR,
      RoleUtilisateur.AGENT_MINISTERE,
      RoleUtilisateur.AGENT_FORESTIER,
    ),
  );

  readonly loading = signal(true);
  readonly stats = signal<DashboardStats | null>(null);
  readonly recentLots = signal<Lot[]>([]);
  readonly myProducteurCount = signal(0);
  readonly statutLotLabels = STATUT_LOT_LABELS;
  readonly lotStatusTone = lotStatusTone;

  readonly statusChart = computed<ApexOptions>(() => {
    const rows = this.stats()?.lots ?? [];
    const byStatus = new Map<string, number>();
    for (const row of rows) {
      const key = row.statut;
      byStatus.set(key, (byStatus.get(key) ?? 0) + (row.nb_lots ?? 0));
    }
    const labels = [...byStatus.keys()].map(
      (s) => this.statutLotLabels[s as StatutLot] ?? s,
    );
    const series = [...byStatus.values()];
    return this.barOptions(labels, series, 'Lots');
  });

  readonly provinceChart = computed<ApexOptions>(() => {
    const rows = this.stats()?.producteurs ?? [];
    const byProvince = new Map<string, number>();
    for (const row of rows) {
      const key = row.province__nom ?? row.province ?? 'Non renseigné';
      byProvince.set(key, (byProvince.get(key) ?? 0) + (row.nombre ?? 0));
    }
    const entries = [...byProvince.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);
    return this.barOptions(
      entries.map(([k]) => k),
      entries.map(([, v]) => v),
      'Producteurs',
      true,
    );
  });

  constructor() {
    this.load();
  }

  private load(): void {
    this.loading.set(true);

    if (this.isInstitutional()) {
      this.dashboardService.stats().subscribe({
        next: (data) => {
          this.stats.set(data);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
      this.lotsService.list({ page_size: 6 }).subscribe((res) => {
        this.recentLots.set(Array.isArray(res) ? res : res.results);
      });
    } else {
      this.lotsService.list({ page_size: 8 }).subscribe({
        next: (res) => {
          this.recentLots.set(Array.isArray(res) ? res : res.results);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
      if (this.auth.hasRole(RoleUtilisateur.COOPERATIVE, RoleUtilisateur.AGENT_MINISTERE)) {
        this.producteursService.list({ page_size: 1 }).subscribe((res) => {
          this.myProducteurCount.set(Array.isArray(res) ? res.length : res.count);
        });
      }
    }
  }

  private barOptions(
    labels: string[],
    series: number[],
    name: string,
    horizontal = false,
  ): ApexOptions {
    return {
      chart: { type: 'bar', height: 280, toolbar: { show: false }, fontFamily: 'Public Sans, sans-serif' },
      series: [{ name, data: series }],
      xaxis: { categories: labels, labels: { style: { fontSize: '11px' } } },
      plotOptions: { bar: { borderRadius: 6, horizontal, columnWidth: '55%' } },
      colors: CHART_PALETTE,
      dataLabels: { enabled: false },
      grid: { borderColor: '#edf0f2' },
      legend: { show: false },
    };
  }
}
