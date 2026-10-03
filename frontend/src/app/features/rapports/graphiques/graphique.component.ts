import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { ApexOptions, NgApexchartsModule } from 'ng-apexcharts';

/** Graphique ApexCharts piloté par un seul objet d'options, avec un état vide lisible. */
@Component({
  selector: 'app-graphique',
  imports: [NgApexchartsModule],
  template: `
    @if (vide()) {
      <p class="graphique__vide" [style.min-height.px]="hauteur()">{{ messageVide() }}</p>
    } @else {
      <div role="img" [attr.aria-label]="description()">
        <apx-chart
          [chart]="options().chart!"
          [series]="options().series!"
          [xaxis]="options().xaxis!"
          [yaxis]="options().yaxis!"
          [labels]="options().labels!"
          [colors]="options().colors!"
          [plotOptions]="options().plotOptions!"
          [dataLabels]="options().dataLabels!"
          [stroke]="options().stroke!"
          [fill]="options().fill!"
          [grid]="options().grid!"
          [legend]="options().legend!"
          [tooltip]="options().tooltip!"
          [markers]="options().markers!"
          [noData]="options().noData!"
        />
      </div>
    }
  `,
  styles: `
    .graphique__vide {
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0;
      color: var(--text-muted);
      font-size: var(--fs-sm);
      text-align: center;
      border: 1px dashed var(--border-subtle);
      border-radius: var(--radius-md);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class GraphiqueComponent {
  readonly options = input.required<ApexOptions>();
  readonly description = input.required<string>();
  readonly messageVide = input('Aucune donnée sur la période choisie.');

  readonly hauteur = computed(() => Number(this.options().chart?.height ?? 280));
  readonly vide = computed(() => {
    const series = this.options().series ?? [];
    return !series.some((s: unknown) =>
      typeof s === 'number' ? s > 0 : ((s as { data?: unknown[] }).data ?? []).some((v) => Number(v) > 0),
    );
  });
}
