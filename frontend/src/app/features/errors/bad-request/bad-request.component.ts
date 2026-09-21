import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ButtonComponent } from '../../../design-system/button/button.component';

@Component({
  selector: 'app-bad-request',
  imports: [RouterLink, ButtonComponent],
  templateUrl: './bad-request.component.html',
  styleUrl: './bad-request.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BadRequestComponent {}
