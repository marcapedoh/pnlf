import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { PasswordService } from '../../../core/services/password.service';
import { passwordMatchValidator } from '../../../core/validators/password-match.validator';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';
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
  private readonly toast = inject(ToastService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly loading = signal(false);
  readonly errorMessage = signal('');
  readonly forced = this.auth.mustChangePassword;

  readonly form = this.fb.nonNullable.group(
    {
      ancien: ['', [Validators.required]],
      nouveau: ['', [Validators.required, Validators.minLength(8)]],
      confirmation: ['', [Validators.required]],
    },
    { validators: passwordMatchValidator('nouveau', 'confirmation') },
  );

  get ancienError(): string {
    return controlError(this.form.controls.ancien, 'Saisissez votre mot de passe actuel.');
  }

  get nouveauError(): string {
    return controlError(this.form.controls.nouveau, 'Saisissez un nouveau mot de passe.');
  }

  get confirmationError(): string {
    const ctrl = this.form.controls.confirmation;
    const err = controlError(ctrl, 'Confirmez le nouveau mot de passe.');
    if (err) return err;
    if (ctrl.touched && this.form.errors?.['passwordMismatch']) return 'Les mots de passe ne correspondent pas.';
    return '';
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }

    const { ancien, nouveau } = this.form.getRawValue();
    this.loading.set(true);
    this.passwordService.changePassword(ancien, nouveau).subscribe({
      next: (res) => {
        this.loading.set(false);
        if (res?.access) {
          this.auth.applySession(res.access, res.user);
        }
        this.auth.updateCurrentUser({ doit_changer_mdp: false });
        this.toast.success('Mot de passe modifié', 'Votre nouveau mot de passe est actif. Vous restez connecté.');
        this.router.navigate(['/app/tableau-de-bord']);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(
          handleFormApiError(this.form, toApiError(err), this.host, {
            ancien_mot_de_passe: 'ancien',
            nouveau_mot_de_passe: 'nouveau',
          }),
        );
      },
    });
  }

  skip(): void {
    this.router.navigate(['/app/parametres']);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/connexion']);
  }
}
