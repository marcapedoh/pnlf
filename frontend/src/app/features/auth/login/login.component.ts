import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { revealFormErrors } from '../../../core/forms/form-errors.util';
import { delaiAttenteSecondes, toApiError } from '../../../core/http/api-error.util';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { AuthLayoutComponent } from '../auth-layout/auth-layout.component';

const REMEMBER_KEY = 'pnlf_remember_email';

/** N'accepte que des chemins relatifs internes (anti open-redirect SEC-10). */
function safeReturnUrl(raw: string | null): string {
  const fallback = '/app/tableau-de-bord';
  if (!raw) return fallback;
  if (!raw.startsWith('/') || raw.startsWith('//') || raw.includes('\\')) return fallback;
  if (raw.startsWith('/connexion') || raw.startsWith('/inscription')) return fallback;
  return raw;
}

@Component({
  selector: 'app-login',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    AuthLayoutComponent,
    TextFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LoginComponent {
  private readonly fb = inject(FormBuilder);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly host = inject(ElementRef<HTMLElement>);

  readonly loading = signal(false);
  readonly errorMessage = signal('');
  readonly submitted = signal(false);
  readonly deconnecteInactivite = this.route.snapshot.queryParamMap.get('raison') === 'inactivite';
  /** Secondes restantes avant de pouvoir réessayer après trop d'échecs. */
  readonly attente = signal(0);
  readonly attenteLibelle = computed(() => {
    const s = this.attente();
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
  });
  private minuteur: ReturnType<typeof setInterval> | undefined;

  constructor() {
    inject(DestroyRef).onDestroy(() => clearInterval(this.minuteur));
  }

  readonly form = this.fb.nonNullable.group({
    email: [localStorage.getItem(REMEMBER_KEY) ?? '', [Validators.required, Validators.email]],
    password: ['', [Validators.required]],
    remember: [!!localStorage.getItem(REMEMBER_KEY)],
  });

  get emailError(): string {
    const ctrl = this.form.controls.email;
    if (!this.submitted() || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Veuillez saisir votre adresse e-mail professionnelle.';
    if (ctrl.errors['email']) return 'Le format de l’adresse e-mail est invalide.';
    return '';
  }

  get passwordError(): string {
    const ctrl = this.form.controls.password;
    if (!this.submitted() || !ctrl.errors) return '';
    if (ctrl.errors['required']) return 'Veuillez saisir votre mot de passe.';
    return '';
  }

  submit(): void {
    if (this.attente() > 0) return;
    this.submitted.set(true);
    this.errorMessage.set('');

    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }

    const { email, password, remember } = this.form.getRawValue();

    if (remember) {
      localStorage.setItem(REMEMBER_KEY, email);
    } else {
      localStorage.removeItem(REMEMBER_KEY);
    }

    this.loading.set(true);
    this.auth.login({ email, password }).subscribe({
      next: (res) => {
        this.loading.set(false);
        if (res.user.doit_changer_mdp) {
          this.router.navigate(['/changer-mot-de-passe']);
          return;
        }
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');
        this.router.navigateByUrl(safeReturnUrl(returnUrl));
      },
      error: (err) => {
        this.loading.set(false);
        const apiError = toApiError(err);
        this.errorMessage.set(apiError.message || 'Adresse e-mail ou mot de passe incorrect.');
        const delai = apiError.status === 429 ? delaiAttenteSecondes(err) : null;
        if (delai) this.demarrerAttente(delai);
      },
    });
  }

  private demarrerAttente(secondes: number): void {
    clearInterval(this.minuteur);
    const fin = Date.now() + secondes * 1000;
    const maj = () => {
      const restant = Math.max(0, Math.ceil((fin - Date.now()) / 1000));
      this.attente.set(restant);
      if (!restant) {
        clearInterval(this.minuteur);
        this.errorMessage.set('');
      }
    };
    maj();
    this.minuteur = setInterval(maj, 1000);
  }
}
