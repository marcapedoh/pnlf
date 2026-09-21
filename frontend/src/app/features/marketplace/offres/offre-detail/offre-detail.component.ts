import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../../core/auth/auth.service';
import { toApiError } from '../../../../core/http/api-error.util';
import { unwrapList } from '../../../../core/models/common.model';
import { OffreDemande, STATUT_OFFRE_DEMANDE_LABELS } from '../../../../core/models/notification.model';
import { RoleUtilisateur } from '../../../../core/models/user.model';
import { MarketplaceService } from '../../../../core/services/marketplace.service';
import { ButtonComponent } from '../../../../design-system/button/button.component';
import { CardComponent } from '../../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../../design-system/confirm-dialog/confirm-dialog.component';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-offre-detail',
  imports: [RouterLink, DatePipe, DecimalPipe, FormsModule, CardComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent, StatusBadgeComponent, ConfirmDialogComponent],
  templateUrl: './offre-detail.component.html',
  styleUrl: './offre-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffreDetailComponent {
  private readonly service = inject(MarketplaceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly offre = signal<OffreDemande | null>(null);
  readonly loading = signal(true);
  readonly acting = signal(false);
  readonly statutLabels = STATUT_OFFRE_DEMANDE_LABELS;
  readonly activePhoto = signal(0);

  readonly currentUserId = this.auth.currentUser()?.id;
  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly dialog = signal<{ kind: 'rejeter' | 'cloturer' } | null>(null);
  readonly dialogLoading = signal(false);
  readonly message = signal('');
  readonly sending = signal(false);
  readonly conversationId = signal<string | null>(null);
  readonly fil = signal<{ id: string; contenu: string | null; expediteur_id: string; created_at: string; piece_type?: string | null; piece_url?: string | null }[]>([]);

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (o) => {
        this.offre.set(o);
        this.loading.set(false);
        this.chargerFil();
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/marketplace/offres']);
      },
    });
  }

  isAuteur(): boolean {
    return this.offre()?.auteur_id === this.currentUserId;
  }

  chargerFil(): void {
    this.service.conversations({ offre_id: this.id }).subscribe({
      next: (res) => {
        const conv = unwrapList(res)[0];
        if (!conv) return;
        this.conversationId.set(conv.id);
        this.service.messages(conv.id).subscribe({
          next: (msgs) => this.fil.set(msgs),
        });
      },
    });
  }

  valider(): void {
    this.acting.set(true);
    this.service.valider(this.id).subscribe({
      next: () => {
        this.acting.set(false);
        this.toast.success('Annonce validée et publiée avec QR code.');
        this.load();
      },
      error: (err) => {
        this.acting.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  rejeter(): void {
    this.dialog.set({ kind: 'rejeter' });
  }

  cloturer(): void {
    this.dialog.set({ kind: 'cloturer' });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    this.acting.set(true);
    const req$ = d.kind === 'rejeter' ? this.service.rejeter(this.id, value.trim()) : this.service.cloturer(this.id);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.acting.set(false);
        this.dialog.set(null);
        this.toast.success(d.kind === 'rejeter' ? 'Annonce rejetée' : 'Annonce clôturée');
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.acting.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  repondre(): void {
    const contenu = this.message().trim();
    if (!contenu) return;
    this.sending.set(true);
    const convId = this.conversationId();
    const send = (id: string) => {
      this.service.envoyerMessage(id, contenu).subscribe({
        next: () => {
          this.sending.set(false);
          this.message.set('');
          this.toast.success('Message envoyé');
          this.chargerFil();
        },
        error: (err) => {
          this.sending.set(false);
          this.toast.error(toApiError(err).message);
        },
      });
    };
    if (convId) {
      send(convId);
      return;
    }
    this.service.ouvrirConversation({ sujet: this.offre()?.titre, offre_id: this.id }).subscribe({
      next: (c) => {
        this.conversationId.set(c.id);
        send(c.id);
      },
      error: (err) => {
        this.sending.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  selectPhoto(i: number): void {
    this.activePhoto.set(i);
  }
}
