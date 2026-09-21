import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { unwrapList } from '../../../core/models/common.model';
import { Cooperative, Producteur, STATUT_COOPERATIVE_LABELS, StatutCooperative } from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { CooperativeMembre, CooperativesService } from '../../../core/services/cooperatives.service';
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { cooperativeStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';

@Component({
  selector: 'app-cooperative-detail',
  imports: [RouterLink, DatePipe, CardComponent, StatusBadgeComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent, ConfirmDialogComponent],
  templateUrl: './cooperative-detail.component.html',
  styleUrl: './cooperative-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CooperativeDetailComponent {
  private readonly service = inject(CooperativesService);
  private readonly producteursService = inject(ProducteursService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly coop = signal<Cooperative | null>(null);
  readonly membres = signal<CooperativeMembre[]>([]);
  readonly loading = signal(true);
  readonly uploadingPhoto = signal(false);
  readonly statutLabels = STATUT_COOPERATIVE_LABELS;
  readonly tone = cooperativeStatusTone;
  readonly StatutCooperative = StatutCooperative;

  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly canManagePhoto = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canAddMembres = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );

  readonly membreQuery = signal('');
  readonly membreResults = signal<Producteur[]>([]);
  readonly selectedCandidat = signal<Producteur | null>(null);
  readonly searchingMembre = signal(false);
  readonly addingMembre = signal(false);
  readonly dialog = signal<{ kind: 'rejeter' | 'desactiver' | 'retirer'; producteur?: string; nom?: string } | null>(null);
  readonly dialogLoading = signal(false);
  private readonly pdfPreview = inject(PdfPreviewService);

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (c) => {
        this.coop.set(c);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/cooperatives']);
      },
    });
    this.service.membres(this.id).subscribe({
      next: (m) => this.membres.set(m),
      error: () => this.membres.set([]),
    });
  }

  valider(): void {
    this.service.valider(this.id).subscribe({
      next: () => {
        this.toast.success('Coopérative validée avec succès');
        this.load();
      },
      error: () => this.toast.error('Échec de la validation'),
    });
  }

  rejeter(): void {
    this.dialog.set({ kind: 'rejeter' });
  }

  desactiver(): void {
    this.dialog.set({ kind: 'desactiver' });
  }

  confirmerRetrait(m: CooperativeMembre): void {
    this.dialog.set({ kind: 'retirer', producteur: m.producteur, nom: m.producteur_nom });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const done = (ok: string) => {
      this.dialogLoading.set(false);
      this.dialog.set(null);
      this.toast.success(ok);
      this.load();
    };
    const fail = () => {
      this.dialogLoading.set(false);
      this.toast.error('Échec de l’opération');
    };
    if (d.kind === 'rejeter') {
      this.service.rejeter(this.id, value.trim()).subscribe({ next: () => done('Demande rejetée'), error: fail });
      return;
    }
    if (d.kind === 'desactiver') {
      this.service.desactiver(this.id).subscribe({ next: () => done('Coopérative désactivée'), error: fail });
      return;
    }
    if (d.kind === 'retirer' && d.producteur) {
      this.service.retirerMembre(this.id, d.producteur).subscribe({
        next: () => {
          this.dialogLoading.set(false);
          this.dialog.set(null);
          this.toast.success('Membre retiré');
          this.service.membres(this.id).subscribe({ next: (m) => this.membres.set(m), error: () => this.membres.set([]) });
        },
        error: fail,
      });
    }
  }

  activer(): void {
    this.service.activer(this.id).subscribe({
      next: () => {
        this.toast.success('Coopérative réactivée');
        this.load();
      },
      error: () => this.toast.error('Échec de la réactivation'),
    });
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (c) => {
        this.coop.set(c);
        this.uploadingPhoto.set(false);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        this.toast.error(err?.error?.photo?.[0] || err?.error?.detail || 'Échec du téléversement');
        input.value = '';
      },
    });
  }

  initials(nom: string): string {
    return nom.slice(0, 2).toUpperCase();
  }

  onMembreQueryChange(value: string): void {
    this.membreQuery.set(value);
    this.selectedCandidat.set(null);
    if (value.trim().length < 2) {
      this.membreResults.set([]);
      return;
    }
    this.searchingMembre.set(true);
    this.producteursService
      .list({
        search: value,
        page_size: 8,
        statut: 'ACTIF',
        candidats_adhesion: '1',
        hors_cooperative: this.id,
      })
      .subscribe({
        next: (res) => {
          const already = new Set(this.membres().map((m) => m.producteur));
          this.membreResults.set(unwrapList(res).filter((p) => !already.has(p.id)));
          this.searchingMembre.set(false);
        },
        error: () => this.searchingMembre.set(false),
      });
  }

  selectCandidat(p: Producteur): void {
    this.selectedCandidat.set(p);
    this.membreResults.set([]);
    this.membreQuery.set(`${p.prenoms} ${p.nom} — ${p.code_producteur}`);
  }

  ajouterMembre(): void {
    const p = this.selectedCandidat();
    if (!p) {
      this.toast.error('Recherchez puis sélectionnez un producteur à rattacher.');
      return;
    }
    this.addingMembre.set(true);
    this.service.ajouterMembre(this.id, { producteur: p.id }).subscribe({
      next: () => {
        this.addingMembre.set(false);
        this.selectedCandidat.set(null);
        this.membreQuery.set('');
        this.membreResults.set([]);
        this.toast.success('Membre enregistré');
        this.service.membres(this.id).subscribe({
          next: (m) => this.membres.set(m),
          error: () => this.membres.set([]),
        });
      },
      error: (err) => {
        this.addingMembre.set(false);
        this.toast.error(err?.error?.detail || 'Impossible d’ajouter ce membre.');
      },
    });
  }

  exporterPdf(): void {
    const c = this.coop();
    const filename = `fiche-cooperative-${c?.code ?? this.id}.pdf`;
    this.pdfPreview.open('Fiche coopérative', filename, () => this.service.fichePdfBlob(this.id));
  }
}
