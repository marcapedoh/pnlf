import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { IconComponent, IconName } from '../icon/icon.component';
import { SkeletonComponent } from '../skeleton/skeleton.component';

export type KpiTone = 'green' | 'gold' | 'blue' | 'neutral';

@Component({
  selector: 'pnlf-kpi-card',
  imports: [IconComponent, SkeletonComponent],
  templateUrl: './kpi-card.component.html',
  styleUrl: './kpi-card.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class KpiCardComponent {
  readonly label = input.required<string>();
  readonly value = input<string | number>('');
  readonly icon = input<IconName>('bar-chart');
  readonly tone = input<KpiTone>('green');
  readonly hint = input<string>('');
  readonly loading = input(false);
}
