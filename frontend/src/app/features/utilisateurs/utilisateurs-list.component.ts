import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../core/http/api-error.util';
import { unwrapList } from '../../core/models/common.model';
import { ROLE_LABELS, RoleUtilisateur, StatutCompte, Utilisateur } from '../../core/models/user.model';
import { UsersAdminService } from '../../core/services/users-admin.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-utilisateurs-list',
  imports: [ReactiveFormsModule, CardComponent, ButtonComponent, EmptyStateComponent, StatusBadgeComponent, SelectFieldComponent, TextFieldComponent, AlertBannerComponent],
  templateUrl: './utilisateurs-list.component.html',
  styleUrl: './utilisateurs-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UtilisateursListComponent {
  private readonly service = inject(UsersAdminService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);

  readonly items = signal<Utilisateur[]>([]);
  readonly loading = signal(true);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly roleLabels = ROLE_LABELS;
  readonly StatutCompte = StatutCompte;

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
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.list().subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
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

  toggleStatus(u: Utilisateur): void {
    const action = u.statut === StatutCompte.ACTIF ? this.service.suspendre(u.id) : this.service.activer(u.id);
    action.subscribe({
      next: () => {
        this.toast.success('Statut du compte mis à jour');
        this.load();
      },
      error: () => this.toast.error('Échec de la mise à jour'),
    });
  }
}
