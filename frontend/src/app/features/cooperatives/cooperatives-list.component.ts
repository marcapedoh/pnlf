import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../core/auth/auth.service';
import {
  messageFromDownloadError,
  navigateOpenedTab,
  openPdfTicketTab,
  toSameOriginUrl,
  writePdfLoadingPlaceholder,
} from '../../core/http/download-file.util';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { Cooperative, STATUT_COOPERATIVE_LABELS, StatutCooperative } from '../../core/models/producteur.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CooperativesService } from '../../core/services/cooperatives.service';
import { cooperativeStatusTone } from '../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { toApiError } from '../../core/http/api-error.util';

@Component({
  selector: 'app-cooperatives-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    RouterLink,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    ConfirmDialogComponent,
    SkeletonComponent,
  ],
  templateUrl: './cooperatives-list.component.html',
  styleUrl: './cooperatives-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CooperativesListComponent {
  private readonly service = inject(CooperativesService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly router = inject(Router);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Cooperative[]>([]);
  readonly loading = signal(true);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;
  readonly search = signal('');

  readonly statutLabels = STATUT_COOPERATIVE_LABELS;
  readonly tone = cooperativeStatusTone;
  readonly StatutCooperative = StatutCooperative;

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly isCoopRole = this.auth.hasRole(RoleUtilisateur.COOPERATIVE);
  readonly isProducteur = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  readonly dialog = signal<{ kind: 'rejeter' | 'desactiver'; item: Cooperative } | null>(null);
  readonly dialogLoading = signal(false);
  readonly adhesionId = signal<string | null>(null);
  readonly exportingPdf = signal(false);
  readonly pdfReadyUrl = signal<string | null>(null);

  readonly form = this.fb.nonNullable.group({
    code: ['', Validators.required],
    nom: ['', Validators.required],
    numero_agrement: [''],
    telephone: [''],
    email: [''],
    adresse: [''],
  });

  constructor() {
    if (this.isCoopRole) {
      this.service.list({ page_size: 1 }).subscribe((res) => {
        const own = unwrapList(res)[0];
        if (own) this.router.navigate(['/app/cooperatives', own.id], { replaceUrl: true });
      });
    }
    this.search$.pipe(debounceTime(350), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  onSearchInput(value: string): void {
    this.search.set(value);
    this.search$.next();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service
      .list({ page: this.page(), page_size: this.pageSize, search: this.search() })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  submit(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    this.service.create(this.form.getRawValue()).subscribe({
      next: () => {
        this.saving.set(false);
        this.showForm.set(false);
        this.form.reset();
        this.toast.success('Coopérative créée avec succès');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }

  valider(coop: Cooperative): void {
    this.service.valider(coop.id).subscribe({
      next: () => {
        this.toast.success('Coopérative validée avec succès');
        this.load();
      },
      error: (err) => this.toast.error(toApiError(err).message),
    });
  }

  rejeter(coop: Cooperative): void {
    this.dialog.set({ kind: 'rejeter', item: coop });
  }

  desactiver(coop: Cooperative): void {
    this.dialog.set({ kind: 'desactiver', item: coop });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const req$ = d.kind === 'rejeter' ? this.service.rejeter(d.item.id, value.trim()) : this.service.desactiver(d.item.id);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.toast.success(d.kind === 'rejeter' ? 'Demande rejetée' : 'Coopérative désactivée');
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  demanderAdhesion(coop: Cooperative, event: Event): void {
    event.stopPropagation();
    this.adhesionId.set(coop.id);
    this.service.demanderAdhesion(coop.id).subscribe({
      next: (res) => {
        this.adhesionId.set(null);
        this.toast.success(res.detail || 'Demande d’adhésion envoyée');
      },
      error: (err) => {
        this.adhesionId.set(null);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  activer(coop: Cooperative): void {
    this.service.activer(coop.id).subscribe({
      next: () => {
        this.toast.success('Coopérative réactivée');
        this.load();
      },
      error: (err) => this.toast.error(toApiError(err).message),
    });
  }

  exporterListePdf(): void {
    this.pdfReadyUrl.set(null);
    const tab = openPdfTicketTab();
    writePdfLoadingPlaceholder(tab);
    this.exportingPdf.set(true);
    this.service.createListePdfTicket({ search: this.search() }).subscribe({
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
}
