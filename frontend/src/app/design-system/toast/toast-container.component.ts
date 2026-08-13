import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { ToastService } from './toast.service';

@Component({
  selector: 'pnlf-toast-container',
  templateUrl: './toast-container.component.html',
  styleUrl: './toast-container.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ToastContainerComponent {
  private readonly service = inject(ToastService);
  readonly toasts = this.service.toasts;

  dismiss(id: number): void {
    this.service.dismiss(id);
  }

  iconPath(variant: string): string {
    switch (variant) {
      case 'success':
        return 'M5 13l4 4L19 7';
      case 'error':
        return 'M12 9v4m0 4h.01M10.3 3.9l-8.2 14A2 2 0 0 0 3.8 21h16.4a2 2 0 0 0 1.7-3.1l-8.2-14a2 2 0 0 0-3.4 0Z';
      case 'warning':
        return 'M12 9v4m0 4h.01M10.3 3.9l-8.2 14A2 2 0 0 0 3.8 21h16.4a2 2 0 0 0 1.7-3.1l-8.2-14a2 2 0 0 0-3.4 0Z';
      default:
        return 'M12 8h.01M11 12h1v4h1';
    }
  }
}
