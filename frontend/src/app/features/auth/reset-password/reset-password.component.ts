import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
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
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

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
    return controlError(this.form.controls.password, 'Saisissez un nouveau mot de passe.');
  }

  get confirmError(): string {
    const ctrl = this.form.controls.confirm;
    const err = controlError(ctrl, 'Confirmez le mot de passe.');
    if (err) return err;
    if (ctrl.touched && this.form.errors?.['passwordMismatch']) return 'Les mots de passe ne correspondent pas.';
    return '';
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (!this.token) {
      this.errorMessage.set('Le lien de réinitialisation est invalide ou a expiré.');
      return;
    }
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }

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
          this.errorMessage.set(
            handleFormApiError(this.form, toApiError(err), this.host, { nouveau_mot_de_passe: 'password' }),
          );
        },
      });
  }
}
