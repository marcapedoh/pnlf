import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../../core/http/api-error.util';
import { AuthService } from '../../../core/auth/auth.service';
import { unwrapList } from '../../../core/models/common.model';
import { OffreDemande } from '../../../core/models/notification.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-offres-list',
  imports: [ReactiveFormsModule, DatePipe, CardComponent, ButtonComponent, EmptyStateComponent, StatusBadgeComponent, SelectFieldComponent, TextFieldComponent, AlertBannerComponent],
  templateUrl: './offres-list.component.html',
  styleUrl: './offres-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffresListComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);

  readonly items = signal<OffreDemande[]>([]);
  readonly loading = signal(true);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly produits = signal<SelectOption[]>([]);

  readonly typeOptions: SelectOption[] = [
    { value: 'OFFRE', label: 'Offre (je vends)' },
    { value: 'DEMANDE', label: 'Demande (je recherche)' },
  ];

  readonly canPost = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ACHETEUR,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  readonly form = this.fb.nonNullable.group({
    type_annonce: ['OFFRE', Validators.required],
    titre: ['', Validators.required],
    produit_id: ['', Validators.required],
    quantite: [''],
    unite: ['KG'],
    prix_unitaire: [''],
    description: [''],
  });

  constructor() {
    this.referenceService.produits().subscribe((res) => {
      this.produits.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.offres({ statut: 'OUVERTE' }).subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  submit(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    const raw = this.form.getRawValue();
    this.service
      .creerOffre({
        ...raw,
        type_annonce: raw.type_annonce as OffreDemande['type_annonce'],
        quantite: raw.quantite ? Number(raw.quantite) : null,
        prix_unitaire: raw.prix_unitaire ? Number(raw.prix_unitaire) : null,
      })
      .subscribe({
        next: () => {
          this.saving.set(false);
          this.showForm.set(false);
          this.toast.success('Annonce publiée avec succès');
          this.load();
        },
        error: (err) => {
          this.saving.set(false);
          this.errorMessage.set(toApiError(err).message);
        },
      });
  }
}
