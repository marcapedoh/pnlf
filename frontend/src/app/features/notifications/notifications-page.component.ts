import { PnlfDatePipe } from '../../shared/pipes/format.pipes';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';

import { PnlfNotification } from '../../core/models/notification.model';
import { NotificationsService } from '../../core/services/notifications.service';
import { notificationTargetLabel, notificationTargetRoute } from '../../core/ui/notification-target.util';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';

@Component({
  selector: 'app-notifications-page',
  imports: [PnlfDatePipe, CardComponent, EmptyStateComponent, ButtonComponent, PaginationComponent, SkeletonComponent, AlertBannerComponent],
  templateUrl: './notifications-page.component.html',
  styleUrl: './notifications-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsPageComponent {
  readonly service = inject(NotificationsService);
  private readonly router = inject(Router);

  readonly page = signal(1);
  readonly pageSize = 10;
  readonly openedId = signal<string | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.refresh(this.page(), this.pageSize).subscribe((res) => {
      this.loading.set(false);
      if (res === null) {
        this.loadError.set('Impossible de charger vos notifications. Vérifiez votre connexion puis réessayez.');
      }
    });
    this.service.refreshUnreadCount().subscribe();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  markAsRead(id: string, event: Event): void {
    event.stopPropagation();
    this.service.markAsRead(id).subscribe();
  }

  markAllAsRead(): void {
    this.service.markAllAsRead().subscribe();
  }

  open(n: PnlfNotification): void {
    this.openedId.update((current) => (current === n.id ? null : n.id));
    if (!n.lue) {
      this.service.markAsRead(n.id).subscribe();
    }
  }

  targetRoute(n: PnlfNotification): string[] | null {
    return notificationTargetRoute(n);
  }

  targetLabel(n: PnlfNotification): string {
    return notificationTargetLabel(n);
  }

  goToTarget(n: PnlfNotification, event: Event): void {
    event.stopPropagation();
    const route = notificationTargetRoute(n);
    if (!route) return;
    const id = n.metadata?.['enregistrement_id'];
    if (n.metadata?.['table_cible'] === 'conversations' && typeof id === 'string') {
      this.router.navigate(route, { queryParams: { conversation: id } });
      return;
    }
    this.router.navigate(route);
  }
}
