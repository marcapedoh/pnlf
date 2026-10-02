import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ASSISTANCE } from '../../../../core/config/assistance';
import { IconComponent } from '../../../../design-system/icon/icon.component';

@Component({
  selector: 'app-conditions-utilisation',
  standalone: true,
  imports: [IconComponent, RouterLink],
  templateUrl: './conditions-utilisation.component.html',
  styleUrl: './conditions-utilisation.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConditionsUtilisationComponent {
  readonly derniereMiseAJour = '21 septembre 2026';
  readonly assistance = ASSISTANCE;
}
