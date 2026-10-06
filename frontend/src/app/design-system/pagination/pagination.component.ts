import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';

/** Élément de la barre de pagination : numéro de page ou ellipse. */
export type PageItem = number | 'ellipsis';

@Component({
  selector: 'pnlf-pagination',
  templateUrl: './pagination.component.html',
  styleUrl: './pagination.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PaginationComponent {
  readonly page = input.required<number>();
  readonly pageSize = input<number>(20);
  readonly total = input.required<number>();
  /** Nom accessible de la navigation (utile si plusieurs listes paginées sur la page). */
  readonly label = input('Pagination');
  /** Tailles proposées à l'utilisateur ; sélecteur masqué si la liste est vide. */
  readonly pageSizeOptions = input<number[]>([]);
  readonly pageChange = output<number>();
  readonly pageSizeChange = output<number>();

  readonly totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));
  readonly rangeStart = computed(() => (this.total() === 0 ? 0 : (this.page() - 1) * this.pageSize() + 1));
  readonly rangeEnd = computed(() => Math.min(this.page() * this.pageSize(), this.total()));
  readonly resultLabel = computed(() => (this.total() > 1 ? 'résultats' : 'résultat'));

  /** Pages affichées : première, dernière, courante ± 1, avec ellipses. */
  readonly pages = computed<PageItem[]>(() => {
    const total = this.totalPages();
    const current = this.page();
    if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
    const set = new Set([1, total, current - 1, current, current + 1]);
    const sorted = [...set].filter((p) => p >= 1 && p <= total).sort((a, b) => a - b);
    const items: PageItem[] = [];
    sorted.forEach((p, i) => {
      if (i > 0 && p - sorted[i - 1] > 1) items.push('ellipsis');
      items.push(p);
    });
    return items;
  });

  goTo(p: number): void {
    if (p < 1 || p > this.totalPages() || p === this.page()) return;
    this.pageChange.emit(p);
  }

  choisirTaille(event: Event): void {
    const taille = Number((event.target as HTMLSelectElement).value);
    if (Number.isInteger(taille) && taille > 0 && taille !== this.pageSize()) {
      this.pageSizeChange.emit(taille);
    }
  }
}
