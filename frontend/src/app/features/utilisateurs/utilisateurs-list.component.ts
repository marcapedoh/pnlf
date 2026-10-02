import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../core/auth/auth.service';
import { displayName } from '../../core/auth/display-name.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { toApiError } from '../../core/http/api-error.util';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import {
  ROLE_LABELS,
  RoleUtilisateur,
  STATUT_COMPTE_LABELS,
  StatutCompte,
  Utilisateur,
  rolesAttribuables,
} from '../../core/models/user.model';
import { UsersAdminService } from '../../core/services/users-admin.service';
import { normaliserTelephone, telephoneValidator } from '../../core/validators/pnlf.validators';
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

type ActionCompte = { kind: 'suspendre' | 'activer' | 'reset'; user: Utilisateur };

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
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly route = inject(ActivatedRoute);
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Utilisateur[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly roleLabels = ROLE_LABELS;
  readonly StatutCompte = StatutCompte;
  readonly displayName = displayName;

  readonly action = signal<ActionCompte | null>(null);
  readonly actionLoading = signal(false);

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;
  readonly search = signal('');
  readonly roleFilter = signal('');
  readonly statutFilter = signal('');
  readonly statutLabels = STATUT_COMPTE_LABELS;

  private readonly currentUser = this.auth.currentUser;
  private readonly isAdmin = computed(() => this.currentUser()?.role === RoleUtilisateur.ADMINISTRATEUR);
  readonly currentUserId = computed(() => this.currentUser()?.id);

  readonly roleFilterOptions: SelectOption[] = Object.entries(ROLE_LABELS).map(([value, label]) => ({ value, label }));
  readonly roleOptions = computed<SelectOption[]>(() => rolesAttribuables(this.currentUser()?.role));

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    nom: ['', Validators.required],
    prenoms: ['', Validators.required],
    role: [RoleUtilisateur.AGENT_FORESTIER as string, Validators.required],
    telephone: ['', [telephoneValidator]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  readonly actionDialog = computed(() => {
    const a = this.action();
    if (!a) return null;
    const nom = displayName(a.user);
    if (a.kind === 'suspendre') {
      return {
        title: `Suspendre le compte de ${nom} ?`,
        message: 'La personne ne pourra plus se connecter tant que le compte n’aura pas été réactivé.',
        confirm: 'Suspendre le compte',
        danger: true,
      };
    }
    if (a.kind === 'activer') {
      return {
        title: `Activer le compte de ${nom} ?`,
        message:
          a.user.statut === StatutCompte.EN_ATTENTE
            ? 'Ce compte est en attente : l’activer valide aussi la fiche liée (producteur, coopérative ou acheteur). Vérifiez les pièces avant de confirmer.'
            : 'La personne pourra de nouveau se connecter à la plateforme.',
        confirm: 'Activer le compte',
        danger: false,
      };
    }
    return {
      title: `Réinitialiser le mot de passe de ${nom} ?`,
      message: `Un lien de réinitialisation sera envoyé à ${a.user.email}.`,
      confirm: 'Envoyer le lien',
      danger: false,
    };
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
    this.form.controls.role.valueChanges.pipe(takeUntilDestroyed()).subscribe((role) => {
      const prenoms = this.form.controls.prenoms;
      prenoms.setValidators(role === RoleUtilisateur.COOPERATIVE ? [] : [Validators.required]);
      prenoms.updateValueAndValidity({ emitEvent: false });
    });
    this.load();
  }

  err(champ: 'email' | 'nom' | 'prenoms' | 'telephone' | 'password' | 'role'): string {
    const requis: Record<string, string> = {
      email: 'L’adresse e-mail est requise.',
      nom: 'Le nom est requis.',
      prenoms: 'Les prénoms sont requis.',
      password: 'Le mot de passe temporaire est requis.',
      role: 'Choisissez un rôle.',
    };
    return controlError(this.form.get(champ), requis[champ]);
  }

  /** Un gestionnaire n'agit ni sur son propre compte ni, s'il n'est pas administrateur, sur un administrateur. */
  peutAgir(u: Utilisateur): boolean {
    if (u.id === this.currentUser()?.id) return false;
    return u.role !== RoleUtilisateur.ADMINISTRATEUR || this.isAdmin();
  }

  ouvrirFormulaire(): void {
    this.errorMessage.set('');
    this.form.reset({ role: RoleUtilisateur.AGENT_FORESTIER });
    this.showForm.set(true);
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

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
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
        error: (err) => {
          this.loadError.set(toApiError(err).message);
          this.loading.set(false);
        },
      });
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    this.saving.set(true);
    const raw = this.form.getRawValue();
    this.service
      .create({
        ...raw,
        email: raw.email.trim(),
        nom: raw.nom.trim(),
        prenoms: raw.prenoms.trim(),
        telephone: normaliserTelephone(raw.telephone) || null,
        role: raw.role as RoleUtilisateur,
        doit_changer_mdp: true,
      })
      .subscribe({
        next: () => {
          this.saving.set(false);
          this.showForm.set(false);
          this.form.reset({ role: RoleUtilisateur.AGENT_FORESTIER });
          this.toast.success('Compte créé', 'Le mot de passe devra être changé à la première connexion.');
          this.load();
        },
        error: (err) => {
          this.saving.set(false);
          this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
        },
      });
  }

  demander(kind: ActionCompte['kind'], user: Utilisateur): void {
    this.action.set({ kind, user });
  }

  confirmerAction(): void {
    const a = this.action();
    if (!a) return;
    this.actionLoading.set(true);
    const done = (message: string) => {
      this.actionLoading.set(false);
      this.action.set(null);
      this.toast.success(message);
    };
    const fail = (err: unknown) => {
      this.actionLoading.set(false);
      this.action.set(null);
      this.toast.error('Action impossible', toApiError(err).message);
    };
    if (a.kind === 'reset') {
      this.service.envoyerReinitialisation(a.user.id).subscribe({
        next: (res) => done(res.detail || 'Lien de réinitialisation envoyé'),
        error: fail,
      });
      return;
    }
    const req$ = a.kind === 'suspendre' ? this.service.suspendre(a.user.id) : this.service.activer(a.user.id);
    req$.subscribe({
      next: () => {
        done(a.kind === 'suspendre' ? 'Compte suspendu' : 'Compte activé');
        this.load();
      },
      error: fail,
    });
  }

  statutTone(statut: StatutCompte): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === StatutCompte.ACTIF) return 'success';
    if (statut === StatutCompte.EN_ATTENTE) return 'warning';
    if (statut === StatutCompte.SUSPENDU) return 'danger';
    return 'neutral';
  }
}
