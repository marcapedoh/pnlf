import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgApexchartsModule, ApexOptions } from 'ng-apexcharts';

import { AuthService } from '../../core/auth/auth.service';
import { displayName } from '../../core/auth/display-name.util';
import { PnlfQuantitePipe } from '../../shared/pipes/format.pipes';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { DashboardStats } from '../../core/models/dashboard.model';
import { Lot, STATUT_LOT_LABELS, StatutLot } from '../../core/models/lot.model';
import { ROLE_SHORT_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { OffreDemande } from '../../core/models/notification.model';
import { DashboardService, InboxValidation } from '../../core/services/dashboard.service';
import { LotsService } from '../../core/services/lots.service';
import { MarketplaceService } from '../../core/services/marketplace.service';
import { ProducteursService } from '../../core/services/producteurs.service';
import { lotStatusTone } from '../../core/ui/status-tone.util';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { KpiCardComponent } from '../../design-system/kpi-card/kpi-card.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';

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
    PnlfQuantitePipe,
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
  private readonly marketplace = inject(MarketplaceService);

  readonly user = this.auth.currentUser;
  readonly roleLabel = computed(() => {
    const role = this.user()?.role;
    return role ? ROLE_SHORT_LABELS[role] : '';
  });
  readonly isInstitutional = computed(() =>
    this.auth.hasRole(
      RoleUtilisateur.ADMINISTRATEUR,
      RoleUtilisateur.AGENT_MINISTERE,
      RoleUtilisateur.AGENT_FORESTIER,
    ),
  );
  readonly isProducteur = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  readonly isCoop = this.auth.hasRole(RoleUtilisateur.COOPERATIVE);
  readonly isAcheteur = this.auth.hasRole(RoleUtilisateur.ACHETEUR);
  readonly canDeclare = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  readonly loading = signal(true);
  readonly stats = signal<DashboardStats | null>(null);
  readonly recentLots = signal<Lot[]>([]);
  readonly lotsTotal = signal(0);
  readonly myProducteurCount = signal(0);
  readonly myProducteurId = signal<string | null>(null);
  readonly inbox = signal<InboxValidation | null>(null);
  readonly offresRecentes = signal<OffreDemande[]>([]);
  readonly statutLotLabels = STATUT_LOT_LABELS;
  readonly lotStatusTone = lotStatusTone;

  readonly statusChart = computed<ApexOptions>(() => {
    const rows = this.stats()?.lots ?? [];
    const byStatus = new Map<string, number>();
    for (const row of rows) {
      byStatus.set(row.statut, (byStatus.get(row.statut) ?? 0) + (row.nb_lots ?? 0));
    }
    return this.barOptions(
      [...byStatus.keys()].map((s) => this.statutLotLabels[s as StatutLot] ?? s),
      [...byStatus.values()],
      'Lots',
      false,
      { categories: 'Statut du lot', valeurs: 'Nombre de lots' },
    );
  });

  readonly provinceChart = computed<ApexOptions>(() => {
    const rows = this.stats()?.producteurs ?? [];
    const byProvince = new Map<string, number>();
    for (const row of rows) {
      const key = row.province__nom ?? row.province ?? 'Non renseigné';
      byProvince.set(key, (byProvince.get(key) ?? 0) + (row.nombre ?? 0));
    }
    const entries = [...byProvince.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);
    return this.barOptions(entries.map(([k]) => k), entries.map(([, v]) => v), 'Producteurs', true, {
      categories: 'Province',
      valeurs: 'Nombre de producteurs',
    });
  });

  readonly salutation = computed(() => {
    const u = this.user();
    if (!u) return 'Bonjour';
    if (u.role === RoleUtilisateur.COOPERATIVE || !u.prenoms?.trim()) return `Bonjour, ${displayName(u)}`;
    return `Bonjour, ${u.prenoms.trim()}`;
  });

  readonly showOnboarding = computed(() => this.isProducteur && this.lotsTotal() === 0);

  constructor() {
    this.load();
  }

  inboxTotal(): number {
    const d = this.inbox();
    if (!d) return 0;
    return d.producteurs.count + d.cooperatives.count + d.certifications.count + d.offres.count + (d.acheteurs?.count ?? 0);
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
      this.dashboardService.aTraiter().subscribe({ next: (d) => this.inbox.set(d) });
    }

    this.lotsService.list({ page_size: 8 }).subscribe({
      next: (res) => {
        this.recentLots.set(unwrapList(res));
        this.lotsTotal.set(unwrapCount(res));
        if (!this.isInstitutional()) this.loading.set(false);
      },
      error: () => {
        if (!this.isInstitutional()) this.loading.set(false);
      },
    });

    if (this.isProducteur || this.isCoop) {
      this.producteursService.list({ page_size: 5 }).subscribe((res) => {
        const list = unwrapList(res);
        this.myProducteurCount.set(unwrapCount(res) || list.length);
        if (list[0]) this.myProducteurId.set(list[0].id);
      });
    }

    if (this.isAcheteur) {
      this.marketplace.offres({ page_size: '6' }).subscribe((res) => {
        this.offresRecentes.set(unwrapList(res));
      });
    }
  }

  private barOptions(
    labels: string[],
    series: number[],
    name: string,
    horizontal: boolean,
    titres: { categories: string; valeurs: string },
  ): ApexOptions {
    const titreStyle = { fontSize: '12px', fontWeight: 600, color: '#5b6670' };
    // En barres horizontales, ApexCharts place les catégories sur l'axe vertical.
    const titreX = horizontal ? titres.valeurs : titres.categories;
    const titreY = horizontal ? titres.categories : titres.valeurs;
    return {
      chart: { type: 'bar', height: 280, toolbar: { show: false }, fontFamily: 'Public Sans, sans-serif' },
      series: [{ name, data: series }],
      xaxis: {
        categories: labels,
        labels: { style: { fontSize: '11px' } },
        title: { text: titreX, style: titreStyle },
      },
      yaxis: { title: { text: titreY, style: titreStyle } },
      plotOptions: { bar: { borderRadius: 6, horizontal, columnWidth: '55%' } },
      colors: CHART_PALETTE,
      dataLabels: { enabled: false },
      grid: { borderColor: '#edf0f2' },
      legend: { show: false },
    };
  }
}
