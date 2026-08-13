import { NG_VALUE_ACCESSOR, ControlValueAccessor } from '@angular/forms';
import {
  ChangeDetectionStrategy,
  Component,
  forwardRef,
  input,
  signal,
} from '@angular/core';

let uid = 0;

@Component({
  selector: 'pnlf-text-field',
  templateUrl: './text-field.component.html',
  styleUrl: './text-field.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => TextFieldComponent),
      multi: true,
    },
  ],
})
export class TextFieldComponent implements ControlValueAccessor {
  readonly label = input<string>('');
  readonly type = input<'text' | 'email' | 'password' | 'tel' | 'number' | 'date' | 'search'>(
    'text',
  );
  readonly placeholder = input<string>('');
  readonly hint = input<string>('');
  readonly errorMessage = input<string>('');
  readonly required = input(false);
  readonly autocomplete = input<string>('off');
  readonly icon = input<string>('');

  readonly id = `pnlf-field-${uid++}`;
  readonly value = signal<string>('');
  readonly disabled = signal(false);
  readonly focused = signal(false);
  readonly showPassword = signal(false);

  private onChange: (value: string) => void = () => {};
  private onTouched: () => void = () => {};

  get effectiveType(): string {
    if (this.type() === 'password') {
      return this.showPassword() ? 'text' : 'password';
    }
    return this.type();
  }

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

  handleInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.value.set(target.value);
    this.onChange(target.value);
  }

  handleBlur(): void {
    this.focused.set(false);
    this.onTouched();
  }

  handleFocus(): void {
    this.focused.set(true);
  }

  togglePasswordVisibility(): void {
    this.showPassword.update((v) => !v);
  }
}
