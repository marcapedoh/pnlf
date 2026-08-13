import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { IconComponent, IconName } from '../icon/icon.component';

export type AlertTone = 'success' | 'error' | 'warning' | 'info';

const ICONS: Record<AlertTone, IconName> = {
  success: 'check',
  error: 'alert-triangle',
  warning: 'alert-triangle',
  info: 'info',
};

@Component({
  selector: 'pnlf-alert',
  imports: [IconComponent],
  templateUrl: './alert-banner.component.html',
  styleUrl: './alert-banner.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AlertBannerComponent {
  readonly tone = input<AlertTone>('info');
  readonly title = input<string>('');

  icon(): IconName {
    return ICONS[this.tone()];
  }
}
