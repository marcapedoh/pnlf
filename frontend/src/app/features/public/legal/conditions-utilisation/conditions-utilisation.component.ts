import { ChangeDetectionStrategy, Component } from '@angular/core';

import { IconComponent } from '../../../../design-system/icon/icon.component';

@Component({
  selector: 'app-conditions-utilisation',
  standalone: true,
  imports: [IconComponent],
  templateUrl: './conditions-utilisation.component.html',
  styleUrl: './conditions-utilisation.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConditionsUtilisationComponent {
  readonly derniereMiseAJour = '21 septembre 2026';
}
