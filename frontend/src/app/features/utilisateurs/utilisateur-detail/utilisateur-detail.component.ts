import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import {
  ROLE_LABELS,
  RoleUtilisateur,
  STATUT_COMPTE_LABELS,
  StatutCompte,
  Utilisateur,
} from '../../../core/models/user.model';
import { UsersAdminService } from '../../../core/services/users-admin.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-utilisateur-detail',
  imports: [
    RouterLink,
    DatePipe,
    ReactiveFormsModule,
    CardComponent,
    ButtonComponent,
    ConfirmDialogComponent,
    SkeletonComponent,
    EmptyStateComponent,
    StatusBadgeComponent,
    TextFieldComponent,
    SelectFieldComponent,
    IconComponent,
  ],
  templateUrl: './utilisateur-detail.component.html',
  styleUrl: './utilisateur-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UtilisateurDetailComponent {
  private readonly service = inject(UsersAdminService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly fb = inject(FormBuilder);

  @ViewChild('photoInput') photoInputRef?: ElementRef<HTMLInputElement>;

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly user = signal<Utilisateur | null>(null);
  readonly loading = signal(true);
  readonly acting = signal(false);
  readonly roleLabels = ROLE_LABELS;
  readonly statutLabels = STATUT_COMPTE_LABELS;
  readonly StatutCompte = StatutCompte;
  readonly resetting = signal(false);
  readonly confirmDeleteOpen = signal(false);
  readonly deleting = signal(false);

  readonly editMode = signal(false);
  readonly saving = signal(false);
  readonly uploadingPhoto = signal(false);

  readonly roleOptions: SelectOption[] = Object.entries(ROLE_LABELS).map(([value, label]) => ({
    value,
    label,
  }));

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    prenoms: [''],
    email: ['', [Validators.required, Validators.email]],
    telephone: [''],
    role: this.fb.nonNullable.control<RoleUtilisateur>(RoleUtilisateur.ACHETEUR),
  });

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (u) => {
        this.user.set(u);
        this.form.patchValue({
          nom: u.nom,
          prenoms: u.prenoms,
          email: u.email,
          telephone: u.telephone || '',
          role: u.role,
        });
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/utilisateurs']);
      },
    });
  }

  startEdit(): void {
    this.editMode.set(true);
  }

  cancelEdit(): void {
    const u = this.user();
    if (u) {
      this.form.patchValue({
        nom: u.nom,
        prenoms: u.prenoms,
        email: u.email,
        telephone: u.telephone || '',
        role: u.role,
      });
    }
    this.editMode.set(false);
  }

  saveEdit(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    const raw = this.form.getRawValue();
    this.service.update(this.id, raw).subscribe({
      next: (u) => {
        this.saving.set(false);
        this.user.set(u);
        this.editMode.set(false);
        this.toast.success('Fiche utilisateur mise à jour');
      },
      error: (err) => {
        this.saving.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  openPhotoPicker(): void {
    this.photoInputRef?.nativeElement.click();
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (u) => {
        this.uploadingPhoto.set(false);
        this.user.set(u);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        this.toast.error(toApiError(err).message);
        input.value = '';
      },
    });
  }

  envoyerReset(): void {
    this.resetting.set(true);
    this.service.envoyerReinitialisation(this.id).subscribe({
      next: (res) => {
        this.resetting.set(false);
        this.toast.success(res.detail || 'Lien de réinitialisation envoyé');
      },
      error: () => {
        this.resetting.set(false);
        this.toast.error('Impossible d’envoyer le lien');
      },
    });
  }

  askDelete(): void {
    this.confirmDeleteOpen.set(true);
  }

  confirmDelete(): void {
    this.deleting.set(true);
    this.service.delete(this.id).subscribe({
      next: () => {
        this.deleting.set(false);
        this.confirmDeleteOpen.set(false);
        this.toast.success('Utilisateur supprimé');
        this.router.navigate(['/app/utilisateurs']);
      },
      error: (err) => {
        this.deleting.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  toggleStatus(): void {
    const u = this.user();
    if (!u) return;
    this.acting.set(true);
    const action = u.statut === StatutCompte.ACTIF ? this.service.suspendre(u.id) : this.service.activer(u.id);
    action.subscribe({
      next: () => {
        this.acting.set(false);
        this.toast.success('Statut du compte mis à jour');
        this.load();
      },
      error: () => {
        this.acting.set(false);
        this.toast.error('Échec de la mise à jour');
      },
    });
  }

  initiales(u: Utilisateur): string {
    return `${(u.prenoms || '').charAt(0)}${(u.nom || '').charAt(0)}`.toUpperCase() || '?';
  }

  statutTone(statut: StatutCompte): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === StatutCompte.ACTIF) return 'success';
    if (statut === StatutCompte.EN_ATTENTE) return 'warning';
    if (statut === StatutCompte.SUSPENDU) return 'danger';
    return 'neutral';
  }
}
