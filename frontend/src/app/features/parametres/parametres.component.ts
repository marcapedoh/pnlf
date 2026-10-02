import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { toApiError } from '../../core/http/api-error.util';
import { ROLE_LABELS, RoleUtilisateur, STATUT_COMPTE_LABELS, StatutCompte } from '../../core/models/user.model';
import { normaliserTelephone, telephoneValidator } from '../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';

const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const PHOTO_MAX = 5 * 1024 * 1024;

@Component({
  selector: 'app-parametres',
  imports: [RouterLink, ReactiveFormsModule, CardComponent, ButtonComponent, TextFieldComponent, AlertBannerComponent],
  templateUrl: './parametres.component.html',
  styleUrl: './parametres.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ParametresComponent {
  readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly host = inject(ElementRef<HTMLElement>);

  @ViewChild('photoInput') photoInputRef?: ElementRef<HTMLInputElement>;

  readonly roleLabels = ROLE_LABELS;
  readonly editMode = signal(false);
  readonly saving = signal(false);
  readonly uploadingPhoto = signal(false);
  readonly formError = signal('');
  readonly estCooperative = computed(() => this.auth.currentUser()?.role === RoleUtilisateur.COOPERATIVE);

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    prenoms: [''],
    telephone: ['', [telephoneValidator]],
  });

  statutLabel(statut: string | undefined): string {
    if (!statut) return 'Non renseigné';
    return STATUT_COMPTE_LABELS[statut as StatutCompte] ?? statut;
  }

  err(champ: 'nom' | 'prenoms' | 'telephone'): string {
    const requis: Record<string, string> = { nom: 'Le nom est requis.', prenoms: 'Les prénoms sont requis.' };
    return controlError(this.form.get(champ), requis[champ]);
  }

  startEdit(): void {
    const u = this.auth.currentUser();
    if (!u) return;
    this.form.controls.prenoms.setValidators(this.estCooperative() ? [] : [Validators.required]);
    this.form.reset({ nom: u.nom, prenoms: u.prenoms || '', telephone: u.telephone || '' });
    this.formError.set('');
    this.editMode.set(true);
  }

  cancelEdit(): void {
    this.formError.set('');
    this.editMode.set(false);
  }

  save(): void {
    this.formError.set('');
    if (this.form.invalid) {
      this.formError.set(revealFormErrors(this.form, this.host));
      return;
    }
    const raw = this.form.getRawValue();
    this.saving.set(true);
    this.auth
      .updateMonProfil({
        nom: raw.nom.trim(),
        prenoms: raw.prenoms.trim(),
        telephone: normaliserTelephone(raw.telephone) || null,
      })
      .subscribe({
        next: () => {
          this.saving.set(false);
          this.editMode.set(false);
          this.toast.success('Profil mis à jour');
        },
        error: (err) => {
          this.saving.set(false);
          this.formError.set(handleFormApiError(this.form, toApiError(err), this.host));
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
    if (!PHOTO_TYPES.includes(file.type)) {
      this.toast.error('Format non pris en charge', 'Choisissez une image JPEG, PNG ou WebP.');
      input.value = '';
      return;
    }
    if (file.size > PHOTO_MAX) {
      this.toast.error('Image trop lourde', 'La photo ne doit pas dépasser 5 Mo.');
      input.value = '';
      return;
    }
    this.uploadingPhoto.set(true);
    this.auth.uploadMaPhoto(file).subscribe({
      next: () => {
        this.uploadingPhoto.set(false);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        this.toast.error('Photo non enregistrée', toApiError(err).message);
        input.value = '';
      },
    });
  }
}
