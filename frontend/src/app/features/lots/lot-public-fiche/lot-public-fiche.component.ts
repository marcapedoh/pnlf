import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { RouterLink } from '@angular/router';

import { LotPublicComplet, STATUT_LOT_LABELS } from '../../../core/models/lot.model';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe } from '../../../shared/pipes/format.pipes';
import { FriseLotComponent } from '../frise-lot/frise-lot.component';

/**
 * Fiche publique complète d'un lot (vérification QR et annuaire) : produit, origine, producteur,
 * certifications valides, validation, photos et frise. N'affiche que des données publiques.
 */
@Component({
  selector: 'app-lot-public-fiche',
  imports: [RouterLink, StatusBadgeComponent, IconComponent, PnlfDatePipe, PnlfQuantitePipe, PnlfMontantPipe, FriseLotComponent],
  template: `
    @let l = lot();
    <article class="fiche" [attr.aria-labelledby]="'fiche-titre-' + l.code_lot">
      <header class="fiche__entete">
        <div class="fiche__sceau" aria-hidden="true"><pnlf-icon name="shield-check" [size]="30" /></div>
        <div class="fiche__entete-texte">
          <p class="fiche__authentique">
            <pnlf-icon name="check" [size]="14" /> Produit authentique, tracé sur la plateforme nationale PFNL
          </p>
          <h2 class="fiche__titre" [id]="'fiche-titre-' + l.code_lot">{{ l.produit.nom }}</h2>
          <p class="fiche__code">Lot {{ l.code_lot }}</p>
          <div class="fiche__badges">
            <pnlf-status-badge [label]="l.statut_libelle || statutLabels[l.statut]" [tone]="tone(l.statut)" />
            @if (l.validation; as v) {
              <span class="fiche__validation">
                <pnlf-icon name="shield" [size]="14" /> {{ v.libelle }}
                @if (v.date) { <span class="fiche__muted">le {{ v.date | pnlfDate }}</span> }
              </span>
            }
          </div>
          @if (l.commercialisation; as c) {
            <p class="fiche__note">
              Lot commercialisé le {{ c.date | pnlfDate }} : il n’est plus proposé à la vente, mais son origine
              reste vérifiable.
            </p>
          }
        </div>
      </header>

      <div class="fiche__grille">
        <section class="fiche__bloc" aria-labelledby="fiche-produit">
          <h3 id="fiche-produit"><pnlf-icon name="package" [size]="16" /> Produit</h3>
          <dl>
            <div><dt>Nom</dt><dd>{{ l.produit.nom }}</dd></div>
            @if (l.produit.nom_scientifique) {
              <div><dt>Nom scientifique</dt><dd><em>{{ l.produit.nom_scientifique }}</em></dd></div>
            }
            @if (l.produit.categorie) {
              <div><dt>Catégorie</dt><dd>{{ l.produit.categorie }}</dd></div>
            }
            <div><dt>Quantité</dt><dd>{{ l.quantite | pnlfQuantite: l.unite }}</dd></div>
            @if (l.qualite_indicateur) {
              <div><dt>Qualité</dt><dd>{{ l.qualite_indicateur }}</dd></div>
            }
            @if (afficherPrix() && l.prix_indicatif) {
              <div><dt>Prix indicatif</dt><dd>{{ l.prix_indicatif | pnlfMontant: l.devise }}</dd></div>
            }
          </dl>
        </section>

        <section class="fiche__bloc" aria-labelledby="fiche-origine">
          <h3 id="fiche-origine"><pnlf-icon name="map-pin" [size]="16" /> Collecte</h3>
          <dl>
            <div><dt>Date de collecte</dt><dd>{{ l.date_collecte | pnlfDate }}</dd></div>
            <div><dt>Zone de collecte</dt><dd>{{ l.lieu.zone || 'Non précisée' }}</dd></div>
            <div><dt>Province</dt><dd>{{ l.lieu.province || 'Non précisée' }}</dd></div>
            @if (l.lieu.latitude && l.lieu.longitude) {
              <div>
                <dt>Position approximative</dt>
                <dd>
                  {{ l.lieu.latitude }}, {{ l.lieu.longitude }}
                  <a class="fiche__lien no-print" [href]="carteUrl()" target="_blank" rel="noopener">
                    Carte<span class="pnlf-visually-hidden"> (nouvel onglet)</span> ↗
                  </a>
                </dd>
              </div>
            }
          </dl>
          <p class="fiche__aide">Position arrondie à environ 1 km : l’emplacement exact de la récolte n’est pas diffusé.</p>
        </section>

        <section class="fiche__bloc" aria-labelledby="fiche-producteur">
          <h3 id="fiche-producteur"><pnlf-icon name="user-check" [size]="16" /> {{ l.producteur.type_acteur_libelle }}</h3>
          <div class="fiche__producteur">
            @if (l.producteur.photo_url) {
              <img class="fiche__avatar" [src]="l.producteur.photo_url" [alt]="'Photo de ' + l.producteur_nom" />
            } @else {
              <span class="fiche__avatar fiche__avatar--vide" aria-hidden="true">{{ initiales() }}</span>
            }
            <div>
              <p class="fiche__nom">{{ l.producteur_nom }}</p>
              @if (l.producteur.cooperative_nom) {
                <p class="fiche__muted">Membre de la coopérative {{ l.producteur.cooperative_nom }}</p>
              }
              @if (l.producteur.province_nom) {
                <p class="fiche__muted">Province : {{ l.producteur.province_nom }}</p>
              }
              @if (l.producteur.id && lienProducteur()) {
                <a class="fiche__lien no-print" [routerLink]="['/annuaire', l.producteur.id]">Voir sa fiche publique</a>
              }
            </div>
          </div>
        </section>

        <section class="fiche__bloc" aria-labelledby="fiche-certifs">
          <h3 id="fiche-certifs"><pnlf-icon name="award" [size]="16" /> Certifications valides</h3>
          @if (l.certifications.length) {
            <ul class="fiche__certifs">
              @for (c of l.certifications; track $index) {
                <li>
                  <strong>{{ c.libelle }}</strong>
                  <span class="fiche__muted">
                    {{ c.portee === 'LOT' ? 'Propre à ce lot' : 'Détenue par le ' + l.producteur.type_acteur_libelle.toLowerCase() }}
                    @if (c.organisme) { , délivrée par {{ c.organisme }} }
                    @if (c.date_expiration) { , valable jusqu’au {{ c.date_expiration | pnlfDate }} }
                  </span>
                  @if (c.numero_certificat) { <span class="fiche__muted">N° {{ c.numero_certificat }}</span> }
                </li>
              }
            </ul>
          } @else {
            <p class="fiche__muted">Aucune certification en cours de validité pour ce lot ou son producteur.</p>
          }
        </section>
      </div>

      @if (l.photos_urls.length) {
        <section class="fiche__bloc" aria-labelledby="fiche-photos">
          <h3 id="fiche-photos"><pnlf-icon name="camera" [size]="16" /> Photos de la marchandise</h3>
          <div class="fiche__photos">
            @for (url of l.photos_urls; track url; let i = $index) {
              <img [src]="url" [alt]="'Photo ' + (i + 1) + ' du lot ' + l.code_lot" loading="lazy" />
            }
          </div>
        </section>
      }

      <section class="fiche__bloc" aria-labelledby="fiche-frise">
        <h3 id="fiche-frise"><pnlf-icon name="clock" [size]="16" /> Parcours du lot</h3>
        <app-frise-lot [evenements]="l.frise" mode="public" [titre]="'Parcours du lot ' + l.code_lot" />
      </section>
    </article>
  `,
  styles: `
    :host {
      display: block;
      text-align: left;
    }

    .fiche {
      display: flex;
      flex-direction: column;
      gap: var(--space-5);
    }

    .fiche__entete {
      display: flex;
      gap: var(--space-4);
      align-items: flex-start;

      @media (max-width: 520px) {
        flex-direction: column;
        align-items: center;
        text-align: center;
      }
    }

    .fiche__sceau {
      flex: none;
      width: 64px;
      height: 64px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--color-success-bg);
      color: var(--color-success);
    }

    .fiche__authentique {
      margin: 0;
      display: inline-flex;
      align-items: center;
      gap: 0.35rem;
      font-size: var(--fs-xs);
      font-weight: 700;
      color: var(--color-success);
    }

    .fiche__titre {
      margin: var(--space-1) 0 0;
      font-family: var(--font-serif);
      font-size: clamp(1.3rem, 2.5vw, 1.7rem);
      color: var(--text-primary);
    }

    .fiche__code {
      margin: 2px 0 var(--space-2);
      font-weight: 700;
      color: var(--pnlf-green-700);
    }

    .fiche__badges {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: var(--space-2) var(--space-3);

      @media (max-width: 520px) {
        justify-content: center;
      }
    }

    .fiche__validation {
      display: inline-flex;
      align-items: center;
      gap: 0.35rem;
      font-size: var(--fs-sm);
      font-weight: 600;
      color: var(--text-primary);
    }

    .fiche__note {
      margin: var(--space-3) 0 0;
      font-size: var(--fs-sm);
      color: var(--text-secondary);
      background: var(--gray-50);
      border-radius: var(--radius-md);
      padding: var(--space-2) var(--space-3);
    }

    .fiche__grille {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: var(--space-4);

      @media (max-width: 720px) {
        grid-template-columns: 1fr;
      }
    }

    .fiche__bloc {
      border: 1px solid var(--border-subtle);
      border-radius: var(--radius-lg);
      padding: var(--space-4);
      break-inside: avoid;

      h3 {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        margin: 0 0 var(--space-3);
        font-size: var(--fs-base);
        color: var(--text-primary);
      }

      dl {
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
      }

      dl > div {
        display: flex;
        justify-content: space-between;
        gap: var(--space-3);
        padding-bottom: var(--space-2);
        border-bottom: 1px dashed var(--border-subtle);
      }

      dl > div:last-child {
        border-bottom: none;
        padding-bottom: 0;
      }

      dt {
        font-size: var(--fs-sm);
        color: var(--text-muted);
      }

      dd {
        margin: 0;
        font-size: var(--fs-sm);
        font-weight: 600;
        color: var(--text-primary);
        text-align: right;
        overflow-wrap: anywhere;
      }
    }

    .fiche__aide,
    .fiche__muted {
      margin: var(--space-1) 0 0;
      font-size: var(--fs-xs);
      color: var(--text-muted);
      font-weight: 400;
    }

    .fiche__lien {
      margin-left: var(--space-2);
      font-size: var(--fs-xs);
      font-weight: 600;
      color: var(--pnlf-green-700);
    }

    .fiche__producteur {
      display: flex;
      gap: var(--space-3);
      align-items: flex-start;

      .fiche__lien {
        display: inline-block;
        margin: var(--space-2) 0 0;
      }
    }

    .fiche__avatar {
      flex: none;
      width: 56px;
      height: 56px;
      border-radius: 50%;
      object-fit: cover;
    }

    .fiche__avatar--vide {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: var(--pnlf-green-100);
      color: var(--pnlf-green-700);
      font-weight: 700;
    }

    .fiche__nom {
      margin: 0;
      font-weight: 700;
      color: var(--text-primary);
    }

    .fiche__certifs {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: var(--space-3);

      li {
        display: flex;
        flex-direction: column;
        font-size: var(--fs-sm);
      }
    }

    .fiche__photos {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-3);

      img {
        width: 160px;
        height: 120px;
        object-fit: cover;
        border-radius: var(--radius-md);
        border: 1px solid var(--border-subtle);
      }
    }

    @media print {
      .no-print {
        display: none !important;
      }

      .fiche__bloc {
        border-color: #999;
      }
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotPublicFicheComponent {
  readonly lot = input.required<LotPublicComplet>();
  /** Le prix indicatif n'a de sens que pour un lot encore proposé (annuaire). */
  readonly afficherPrix = input(false);
  readonly lienProducteur = input(true);

  readonly statutLabels = STATUT_LOT_LABELS;
  readonly tone = lotStatusTone;

  readonly carteUrl = computed(() => {
    const l = this.lot();
    return `https://www.openstreetmap.org/?mlat=${l.lieu.latitude}&mlon=${l.lieu.longitude}#map=12/${l.lieu.latitude}/${l.lieu.longitude}`;
  });

  readonly initiales = computed(() => {
    const p = this.lot().producteur;
    return `${(p.prenoms || '').charAt(0)}${(p.nom || '').charAt(0)}`.toUpperCase() || '?';
  });
}
