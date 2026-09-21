import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { PublicOffreDemande, PublicProduit, PublicProvince } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';

@Component({
  selector: 'app-offres-publiques',
  imports: [
    FormsModule,
    RouterLink,
    DatePipe,
    DecimalPipe,
    EmptyStateComponent,
    IconComponent,
    SkeletonComponent,
    PaginationComponent,
  ],
  templateUrl: './offres-publiques.component.html',
  styleUrl: './offres-publiques.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffresPubliquesComponent {
  private readonly publicService = inject(PublicService);

  readonly items = signal<PublicOffreDemande[]>([]);
  readonly loading = signal(true);
  readonly provinces = signal<PublicProvince[]>([]);
  readonly produits = signal<PublicProduit[]>([]);
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;
  recherche = '';
  typeAnnonce = '';
  province = '';
  produit = '';
  private readonly filter$ = new Subject<void>();

  constructor() {
    this.publicService.provinces().subscribe((p) => this.provinces.set(p));
    this.publicService.produits().subscribe((p) => this.produits.set(p));
    this.filter$.pipe(debounceTime(300), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  onFilterChange(): void {
    this.filter$.next();
  }

  resetFilters(): void {
    this.recherche = '';
    this.typeAnnonce = '';
    this.province = '';
    this.produit = '';
    this.page.set(1);
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.publicService
      .offres({
        q: this.recherche.trim() || undefined,
        type_annonce: this.typeAnnonce || undefined,
        province: this.province || undefined,
        produit: this.produit || undefined,
        page: this.page(),
        page_size: this.pageSize,
      })
      .subscribe({
        next: (res) => {
          this.items.set(res.results);
          this.total.set(res.count ?? res.results.length);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }
}
