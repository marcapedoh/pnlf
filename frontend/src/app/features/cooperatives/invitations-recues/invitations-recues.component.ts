import { ChangeDetectionStrategy, Component, inject, input, output, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import { InvitationCooperative } from '../../../core/models/producteur.model';
import { CooperativesService } from '../../../core/services/cooperatives.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { PnlfDatePipe } from '../../../shared/pipes/format.pipes';

/**
 * Invitations de coopératives reçues par le producteur connecté, avec acceptation ou refus.
 * Le bloc reste masqué tant qu'aucune invitation n'est en attente (sauf `afficherVide`).
 */
@Component({
  selector: 'app-invitations-recues',
  imports: [RouterLink, CardComponent, ButtonComponent, AlertBannerComponent, ConfirmDialogComponent, PnlfDatePipe],
  template: `
    @if (erreur()) {
      <pnlf-alert tone="error" title="Invitations indisponibles">
        {{ erreur() }}
        <button pnlfButton type="button" variant="outline" size="sm" (click)="charger()">Réessayer</button>
      </pnlf-alert>
    } @else if (invitations().length || (afficherVide() && charge())) {
      <pnlf-card title="Invitations reçues" subtitle="Des coopératives vous proposent de rejoindre leurs membres">
        @if (invitations().length === 0) {
          <p class="text-sm text-muted">Aucune invitation en attente.</p>
        } @else {
          <ul class="invitations-recues">
            @for (inv of invitations(); track inv.id) {
              <li class="invitations-recues__item">
                <div class="invitations-recues__logo" aria-hidden="true">
                  @if (inv.cooperative_photo_url) {
                    <img [src]="inv.cooperative_photo_url" alt="" />
                  } @else {
                    <span>{{ initiales(inv.cooperative_nom) }}</span>
                  }
                </div>
                <div class="invitations-recues__texte">
                  <a class="pnlf-table__link" [routerLink]="['/app/cooperatives', inv.cooperative]">
                    <strong>{{ inv.cooperative_nom }}</strong>
                  </a>
                  <small class="text-muted">
                    {{ inv.cooperative_province || 'Province non renseignée' }} · invitation du {{ inv.created_at | pnlfDate }}
                  </small>
                  @if (inv.message) {
                    <p class="invitations-recues__message">« {{ inv.message }} »</p>
                  }
                </div>
                <div class="invitations-recues__actions">
                  <button pnlfButton type="button" variant="primary" size="sm" (click)="aAccepter.set(inv)">Accepter</button>
                  <button pnlfButton type="button" variant="ghost" size="sm" (click)="aRefuser.set(inv)">Refuser</button>
                </div>
              </li>
            }
          </ul>
        }
      </pnlf-card>
    }

    <pnlf-confirm-dialog
      [open]="aAccepter() !== null"
      title="Rejoindre cette coopérative ?"
      [message]="'Vous deviendrez membre actif de « ' + (aAccepter()?.cooperative_nom ?? '') + ' ». Vos autres invitations et demandes en attente seront closes.'"
      confirmLabel="Accepter l'invitation"
      [loading]="enCours()"
      (confirmed)="accepter()"
      (cancelled)="aAccepter.set(null)"
    />
    <pnlf-confirm-dialog
      [open]="aRefuser() !== null"
      title="Refuser cette invitation ?"
      [message]="'La coopérative « ' + (aRefuser()?.cooperative_nom ?? '') + ' » sera prévenue de votre refus.'"
      confirmLabel="Refuser"
      [danger]="true"
      inputLabel="Motif (facultatif)"
      inputPlaceholder="Ex. : je préfère rester indépendant pour le moment"
      [loading]="enCours()"
      (confirmed)="refuser($event)"
      (cancelled)="aRefuser.set(null)"
    />
  `,
  styles: `
    .invitations-recues {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: var(--space-4);
    }
    .invitations-recues__item {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: var(--space-4);
      padding-bottom: var(--space-4);
      border-bottom: 1px dashed var(--border-subtle);
    }
    .invitations-recues__item:last-child {
      border-bottom: none;
      padding-bottom: 0;
    }
    .invitations-recues__logo {
      width: 48px;
      height: 48px;
      border-radius: var(--radius-md, 8px);
      overflow: hidden;
      flex-shrink: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--pnlf-green-100);
      color: var(--pnlf-green-600);
      font-weight: 700;
    }
    .invitations-recues__logo img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .invitations-recues__texte {
      flex: 1;
      min-width: 200px;
      display: flex;
      flex-direction: column;
      gap: 0.15rem;
    }
    .invitations-recues__message {
      margin: var(--space-1) 0 0;
      font-size: var(--fs-sm);
      font-style: italic;
      white-space: pre-wrap;
    }
    .invitations-recues__actions {
      display: flex;
      gap: var(--space-2);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InvitationsRecuesComponent {
  private readonly service = inject(CooperativesService);
  private readonly toast = inject(ToastService);

  /** Affiche le bloc même sans invitation en attente. */
  readonly afficherVide = input(false);
  /** Émis après acceptation (identifiant de la coopérative rejointe) ou refus (null). */
  readonly reponse = output<string | null>();

  readonly invitations = signal<InvitationCooperative[]>([]);
  readonly charge = signal(false);
  readonly erreur = signal('');
  readonly aAccepter = signal<InvitationCooperative | null>(null);
  readonly aRefuser = signal<InvitationCooperative | null>(null);
  readonly enCours = signal(false);

  constructor() {
    this.charger();
  }

  charger(): void {
    this.erreur.set('');
    this.service.invitationsRecues().subscribe({
      next: (liste) => {
        this.invitations.set(liste);
        this.charge.set(true);
      },
      error: (err) => {
        this.charge.set(true);
        this.erreur.set(toApiError(err).message);
      },
    });
  }

  initiales(nom: string): string {
    const mots = nom.split(/\s+/).filter((m) => /^[A-Za-zÀ-ÿ]/.test(m) && m.length > 2);
    return ((mots[0]?.[0] ?? 'C') + (mots[1]?.[0] ?? '')).toUpperCase();
  }

  accepter(): void {
    const inv = this.aAccepter();
    if (!inv) return;
    this.enCours.set(true);
    this.service.accepterInvitation(inv.id).subscribe({
      next: (res) => {
        this.enCours.set(false);
        this.aAccepter.set(null);
        this.toast.success('Invitation acceptée', res.detail);
        this.charger();
        this.reponse.emit(res.cooperative);
      },
      error: (err) => {
        this.enCours.set(false);
        this.aAccepter.set(null);
        this.toast.error('Impossible d’accepter l’invitation', toApiError(err).message);
        this.charger();
      },
    });
  }

  refuser(motif: string): void {
    const inv = this.aRefuser();
    if (!inv) return;
    this.enCours.set(true);
    this.service.refuserInvitation(inv.id, motif || undefined).subscribe({
      next: () => {
        this.enCours.set(false);
        this.aRefuser.set(null);
        this.toast.success('Invitation refusée', 'La coopérative a été prévenue.');
        this.charger();
        this.reponse.emit(null);
      },
      error: (err) => {
        this.enCours.set(false);
        this.aRefuser.set(null);
        this.toast.error('Impossible de refuser l’invitation', toApiError(err).message);
        this.charger();
      },
    });
  }
}
