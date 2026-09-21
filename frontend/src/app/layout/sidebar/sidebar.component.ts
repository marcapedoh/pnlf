import { ChangeDetectionStrategy, Component, OnDestroy, computed, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive } from '@angular/router';
import { filter, Subscription } from 'rxjs';

import { AuthService } from '../../core/auth/auth.service';
import { navSectionsForRole } from '../../core/navigation/nav-items';
import { ChatService } from '../../core/services/chat.service';
import { UiStateService } from '../../core/ui/ui-state.service';
import { IconComponent } from '../../design-system/icon/icon.component';

@Component({
  selector: 'app-sidebar',
  imports: [RouterLink, RouterLinkActive, IconComponent],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SidebarComponent implements OnDestroy {
  private readonly auth = inject(AuthService);
  private readonly chat = inject(ChatService);
  private readonly router = inject(Router);
  readonly ui = inject(UiStateService);

  readonly sections = computed(() => navSectionsForRole(this.auth.currentUser()?.role));
  readonly unreadMessages = signal(0);

  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private navSub: Subscription | null = null;

  constructor() {
    this.refreshUnread();
    this.pollTimer = setInterval(() => this.refreshUnread(), 4000);
    this.navSub = this.router.events
      .pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd))
      .subscribe((e) => {
        if (e.urlAfterRedirects.includes('/app/messagerie')) {
          setTimeout(() => this.refreshUnread(), 600);
        }
      });
  }

  ngOnDestroy(): void {
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.navSub?.unsubscribe();
  }

  closeMobile(): void {
    this.ui.closeMobileMenu();
  }

  isMessagerie(route: string): boolean {
    return route.includes('messagerie');
  }

  private refreshUnread(): void {
    if (!this.auth.isAuthenticated()) {
      this.unreadMessages.set(0);
      return;
    }
    this.chat.nonLus().subscribe({
      next: (res) => this.unreadMessages.set(res.count || 0),
      error: () => undefined,
    });
  }
}
