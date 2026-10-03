import { PnlfDatePipe } from '../../shared/pipes/format.pipes';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';

import { FiltresRapport } from '../../core/models/rapports.model';
import { FiltrePeriodeComponent, filtresParDefaut } from './filtre-periode/filtre-periode.component';
import { RapportActiviteComponent } from './onglets/rapport-activite.component';
import { RapportFiliereComponent } from './onglets/rapport-filiere.component';
import { RapportInscriptionsComponent } from './onglets/rapport-inscriptions.component';
import { IconComponent, IconName } from '../../design-system/icon/icon.component';

type Onglet = 'activite' | 'inscriptions' | 'filiere' | 'journal';

import {
  DashboardService,
  ExportFormat,
  JournalEvent,
  JournalFiltres,
  JournalGranularite,
  JournalPeriode,
} from '../../core/services/dashboard.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ProducteursService } from '../../core/services/producteurs.service';
import { CertificationsService } from '../../core/services/certifications.service';
import { unwrapList } from '../../core/models/common.model';
import { ToastService } from '../../design-system/toast/toast.service';
import { FileDownloadService, messageFromDownloadError, triggerBrowserDownload } from '../../core/http/download-file.util';
import { AuthService } from '../../core/auth/auth.service';
import { RoleUtilisateur } from '../../core/models/user.model';
import { PdfPreviewService } from '../../core/services/pdf-preview.service';
import { STATUT_PRODUCTEUR_LABELS, StatutProducteur } from '../../core/models/producteur.model';
import { STATUT_CERTIFICATION_LABELS, StatutCertification } from '../../core/models/certification.model';
import { formatDateFr } from '../../core/format/format.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { toApiError } from '../../core/http/api-error.util';

const ACTION_LABELS: Record<string, string> = {
  CREATE: 'Création',
  UPDATE: 'Modification',
  DELETE: 'Suppression',
  SOFT_DELETE: 'Suppression',
  LOGIN: 'Connexion',
  LOGOUT: 'Déconnexion',
  EXPORT: 'Export',
  IMPORT: 'Import',
  PASSWORD_CHANGE: 'Changement de mot de passe',
  PASSWORD_RESET: 'Réinitialisation du mot de passe',
  PASSWORD_RESET_REQUEST: 'Envoi d’un lien de réinitialisation',
  VALIDATE: 'Validation',
  REJECT: 'Rejet',
  ACTIVATE: 'Activation',
  DEACTIVATE: 'Désactivation',
  UPDATE_PHOTO: 'Mise à jour de photo',
  DELETE_PHOTO: 'Suppression de photo',
  UPDATE_IMAGE: 'Mise à jour d’image',
  INSCRIPTION_PUBLIQUE: 'Inscription publique',
  SYNC: 'Synchronisation',
};

const TABLE_LABELS: Record<string, string> = {
  lots: 'Lots',
  utilisateurs: 'Utilisateurs',
  audit_logs: 'Journal d’audit',
  producteurs: 'Producteurs',
  cooperatives: 'Coopératives',
  certifications: 'Certifications',
  offres_demandes: 'Offres et demandes',
  produits: 'Produits',
  acheteurs: 'Acheteurs',
  zones_collecte: 'Zones de collecte',
  mouvements: 'Mouvements',
  notifications: 'Notifications',
};

/**
 * Cellule CSV séparée par des points-virgules (Excel en français), guillemets échappés.
 * Une valeur commençant par = + - @ ou une tabulation est préfixée d'une apostrophe pour
 * qu'un tableur ne l'interprète jamais comme une formule.
 */
