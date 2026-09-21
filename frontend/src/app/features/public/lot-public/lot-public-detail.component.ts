import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { PublicLotDetail } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { STATUT_LOT_LABELS, StatutLot } from '../../../core/models/lot.model';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-lot-public-detail',
  imports: [RouterLink, DatePipe, DecimalPipe, ButtonComponent, SkeletonComponent, IconComponent, StatusBadgeComponent],
  templateUrl: './lot-public-detail.component.html',
  styleUrl: './lot-public-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotPublicDetailComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly lot = signal<PublicLotDetail | null>(null);
  readonly loading = signal(true);
  readonly notFound = signal(false);
  readonly activePhoto = signal(0);

  constructor() {
    this.publicService.lot(this.id).subscribe({
      next: (l) => {
        this.lot.set(l);
        this.loading.set(false);
      },
      error: () => {
        this.notFound.set(true);
        this.loading.set(false);
      },
    });
  }

  initials(nom: string, prenoms: string): string {
    return `${prenoms.charAt(0)}${nom.charAt(0)}`.toUpperCase();
  }

  selectPhoto(index: number): void {
    this.activePhoto.set(index);
  }

  mapsUrl(lat: number, lon: number): string {
    return `https://www.google.com/maps?q=${lat},${lon}`;
  }

  statutLabel(statut: string): string {
    return STATUT_LOT_LABELS[statut as StatutLot] ?? statut;
  }

  statutTone(statut: string) {
    return lotStatusTone(statut as StatutLot);
  }

  partager(l: PublicLotDetail): void {
    const url = l.uuid_public ? `${window.location.origin}/verifier/${l.uuid_public}` : window.location.href;
    if (navigator.share) {
      navigator.share({ title: `Lot ${l.code_lot} — ${l.produit_nom}`, url }).catch(() => {});
      return;
    }
    navigator.clipboard?.writeText(url).then(
      () => this.toast.success('Lien de traçabilité copié'),
      () => this.toast.info(url),
    );
  }

  imprimer(): void {
    window.print();
  }
}
