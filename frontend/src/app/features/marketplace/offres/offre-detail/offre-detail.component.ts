import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { AuthService } from '../../../../core/auth/auth.service';
import { toApiError } from '../../../../core/http/api-error.util';
import { unwrapList } from '../../../../core/models/common.model';
import { OffreDemande, STATUT_OFFRE_DEMANDE_LABELS } from '../../../../core/models/notification.model';
import { RoleUtilisateur } from '../../../../core/models/user.model';
import { ConversationResume, MarketplaceService } from '../../../../core/services/marketplace.service';
import { AlertBannerComponent } from '../../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../../design-system/button/button.component';
import { CardComponent } from '../../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../../design-system/confirm-dialog/confirm-dialog.component';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe } from '../../../../shared/pipes/format.pipes';

type MessageFil = {
  id: string;
  contenu: string | null;
  expediteur_id: string;
  created_at: string;
  piece_type?: string | null;
  piece_url?: string | null;
};

@Component({
  selector: 'app-offre-detail',
  imports: [
    RouterLink,
    FormsModule,
    PnlfDatePipe,
    PnlfMontantPipe,
    PnlfQuantitePipe,
    PnlfUnitePipe,
    CardComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    StatusBadgeComponent,
    ConfirmDialogComponent,
    AlertBannerComponent,
  ],
  templateUrl: './offre-detail.component.html',
  styleUrl: './offre-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffreDetailComponent {
  private readonly service = inject(MarketplaceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly offre = signal<OffreDemande | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly acting = signal(false);
  readonly statutLabels = STATUT_OFFRE_DEMANDE_LABELS;
  readonly activePhoto = signal(0);

  readonly currentUserId = this.auth.currentUser()?.id;
  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  private readonly estAgent = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );
  readonly dialog = signal<{ kind: 'valider' | 'rejeter' | 'cloturer' } | null>(null);
  readonly dialogLoading = signal(false);
  readonly message = signal('');
  readonly sending = signal(false);
  readonly conversations = signal<ConversationResume[]>([]);
  readonly conversationId = signal<string | null>(null);
  readonly fil = signal<MessageFil[]>([]);
  readonly filError = signal('');

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id).subscribe({
      next: (o) => {
        this.offre.set(o);
        this.title.setTitle(`${o.titre} | PFNL`);
        this.loading.set(false);
        this.chargerConversations();
      },
      error: (err) => {
        this.loading.set(false);
        this.offre.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  isAuteur(): boolean {
    return this.offre()?.auteur_id === this.currentUserId;
  }

  tone(statut: string): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === 'OUVERTE') return 'success';
    if (statut === 'EN_VALIDATION') return 'warning';
    if (statut === 'REJETEE') return 'danger';
    return 'neutral';
  }

  /** L'auteur voit toutes les conversations reçues ; un visiteur ne voit que la sienne. */
  chargerConversations(): void {
    this.service.conversations({ offre_id: this.id }).subscribe({
      next: (res) => {
        const convs = unwrapList(res);
        this.conversations.set(convs);
        const courante = this.conversationId();
        const cible = convs.find((c) => c.id === courante) ?? (this.isAuteur() && convs.length > 1 ? null : convs[0]);
        if (cible) this.ouvrirFil(cible.id);
      },
      error: (err) => this.filError.set(toApiError(err).message),
    });
  }

  ouvrirFil(conversationId: string): void {
    this.conversationId.set(conversationId);
    this.filError.set('');
    this.service.messages(conversationId).subscribe({
      next: (msgs) => this.fil.set(msgs),
      error: (err) => this.filError.set(toApiError(err).message),
    });
  }

  interlocuteur(convId: string | null): string {
    return this.conversations().find((c) => c.id === convId)?.interlocuteur_nom || 'votre interlocuteur';
  }

  /** Un fil existant reste ouvert ; un nouveau fil n'est possible que sur une annonce publiée (sauf agents). */
  peutEcrire(): boolean {
    if (this.conversationId()) return true;
    if (this.isAuteur()) return false;
    return this.offre()?.statut === 'OUVERTE' || this.estAgent;
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    this.acting.set(true);
    const req$ =
      d.kind === 'valider'
        ? this.service.valider(this.id)
        : d.kind === 'rejeter'
          ? this.service.rejeter(this.id, value.trim())
          : this.service.cloturer(this.id);
    const libelles = {
      valider: ['Annonce validée et publiée', 'Échec de la validation'],
      rejeter: ['Annonce rejetée', 'Échec du rejet'],
      cloturer: ['Annonce clôturée', 'Échec de la clôture'],
    } as const;
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.acting.set(false);
        this.dialog.set(null);
        this.toast.success(libelles[d.kind][0]);
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.acting.set(false);
        this.dialog.set(null);
        this.toast.error(libelles[d.kind][1], toApiError(err).message);
      },
    });
  }

  repondre(): void {
    const contenu = this.message().trim();
    if (!contenu || !this.peutEcrire()) return;
    this.sending.set(true);
    const convId = this.conversationId();
    const send = (id: string) => {
      this.service.envoyerMessage(id, contenu).subscribe({
        next: () => {
          this.sending.set(false);
          this.message.set('');
          this.toast.success('Message envoyé');
          this.chargerConversations();
        },
        error: (err) => {
          this.sending.set(false);
          this.toast.error('Message non envoyé', toApiError(err).message);
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
        const apiError = toApiError(err);
        this.toast.error('Message non envoyé', apiError.fieldErrors?.['offre_id']?.[0] ?? apiError.message);
      },
    });
  }

  selectPhoto(i: number): void {
    this.activePhoto.set(i);
  }
}
