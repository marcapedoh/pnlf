import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { OfflineBannerComponent } from '../../design-system/offline-banner/offline-banner.component';
import { ToastContainerComponent } from '../../design-system/toast/toast-container.component';
import { TopProgressBarComponent } from '../../design-system/progress-bar/top-progress-bar.component';
import { FooterComponent } from '../footer/footer.component';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';

@Component({
  selector: 'app-shell',
  imports: [
    RouterOutlet,
    HeaderComponent,
    SidebarComponent,
    FooterComponent,
    OfflineBannerComponent,
    ToastContainerComponent,
    TopProgressBarComponent,
  ],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShellComponent {}
