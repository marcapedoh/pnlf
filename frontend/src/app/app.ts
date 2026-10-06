import { Component, inject, OnInit } from '@angular/core';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';
import { RouterOutlet } from '@angular/router';
import { filter } from 'rxjs';

import { CookieConsentComponent } from './design-system/cookie-consent/cookie-consent.component';
import { PdfPreviewModalComponent } from './design-system/pdf-preview/pdf-preview-modal.component';
import { SessionInactiviteComponent } from './layout/session-inactivite/session-inactivite.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CookieConsentComponent, PdfPreviewModalComponent, SessionInactiviteComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App implements OnInit {
  private readonly swUpdate = inject(SwUpdate, { optional: true });

  ngOnInit(): void {
    const sw = this.swUpdate;
    if (!sw?.isEnabled) return;

    // Force la récupération de la dernière version (CSS/JS) après un deploy Netlify
    void sw.checkForUpdate();

    sw.versionUpdates
      .pipe(filter((e): e is VersionReadyEvent => e.type === 'VERSION_READY'))
      .subscribe(() => {
        void sw.activateUpdate().then(() => document.location.reload());
      });
  }
}
