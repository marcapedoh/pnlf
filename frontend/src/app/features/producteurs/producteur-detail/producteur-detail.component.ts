import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import {
  messageFromDownloadError,
  navigateOpenedTab,
  openPdfTicketTab,
  toSameOriginUrl,
  writePdfLoadingPlaceholder,
} from '../../../core/http/download-file.util';
import { unwrapList } from '../../../core/models/common.model';
import { Lot, STATUT_LOT_LABELS } from '../../../core/models/lot.model';
import { Producteur, STATUT_PRODUCTEUR_LABELS, StatutProducteur } from '../../../core/models/producteur.model';
import { MessagePublic } from '../../../core/models/public.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { lotStatusTone, producteurStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';

@Component({
  selector: 'app-producteur-detail',
  imports: [RouterLink, DatePipe, CardComponent, StatusBadgeComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent, ConfirmDialogComponent],
  templateUrl: './producteur-detail.component.html',
  styleUrl: './producteur-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteurDetailComponent {
  private readonly service = inject(ProducteursService);
  private readonly lotsService = inject(LotsService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly producteur = signal<Producteur | null>(null);
  readonly lots = signal<Lot[]>([]);
  readonly messages = signal<MessagePublic[]>([]);
  readonly loading = signal(true);
  readonly statutLabels = STATUT_PRODUCTEUR_LABELS;
  readonly statutLotLabels = STATUT_LOT_LABELS;
  readonly tone = producteurStatusTone;
  readonly lotTone = lotStatusTone;
  readonly StatutProducteur = StatutProducteur;

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canValidate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );
  readonly uploadingPhoto = signal(false);
  readonly dialog = signal<{ kind: 'rejeter' | 'desactiver' } | null>(null);
  readonly dialogLoading = signal(false);
  readonly exportingPdf = signal(false);
  readonly pdfReadyUrl = signal<string | null>(null);

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/producteurs']);
      },
    });
    this.lotsService.list({ producteur: this.id, page_size: 10 }).subscribe((res) => {
      this.lots.set(unwrapList(res));
    });
    this.service.messagesPublics(this.id).subscribe({
      next: (res) => this.messages.set(unwrapList(res)),
      error: () => this.messages.set([]),
    });
  }

  valider(): void {
    this.service.valider(this.id).subscribe({
      next: () => {
        this.toast.success('Fiche validée avec succès');
        this.load();
      },
      error: () => this.toast.error('Échec de la validation'),
    });
  }

  rejeter(): void {
    this.dialog.set({ kind: 'rejeter' });
  }

  desactiver(): void {
    this.dialog.set({ kind: 'desactiver' });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const req$ = d.kind === 'rejeter' ? this.service.rejeter(this.id, value.trim()) : this.service.desactiver(this.id);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.toast.success(d.kind === 'rejeter' ? 'Fiche rejetée' : 'Fiche désactivée');
        this.load();
      },
      error: () => {
        this.dialogLoading.set(false);
        this.toast.error(d.kind === 'rejeter' ? 'Échec du rejet' : 'Échec de la désactivation');
      },
    });
  }

  activer(): void {
    this.service.activer(this.id).subscribe({
      next: () => {
        this.toast.success('Fiche réactivée');
        this.load();
      },
      error: () => this.toast.error('Échec de la réactivation'),
    });
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.uploadingPhoto.set(false);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        const msg = err?.error?.photo?.[0] || err?.error?.detail || 'Échec du téléversement';
        this.toast.error(msg);
        input.value = '';
      },
    });
  }

  initials(p: Producteur): string {
    return `${p.prenoms.charAt(0)}${p.nom.charAt(0)}`.toUpperCase();
  }

  exporterPdf(): void {
    this.pdfReadyUrl.set(null);
    const tab = openPdfTicketTab();
    writePdfLoadingPlaceholder(tab);
    this.exportingPdf.set(true);
    this.service.createFichePdfTicket(this.id).subscribe({
      next: ({ url }) => {
        this.exportingPdf.set(false);
        if (navigateOpenedTab(tab, url)) {
          this.toast.success('Le PDF s’ouvre dans un nouvel onglet.');
          return;
        }
        this.pdfReadyUrl.set(toSameOriginUrl(url));
        this.toast.info('Cliquez sur « Ouvrir le PDF » — le navigateur a bloqué la nouvelle fenêtre.');
      },
      error: (err: unknown) => {
        this.exportingPdf.set(false);
        tab?.close();
        this.toast.error(messageFromDownloadError(err));
      },
    });
  }

  marquerTraite(m: MessagePublic): void {
    this.service.marquerMessageTraite(m.id).subscribe({
      next: (updated) => {
        this.messages.set(this.messages().map((x) => (x.id === updated.id ? updated : x)));
        this.toast.success('Message marqué comme traité');
      },
      error: () => this.toast.error('Impossible de marquer ce message'),
    });
  }
}
