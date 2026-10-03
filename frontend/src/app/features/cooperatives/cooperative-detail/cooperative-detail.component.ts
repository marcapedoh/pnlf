import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Subject, catchError, debounceTime, distinctUntilChanged, map, of, switchMap, tap } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { initialesStructure } from '../../../core/auth/display-name.util';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import {
  CandidatInvitation,
  Cooperative,
  InvitationCooperative,
  Producteur,
  STATUT_COOPERATIVE_LABELS,
  StatutCooperative,
  StatutInvitation,
} from '../../../core/models/producteur.model';
import { BadgeTone } from '../../../design-system/badge/status-badge.component';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { CooperativeMembre, CooperativesService } from '../../../core/services/cooperatives.service';
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { cooperativeStatusTone } from '../../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { PnlfDatePipe, PnlfTelephonePipe } from '../../../shared/pipes/format.pipes';

type DialogKind = 'valider' | 'rejeter' | 'desactiver' | 'activer' | 'retirer' | 'adhesion' | 'accepter' | 'refuser'
  | 'inviter' | 'annulerInvitation' | 'accepterInvitation' | 'refuserInvitation';

const TON_INVITATION: Record<StatutInvitation, BadgeTone> = {
  EN_ATTENTE: 'warning',
  ACCEPTEE: 'success',
  REFUSEE: 'danger',
  ANNULEE: 'neutral',
  CADUQUE: 'neutral',
};

