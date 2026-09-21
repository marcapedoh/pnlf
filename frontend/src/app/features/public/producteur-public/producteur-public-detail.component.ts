import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
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
    DatePipe,
    DecimalPipe,
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

  readonly contactForm = this.fb.nonNullable.group({
    nom_visiteur: ['', [Validators.required, Validators.minLength(2)]],
    email_visiteur: ['', [Validators.required, Validators.email]],
    telephone_visiteur: [''],
    message: ['', [Validators.required, Validators.minLength(10)]],
    site_web: [''],
  });

  constructor() {
    this.publicService.producteur(this.id).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  initials(p: PublicProducteur): string {
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
    if (this.contactForm.invalid) {
      this.contactForm.markAllAsTouched();
      return;
    }
    this.sending.set(true);
    this.publicService.contacter(this.id, this.contactForm.getRawValue()).subscribe({
      next: () => {
        this.sent.set(true);
        this.sending.set(false);
        this.toast.success('Votre message a été transmis au producteur.');
        this.contactForm.reset();
      },
      error: (err) => {
        this.sending.set(false);
        const msg = err?.error?.detail || 'Impossible d\'envoyer le message. Réessayez plus tard.';
        this.toast.error(msg);
      },
    });
  }
}
