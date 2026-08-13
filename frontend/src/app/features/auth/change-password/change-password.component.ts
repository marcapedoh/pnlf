import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { toApiError } from '../../../core/http/api-error.util';
import { PasswordService } from '../../../core/services/password.service';
import { passwordMatchValidator } from '../../../core/validators/password-match.validator';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { AuthLayoutComponent } from '../auth-layout/auth-layout.component';

@Component({
  selector: 'app-change-password',
  imports: [
    ReactiveFormsModule,
    AuthLayoutComponent,
    TextFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './change-password.component.html',
  styleUrl: '../login/login.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ChangePasswordComponent {
  private readonly fb = inject(FormBuilder);
  private readonly passwordService = inject(PasswordService);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly errorMessage = signal('');
  readonly forced = this.auth.currentUser()?.doit_changer_mdp ?? false;

  readonly form = this.fb.nonNullable.group(
    {
      ancien: ['', [Validators.required]],
      nouveau: ['', [Validators.required, Validators.minLength(8)]],
      confirmation: ['', [Validators.required]],
    },
    { validators: passwordMatchValidator('nouveau', 'confirmation') },
  );

  get ancienError(): string {
    if (!this.submitted()) return '';
    return this.form.controls.ancien.errors?.['required']
      ? 'Veuillez saisir votre mot de passe actuel.'
      : '';
  }

  get nouveauError(): string {
    const ctrl = this.form.controls.nouveau;
    if (!this.submitted() || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Veuillez saisir un nouveau mot de passe.';
    if (ctrl.errors['minlength']) return 'Le mot de passe doit contenir au moins 8 caractères.';
    return '';
  }

  get confirmationError(): string {
    if (!this.submitted()) return '';
    if (this.form.controls.confirmation.errors?.['required']) return 'Veuillez confirmer le mot de passe.';
    if (this.form.errors?.['passwordMismatch']) return 'Les mots de passe ne correspondent pas.';
    return '';
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (this.form.invalid) return;

    const { ancien, nouveau } = this.form.getRawValue();
    this.loading.set(true);
    this.passwordService.changePassword(ancien, nouveau).subscribe({
      next: () => {
        this.loading.set(false);
        this.auth.updateCurrentUser({ doit_changer_mdp: false });
        this.router.navigate(['/app/tableau-de-bord']);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }

  skip(): void {
    this.router.navigate(['/app/tableau-de-bord']);
  }
}
