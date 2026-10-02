import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ASSISTANCE } from '../../../../core/config/assistance';
import { IconComponent } from '../../../../design-system/icon/icon.component';

@Component({
  selector: 'app-confidentialite',
  standalone: true,
  imports: [RouterLink, IconComponent],
  templateUrl: './confidentialite.component.html',
  styleUrl: './confidentialite.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfidentialiteComponent {
  readonly derniereMiseAJour = '21 septembre 2026';
  readonly assistance = ASSISTANCE;
}
