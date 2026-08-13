import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type SpinnerSize = 'sm' | 'md' | 'lg';
export type SpinnerTone = 'brand' | 'inverse' | 'neutral';

@Component({
  selector: 'pnlf-spinner',
  templateUrl: './spinner.component.html',
  styleUrl: './spinner.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'pnlf-spinner-host' },
})
export class SpinnerComponent {
  readonly size = input<SpinnerSize>('md');
  readonly tone = input<SpinnerTone>('brand');
  readonly label = input<string>('Chargement en cours');
}
