import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { displayName, initialesStructure } from '../../../core/auth/display-name.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { normaliserTelephone, telephoneValidator } from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe } from '../../../shared/pipes/format.pipes';
import {
  PublicProducteur,
  TYPE_ACTEUR_PUBLIC_LABELS,
} from '../../../core/models/public.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { STATUT_LOT_LABELS, StatutLot } from '../../../core/models/lot.model';
import { PublicService } from '../../../core/services/public.service';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-producteur-public-detail',
  imports: [
    RouterLink,
    ReactiveFormsModule,
    PnlfDatePipe,
    PnlfMontantPipe,
    PnlfQuantitePipe,
    PnlfUnitePipe,
    AlertBannerComponent,
    CardComponent,
    ButtonComponent,
    TextFieldComponent,
    SkeletonComponent,
    IconComponent,
    StatusBadgeComponent,
    EmptyStateComponent,
  ],
  templateUrl: './producteur-public-detail.component.html',
  styleUrl: './producteur-public-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteurPublicDetailComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);
  private readonly host = inject(ElementRef<HTMLElement>);
  readonly auth = inject(AuthService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly returnUrl = `/annuaire/${this.id}`;
  readonly producteur = signal<PublicProducteur | null>(null);
  readonly loading = signal(true);
  readonly sending = signal(false);
  readonly sent = signal(false);
  readonly openingChat = signal(false);
  readonly typeLabels = TYPE_ACTEUR_PUBLIC_LABELS;

  readonly isAuthenticated = this.auth.isAuthenticated;
  readonly peutDiscuter = computed(() => {
    if (!this.auth.isAuthenticated()) return false;
    if (!this.producteur()?.compte_connecte) return false;
    return this.auth.hasRole(
      RoleUtilisateur.ACHETEUR,
      RoleUtilisateur.ADMINISTRATEUR,
      RoleUtilisateur.AGENT_MINISTERE,
      RoleUtilisateur.AGENT_FORESTIER,
    );
  });

  readonly formError = signal('');

  readonly contactForm = this.fb.nonNullable.group({
    nom_visiteur: ['', [Validators.required, Validators.minLength(2)]],
    email_visiteur: ['', [Validators.required, Validators.email]],
    telephone_visiteur: ['', [telephoneValidator]],
    message: ['', [Validators.required, Validators.minLength(10), Validators.maxLength(2000)]],
    site_web: [''],
  });

  constructor() {
    const user = this.auth.currentUser();
    if (user) {
      this.contactForm.patchValue({
        nom_visiteur: displayName(user),
        email_visiteur: user.email ?? '',
        telephone_visiteur: user.telephone ?? '',
      });
    }
    this.publicService.producteur(this.id).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.title.setTitle(`${p.prenoms ? p.prenoms + ' ' : ''}${p.nom} | Annuaire PFNL`);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  err(champ: 'nom_visiteur' | 'email_visiteur' | 'telephone_visiteur' | 'message'): string {
    const requis = {
      nom_visiteur: 'Votre nom est requis.',
      email_visiteur: 'Votre adresse e-mail est requise.',
      telephone_visiteur: '',
      message: 'Votre message est requis.',
    };
    return controlError(this.contactForm.get(champ), requis[champ]);
  }

  /** Évite « Estuaire · Estuaire » lorsque la communauté reprend le nom de la province. */
  localisation(p: PublicProducteur): string {
    const province = (p.province_nom ?? '').trim();
    const communaute = (p.communaute ?? '').trim();
    if (!communaute || communaute.localeCompare(province, 'fr', { sensitivity: 'base' }) === 0) {
      return province || 'Province non renseignée';
    }
    return province ? `${province} · ${communaute}` : communaute;
  }

  initials(p: PublicProducteur): string {
    if (!p.prenoms?.trim()) return initialesStructure(p.nom);
    return `${p.prenoms.charAt(0)}${p.nom.charAt(0)}`.toUpperCase();
  }

  statutLabel(statut: string): string {
    return STATUT_LOT_LABELS[statut as StatutLot] ?? statut;
  }

  statutTone(statut: string) {
    return lotStatusTone(statut as StatutLot);
  }

  ouvrirDiscussion(): void {
    this.openingChat.set(true);
    this.router.navigate(['/app/messagerie'], { queryParams: { producteur: this.id } });
  }

  submitContact(): void {
    this.formError.set('');
    if (this.contactForm.invalid) {
      this.formError.set(revealFormErrors(this.contactForm, this.host));
      return;
    }
    const v = this.contactForm.getRawValue();
    this.sending.set(true);
    this.publicService
      .contacter(this.id, {
        ...v,
        nom_visiteur: v.nom_visiteur.trim(),
        email_visiteur: v.email_visiteur.trim(),
        telephone_visiteur: normaliserTelephone(v.telephone_visiteur),
        message: v.message.trim(),
      })
      .subscribe({
        next: () => {
          this.sent.set(true);
          this.sending.set(false);
          this.toast.success('Votre message a été transmis au producteur.');
          this.contactForm.reset();
        },
        error: (err) => {
          this.sending.set(false);
          this.formError.set(handleFormApiError(this.contactForm, toApiError(err), this.host));
        },
      });
  }
}