@Component({
  selector: 'app-cooperative-detail',
  imports: [
    RouterLink,
    PnlfDatePipe,
    PnlfTelephonePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    ConfirmDialogComponent,
    AlertBannerComponent,
  ],
  templateUrl: './cooperative-detail.component.html',
  styleUrl: './cooperative-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CooperativeDetailComponent {
  private readonly service = inject(CooperativesService);
  private readonly producteursService = inject(ProducteursService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly coop = signal<Cooperative | null>(null);
  readonly membres = signal<CooperativeMembre[]>([]);
  readonly membresActifs = computed(() => this.membres().filter((m) => m.actif).length);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly uploadingPhoto = signal(false);
  readonly statutLabels = STATUT_COOPERATIVE_LABELS;
  readonly tone = cooperativeStatusTone;
  readonly StatutCooperative = StatutCooperative;

  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly canManagePhoto = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );
  /** Rattachement direct réservé à l'administration ; la coopérative accepte les demandes reçues. */
  readonly canAddMembres = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly canManageMembres = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly demandes = signal<CooperativeMembre[]>([]);
  readonly isCoopRole = this.auth.hasRole(RoleUtilisateur.COOPERATIVE);
  readonly isProducteur = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);

  readonly membreQuery = signal('');
  readonly membreResults = signal<Producteur[]>([]);
  readonly membreSearchDone = signal(false);
  readonly membreSearchError = signal('');
  readonly selectedCandidat = signal<Producteur | null>(null);
  readonly searchingMembre = signal(false);
  readonly addingMembre = signal(false);
  readonly membreError = signal('');
  private readonly membreSearch$ = new Subject<string>();

  /** Invitations : la coopérative propose l'adhésion à un producteur actif sans coopérative. */
  readonly invitations = signal<InvitationCooperative[]>([]);
  readonly invitationsEnAttente = computed(() => this.invitations().filter((i) => i.statut === 'EN_ATTENTE'));
  readonly invitationsTraitees = computed(() => this.invitations().filter((i) => i.statut !== 'EN_ATTENTE').slice(0, 10));
  readonly inviteQuery = signal('');
  readonly inviteResults = signal<CandidatInvitation[]>([]);
  readonly inviteSearching = signal(false);
  readonly inviteSearchDone = signal(false);
  readonly inviteSearchError = signal('');
  private readonly inviteSearch$ = new Subject<string>();
  readonly tonInvitation = (s: StatutInvitation): BadgeTone => TON_INVITATION[s] ?? 'neutral';

  readonly dialog = signal<{ kind: DialogKind; producteur?: string; nom?: string; invitation?: string } | null>(null);
  readonly dialogLoading = signal(false);
  readonly coopNom = computed(() => this.coop()?.nom ?? '');
  private readonly pdfPreview = inject(PdfPreviewService);

  constructor() {
    this.membreSearch$
      .pipe(
        map((q) => q.trim()),
        debounceTime(250),
        distinctUntilChanged(),
        tap((q) => {
          this.membreSearchError.set('');
          this.membreSearchDone.set(false);
          this.searchingMembre.set(q.length >= 2);
          if (q.length < 2) this.membreResults.set([]);
        }),
        switchMap((q) =>
          q.length < 2
            ? of(null)
            : this.producteursService
                .list({ search: q, page_size: 8, statut: 'ACTIF', candidats_adhesion: '1', hors_cooperative: this.id })
                .pipe(
                  map((res) => unwrapList(res)),
                  catchError((err) => {
                    this.membreSearchError.set(toApiError(err).message);
                    return of([] as Producteur[]);
                  }),
                ),
        ),
        takeUntilDestroyed(),
      )
      .subscribe((results) => {
        this.searchingMembre.set(false);
        if (results === null) return;
        const already = new Set(this.membres().map((m) => m.producteur));
        this.membreResults.set(results.filter((p) => !already.has(p.id)));
        this.membreSearchDone.set(true);
      });
    this.inviteSearch$
      .pipe(
        map((q) => q.trim()),
        debounceTime(250),
        distinctUntilChanged(),
        tap((q) => {
          this.inviteSearchError.set('');
          this.inviteSearchDone.set(false);
          this.inviteSearching.set(q.length >= 2);
          if (q.length < 2) this.inviteResults.set([]);
        }),
        switchMap((q) =>
          q.length < 2
            ? of(null)
            : this.service.candidatsInvitation(this.id, q).pipe(
                catchError((err) => {
                  this.inviteSearchError.set(toApiError(err).message);
                  return of([] as CandidatInvitation[]);
                }),
              ),
        ),
        takeUntilDestroyed(),
      )
      .subscribe((results) => {
        this.inviteSearching.set(false);
        if (results === null) return;
        this.inviteResults.set(results);
        this.inviteSearchDone.set(true);
      });
    this.load();
  }

  onInviteQueryChange(value: string): void {
    this.inviteQuery.set(value);
    this.inviteSearch$.next(value);
  }

  private relancerRechercheInvitation(): void {
    const q = this.inviteQuery().trim();
    if (q.length < 2) return;
    this.service.candidatsInvitation(this.id, q).subscribe({
      next: (r) => this.inviteResults.set(r),
      error: () => undefined,
    });
  }

  libelleType(type: string): string {
    return type === 'COLLECTEUR' ? 'Collecteur' : 'Producteur';
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id).subscribe({
      next: (c) => {
        this.coop.set(c);
        this.title.setTitle(`${c.nom} | PFNL`);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.coop.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
    this.reloadMembres();
  }

  private reloadMembres(): void {
    this.service.membres(this.id).subscribe({
      next: (m) => this.membres.set(m),
      error: () => this.membres.set([]),
    });
    if (this.canManageMembres) {
      this.service.demandesAdhesion(this.id).subscribe({
        next: (d) => this.demandes.set(d),
        error: () => this.demandes.set([]),
      });
      this.service.invitations(this.id).subscribe({
        next: (i) => this.invitations.set(i),
        error: () => this.invitations.set([]),
      });
    }
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const done = (ok: string, rechargerFiche = true) => {
      this.dialogLoading.set(false);
      this.dialog.set(null);
      this.toast.success(ok);
      if (rechargerFiche) this.load();
      else this.reloadMembres();
    };
    const fail = (titre: string) => (err: unknown) => {
      this.dialogLoading.set(false);
      this.dialog.set(null);
      this.toast.error(titre, toApiError(err).message);
    };
    switch (d.kind) {
      case 'valider':
        this.service.valider(this.id).subscribe({ next: () => done('Coopérative validée'), error: fail('Échec de la validation') });
        break;
      case 'rejeter':
        this.service.rejeter(this.id, value.trim()).subscribe({ next: () => done('Demande rejetée'), error: fail('Échec du rejet') });
        break;
      case 'desactiver':
        this.service.desactiver(this.id).subscribe({ next: () => done('Coopérative désactivée'), error: fail('Échec de la désactivation') });
        break;
      case 'activer':
        this.service.activer(this.id).subscribe({ next: () => done('Coopérative réactivée'), error: fail('Échec de la réactivation') });
        break;
      case 'adhesion':
        this.service.demanderAdhesion(this.id).subscribe({
          next: (res) => done(res.detail || 'Demande d’adhésion envoyée'),
          error: fail('Demande d’adhésion impossible'),
        });
        break;
      case 'accepter':
        if (d.producteur) {
          this.service.ajouterMembre(this.id, { producteur: d.producteur }).subscribe({
            next: () => done('Adhésion acceptée', false),
            error: fail('Impossible d’accepter cette demande'),
          });
        }
        break;
      case 'refuser':
        if (d.producteur) {
          this.service.refuserAdhesion(this.id, d.producteur, value.trim()).subscribe({
            next: () => done('Demande d’adhésion refusée', false),
            error: fail('Impossible de refuser cette demande'),
          });
        }
        break;
      case 'retirer':
        if (d.producteur) {
          this.service.retirerMembre(this.id, d.producteur).subscribe({
            next: () => done('Membre retiré', false),
            error: fail('Impossible de retirer ce membre'),
          });
        }
        break;
      case 'inviter':
        if (d.producteur) {
          this.service.inviter(this.id, d.producteur, value.trim() || undefined).subscribe({
            next: () => {
              done('Invitation envoyée', false);
              this.relancerRechercheInvitation();
            },
            error: fail('Invitation impossible'),
          });
        }
        break;
      case 'annulerInvitation':
        if (d.invitation) {
          this.service.annulerInvitation(this.id, d.invitation).subscribe({
            next: () => {
              done('Invitation annulée', false);
              this.relancerRechercheInvitation();
            },
            error: fail('Impossible d’annuler cette invitation'),
          });
        }
        break;
      case 'accepterInvitation':
        if (d.invitation) {
          this.service.accepterInvitation(d.invitation).subscribe({
            next: (res) => done(res.detail || 'Invitation acceptée'),
            error: fail('Impossible d’accepter l’invitation'),
          });
        }
        break;
      case 'refuserInvitation':
        if (d.invitation) {
          this.service.refuserInvitation(d.invitation, value.trim() || undefined).subscribe({
            next: () => done('Invitation refusée'),
            error: fail('Impossible de refuser l’invitation'),
          });
        }
        break;
    }
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (c) => {
        this.coop.set(c);
        this.uploadingPhoto.set(false);
        this.toast.success('Logo mis à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        const apiError = toApiError(err);
        this.toast.error('Échec du téléversement', apiError.fieldErrors?.['photo']?.[0] ?? apiError.message);
        input.value = '';
      },
    });
  }

  initials(nom: string): string {
    return initialesStructure(nom);
  }

  get membreComboOpen(): boolean {
    return (
      !this.selectedCandidat() &&
      this.membreQuery().trim().length >= 2 &&
      (this.searchingMembre() || this.membreSearchDone() || !!this.membreSearchError())
    );
  }

  onMembreQueryChange(value: string): void {
    this.membreQuery.set(value);
    this.selectedCandidat.set(null);
    this.membreError.set('');
    this.membreSearch$.next(value);
  }

  onMembreKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      this.membreResults.set([]);
      this.membreSearchDone.set(false);
    }
  }

  selectCandidat(p: Producteur): void {
    this.selectedCandidat.set(p);
    this.membreResults.set([]);
    this.membreSearchDone.set(false);
    this.membreError.set('');
    this.membreQuery.set(`${p.prenoms} ${p.nom} (${p.code_producteur})`);
  }

  ajouterMembre(): void {
    const p = this.selectedCandidat();
    if (!p) {
      this.membreError.set('Recherchez puis sélectionnez un producteur à rattacher.');
      return;
    }
    this.addingMembre.set(true);
    this.service.ajouterMembre(this.id, { producteur: p.id }).subscribe({
      next: () => {
        this.addingMembre.set(false);
        this.selectedCandidat.set(null);
        this.membreQuery.set('');
        this.membreResults.set([]);
        this.toast.success('Membre enregistré', `${p.prenoms} ${p.nom}`);
        this.reloadMembres();
      },
      error: (err) => {
        this.addingMembre.set(false);
        const apiError = toApiError(err);
        this.membreError.set(apiError.fieldErrors?.['producteur']?.[0] ?? apiError.message);
      },
    });
  }

  exporterPdf(): void {
    const c = this.coop();
    const filename = `fiche-cooperative-${c?.code ?? this.id}.pdf`;
    this.pdfPreview.open('Fiche coopérative', filename, () => this.service.fichePdfBlob(this.id));
  }
}
