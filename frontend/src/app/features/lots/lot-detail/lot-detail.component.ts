import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { environment } from '../../../../environments/environment';
import {
  Lot,
  STATUT_LOT_LABELS,
  STATUT_LOT_ORDRE,
  StatutLot,
  TYPE_MOUVEMENT_LABELS,
} from '../../../core/models/lot.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-lot-detail',
  imports: [RouterLink, DatePipe, FormsModule, CardComponent, StatusBadgeComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent],
  templateUrl: './lot-detail.component.html',
  styleUrl: './lot-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotDetailComponent {
  private readonly service = inject(LotsService);
  private readonly http = inject(HttpClient);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly lot = signal<Lot | null>(null);
  readonly loading = signal(true);
  readonly changingStatus = signal(false);
  readonly nextStatut = signal('');

  readonly statutLabels = STATUT_LOT_LABELS;
  readonly typeMouvementLabels = TYPE_MOUVEMENT_LABELS;
  readonly tone = lotStatusTone;
  readonly verifyUrl = (uuid: string) => `${window.location.origin}/verifier/${uuid}`;
  readonly appApiOrigin = environment.apiUrl.replace(/\/api$/, '');

  readonly canChangeStatus = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/lots']);
      },
    });
  }

  nextStatusOptions(): StatutLot[] {
    const current = this.lot()?.statut;
    if (!current) return [];
    const idx = STATUT_LOT_ORDRE.indexOf(current as StatutLot);
    return idx >= 0 ? STATUT_LOT_ORDRE.slice(idx + 1) : [];
  }

  changerStatut(): void {
    if (!this.nextStatut()) return;
    this.changingStatus.set(true);
    this.service.changerStatut(this.id, this.nextStatut()).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.changingStatus.set(false);
        this.nextStatut.set('');
        this.toast.success('Statut mis à jour', `Le lot est désormais "${this.statutLabels[lot.statut]}".`);
      },
      error: () => {
        this.changingStatus.set(false);
        this.toast.error('Échec de la mise à jour du statut');
      },
    });
  }

  copyVerifyLink(uuid: string): void {
    navigator.clipboard?.writeText(this.verifyUrl(uuid));
    this.toast.info('Lien copié', "Le lien de vérification publique a été copié.");
  }

  downloadQr(): void {
    const lot = this.lot();
    if (!lot) return;
    this.http.get(this.service.qrDownloadUrl(lot.id), { responseType: 'blob' }).subscribe((blob) => {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${lot.code_lot}-qr.png`;
      a.click();
      URL.revokeObjectURL(url);
    });
  }
}
