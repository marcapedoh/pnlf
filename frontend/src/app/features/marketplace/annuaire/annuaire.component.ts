import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { toApiError } from '../../../core/http/api-error.util';
import { Cooperative, Producteur } from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { AnnuaireParams, MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { unwrapList } from '../../../core/models/common.model';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';

type ListeAnnuaire = 'producteurs' | 'cooperatives';

const TYPE_ACTEUR_LIBELLES: Record<string, string> = {
  PRODUCTEUR: 'Producteur',
  COLLECTEUR: 'Collecteur',
  RECOLTEUR: 'Récolteur',
};

function pageDepuis(valeur: string | null): number {
  const n = Number(valeur);
  return Number.isInteger(n) && n > 1 ? n : 1;
}

@Component({
  selector: 'app-annuaire',
  imports: [
    FormsModule,
    RouterLink,
    ButtonComponent,
    CardComponent,
    EmptyStateComponent,
    IconComponent,
    PaginationComponent,
    SkeletonComponent,
  ],
  templateUrl: './annuaire.component.html',
  styleUrl: './annuaire.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnuaireComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly search$ = new Subject<void>();
  private readonly requetes: Record<ListeAnnuaire, number> = { producteurs: 0, cooperatives: 0 };

  readonly pageSize = 10;
  readonly producteurs = signal<Producteur[]>([]);
  readonly cooperatives = signal<Cooperative[]>([]);
  readonly loadingProd = signal(true);
  readonly loadingCoop = signal(true);
  readonly totalProd = signal(0);
  readonly totalCoop = signal(0);
  readonly pageProd = signal(1);
  readonly pageCoop = signal(1);
  readonly loadError = signal('');
  readonly provinceFilter = signal('');
  readonly provinces = signal<SelectOption[]>([]);
  readonly recherche = signal('');

  constructor() {
    const params = this.route.snapshot.queryParamMap;
    this.recherche.set(params.get('q') ?? '');
    this.provinceFilter.set(params.get('province') ?? '');
    this.pageProd.set(pageDepuis(params.get('pp')));
    this.pageCoop.set(pageDepuis(params.get('pc')));
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.search$.pipe(debounceTime(300), takeUntilDestroyed()).subscribe(() => this.reinitialiser());
    this.load();
  }

  onSearchInput(value: string): void {
    this.recherche.set(value);
    this.search$.next();
  }

  onFilterChange(): void {
    this.reinitialiser();
  }

  goToProdPage(page: number): void {
    this.pageProd.set(page);
    this.load('producteurs');
  }

  goToCoopPage(page: number): void {
    this.pageCoop.set(page);
    this.load('cooperatives');
  }

  /** Recharge une liste (ou les deux) et reflète l'état des filtres dans l'URL. */
  load(liste?: ListeAnnuaire): void {
    this.syncUrl();
    this.loadError.set('');
    const listes: ListeAnnuaire[] = liste ? [liste] : ['producteurs', 'cooperatives'];
    const base: AnnuaireParams = {
      q: this.recherche().trim(),
      province: this.provinceFilter(),
      page_size: this.pageSize,
    };
    for (const cible of listes) {
      const req = ++this.requetes[cible];
      const enProd = cible === 'producteurs';
      (enProd ? this.loadingProd : this.loadingCoop).set(true);
      const params: AnnuaireParams = enProd
        ? { ...base, liste: cible, page_producteurs: this.pageProd() }
        : { ...base, liste: cible, page_cooperatives: this.pageCoop() };
      this.service.annuaire(params).subscribe({
        next: (res) => {
          if (req !== this.requetes[cible]) return;
          if (enProd) {
            this.producteurs.set(res.producteurs ?? []);
            this.totalProd.set(res.producteurs_count ?? 0);
            this.pageProd.set(res.page_producteurs ?? 1);
            this.loadingProd.set(false);
          } else {
            this.cooperatives.set(res.cooperatives ?? []);
            this.totalCoop.set(res.cooperatives_count ?? 0);
            this.pageCoop.set(res.page_cooperatives ?? 1);
            this.loadingCoop.set(false);
          }
          this.syncUrl();
        },
        error: (err) => {
          if (req !== this.requetes[cible]) return;
          (enProd ? this.loadingProd : this.loadingCoop).set(false);
          this.loadError.set(toApiError(err).message);
        },
      });
    }
  }

  resetFilters(): void {
    this.recherche.set('');
    this.provinceFilter.set('');
    this.reinitialiser();
  }

  private reinitialiser(): void {
    this.pageProd.set(1);
    this.pageCoop.set(1);
    this.load();
  }

  private syncUrl(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        q: this.recherche().trim() || null,
        province: this.provinceFilter() || null,
        pp: this.pageProd() > 1 ? this.pageProd() : null,
        pc: this.pageCoop() > 1 ? this.pageCoop() : null,
      },
      replaceUrl: true,
    });
  }

  /** Fiche producteur dans le shell si le rôle a accès ; sinon fiche publique. */
  producteurRoute(p: Producteur): string[] {
    if (
      this.auth.hasRole(
        RoleUtilisateur.ADMINISTRATEUR,
        RoleUtilisateur.AGENT_MINISTERE,
        RoleUtilisateur.AGENT_FORESTIER,
        RoleUtilisateur.COOPERATIVE,
        RoleUtilisateur.PRODUCTEUR,
      )
    ) {
      return ['/app/producteurs', p.id];
    }
    return ['/annuaire', p.id];
  }

  /** Fiche coop dans le shell app si le rôle y a accès ; sinon annuaire public filtré. */
  cooperativeRoute(c: Cooperative): string[] {
    if (this.canOpenCooperativeApp()) {
      return ['/app/cooperatives', c.id];
    }
    return ['/annuaire'];
  }

  cooperativeQuery(c: Cooperative): Record<string, string> | undefined {
    if (this.canOpenCooperativeApp()) return undefined;
    return { q: c.nom };
  }

  private canOpenCooperativeApp(): boolean {
    return this.auth.hasRole(
      RoleUtilisateur.ADMINISTRATEUR,
      RoleUtilisateur.AGENT_MINISTERE,
      RoleUtilisateur.AGENT_FORESTIER,
      RoleUtilisateur.COOPERATIVE,
    );
  }

  /** Compte connecté et différent du vôtre : la discussion peut être ouverte directement. */
  peutEcrire(utilisateurId: string | null | undefined): boolean {
    return !!utilisateurId && utilisateurId !== this.auth.currentUser()?.id;
  }

  metaProducteur(p: Producteur): string {
    const type = TYPE_ACTEUR_LIBELLES[String(p.type_acteur)] ?? 'Producteur';
    return [p.province_nom || 'Province non renseignée', type].join(' · ');
  }

  initials(nom: string, prenoms = ''): string {
    return `${prenoms.charAt(0)}${nom.charAt(0)}`.toUpperCase() || nom.slice(0, 2).toUpperCase();
  }
}
