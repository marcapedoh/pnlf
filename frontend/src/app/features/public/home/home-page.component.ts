import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';

import { PublicStats } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';

@Component({
  selector: 'app-home-page',
  imports: [RouterLink, FormsModule, ButtonComponent, IconComponent, SkeletonComponent],
  templateUrl: './home-page.component.html',
  styleUrl: './home-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HomePageComponent {
  private readonly publicService = inject(PublicService);
  private readonly router = inject(Router);

  readonly stats = signal<PublicStats | null>(null);
  readonly loading = signal(true);
  recherche = '';

  constructor() {
    this.publicService.stats().subscribe({
      next: (s) => {
        this.stats.set(s);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  rechercher(): void {
    const q = this.recherche.trim();
    this.router.navigate(['/annuaire'], q ? { queryParams: { q } } : {});
  }
}
