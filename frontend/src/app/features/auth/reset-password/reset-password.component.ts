import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { passwordMatchValidator } from '../../../core/validators/password-match.validator';
import { toApiError } from '../../../core/http/api-error.util';
import { PasswordService } from '../../../core/services/password.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { AuthLayoutComponent } from '../auth-layout/auth-layout.component';

@Component({
  selector: 'app-reset-password',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    AuthLayoutComponent,
    TextFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './reset-password.component.html',
  styleUrl: '../login/login.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ResetPasswordComponent {
  private readonly fb = inject(FormBuilder);
  private readonly passwordService = inject(PasswordService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly done = signal(false);
  readonly errorMessage = signal('');
  readonly token =
    this.route.snapshot.queryParamMap.get('token')
    || (typeof location !== 'undefined' && location.hash.startsWith('#token=')
      ? decodeURIComponent(location.hash.slice('#token='.length))
      : '');

  readonly form = this.fb.nonNullable.group(
    {
      password: ['', [Validators.required, Validators.minLength(8)]],
      confirm: ['', [Validators.required]],
    },
    { validators: passwordMatchValidator('password', 'confirm') },
  );

  get passwordError(): string {
    const ctrl = this.form.controls.password;
    if (!this.submitted() || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Veuillez saisir un nouveau mot de passe.';
    if (ctrl.errors['minlength']) return 'Le mot de passe doit contenir au moins 8 caractères.';
    return '';
  }

  get confirmError(): string {
    if (!this.submitted()) return '';
    if (this.form.controls.confirm.errors?.['required']) return 'Veuillez confirmer le mot de passe.';
    if (this.form.errors?.['passwordMismatch']) return 'Les mots de passe ne correspondent pas.';
    return '';
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (!this.token) {
      this.errorMessage.set('Le lien de réinitialisation est invalide ou a expiré.');
      return;
    }
    if (this.form.invalid) return;

    this.loading.set(true);
    this.passwordService
      .confirmReset(this.token, this.form.getRawValue().password)
      .subscribe({
        next: () => {
          this.loading.set(false);
          this.done.set(true);
          setTimeout(() => this.router.navigate(['/connexion']), 2500);
        },
        error: (err) => {
          this.loading.set(false);
          this.errorMessage.set(toApiError(err).message);
        },
      });
  }
}
