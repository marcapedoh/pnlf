import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'pnlf-skeleton',
  template: `<span
    class="pnlf-skeleton"
    [style.width]="width()"
    [style.height]="height()"
    [style.border-radius]="radius()"
  ></span>`,
  styleUrl: './skeleton.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SkeletonComponent {
  readonly width = input<string>('100%');
  readonly height = input<string>('14px');
  readonly radius = input<string>('6px');
}
