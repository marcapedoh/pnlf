import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';

import { NotificationsService } from '../../core/services/notifications.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';

@Component({
  selector: 'app-notifications-page',
  imports: [DatePipe, CardComponent, EmptyStateComponent, ButtonComponent],
  templateUrl: './notifications-page.component.html',
  styleUrl: './notifications-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsPageComponent {
  readonly service = inject(NotificationsService);

  constructor() {
    this.service.refresh().subscribe();
  }

  markAsRead(id: string): void {
    this.service.markAsRead(id).subscribe();
  }
}
