import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
} from '@angular/core';

import { ButtonComponent } from '../button/button.component';
import { focusFirstIn, trapTabKey } from './focus-trap.util';

let uid = 0;

@Component({
  selector: 'pnlf-confirm-dialog',
  imports: [ButtonComponent],
  templateUrl: './confirm-dialog.component.html',
  styleUrl: './confirm-dialog.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmDialogComponent {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly open = input(false);
  readonly title = input.required<string>();
  readonly message = input('');
  readonly confirmLabel = input('Confirmer');
  readonly cancelLabel = input('Annuler');
  readonly danger = input(false);
  readonly inputLabel = input('');
  readonly inputRequired = input(false);
  readonly inputPlaceholder = input('');
  readonly inputHint = input('');
  readonly loading = input(false);

  readonly confirmed = output<string>();
  readonly cancelled = output<void>();

  readonly titleId = `pnlf-dialog-title-${uid++}`;
  readonly messageId = `${this.titleId}-message`;
  readonly inputValue = signal('');
  readonly showInput = computed(() => !!this.inputLabel());

  private previousFocus: HTMLElement | null = null;

  constructor() {
    effect(() => {
      const isOpen = this.open();
      untracked(() => (isOpen ? this.onOpened() : this.onClosed()));
    });
  }

  onConfirm(): void {
    const value = this.inputValue().trim();
    if (this.inputRequired() && !value) return;
    this.confirmed.emit(value);
  }

  onCancel(): void {
    if (this.loading()) return;
    this.cancelled.emit();
  }

  onBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.onCancel();
    }
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      this.onCancel();
      return;
    }
    const dialog = this.host.nativeElement.querySelector<HTMLElement>('.pnlf-dialog');
    if (dialog) trapTabKey(event, dialog);
  }

  private onOpened(): void {
    this.inputValue.set('');
    const active = document.activeElement;
    this.previousFocus = active instanceof HTMLElement ? active : null;
    setTimeout(() => {
      const dialog = this.host.nativeElement.querySelector<HTMLElement>('.pnlf-dialog');
      if (dialog) focusFirstIn(dialog, 'textarea, [data-autofocus]');
    });
  }

  private onClosed(): void {
    const target = this.previousFocus;
    this.previousFocus = null;
    if (target?.isConnected) {
      setTimeout(() => target.focus());
    }
  }
}
