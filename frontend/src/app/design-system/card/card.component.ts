import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'pnlf-card',
  templateUrl: './card.component.html',
  styleUrl: './card.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CardComponent {
  readonly title = input<string>('');
  readonly subtitle = input<string>('');
  readonly padded = input(true);
}
