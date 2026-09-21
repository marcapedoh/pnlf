import { ChangeDetectionStrategy, Component, computed, input, output, signal } from '@angular/core';

import { ButtonComponent } from '../button/button.component';

@Component({
  selector: 'pnlf-confirm-dialog',
  imports: [ButtonComponent],
  templateUrl: './confirm-dialog.component.html',
  styleUrl: './confirm-dialog.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmDialogComponent {
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

  readonly inputValue = signal('');
  readonly showInput = computed(() => !!this.inputLabel());

  onConfirm(): void {
    const value = this.inputValue().trim();
    if (this.inputRequired() && !value) return;
    this.confirmed.emit(value);
  }

  onCancel(): void {
    this.inputValue.set('');
    this.cancelled.emit();
  }

  onBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.onCancel();
    }
  }
}
