import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { displayName } from '../../../core/auth/display-name.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { PublicOffreDemande } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { normaliserTelephone, telephoneValidator } from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { toApiError } from '../../../core/http/api-error.util';
import { libelleModeRemise, libelleMoyenPaiement } from '../../../core/models/annonce.model';
import {
  PnlfDatePipe,
  PnlfMontantPipe,
  PnlfQuantitePipe,
  PnlfTelephonePipe,
  PnlfUnitePipe,
} from '../../../shared/pipes/format.pipes';

@Component({
  selector: 'app-offre-publique-detail',
  imports: [
    RouterLink,
    ReactiveFormsModule,
    PnlfDatePipe,
    PnlfMontantPipe,
    PnlfQuantitePipe,
    PnlfUnitePipe,
    PnlfTelephonePipe,
    CardComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    AlertBannerComponent,
  ],
  templateUrl: './offre-publique-detail.component.html',
  styleUrl: './offre-publique-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffrePubliqueDetailComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);
  private readonly auth = inject(AuthService);
  private readonly title = inject(Title);
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly fb = inject(FormBuilder);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly offre = signal<PublicOffreDemande | null>(null);
  readonly loading = signal(true);
  readonly notFound = signal(false);
  readonly erreurChargement = signal('');
  readonly activePhoto = signal(0);
  readonly sending = signal(false);
  readonly sent = signal(false);
  readonly formError = signal('');
  readonly connecte = this.auth.isAuthenticated();
  readonly libelleModeRemise = libelleModeRemise;

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(150)]],
    email: ['', [Validators.required, Validators.email]],
    telephone: ['', [telephoneValidator]],
    message: ['', [Validators.required, Validators.minLength(10), Validators.maxLength(2000)]],
    site_web: [''],
  });

  constructor() {
    const user = this.auth.currentUser();
    if (user) {
      this.form.patchValue({
        nom: displayName(user),
        email: user.email ?? '',
        telephone: user.telephone ?? '',
      });
    }
    this.charger();
  }

  charger(): void {
    this.loading.set(true);
    this.notFound.set(false);
    this.erreurChargement.set('');
    this.publicService.offre(this.id).subscribe({
      next: (o) => {
        this.offre.set(o);
        this.title.setTitle(`${o.titre} | PFNL`);
        this.loading.set(false);
      },
      error: (err) => {
        const apiError = toApiError(err);
        if (apiError.status === 404) this.notFound.set(true);
        else this.erreurChargement.set(apiError.message);
        this.loading.set(false);
      },
    });
  }

  moyensPaiement(o: PublicOffreDemande): string {
    return (o.moyens_paiement ?? []).map(libelleMoyenPaiement).join(', ');
  }

  initiales(nom: string | null | undefined): string {
    const mots = (nom ?? '').trim().split(/\s+/).filter(Boolean);
    return (mots.slice(0, 2).map((m) => m[0]).join('') || '?').toUpperCase();
  }

  contactTitre(o: PublicOffreDemande): string {
    return o.type_annonce === 'DEMANDE' ? 'Proposer votre produit à l’acheteur' : 'Contacter le vendeur';
  }

  err(champ: 'nom' | 'email' | 'telephone' | 'message'): string {
    const requis = {
      nom: 'Votre nom est requis.',
      email: 'Votre adresse e-mail est requise.',
      telephone: '',
      message: 'Votre message est requis.',
    };
    return controlError(this.form.get(champ), requis[champ]);
  }

  selectPhoto(i: number): void {
    this.activePhoto.set(i);
  }

  envoyerContact(): void {
    this.formError.set('');
    if (this.form.invalid) {
      this.formError.set(revealFormErrors(this.form, this.host));
      return;
    }
    const v = this.form.getRawValue();
    this.sending.set(true);
    this.publicService
      .contacterOffre(this.id, {
        nom: v.nom.trim(),
        email: v.email.trim(),
        telephone: normaliserTelephone(v.telephone) || undefined,
        message: v.message.trim(),
        site_web: v.site_web,
      })
      .subscribe({
        next: (res) => {
          this.sending.set(false);
          this.sent.set(true);
          this.toast.success(res.detail || 'Message transmis à l’auteur de l’annonce.');
        },
        error: (err) => {
          this.sending.set(false);
          this.formError.set(handleFormApiError(this.form, toApiError(err), this.host));
        },
      });
  }
}
