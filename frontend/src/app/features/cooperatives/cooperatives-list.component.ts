import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { Observable, Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { Cooperative, STATUT_COOPERATIVE_LABELS, StatutCooperative } from '../../core/models/producteur.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CooperativesService } from '../../core/services/cooperatives.service';
import { PdfPreviewService } from '../../core/services/pdf-preview.service';
import { ReferenceService } from '../../core/services/reference.service';
import { cooperativeStatusTone } from '../../core/ui/status-tone.util';
import { normaliserTelephone, telephoneValidator } from '../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { toApiError } from '../../core/http/api-error.util';
import { PnlfTelephonePipe } from '../../shared/pipes/format.pipes';
import { InvitationsRecuesComponent } from './invitations-recues/invitations-recues.component';

type DialogKind = 'valider' | 'rejeter' | 'desactiver' | 'activer' | 'adhesion';

const DIALOG_MESSAGES: Record<DialogKind, { ok: string; ko: string }> = {
  valider: { ok: 'Coopérative validée', ko: 'Échec de la validation' },
  rejeter: { ok: 'Demande rejetée', ko: 'Échec du rejet' },
  desactiver: { ok: 'Coopérative désactivée', ko: 'Échec de la désactivation' },
  activer: { ok: 'Coopérative réactivée', ko: 'Échec de la réactivation' },
  adhesion: { ok: 'Demande d’adhésion envoyée', ko: 'Demande d’adhésion impossible' },
};

type FormKey = 'nom' | 'telephone' | 'email' | 'province';

@Component({
  selector: 'app-cooperatives-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    RouterLink,
    PnlfTelephonePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    SelectFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    ConfirmDialogComponent,
    SkeletonComponent,
    InvitationsRecuesComponent,
  ],
  templateUrl: './cooperatives-list.component.html',
  styleUrl: './cooperatives-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CooperativesListComponent {
  private readonly service = inject(CooperativesService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly router = inject(Router);
  private readonly pdfPreview = inject(PdfPreviewService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Cooperative[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly provinces = signal<SelectOption[]>([]);

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;
  readonly search = signal('');

  readonly statutLabels = STATUT_COOPERATIVE_LABELS;
  readonly tone = cooperativeStatusTone;
  readonly StatutCooperative = StatutCooperative;

  /** Création d'une coopérative depuis l'espace : réservée à l'administration. */
  readonly canCreate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly isCoopRole = this.auth.hasRole(RoleUtilisateur.COOPERATIVE);
  readonly isProducteur = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  readonly dialog = signal<{ kind: DialogKind; item: Cooperative } | null>(null);
  readonly dialogNom = computed(() => this.dialog()?.item.nom ?? '');
  readonly dialogLoading = signal(false);

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    province: [''],
    telephone: ['', telephoneValidator],
    email: ['', Validators.email],
    adresse: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  constructor() {
    if (this.isCoopRole) {
      // Une coopérative n'a accès qu'à sa propre fiche : redirection sans afficher la liste.
      this.service.list({ page_size: 1 }).subscribe({
        next: (res) => {
          const own = unwrapList(res)[0];
          if (own) {
            this.router.navigate(['/app/cooperatives', own.id], { replaceUrl: true });
            return;
          }
          this.loading.set(false);
        },
        error: (err) => {
          this.loading.set(false);
          this.loadError.set(toApiError(err).message);
        },
      });
      return;
    }
    if (this.canCreate) {
      this.referenceService.provinces().subscribe((res) => {
        this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
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
    this.loadError.set('');
    this.service
      .list({ page: this.page(), page_size: this.pageSize, search: this.search() })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: (err) => {
          this.loading.set(false);
          this.loadError.set(toApiError(err).message);
        },
      });
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    const raw = this.form.getRawValue();
    this.saving.set(true);
    this.service
      .create({
        ...raw,
        province: raw.province || null,
        telephone: raw.telephone ? normaliserTelephone(raw.telephone) : null,
        email: raw.email.trim() || null,
      })
      .subscribe({
        next: (coop) => {
          this.saving.set(false);
          this.showForm.set(false);
          this.form.reset();
          this.toast.success('Coopérative créée', [coop.nom, coop.code, coop.numero_agrement].filter(Boolean).join(' · '));
          this.load();
        },
        error: (err) => {
          this.saving.set(false);
          this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
        },
      });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const id = d.item.id;
    const req$: Observable<unknown> =
      d.kind === 'rejeter'
        ? this.service.rejeter(id, value.trim())
        : d.kind === 'valider'
          ? this.service.valider(id)
          : d.kind === 'activer'
            ? this.service.activer(id)
            : d.kind === 'adhesion'
              ? this.service.demanderAdhesion(id)
              : this.service.desactiver(id);
    req$.subscribe({
      next: (res: unknown) => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        const detail = d.kind === 'adhesion' ? (res as { detail?: string } | null)?.detail : d.item.nom;
        this.toast.success(DIALOG_MESSAGES[d.kind].ok, detail);
        this.load();
      },
      error: (err: unknown) => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.toast.error(DIALOG_MESSAGES[d.kind].ko, toApiError(err).message);
      },
    });
  }

  exporterListePdf(): void {
    this.pdfPreview.open('Liste des coopératives', 'pnlf-cooperatives.pdf', () =>
      this.service.listePdfBlob({ search: this.search() }),
    );
  }
}
