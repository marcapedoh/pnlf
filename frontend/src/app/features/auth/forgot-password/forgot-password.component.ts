import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import { PasswordService } from '../../../core/services/password.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { AuthLayoutComponent } from '../auth-layout/auth-layout.component';

@Component({
  selector: 'app-forgot-password',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    AuthLayoutComponent,
    TextFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './forgot-password.component.html',
  styleUrl: '../login/login.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ForgotPasswordComponent {
  private readonly fb = inject(FormBuilder);
  private readonly passwordService = inject(PasswordService);

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly done = signal(false);
  readonly errorMessage = signal('');

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
  });

  get emailError(): string {
    const ctrl = this.form.controls.email;
    if (!this.submitted() || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Veuillez saisir votre adresse e-mail.';
    if (ctrl.errors['email']) return 'Le format de l’adresse e-mail est invalide.';
    return '';
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (this.form.invalid) return;

    this.loading.set(true);
    this.passwordService.requestReset(this.form.getRawValue().email).subscribe({
      next: () => {
        this.loading.set(false);
        this.done.set(true);
      },
      error: (err) => {
        this.loading.set(false);
        // Pour des raisons de sécurité, on ne confirme pas si l'e-mail existe réellement.
        this.done.set(true);
        void err;
      },
    });
  }
}
