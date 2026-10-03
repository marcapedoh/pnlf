/** Champs complémentaires des annonces (offres et demandes) et profil public de l'auteur. */

import { BadgeTone } from '../../design-system/badge/status-badge.component';

export function toneStatutAnnonce(statut: string): BadgeTone {
  if (statut === 'OUVERTE') return 'success';
  if (statut === 'EN_VALIDATION') return 'warning';
  if (statut === 'REJETEE') return 'danger';
  return 'neutral';
}

export type ModeRemise = 'LIVRAISON' | 'RETRAIT' | 'LIVRAISON_OU_RETRAIT';
export type MoyenPaiement = 'ESPECES' | 'MOBILE_MONEY' | 'VIREMENT' | 'CHEQUE' | 'A_LA_LIVRAISON' | 'ACOMPTE';
export type VueAnnonces = 'liste' | 'grille' | 'tableau';
export type TriAnnonces = 'recent' | 'ancien' | 'prix_asc' | 'prix_desc' | 'expiration';

export const MODES_REMISE: { value: ModeRemise; label: string }[] = [
  { value: 'LIVRAISON', label: 'Livraison par le vendeur' },
  { value: 'RETRAIT', label: 'Retrait sur place' },
  { value: 'LIVRAISON_OU_RETRAIT', label: 'Livraison ou retrait' },
];

export const MOYENS_PAIEMENT: { value: MoyenPaiement; label: string }[] = [
  { value: 'ESPECES', label: 'Espèces' },
  { value: 'MOBILE_MONEY', label: 'Mobile Money (Airtel Money, Moov Money)' },
  { value: 'VIREMENT', label: 'Virement bancaire' },
  { value: 'CHEQUE', label: 'Chèque' },
  { value: 'A_LA_LIVRAISON', label: 'Paiement à la livraison' },
  { value: 'ACOMPTE', label: 'Acompte à la commande' },
];

export const TRIS_ANNONCES: { value: TriAnnonces; label: string }[] = [
  { value: 'recent', label: 'Plus récentes' },
  { value: 'ancien', label: 'Plus anciennes' },
  { value: 'prix_asc', label: 'Prix croissant' },
  { value: 'prix_desc', label: 'Prix décroissant' },
  { value: 'expiration', label: 'Expiration proche' },
];

export const VUES_ANNONCES: { value: VueAnnonces; label: string; icon: 'list' | 'grid' | 'table' }[] = [
  { value: 'liste', label: 'Liste', icon: 'list' },
  { value: 'grille', label: 'Grille', icon: 'grid' },
  { value: 'tableau', label: 'Tableau compact', icon: 'table' },
];

export function libelleModeRemise(mode: string | null | undefined): string {
  return MODES_REMISE.find((m) => m.value === mode)?.label ?? '';
}

export function libelleMoyenPaiement(moyen: string): string {
  return MOYENS_PAIEMENT.find((m) => m.value === moyen)?.label ?? moyen;
}

export interface AnnonceAuteur {
  nom: string;
  type_acteur: string;
  province: string | null;
  photo_url: string | null;
  membre_depuis: string | null;
  certifie: boolean;
  fiche_publique_id: string | null;
}

export interface AnnonceContact {
  telephone: string | null;
  email: string | null;
}

export interface AnnonceModeration {
  decision: 'VALIDEE' | 'REJETEE';
  moderateur_nom: string | null;
  decide_at: string;
  motif: string | null;
}

export interface AnnonceDetails {
  categorie_id?: string | null;
  categorie_nom?: string | null;
  prix_total?: string | number | null;
  negociable?: boolean;
  conditionnement?: string | null;
  qualite?: string | null;
  localite?: string | null;
  disponible_du?: string | null;
  mode_remise?: ModeRemise | '' | null;
  modalites_livraison?: string | null;
  moyens_paiement?: MoyenPaiement[];
  conditions_paiement?: string | null;
  afficher_telephone?: boolean;
  afficher_email?: boolean;
  auteur?: AnnonceAuteur | null;
  contact?: AnnonceContact;
  expiree?: boolean;
  photos_max?: number;
  moderation?: AnnonceModeration | null;
}

export interface AnnoncesFiltres {
  q?: string;
  type_annonce?: string;
  produit?: string;
  categorie?: string;
  province?: string;
  prix_min?: string;
  prix_max?: string;
  statut?: string;
  mine?: string;
  tri?: TriAnnonces;
  page?: number;
  page_size?: number;
}

const CLE_VUE = 'pfnl.annonces.vue';

export function vueAnnoncesMemorisee(defaut: VueAnnonces = 'grille'): VueAnnonces {
  try {
    const valeur = localStorage.getItem(CLE_VUE);
    return VUES_ANNONCES.some((v) => v.value === valeur) ? (valeur as VueAnnonces) : defaut;
  } catch {
    return defaut;
  }
}

export function memoriserVueAnnonces(vue: VueAnnonces): void {
  try {
    localStorage.setItem(CLE_VUE, vue);
  } catch {
    /* stockage indisponible (navigation privée) : le choix reste valable pour la session en cours */
  }
}

/** Paramètres HTTP non vides, prêts pour HttpClient. */
export function paramsAnnonces(filtres: AnnoncesFiltres): Record<string, string> {
  const params: Record<string, string> = {};
  for (const [cle, valeur] of Object.entries(filtres)) {
    if (valeur !== undefined && valeur !== null && String(valeur).trim() !== '') params[cle] = String(valeur).trim();
  }
  return params;
}