function celluleCsv(valeur: unknown): string {
  let s = valeur === null || valeur === undefined ? '' : String(valeur);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[;"\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function ligneCsv(valeurs: unknown[]): string {
  return valeurs.map(celluleCsv).join(';');
}

@Component({
  selector: 'app-rapports',
  imports: [
    PnlfDatePipe,
    FormsModule,
    CardComponent,
    ButtonComponent,
    EmptyStateComponent,
    PaginationComponent,
    TextFieldComponent,
    AlertBannerComponent,
    IconComponent,
    FiltrePeriodeComponent,
    RapportActiviteComponent,
    RapportInscriptionsComponent,
    RapportFiliereComponent,
  ],
  templateUrl: './rapports.component.html',
  styleUrl: './rapports.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportsComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly downloads = inject(FileDownloadService);
  private readonly toast = inject(ToastService);
  private readonly producteurs = inject(ProducteursService);
  private readonly certifications = inject(CertificationsService);
  private readonly pdfPreview = inject(PdfPreviewService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  /** Statistiques de connexion, inscriptions, journal et exports : administrateur et agent du ministère. */
  readonly canExportJournal = computed(() =>
    this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE),
  );

  readonly onglets = computed<{ id: Onglet; libelle: string; icone: IconName }[]>(() =>
    this.canExportJournal()
      ? [
          { id: 'activite', libelle: 'Activité et connexions', icone: 'users' },
          { id: 'inscriptions', libelle: 'Inscriptions', icone: 'user-check' },
          { id: 'filiere', libelle: 'Filière et lots', icone: 'package' },
          { id: 'journal', libelle: 'Journal d’audit', icone: 'file-text' },
        ]
      : [{ id: 'filiere', libelle: 'Filière et lots', icone: 'package' }],
  );
  readonly onglet = signal<Onglet>(this.ongletInitial());
  readonly filtres = signal<FiltresRapport>(filtresParDefaut());
  private journalCharge = false;

  readonly downloading = signal<string | null>(null);
  readonly granularite = signal<JournalGranularite>('jour');
  readonly periodes = signal<JournalPeriode[]>([]);
  readonly loadingPeriodes = signal(true);
  readonly selected = signal<JournalPeriode | null>(null);
  readonly events = signal<JournalEvent[]>([]);
  readonly eventsTotal = signal(0);
  readonly eventsPage = signal(1);
  readonly eventsPageSize = 25;
  readonly loadingEvents = signal(false);
  readonly selectedLibelle = signal('');
  readonly periodesError = signal('');
  readonly eventsError = signal('');

  /** Une seule date pour aller à une période précise. */
  periodeDate = '';

  /** Recherche utilisateur dans le détail (filtre la liste en direct). */
  userSearch = '';

  private readonly filterReload$ = new Subject<string>();

  constructor() {
    if (this.onglet() === 'journal') this.activerJournal();
    this.filterReload$
      .pipe(debounceTime(250), distinctUntilChanged())
      .subscribe(() => {
        this.eventsPage.set(1);
        this.loadEvents();
      });
  }

  private ongletInitial(): Onglet {
    const demande = this.route.snapshot.queryParamMap.get('onglet');
    const disponibles = this.onglets().map((o) => o.id);
    return disponibles.includes(demande as Onglet) ? (demande as Onglet) : disponibles[0];
  }

  choisirOnglet(onglet: Onglet): void {
    this.onglet.set(onglet);
    if (onglet === 'journal') this.activerJournal();
    this.router.navigate([], { relativeTo: this.route, queryParams: { onglet }, replaceUrl: true });
  }

  naviguerOnglets(event: KeyboardEvent, index: number): void {
    const liste = this.onglets();
    const cible =
      event.key === 'ArrowRight' ? (index + 1) % liste.length
      : event.key === 'ArrowLeft' ? (index - 1 + liste.length) % liste.length
      : event.key === 'Home' ? 0
      : event.key === 'End' ? liste.length - 1
      : -1;
    if (cible < 0) return;
    event.preventDefault();
    this.choisirOnglet(liste[cible].id);
    document.getElementById(`onglet-${liste[cible].id}`)?.focus();
  }

  appliquerFiltres(filtres: FiltresRapport): void {
    this.filtres.set(filtres);
    if (this.journalCharge) {
      this.selected.set(null);
      this.events.set([]);
      this.loadPeriodes();
    }
  }

  private activerJournal(): void {
    if (this.journalCharge || !this.canExportJournal()) return;
    this.journalCharge = true;
    this.loadPeriodes();
  }

  setGranularite(g: JournalGranularite): void {
    this.granularite.set(g);
    this.selected.set(null);
    this.events.set([]);
    this.userSearch = '';
    this.loadPeriodes();
  }

  loadPeriodes(): void {
    this.loadingPeriodes.set(true);
    this.periodesError.set('');
    const f = this.filtres();
    this.dashboardService.journalPeriodes(this.granularite(), { date_debut: f.date_debut, date_fin: f.date_fin, q: f.q }).subscribe({
      next: (res) => {
        this.periodes.set(res.results);
        this.loadingPeriodes.set(false);
        // Affiche par défaut le détail de la première période (liste complète).
        if (res.results.length > 0 && !this.selected()) {
          this.openPeriode(res.results[0]);
        }
      },
      error: (err) => {
        this.periodes.set([]);
        this.loadingPeriodes.set(false);
        this.periodesError.set(toApiError(err).message);
      },
    });
  }

  /** Ouvre la période correspondant à la date saisie. */
  allerAPeriode(): void {
    const d = this.periodeDate.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(d)) {
      this.toast.info('Choisissez une date pour afficher la période.');
      return;
    }
    this.userSearch = '';
    this.openPeriode({ date: d, libelle: d, nb_evenements: 0, nb_utilisateurs: 0 });
  }

  openPeriode(p: JournalPeriode): void {
    this.selected.set(p);
    this.userSearch = '';
    this.eventsPage.set(1);
    this.loadEvents();
  }

  goToEventsPage(page: number): void {
    this.eventsPage.set(page);
    this.loadEvents();
  }

  private currentFiltres(): JournalFiltres {
    const q = this.userSearch.trim();
    return q ? { q } : {};
  }

  loadEvents(): void {
    const p = this.selected();
    if (!p) return;

    this.loadingEvents.set(true);
    this.eventsError.set('');
    this.dashboardService
      .journalDetail(
        this.granularite(),
        p.date,
        this.eventsPage(),
        this.eventsPageSize,
        this.currentFiltres(),
      )
      .subscribe({
        next: (res) => {
          this.events.set(res.results);
          this.eventsTotal.set(res.count);
          this.selectedLibelle.set(res.libelle);
          this.loadingEvents.set(false);
        },
        error: (err) => {
          this.loadingEvents.set(false);
          this.events.set([]);
          this.eventsError.set(toApiError(err).message);
        },
      });
  }

  onUserSearch(value: string): void {
    this.userSearch = value;
    // Met à jour la liste au fur et à mesure de la saisie (vide = tout le monde).
    this.filterReload$.next(value.trim());
  }

  clearUtilisateur(): void {
    this.userSearch = '';
    this.eventsPage.set(1);
    this.loadEvents();
  }

  actionLabel(action: string | null | undefined): string {
    if (!action) return '-';
    return ACTION_LABELS[action] ?? action.replace(/_/g, ' ').toLowerCase().replace(/^./, (c) => c.toUpperCase());
  }

  tableLabel(table: string | null | undefined): string {
    if (!table) return '-';
    return TABLE_LABELS[table] ?? table;
  }

  downloadProducteurs(): void {
    this.downloading.set('prod-csv');
    this.producteurs.list({ page_size: 500 }).subscribe({
      next: (res) => {
        const rows = unwrapList(res);
        const csv = [
          ligneCsv(['Code', 'Nom', 'Prénoms', 'Province', 'Statut', 'Téléphone']),
          ...rows.map((p) =>
            ligneCsv([
              p.code_producteur,
              p.nom,
              p.prenoms,
              p.province_nom,
              STATUT_PRODUCTEUR_LABELS[p.statut as StatutProducteur] ?? p.statut,
              p.telephone || '',
            ]),
          ),
        ].join('\r\n');
        this._saveBlob(csv, 'pfnl-producteurs.csv', 'text/csv');
        this.downloading.set(null);
        this.toast.success('Export producteurs téléchargé');
      },
      error: (err) => {
        this.downloading.set(null);
        this.toast.error(`Export des producteurs impossible. ${toApiError(err).message}`);
      },
    });
  }

  downloadCertifications(): void {
    this.downloading.set('cert-csv');
    this.certifications.list({ page_size: '500' }).subscribe({
      next: (res) => {
        const rows = unwrapList(res);
        const csv = [
          ligneCsv(['Type', 'Producteur', 'Numéro de certificat', 'Statut', 'Date de demande']),
          ...rows.map((c) =>
            ligneCsv([
              c.type_libelle,
              c.producteur_nom || '',
              c.numero_certificat || '',
              STATUT_CERTIFICATION_LABELS[c.statut as StatutCertification] ?? c.statut,
              formatDateFr(c.date_demande),
            ]),
          ),
        ].join('\r\n');
        this._saveBlob(csv, 'pfnl-certifications.csv', 'text/csv');
        this.downloading.set(null);
        this.toast.success('Export certifications téléchargé');
      },
      error: (err) => {
        this.downloading.set(null);
        this.toast.error(`Export des certifications impossible. ${toApiError(err).message}`);
      },
    });
  }

  private _saveBlob(content: string, filename: string, mime: string): void {
    // BOM UTF-8 : sans lui, Excel affiche les accents de travers.
    triggerBrowserDownload(new Blob(['\ufeff' + content], { type: `${mime};charset=utf-8` }), filename);
  }

  downloadJournal(format: ExportFormat): void {
    const p = this.selected();
    if (!p) {
      this.toast.info("Sélectionnez d'abord une période.");
      return;
    }
    if (format === 'pdf') {
      this._openPdfJournal();
      return;
    }
    const filtres = this.currentFiltres();
    const url = this.dashboardService.journalExportUrl(this.granularite(), p.date, format, filtres);
    const slug = filtres.q
      ? `journal-${this.granularite()}-${p.date}-filtre`
      : `journal-${this.granularite()}-${p.date}`;
    this._download(url, `${slug}.${format}`, format, `journal-${format}`);
  }

  private _openPdfJournal(): void {
    const p = this.selected();
    if (!p) return;
    const filtres = this.currentFiltres();
    const title = filtres.q
      ? `Journal d’audit : recherche « ${filtres.q} »`
      : 'Journal d’audit (PDF)';
    const filename = `pfnl-journal-${this.granularite()}-${p.date}.pdf`;
    this.pdfPreview.open(title, filename, () =>
      this.dashboardService.journalPdfBlob(this.granularite(), p.date, filtres),
    );
  }

  private _download(url: string, filename: string, format: ExportFormat, key: string): void {
    this.downloading.set(key);
    const mime = {
      csv: 'text/csv;charset=utf-8',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      pdf: 'application/pdf',
    }[format];
    this.downloads.download(url, filename, mime).subscribe({
      next: () => {
        this.downloading.set(null);
        this.toast.success('Export téléchargé');
      },
      error: (err: unknown) => {
        this.downloading.set(null);
        this.toast.error(messageFromDownloadError(err));
      },
    });
  }
}
