import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type BadgeTone = 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'gold';

@Component({
  selector: 'pnlf-status-badge',
  template: `<span class="pnlf-badge" [class]="'pnlf-badge--' + tone()"
    ><span class="pnlf-badge__dot"></span>{{ label() }}</span
  >`,
  styleUrl: './status-badge.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StatusBadgeComponent {
  readonly label = input.required<string>();
  readonly tone = input<BadgeTone>('neutral');
}
