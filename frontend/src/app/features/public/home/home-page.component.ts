import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { interval } from 'rxjs';

import { PublicStats } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { HomePartnersComponent } from './home-partners/home-partners.component';

/** Images du dossier « image pfnl », copiées dans public/assets/home-carousel. */
const HERO_SLIDES = [
  { src: 'assets/home-carousel/slide-01.jpg', alt: 'Filière PFNL, image 1' },
  { src: 'assets/home-carousel/slide-02.jpg', alt: 'Filière PFNL, image 2' },
  { src: 'assets/home-carousel/slide-03.jpg', alt: 'Filière PFNL, image 3' },
  { src: 'assets/home-carousel/slide-04.jpg', alt: 'Filière PFNL, image 4' },
  { src: 'assets/home-carousel/slide-05.jpg', alt: 'Filière PFNL, image 5' },
  { src: 'assets/home-carousel/slide-06.jpg', alt: 'Filière PFNL, image 6' },
  { src: 'assets/home-carousel/slide-07.jpg', alt: 'Filière PFNL, image 7' },
  { src: 'assets/home-carousel/slide-08.jpg', alt: 'Filière PFNL, image 8' },
  { src: 'assets/home-carousel/slide-09.jpg', alt: 'Filière PFNL, image 9' },
  { src: 'assets/home-carousel/slide-10.jpg', alt: 'Filière PFNL, image 10' },
  { src: 'assets/home-carousel/slide-11.jpg', alt: 'Filière PFNL, image 11' },
  { src: 'assets/home-carousel/slide-12.jpg', alt: 'Filière PFNL, image 12' },
  { src: 'assets/home-carousel/slide-13.jpg', alt: 'Filière PFNL, image 13' },
  { src: 'assets/home-carousel/slide-14.jpg', alt: 'Filière PFNL, image 14' },
];

const SLIDE_MS = 4500;

@Component({
  selector: 'app-home-page',
  imports: [RouterLink, FormsModule, ButtonComponent, IconComponent, SkeletonComponent, HomePartnersComponent],
  templateUrl: './home-page.component.html',
  styleUrl: './home-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HomePageComponent implements OnInit {
  private readonly publicService = inject(PublicService);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  readonly stats = signal<PublicStats | null>(null);
  readonly loading = signal(true);
  readonly slides = HERO_SLIDES;
  readonly activeIndex = signal(0);
  readonly paused = signal(false);
  recherche = '';

  ngOnInit(): void {
    this.publicService.stats().subscribe({
      next: (s) => {
        this.stats.set(s);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });

    interval(SLIDE_MS)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        if (!this.paused()) this.next();
      });
  }

  next(): void {
    this.activeIndex.update((i) => (i + 1) % this.slides.length);
  }

  prev(): void {
    this.activeIndex.update((i) => (i - 1 + this.slides.length) % this.slides.length);
  }

  goTo(index: number): void {
    this.activeIndex.set(index);
  }

  pause(): void {
    this.paused.set(true);
  }

  resume(): void {
    this.paused.set(false);
  }

  rechercher(): void {
    const q = this.recherche.trim();
    this.router.navigate(['/annuaire'], q ? { queryParams: { q } } : {});
  }
}
