import { AfterViewInit, Directive, ElementRef, OnDestroy, inject, input, output } from '@angular/core';

import { focusFirstIn, trapTabKey } from '../confirm-dialog/focus-trap.util';

/**
 * Comportement clavier d'une fenêtre modale : focus initial, tabulation contenue,
 * fermeture par Échap et retour du focus sur l'élément déclencheur.
 *
 * `<div role="dialog" aria-modal="true" aria-labelledby="…" pnlfModal (pnlfModalClose)="fermer()">`
 */
@Directive({
  selector: '[pnlfModal]',
  host: {
    '(keydown)': 'onKeydown($event)',
  },
})
export class ModalA11yDirective implements AfterViewInit, OnDestroy {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private previousFocus: HTMLElement | null = null;

  /** Sélecteur de l'élément à focaliser à l'ouverture (sinon premier élément focalisable). */
  readonly pnlfModalAutofocus = input<string>('[data-autofocus]');
  readonly pnlfModalClose = output<void>();

  ngAfterViewInit(): void {
    this.previousFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setTimeout(() => focusFirstIn(this.host.nativeElement, this.pnlfModalAutofocus()));
  }

  ngOnDestroy(): void {
    const target = this.previousFocus;
    if (target && document.contains(target)) setTimeout(() => target.focus());
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.stopPropagation();
      this.pnlfModalClose.emit();
      return;
    }
    trapTabKey(event, this.host.nativeElement);
  }
}
