import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { PublicOffreDemande } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { toApiError } from '../../../core/http/api-error.util';

@Component({
  selector: 'app-offre-publique-detail',
  imports: [RouterLink, DatePipe, DecimalPipe, FormsModule, CardComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent],
  templateUrl: './offre-publique-detail.component.html',
  styleUrl: './offre-publique-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffrePubliqueDetailComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly offre = signal<PublicOffreDemande | null>(null);
  readonly loading = signal(true);
  readonly notFound = signal(false);
  readonly activePhoto = signal(0);
  readonly contactNom = signal('');
  readonly contactEmail = signal('');
  readonly contactTel = signal('');
  readonly contactMessage = signal('');
  readonly contactHoneypot = signal('');
  readonly sending = signal(false);
  readonly sent = signal(false);
  private readonly toast = inject(ToastService);

  constructor() {
    this.publicService.offre(this.id).subscribe({
      next: (o) => {
        this.offre.set(o);
        this.loading.set(false);
      },
      error: () => {
        this.notFound.set(true);
        this.loading.set(false);
      },
    });
  }

  selectPhoto(i: number): void {
    this.activePhoto.set(i);
  }

  envoyerContact(): void {
    if (!this.contactNom().trim() || !this.contactEmail().trim() || !this.contactMessage().trim()) {
      this.toast.error('Indiquez votre nom, e-mail et message.');
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.contactEmail().trim())) {
      this.toast.error('Adresse e-mail invalide.');
      return;
    }
    if (this.contactMessage().trim().length < 10) {
      this.toast.error('Votre message est trop court (10 caractères minimum).');
      return;
    }
    this.sending.set(true);
    this.publicService
      .contacterOffre(this.id, {
        nom: this.contactNom().trim(),
        email: this.contactEmail().trim(),
        telephone: this.contactTel().trim() || undefined,
        message: this.contactMessage().trim(),
        site_web: this.contactHoneypot(),
      })
      .subscribe({
        next: (res) => {
          this.sending.set(false);
          this.sent.set(true);
          this.toast.success(res.detail || 'Message transmis à l’auteur de l’annonce.');
        },
        error: (err) => {
          this.sending.set(false);
          this.toast.error(toApiError(err).message);
        },
      });
  }
}
