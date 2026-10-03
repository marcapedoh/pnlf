import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { toApiError } from '../../core/http/api-error.util';
import { FiltreModerationImages, ModerationImage } from '../../core/models/moderation-image.model';
import { ROLE_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { ModerationImagesService } from '../../core/services/moderation-images.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { BadgeTone, StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../design-system/icon/icon.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { PnlfDatePipe } from '../../shared/pipes/format.pipes';

type ActionModeration = { type: 'approuver' | 'rejeter'; image: ModerationImage };

const TONS_STATUT: Record<string, BadgeTone> = {
  EN_ATTENTE: 'warning',
  APPROUVEE: 'success',
  REJETEE: 'danger',
  REMPLACEE: 'neutral',
};

@Component({
  selector: 'app-moderation-images',
  imports: [
    RouterLink,
    PnlfDatePipe,
    AlertBannerComponent,
    ButtonComponent,
    ConfirmDialogComponent,
    EmptyStateComponent,
    IconComponent,
    PaginationComponent,
    SkeletonComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './moderation-images.component.html',
  styleUrl: './moderation-images.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ModerationImagesComponent {
  private readonly service = inject(ModerationImagesService);
  private readonly toast = inject(ToastService);

  readonly pageSize = 12;
  readonly filtre = signal<FiltreModerationImages>('EN_ATTENTE');
  readonly page = signal(1);
  readonly images = signal<ModerationImage[]>([]);
  readonly total = signal(0);
  readonly enAttente = signal<number | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly defloutees = signal<ReadonlySet<string>>(new Set());
  readonly action = signal<ActionModeration | null>(null);
  readonly actionEnCours = signal(false);

  readonly squelettes = Array.from({ length: 6 }, (_, i) => i);
  readonly titreAction = computed(() =>
    this.action()?.type === 'rejeter' ? 'Rejeter cette image ?' : 'Approuver cette image ?',
  );
  readonly messageAction = computed(() => {
    const a = this.action();
    if (!a) return '';
    const cible = a.image.objet_libelle ? ` (${a.image.objet_libelle})` : '';
    return a.type === 'rejeter'
      ? `L’image${cible} sera supprimée définitivement et retirée de la fiche. L’auteur sera prévenu avec le motif indiqué.`
      : `L’image${cible} deviendra visible pour tous les utilisateurs autorisés. L’auteur sera prévenu.`;
  });

  constructor() {
    this.charger();
  }

  changerFiltre(filtre: FiltreModerationImages): void {
    if (filtre === this.filtre()) return;
    this.filtre.set(filtre);
    this.page.set(1);
    this.charger();
  }

  changerPage(page: number): void {
    this.page.set(page);
    this.charger();
  }

  charger(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.lister(this.filtre(), this.page(), this.pageSize).subscribe({
      next: (res) => {
        this.images.set(res.results);
        this.total.set(res.count);
        if (this.filtre() === 'EN_ATTENTE') this.enAttente.set(res.count);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
    if (this.filtre() !== 'EN_ATTENTE') {
      this.service.compteur().subscribe({ next: (c) => this.enAttente.set(c.en_attente), error: () => undefined });
    }
  }

  estDefloutee(id: string): boolean {
    return this.defloutees().has(id);
  }

  basculerFlou(id: string): void {
    this.defloutees.update((ids) => {
      const suivant = new Set(ids);
      if (suivant.has(id)) suivant.delete(id);
      else suivant.add(id);
      return suivant;
    });
  }

  demander(type: ActionModeration['type'], image: ModerationImage): void {
    this.action.set({ type, image });
  }

  annuler(): void {
    if (!this.actionEnCours()) this.action.set(null);
  }

  confirmer(motif: string): void {
    const a = this.action();
    if (!a) return;
    if (a.type === 'rejeter' && motif.trim().length < 5) {
      this.toast.warning('Motif trop court', 'Indiquez au moins 5 caractères : le motif est communiqué à l’auteur.');
      return;
    }
    this.actionEnCours.set(true);
    const requete = a.type === 'rejeter' ? this.service.rejeter(a.image.id, motif) : this.service.approuver(a.image.id);
    requete.subscribe({
      next: () => {
        this.actionEnCours.set(false);
        this.action.set(null);
        this.toast.success(
          a.type === 'rejeter' ? 'Image rejetée' : 'Image approuvée',
          a.type === 'rejeter'
            ? 'Le fichier a été supprimé et l’auteur a été prévenu.'
            : 'L’image est désormais visible et l’auteur a été prévenu.',
        );
        if (this.images().length === 1 && this.page() > 1) this.page.update((p) => p - 1);
        this.charger();
      },
      error: (err) => {
        this.actionEnCours.set(false);
        this.toast.error('Action impossible', toApiError(err).message);
        if (toApiError(err).status === 400) {
          this.action.set(null);
          this.charger();
        }
      },
    });
  }

  pourcentage(score: number | null | undefined): string {
    return score === null || score === undefined ? 'non mesuré' : `${Math.round(score * 100)} %`;
  }

  libelleRole(role: string | undefined): string {
    return role ? (ROLE_LABELS[role as RoleUtilisateur] ?? role) : '';
  }

  tonStatut(statut: string): BadgeTone {
    return TONS_STATUT[statut] ?? 'neutral';
  }

  raisonAnalyse(image: ModerationImage): string {
    if (image.scores.motif) {
      return 'Analyse automatique indisponible au moment de l’envoi : image mise en attente par précaution.';
    }
    return `Score de contenu sensible : ${this.pourcentage(image.score_nsfw)} (zone de doute à partir de ${this.pourcentage(image.scores.seuil_douteux)}).`;
  }
}
