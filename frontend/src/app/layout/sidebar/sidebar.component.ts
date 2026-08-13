import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { navSectionsForRole } from '../../core/navigation/nav-items';
import { UiStateService } from '../../core/ui/ui-state.service';
import { IconComponent } from '../../design-system/icon/icon.component';

@Component({
  selector: 'app-sidebar',
  imports: [RouterLink, RouterLinkActive, IconComponent],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SidebarComponent {
  private readonly auth = inject(AuthService);
  readonly ui = inject(UiStateService);

  readonly sections = computed(() => navSectionsForRole(this.auth.currentUser()?.role));

  closeMobile(): void {
    this.ui.closeMobileMenu();
  }
}
