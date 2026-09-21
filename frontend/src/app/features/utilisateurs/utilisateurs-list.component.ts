import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { toApiError } from '../../core/http/api-error.util';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { ROLE_LABELS, RoleUtilisateur, STATUT_COMPTE_LABELS, StatutCompte, Utilisateur } from '../../core/models/user.model';
import { UsersAdminService } from '../../core/services/users-admin.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-utilisateurs-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    RouterLink,
    CardComponent,
    ButtonComponent,
    ConfirmDialogComponent,
    EmptyStateComponent,
    StatusBadgeComponent,
    SelectFieldComponent,
    TextFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    SkeletonComponent,
  ],
  templateUrl: './utilisateurs-list.component.html',
  styleUrl: './utilisateurs-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UtilisateursListComponent {
  private readonly service = inject(UsersAdminService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Utilisateur[]>([]);
  readonly loading = signal(true);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly roleLabels = ROLE_LABELS;
  readonly StatutCompte = StatutCompte;
  readonly confirmDeleteOpen = signal(false);
  readonly deleting = signal(false);
  readonly pendingDelete = signal<Utilisateur | null>(null);
  readonly resettingId = signal<string | null>(null);

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;
  readonly search = signal('');
  readonly roleFilter = signal('');
  readonly statutFilter = signal('');
  readonly statutLabels = STATUT_COMPTE_LABELS;

  readonly roleOptions: SelectOption[] = Object.entries(ROLE_LABELS).map(([value, label]) => ({
    value,
    label,
  }));

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    nom: ['', Validators.required],
    prenoms: ['', Validators.required],
    role: [RoleUtilisateur.AGENT_FORESTIER as string, Validators.required],
    telephone: [''],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  constructor() {
    const qp = this.route.snapshot.queryParamMap;
    const role = qp.get('role');
    const statut = qp.get('statut');
    if (role) this.roleFilter.set(role);
    if (statut) this.statutFilter.set(statut);
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

  onFilterChange(): void {
    this.page.set(1);
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  openDetail(u: Utilisateur): void {
    this.router.navigate(['/app/utilisateurs', u.id]);
  }

  load(): void {
    this.loading.set(true);
    this.service
      .list({
        page: String(this.page()),
        page_size: String(this.pageSize),
        search: this.search(),
        role: this.roleFilter(),
        statut: this.statutFilter(),
      })
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
    const raw = this.form.getRawValue();
    this.service.create({ ...raw, role: raw.role as RoleUtilisateur }).subscribe({
      next: () => {
        this.saving.set(false);
        this.showForm.set(false);
        this.form.reset({ role: RoleUtilisateur.AGENT_FORESTIER });
        this.toast.success('Compte créé avec succès');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }

  toggleStatus(u: Utilisateur, event: Event): void {
    event.stopPropagation();
    const action = u.statut === StatutCompte.ACTIF ? this.service.suspendre(u.id) : this.service.activer(u.id);
    action.subscribe({
      next: () => {
        this.toast.success('Statut du compte mis à jour');
        this.load();
      },
      error: () => this.toast.error('Échec de la mise à jour'),
    });
  }

  askDelete(u: Utilisateur, event: Event): void {
    event.stopPropagation();
    this.pendingDelete.set(u);
    this.confirmDeleteOpen.set(true);
  }

  confirmDelete(): void {
    const u = this.pendingDelete();
    if (!u) return;
    this.deleting.set(true);
    this.service.delete(u.id).subscribe({
      next: () => {
        this.deleting.set(false);
        this.confirmDeleteOpen.set(false);
        this.pendingDelete.set(null);
        this.toast.success('Utilisateur supprimé');
        this.load();
      },
      error: (err) => {
        this.deleting.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  resetPassword(u: Utilisateur, event: Event): void {
    event.stopPropagation();
    this.resettingId.set(u.id);
    this.service.envoyerReinitialisation(u.id).subscribe({
      next: (res) => {
        this.resettingId.set(null);
        this.toast.success(res.detail || 'Lien de réinitialisation envoyé');
      },
      error: () => {
        this.resettingId.set(null);
        this.toast.error('Impossible d’envoyer le lien');
      },
    });
  }

  statutTone(statut: StatutCompte): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === StatutCompte.ACTIF) return 'success';
    if (statut === StatutCompte.EN_ATTENTE) return 'warning';
    if (statut === StatutCompte.SUSPENDU) return 'danger';
    return 'neutral';
  }
}
