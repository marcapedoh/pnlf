import { ChangeDetectionStrategy, Component, DestroyRef, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { Subscription } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import {
  FiltresRapport,
  LigneConnexion,
  PresenceEnLigne,
  StatistiquesConnexions,
} from '../../../core/models/rapports.model';
import { RapportsService } from '../../../core/services/rapports.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { KpiCardComponent } from '../../../design-system/kpi-card/kpi-card.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { PnlfDatePipe } from '../../../shared/pipes/format.pipes';
import { ExportRapportComponent } from '../export-rapport/export-rapport.component';
import { GraphiqueComponent } from '../graphiques/graphique.component';
import { anneau, classement, evolution, libellePeriode } from '../graphiques/graphiques';

const RAFRAICHISSEMENT_EN_LIGNE_MS = 30_000;

/** Onglet « Activité et connexions » : connexions, appareils, présence en temps réel et visites publiques. */
@Component({
  selector: 'app-rapport-activite',
  imports: [
    AlertBannerComponent,
    ButtonComponent,
    CardComponent,
    EmptyStateComponent,
    KpiCardComponent,
    PaginationComponent,
    SkeletonComponent,
    StatusBadgeComponent,
    PnlfDatePipe,
    ExportRapportComponent,
    GraphiqueComponent,
  ],
  templateUrl: './rapport-activite.component.html',
  styleUrl: './onglets.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportActiviteComponent {
  private readonly rapports = inject(RapportsService);

  readonly filtres = input.required<FiltresRapport>();

  readonly stats = signal<StatistiquesConnexions | null>(null);
  readonly chargement = signal(true);
  readonly erreur = signal('');

  readonly enLigne = signal<PresenceEnLigne | null>(null);
  readonly erreurEnLigne = signal('');

  readonly lignes = signal<LigneConnexion[]>([]);
  readonly total = signal(0);
  readonly page = signal(1);
  readonly pageSize = 20;
  readonly succes = signal<'' | '1' | '0'>('');
  readonly chargementListe = signal(true);
  readonly erreurListe = signal('');

  private requeteStats?: Subscription;
  private requeteListe?: Subscription;

  readonly filtresListe = computed(() => ({ ...this.filtres(), succes: this.succes() }));

  readonly graphEvolution = computed(() => {
    const s = this.stats();
    if (!s) return null;
    const g = s.periode.granularite;
    return evolution(
      s.serie.map((p) => libellePeriode(p.periode, g)),
      [
        { name: 'Connexions réussies', data: s.serie.map((p) => p.connexions) },
        { name: 'Utilisateurs uniques', data: s.serie.map((p) => p.utilisateurs) },
        { name: 'Tentatives échouées', data: s.serie.map((p) => p.echecs) },
      ],
      { couleurs: ['#146b3f', '#3260a3', '#ab2626'] },
    );
  });

  readonly graphAppareils = computed(() => {
    const s = this.stats();
    return s ? anneau(s.par_appareil.map((r) => r.libelle), s.par_appareil.map((r) => r.connexions), { total: 'Connexions' }) : null;
  });

  readonly graphRoles = computed(() => {
    const s = this.stats();
    return s ? classement(s.par_role.map((r) => r.libelle), s.par_role.map((r) => r.connexions), 'Connexions') : null;
  });

  readonly graphSystemes = computed(() => {
    const s = this.stats();
    return s
      ? classement(s.par_systeme.slice(0, 8).map((r) => r.libelle), s.par_systeme.slice(0, 8).map((r) => r.connexions), 'Connexions', { couleurs: ['#3260a3'] })
      : null;
  });

  readonly graphNavigateurs = computed(() => {
    const s = this.stats();
    return s
      ? classement(s.par_navigateur.slice(0, 8).map((r) => r.libelle), s.par_navigateur.slice(0, 8).map((r) => r.connexions), 'Connexions', { couleurs: ['#6bc48a'] })
      : null;
  });

  readonly graphVisites = computed(() => {
    const v = this.stats()?.visites;
    if (!v) return null;
    return evolution(
      v.serie.map((p) => libellePeriode(p.periode, v.periode.granularite)),
      [{ name: 'Visites', data: v.serie.map((p) => p.visites) }],
      { type: 'bar', couleurs: ['#e4b91a'], hauteur: 260 },
    );
  });

  readonly graphPages = computed(() => {
    const v = this.stats()?.visites;
    if (!v) return null;
    const pages = v.par_page.slice(0, 10);
    return classement(pages.map((p) => p.libelle), pages.map((p) => p.visites), 'Visites', { couleurs: ['#a4650a'] });
  });

  constructor() {
    effect(() => {
      this.filtres();
      untracked(() => {
        this.page.set(1);
        this.charger();
        this.chargerListe();
      });
    });
    this.chargerEnLigne(false);
    const minuterie = setInterval(() => {
      if (document.visibilityState === 'visible') this.chargerEnLigne(true);
    }, RAFRAICHISSEMENT_EN_LIGNE_MS);
    inject(DestroyRef).onDestroy(() => {
      clearInterval(minuterie);
      this.requeteStats?.unsubscribe();
      this.requeteListe?.unsubscribe();
    });
  }

  charger(): void {
    this.requeteStats?.unsubscribe();
    this.chargement.set(true);
    this.erreur.set('');
    this.requeteStats = this.rapports.connexions(this.filtres()).subscribe({
      next: (s) => {
        this.stats.set(s);
        this.chargement.set(false);
      },
      error: (err) => {
        this.chargement.set(false);
        this.erreur.set(toApiError(err).message);
      },
    });
  }

  chargerListe(): void {
    this.requeteListe?.unsubscribe();
    this.chargementListe.set(true);
    this.erreurListe.set('');
    this.requeteListe = this.rapports
      .listeConnexions({ ...this.filtresListe(), page: this.page(), page_size: this.pageSize })
      .subscribe({
        next: (res) => {
          this.lignes.set(res.results);
          this.total.set(res.count);
          this.chargementListe.set(false);
        },
        error: (err) => {
          this.chargementListe.set(false);
          this.erreurListe.set(toApiError(err).message);
        },
      });
  }

  chargerEnLigne(silencieux: boolean): void {
    this.rapports.enLigne(silencieux).subscribe({
      next: (p) => {
        this.enLigne.set(p);
        this.erreurEnLigne.set('');
      },
      error: (err) => {
        if (!silencieux) this.erreurEnLigne.set(toApiError(err).message);
      },
    });
  }

  filtrerSucces(valeur: '' | '1' | '0'): void {
    this.succes.set(valeur);
    this.page.set(1);
    this.chargerListe();
  }

  allerPage(page: number): void {
    this.page.set(page);
    this.chargerListe();
  }

  tauxEchec(s: StatistiquesConnexions): string {
    const tentatives = s.totaux.connexions + s.totaux.echecs;
    return tentatives ? `${Math.round((s.totaux.echecs / tentatives) * 100)} % des tentatives` : 'Aucune tentative';
  }
}
