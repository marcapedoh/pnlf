import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { Cooperative, Producteur } from '../../../core/models/producteur.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { unwrapList } from '../../../core/models/common.model';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SelectOption } from '../../../design-system/select-field/select-field.component';

@Component({
  selector: 'app-annuaire',
  imports: [FormsModule, CardComponent, EmptyStateComponent],
  templateUrl: './annuaire.component.html',
  styleUrl: './annuaire.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnuaireComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);

  readonly producteurs = signal<Producteur[]>([]);
  readonly cooperatives = signal<Cooperative[]>([]);
  readonly loading = signal(true);
  readonly provinceFilter = signal('');
  readonly provinces = signal<SelectOption[]>([]);

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.load();
  }

  onFilterChange(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service
      .annuaire(this.provinceFilter() ? { province: this.provinceFilter() } : {})
      .subscribe({
        next: (res) => {
          this.producteurs.set(res.producteurs ?? []);
          this.cooperatives.set(res.cooperatives ?? []);
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }
}
