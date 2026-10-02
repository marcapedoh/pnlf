import { NG_VALUE_ACCESSOR, ControlValueAccessor } from '@angular/forms';
import { ChangeDetectionStrategy, Component, forwardRef, input, signal } from '@angular/core';

export interface SelectOption {
  value: string;
  label: string;
}

let uid = 0;

@Component({
  selector: 'pnlf-select-field',
  templateUrl: './select-field.component.html',
  styleUrl: './select-field.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => SelectFieldComponent),
      multi: true,
    },
  ],
})
export class SelectFieldComponent implements ControlValueAccessor {
  readonly label = input<string>('');
  readonly options = input<SelectOption[]>([]);
  readonly placeholder = input<string>('Sélectionner…');
  readonly required = input(false);
  readonly errorMessage = input<string>('');
  readonly hint = input<string>('');
  readonly name = input<string>('');
  /** Nom accessible lorsque le champ n'a pas de libellé visible (filtres). */
  readonly ariaLabel = input<string>('');

  readonly id = `pnlf-select-${uid++}`;
  readonly value = signal<string>('');
  readonly disabled = signal(false);

  private onChange: (value: string) => void = () => {};
  private onTouched: () => void = () => {};

  writeValue(value: string): void {
    this.value.set(value ?? '');
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  handleChange(event: Event): void {
    const target = event.target as HTMLSelectElement;
    this.value.set(target.value);
    this.onChange(target.value);
    this.onTouched();
  }

  handleBlur(): void {
    this.onTouched();
  }
}
