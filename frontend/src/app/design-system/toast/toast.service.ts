import { Injectable, signal } from '@angular/core';

import { ToastMessage, ToastVariant } from './toast.model';

let uid = 0;

@Injectable({ providedIn: 'root' })
export class ToastService {
  private readonly _toasts = signal<ToastMessage[]>([]);
  readonly toasts = this._toasts.asReadonly();

  show(variant: ToastVariant, title: string, description?: string, duration = 5000): void {
    const id = uid++;
    this._toasts.update((list) => [...list, { id, variant, title, description, duration }]);
    if (duration > 0) {
      setTimeout(() => this.dismiss(id), duration);
    }
  }

  success(title: string, description?: string): void {
    this.show('success', title, description);
  }

  error(title: string, description?: string): void {
    this.show('error', title, description, 7000);
  }

  info(title: string, description?: string): void {
    this.show('info', title, description);
  }

  warning(title: string, description?: string): void {
    this.show('warning', title, description, 6000);
  }

  dismiss(id: number): void {
    this._toasts.update((list) => list.filter((t) => t.id !== id));
  }
}
