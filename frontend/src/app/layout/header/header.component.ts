import {
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  HostListener,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { interval, startWith } from 'rxjs';

import { AuthService } from '../../core/auth/auth.service';
import { PnlfNotification } from '../../core/models/notification.model';
import { ConnectivityService } from '../../core/network/connectivity.service';
import { NotificationsService } from '../../core/services/notifications.service';
import { UiStateService } from '../../core/ui/ui-state.service';
import { ROLE_SHORT_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { notificationTargetRoute } from '../../core/ui/notification-target.util';
import { IconComponent } from '../../design-system/icon/icon.component';

const VALIDATOR_ROLES: RoleUtilisateur[] = [
  RoleUtilisateur.ADMINISTRATEUR,
  RoleUtilisateur.AGENT_MINISTERE,
  RoleUtilisateur.AGENT_FORESTIER,
];

const POLL_INTERVAL_MS = 20_000;

@Component({
  selector: 'app-header',
  imports: [RouterLink, IconComponent],
  templateUrl: './header.component.html',
  styleUrl: './header.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HeaderComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly elementRef = inject(ElementRef);

  readonly ui = inject(UiStateService);
  readonly connectivity = inject(ConnectivityService);
  readonly notifications = inject(NotificationsService);

  readonly user = this.auth.currentUser;
  readonly fullName = this.auth.fullName;
  readonly initials = this.auth.initials;
  readonly roleLabel = () => {
    const role = this.user()?.role;
    return role ? ROLE_SHORT_LABELS[role] : '';
  };

  readonly userMenuOpen = signal(false);
  readonly notifMenuOpen = signal(false);
  private readonly userTrigger = viewChild<ElementRef<HTMLButtonElement>>('userTrigger');
  private readonly notifTrigger = viewChild<ElementRef<HTMLButtonElement>>('notifTrigger');

  readonly isValidator = computed(() => {
    const role = this.user()?.role;
    return !!role && VALIDATOR_ROLES.includes(role);
  });

  /** Compteur affiché sur la cloche : notifications non lues (les demandes d'inscription restent un bandeau dédié). */
  readonly badgeCount = computed(() => this.notifications.unreadCount());

  constructor() {
    interval(POLL_INTERVAL_MS)
      .pipe(startWith(0), takeUntilDestroyed())
      .subscribe(() => {
        this.notifications.refreshUnreadCount().subscribe();
        if (this.isValidator()) {
          this.notifications.refreshPendingRegistrations().subscribe();
        }
        // Rafraîchit aussi la liste en tâche de fond, pour que le menu déroulant
        // reflète en temps réel les nouvelles notifications sans action de l'utilisateur.
        this.notifications.refresh().subscribe();
      });
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      this.userMenuOpen.set(false);
      this.notifMenuOpen.set(false);
    }
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    const trigger = this.userMenuOpen() ? this.userTrigger() : this.notifMenuOpen() ? this.notifTrigger() : null;
    this.userMenuOpen.set(false);
    this.notifMenuOpen.set(false);
    trigger?.nativeElement.focus();
  }

  toggleUserMenu(): void {
    this.userMenuOpen.update((v) => !v);
    this.notifMenuOpen.set(false);
  }

  toggleNotifMenu(): void {
    this.notifMenuOpen.update((v) => !v);
    this.userMenuOpen.set(false);
    if (this.notifMenuOpen()) {
      this.notifications.refresh().subscribe();
    }
  }

  markAllRead(): void {
    this.notifications.markAllAsRead().subscribe();
  }

  openNotification(n: PnlfNotification): void {
    if (!n.lue) {
      this.notifications.markAsRead(n.id).subscribe();
    }
    this.notifMenuOpen.set(false);
    const route = notificationTargetRoute(n);
    this.router.navigate(route ?? ['/app/notifications']);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/connexion']);
  }
}
