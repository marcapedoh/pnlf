import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApexOptions } from 'ng-apexcharts';
import { Subscription } from 'rxjs';

import { toApiError } from '../../core/http/api-error.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';

import { AuthService } from '../../core/auth/auth.service';
import { displayName } from '../../core/auth/display-name.util';
import { PnlfDatePipe, PnlfQuantitePipe } from '../../shared/pipes/format.pipes';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { DashboardStats } from '../../core/models/dashboard.model';
import { Lot, STATUT_LOT_LABELS } from '../../core/models/lot.model';
import { ROLE_SHORT_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { OffreDemande } from '../../core/models/notification.model';
import { CompteursParStatut, ResumeTableauDeBord, SectionATraiter } from '../../core/models/rapports.model';
import { DashboardService } from '../../core/services/dashboard.service';
import { LotsService } from '../../core/services/lots.service';
import { MarketplaceService } from '../../core/services/marketplace.service';
import { RapportsService } from '../../core/services/rapports.service';
import { lotStatusTone } from '../../core/ui/status-tone.util';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { IconComponent, IconName } from '../../design-system/icon/icon.component';
import { KpiCardComponent } from '../../design-system/kpi-card/kpi-card.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { GraphiqueComponent } from '../rapports/graphiques/graphique.component';
import { COULEURS_STATUT_LOT, anneau, classement } from '../rapports/graphiques/graphiques';

const ACTUALISATION_MS = 60_000;

/** Liens de la file « À traiter » : chaque section renvoie vers l'écran où la décision se prend. */
const SECTIONS_A_TRAITER: { cle: SectionATraiter; libelle: string; icone: IconName; lien: string; params?: Record<string, string> }[] = [
  { cle: 'producteurs', libelle: 'Fiches producteurs', icone: 'users', lien: '/app/a-traiter' },
  { cle: 'lots', libelle: 'Lots à valider', icone: 'package', lien: '/app/a-traiter' },
  { cle: 'cooperatives', libelle: 'Coopératives', icone: 'building', lien: '/app/a-traiter' },
  { cle: 'certifications', libelle: 'Certifications', icone: 'award', lien: '/app/a-traiter' },
  { cle: 'offres', libelle: 'Annonces', icone: 'shopping-bag', lien: '/app/marketplace/offres', params: { statut: 'EN_VALIDATION' } },
  { cle: 'acheteurs', libelle: 'Comptes acheteurs', icone: 'user-check', lien: '/app/a-traiter' },
  { cle: 'images', libelle: 'Images à vérifier', icone: 'camera', lien: '/app/moderation-images' },
];

const COULEUR_PAR_STATUT_LOT: Record<string, string> = {
  BROUILLON: COULEURS_STATUT_LOT.brouillon,
  VALIDE: COULEURS_STATUT_LOT.valide,
  COMMERCIALISE: COULEURS_STATUT_LOT.commercialise,
};

@Component({
  selector: 'app-dashboard',
  imports: [
    RouterLink,
    AlertBannerComponent,
    CardComponent,
    KpiCardComponent,
    SkeletonComponent,
    EmptyStateComponent,
    ButtonComponent,
    IconComponent,
    StatusBadgeComponent,
    PnlfDatePipe,
    PnlfQuantitePipe,
    GraphiqueComponent,
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DashboardComponent {
  private readonly auth = inject(AuthService);
  private readonly dashboardService = inject(DashboardService);
  private readonly rapports = inject(RapportsService);
  private readonly lotsService = inject(LotsService);
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

  readonly isPilotage = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly peutPublier = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ACHETEUR,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  readonly resume = signal<ResumeTableauDeBord | null>(null);
  readonly chargementResume = signal(true);
  readonly erreurResume = signal('');
  readonly stats = signal<DashboardStats | null>(null);
  readonly chargementStats = signal(false);
  readonly recentLots = signal<Lot[]>([]);
  readonly lotsTotal = signal(0);
  readonly chargementLots = signal(true);
  readonly offresRecentes = signal<OffreDemande[]>([]);
  readonly statutLotLabels = STATUT_LOT_LABELS;
  readonly lotStatusTone = lotStatusTone;

  private requeteResume?: Subscription;

  readonly sectionsATraiter = computed(() => {
    const a = this.resume()?.a_traiter ?? {};
    return SECTIONS_A_TRAITER.filter((s) => a[s.cle]?.autorise).map((s) => ({ ...s, count: a[s.cle]?.count ?? 0 }));
  });

  readonly graphLots = computed<ApexOptions | null>(() => {
    const lots = this.resume()?.lots;
    if (!lots) return null;
    return anneau(
      lots.par_statut.map((s) => s.libelle),
      lots.par_statut.map((s) => s.nombre),
      { couleurs: lots.par_statut.map((s) => COULEUR_PAR_STATUT_LOT[s.cle] ?? '#5b6670'), total: 'Lots', hauteur: 260 },
    );
  });

  readonly provinceChart = computed<ApexOptions | null>(() => {
    const rows = this.stats()?.producteurs;
    if (!rows) return null;
    const byProvince = new Map<string, number>();
    for (const row of rows) {
      const key = row.province__nom ?? row.province ?? 'Non renseigné';
      byProvince.set(key, (byProvince.get(key) ?? 0) + (row.nombre ?? 0));
    }
    const entries = [...byProvince.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);
    return classement(entries.map(([k]) => k), entries.map(([, v]) => v), 'Producteurs', { couleurs: ['#146b3f'] });
  });

  readonly salutation = computed(() => {
    const u = this.user();
    if (!u) return 'Bonjour';
    if (u.role === RoleUtilisateur.COOPERATIVE || !u.prenoms?.trim()) return `Bonjour, ${displayName(u)}`;
    return `Bonjour, ${u.prenoms.trim()}`;
  });

  readonly showOnboarding = computed(() => this.isProducteur && !this.chargementResume() && (this.resume()?.lots?.total ?? 0) === 0);

  constructor() {
    this.chargerResume();
    this.load();
    if (this.isPilotage) {
      const minuterie = setInterval(() => {
        if (document.visibilityState === 'visible') this.chargerResume(true);
      }, ACTUALISATION_MS);
      inject(DestroyRef).onDestroy(() => {
        clearInterval(minuterie);
        this.requeteResume?.unsubscribe();
      });
    }
  }

  chargerResume(silencieux = false): void {
    this.requeteResume?.unsubscribe();
    if (!silencieux) {
      this.chargementResume.set(true);
      this.erreurResume.set('');
    }
    this.requeteResume = this.rapports.resume(silencieux).subscribe({
      next: (r) => {
        this.resume.set(r);
        this.erreurResume.set('');
        this.chargementResume.set(false);
      },
      error: (err) => {
        this.chargementResume.set(false);
        if (!silencieux || !this.resume()) this.erreurResume.set(toApiError(err).message);
      },
    });
  }

  nombre(compteurs: CompteursParStatut | undefined, cle: string): number {
    return compteurs?.par_statut.find((s) => s.cle === cle)?.nombre ?? 0;
  }

  part(valeur: number, total: number): number {
    return total ? Math.round((valeur / total) * 100) : 0;
  }

  couleurStatutLot(cle: string): string {
    return COULEUR_PAR_STATUT_LOT[cle] ?? '#5b6670';
  }

  pluriel(n: number, singulier: string, pluriel: string): string {
    return `${n} ${n > 1 ? pluriel : singulier}`;
  }

  private load(): void {
    if (this.isInstitutional()) {
      this.chargementStats.set(true);
      this.dashboardService.stats().subscribe({
        next: (data) => {
          this.stats.set(data);
          this.chargementStats.set(false);
        },
        error: () => this.chargementStats.set(false),
      });
    }

    this.lotsService.list({ page_size: 8 }).subscribe({
      next: (res) => {
        this.recentLots.set(unwrapList(res));
        this.lotsTotal.set(unwrapCount(res));
        this.chargementLots.set(false);
      },
      error: () => this.chargementLots.set(false),
    });

    if (this.isAcheteur) {
      this.marketplace.offres({ page_size: '6' }).subscribe({
        next: (res) => this.offresRecentes.set(unwrapList(res)),
      });
    }
  }
}
