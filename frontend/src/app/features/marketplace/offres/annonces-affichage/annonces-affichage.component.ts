import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AnnonceDetails, VueAnnonces, libelleModeRemise, toneStatutAnnonce } from '../../../../core/models/annonce.model';
import { STATUT_OFFRE_DEMANDE_LABELS, StatutOffreDemande } from '../../../../core/models/notification.model';
import { StatusBadgeComponent } from '../../../../design-system/badge/status-badge.component';
import { IconComponent } from '../../../../design-system/icon/icon.component';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe } from '../../../../shared/pipes/format.pipes';

export interface AnnonceAffichee extends AnnonceDetails {
  id: string;
  type_annonce: 'OFFRE' | 'DEMANDE';
  titre: string;
  description: string | null;
  produit_nom?: string | null;
  province_nom?: string | null;
  auteur_nom?: string | null;
  quantite: number | null;
  unite: string | null;
  prix_unitaire: number | null;
  devise: string;
  statut: string;
  expire_at?: string | null;
  photos_urls?: string[];
  created_at: string;
}

/** Présentation des annonces en liste, grille ou tableau compact (espace connecté et vitrine publique). */
@Component({
  selector: 'app-annonces-affichage',
  imports: [RouterLink, PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe, StatusBadgeComponent, IconComponent],
  templateUrl: './annonces-affichage.component.html',
  styleUrl: './annonces-affichage.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnoncesAffichageComponent {
  readonly items = input.required<AnnonceAffichee[]>();
  readonly vue = input<VueAnnonces>('grille');
  readonly lien = input.required<string>();
  readonly afficherStatut = input(false);

  readonly libelleModeRemise = libelleModeRemise;

  statutLibelle(statut: string): string {
    return STATUT_OFFRE_DEMANDE_LABELS[statut as StatutOffreDemande] ?? statut;
  }

  tone(statut: string) {
    return toneStatutAnnonce(statut);
  }

  expireBientot(a: AnnonceAffichee): boolean {
    if (!a.expire_at || a.expiree) return false;
    return new Date(a.expire_at).getTime() - Date.now() < 7 * 86_400_000;
  }
}
