import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { Producteur } from '../../../core/models/producteur.model';
import { LotsService } from '../../../core/services/lots.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

const UNITES: SelectOption[] = [
  { value: 'KG', label: 'Kilogramme (kg)' },
  { value: 'TONNE', label: 'Tonne' },
  { value: 'LITRE', label: 'Litre' },
  { value: 'SAC', label: 'Sac' },
  { value: 'UNITE', label: 'Unité' },
  { value: 'BOTTE', label: 'Botte' },
];

@Component({
  selector: 'app-lot-form',
  imports: [ReactiveFormsModule, RouterLink, CardComponent, TextFieldComponent, SelectFieldComponent, ButtonComponent, AlertBannerComponent],
  templateUrl: './lot-form.component.html',
  styleUrl: './lot-form.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly service = inject(LotsService);
  private readonly referenceService = inject(ReferenceService);
  private readonly producteursService = inject(ProducteursService);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly errorMessage = signal('');
  readonly unites = UNITES;
  readonly produits = signal<SelectOption[]>([]);

  readonly producteurQuery = signal('');
  readonly producteurResults = signal<Producteur[]>([]);
  readonly selectedProducteur = signal<Producteur | null>(null);
  readonly searchingProducteur = signal(false);

  readonly form = this.fb.nonNullable.group({
    produit: ['', Validators.required],
    date_collecte: [new Date().toISOString().slice(0, 10), Validators.required],
    quantite: ['', [Validators.required, Validators.min(0.001)]],
    unite: ['KG', Validators.required],
    qualite_indicateur: [''],
    prix_indicatif: [''],
    devise: ['XAF'],
    observations: [''],
  });

  constructor() {
    this.referenceService.produits().subscribe((res) => {
      this.produits.set(unwrapList(res).map((p) => ({ value: p.id, label: `${p.nom} (${p.code})` })));
    });
  }

  onProducteurQueryChange(value: string): void {
    this.producteurQuery.set(value);
    this.selectedProducteur.set(null);
    if (value.trim().length < 2) {
      this.producteurResults.set([]);
      return;
    }
    this.searchingProducteur.set(true);
    this.producteursService.list({ search: value, page_size: 6 }).subscribe((res) => {
      this.producteurResults.set(unwrapList(res));
      this.searchingProducteur.set(false);
    });
  }

  selectProducteur(p: Producteur): void {
    this.selectedProducteur.set(p);
    this.producteurResults.set([]);
    this.producteurQuery.set(`${p.prenoms} ${p.nom} — ${p.code_producteur}`);
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');

    if (!this.selectedProducteur()) {
      this.errorMessage.set('Veuillez sélectionner un producteur ou collecteur dans la liste.');
      return;
    }
    if (this.form.invalid) return;

    const raw = this.form.getRawValue();
    const payload = {
      ...raw,
      producteur: this.selectedProducteur()!.id,
      quantite: Number(raw.quantite),
      prix_indicatif: raw.prix_indicatif ? Number(raw.prix_indicatif) : null,
    };

    this.loading.set(true);
    this.service.create(payload).subscribe({
      next: (lot) => {
        this.loading.set(false);
        this.toast.success('Lot déclaré avec succès', `Code lot : ${lot.code_lot}`);
        this.router.navigate(['/app/lots', lot.id]);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }
}
