import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { TypeActeur } from '../../../core/models/producteur.model';
import {
  PublicProducteur,
  PublicProvince,
  TYPE_ACTEUR_PUBLIC_LABELS,
} from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';

@Component({
  selector: 'app-annuaire-public',
  imports: [
    RouterLink,
    FormsModule,
    SkeletonComponent,
    EmptyStateComponent,
    IconComponent,
    ButtonComponent,
    PaginationComponent,
  ],
  templateUrl: './annuaire-public.component.html',
  styleUrl: './annuaire-public.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnuairePublicComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);

  readonly producteurs = signal<PublicProducteur[]>([]);
  readonly provinces = signal<PublicProvince[]>([]);
  readonly loading = signal(true);
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;
  readonly typeLabels = TYPE_ACTEUR_PUBLIC_LABELS;
  readonly TypeActeur = TypeActeur;

  province = '';
  typeActeur = '';
  produit = '';
  recherche = '';

  private readonly filter$ = new Subject<void>();

  constructor() {
    const params = this.route.snapshot.queryParamMap;
    this.recherche = params.get('q') ?? '';
    this.produit = params.get('produit') ?? '';
    this.province = params.get('province') ?? '';
    this.typeActeur = params.get('type_acteur') ?? '';

    this.publicService.provinces().subscribe((p) => this.provinces.set(p));
    this.filter$.pipe(debounceTime(300), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.publicService
      .producteurs({
        province: this.province || undefined,
        type_acteur: this.typeActeur || undefined,
        produit: this.produit || undefined,
        q: this.recherche || undefined,
        page: this.page(),
        page_size: this.pageSize,
      })
      .subscribe({
        next: (res) => {
          this.producteurs.set(res.results);
          this.total.set(res.count ?? res.results.length);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  onFilterChange(): void {
    this.filter$.next();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  resetFilters(): void {
    this.recherche = '';
    this.produit = '';
    this.province = '';
    this.typeActeur = '';
    this.page.set(1);
    this.load();
  }

  initials(p: PublicProducteur): string {
    return `${p.prenoms.charAt(0)}${p.nom.charAt(0)}`.toUpperCase();
  }
}
