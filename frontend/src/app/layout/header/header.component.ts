import { ChangeDetectionStrategy, Component, ElementRef, HostListener, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { ConnectivityService } from '../../core/network/connectivity.service';
import { NotificationsService } from '../../core/services/notifications.service';
import { UiStateService } from '../../core/ui/ui-state.service';
import { ROLE_SHORT_LABELS } from '../../core/models/user.model';
import { IconComponent } from '../../design-system/icon/icon.component';

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

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      this.userMenuOpen.set(false);
      this.notifMenuOpen.set(false);
    }
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

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/connexion']);
  }
}
