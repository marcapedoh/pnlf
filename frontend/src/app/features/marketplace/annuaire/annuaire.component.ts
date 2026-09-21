import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { Cooperative, Producteur } from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { unwrapList } from '../../../core/models/common.model';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';

@Component({
  selector: 'app-annuaire',
  imports: [FormsModule, CardComponent, EmptyStateComponent, IconComponent, SkeletonComponent],
  templateUrl: './annuaire.component.html',
  styleUrl: './annuaire.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnuaireComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);
  private readonly router = inject(Router);
  private readonly auth = inject(AuthService);
  private readonly search$ = new Subject<void>();

  readonly producteurs = signal<Producteur[]>([]);
  readonly cooperatives = signal<Cooperative[]>([]);
  readonly loading = signal(true);
  readonly provinceFilter = signal('');
  readonly provinces = signal<SelectOption[]>([]);
  readonly recherche = signal('');

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.search$.pipe(debounceTime(300), takeUntilDestroyed()).subscribe(() => this.load());
    this.load();
  }

  onSearchInput(value: string): void {
    this.recherche.set(value);
    this.search$.next();
  }

  onFilterChange(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    const params: Record<string, string> = {};
    if (this.provinceFilter()) params['province'] = this.provinceFilter();
    if (this.recherche().trim()) params['q'] = this.recherche().trim();
    this.service.annuaire(params).subscribe({
      next: (res) => {
        this.producteurs.set(res.producteurs ?? []);
        this.cooperatives.set(res.cooperatives ?? []);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  openProducteur(p: Producteur): void {
    this.router.navigate(['/annuaire', p.id]);
  }

  openCooperative(c: Cooperative): void {
    if (
      this.auth.hasRole(
        RoleUtilisateur.ADMINISTRATEUR,
        RoleUtilisateur.AGENT_MINISTERE,
        RoleUtilisateur.AGENT_FORESTIER,
        RoleUtilisateur.COOPERATIVE,
      )
    ) {
      this.router.navigate(['/app/cooperatives', c.id]);
      return;
    }
    this.router.navigate(['/annuaire'], { queryParams: { q: c.nom } });
  }

  initials(nom: string, prenoms = ''): string {
    return `${prenoms.charAt(0)}${nom.charAt(0)}`.toUpperCase() || nom.slice(0, 2).toUpperCase();
  }
}
