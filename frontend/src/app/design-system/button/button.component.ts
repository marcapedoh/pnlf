import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import { SpinnerComponent } from '../spinner/spinner.component';

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger' | 'gold';
export type ButtonSize = 'sm' | 'md' | 'lg';

@Component({
  selector: 'button[pnlfButton], a[pnlfButton]',
  standalone: true,
  imports: [SpinnerComponent],
  templateUrl: './button.component.html',
  styleUrl: './button.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class]': 'hostClasses()',
    '[attr.disabled]': 'disabled() || loading() ? true : null',
    '[attr.aria-busy]': 'loading()',
  },
})
export class ButtonComponent {
  readonly variant = input<ButtonVariant>('primary');
  readonly size = input<ButtonSize>('md');
  readonly loading = input(false);
  readonly disabled = input(false);
  readonly fullWidth = input(false, { alias: 'fullWidth' });

  hostClasses(): string {
    const classes = [
      'pnlf-btn',
      `pnlf-btn--${this.variant()}`,
      `pnlf-btn--${this.size()}`,
    ];
    if (this.fullWidth()) classes.push('pnlf-btn--full');
    if (this.loading()) classes.push('pnlf-btn--loading');
    return classes.join(' ');
  }
}
