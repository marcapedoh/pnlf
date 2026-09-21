import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { CookieConsentComponent } from './design-system/cookie-consent/cookie-consent.component';
import { PdfPreviewModalComponent } from './design-system/pdf-preview/pdf-preview-modal.component';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CookieConsentComponent, PdfPreviewModalComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App {}
