/** Contrats des rapports statistiques (connexions, présence, visites, inscriptions, filière) et du tableau de bord. */

export type Granularite = 'jour' | 'semaine' | 'mois';

export interface PeriodeRapport {
  date_debut: string;
  date_fin: string;
  granularite: Granularite;
  libelle: string;
}

export interface FiltresRapport {
  date_debut?: string;
  date_fin?: string;
  granularite?: Granularite | '';
  q?: string;
}

export interface Repartition {
  cle: string;
  libelle: string;
  connexions: number;
  appareils: number;
}

export interface PointConnexions {
  periode: string;
  connexions: number;
  echecs: number;
  utilisateurs: number;
}

export interface StatistiquesVisites {
  periode: PeriodeRapport;
  total: number;
  serie: { periode: string; visites: number }[];
  par_page: { page: string; libelle: string; visites: number }[];
  par_appareil: { cle: string; libelle: string; visites: number }[];
}

export interface StatistiquesConnexions {
  periode: PeriodeRapport;
  totaux: { connexions: number; echecs: number; utilisateurs_uniques: number; appareils_distincts: number };
  serie: PointConnexions[];
  par_appareil: Repartition[];
  par_systeme: Repartition[];
  par_navigateur: Repartition[];
  par_role: Repartition[];
  echecs_par_motif: { cle: string; libelle: string; nombre: number }[];
  visites: StatistiquesVisites;
}

export interface LigneConnexion {
  id: number;
  date: string;
  utilisateur_id: string | null;
  utilisateur: string;
  email: string | null;
  role: string | null;
  role_libelle: string;
  succes: boolean;
  motif_echec: string | null;
  appareil: string;
  appareil_libelle: string;
  systeme: string | null;
  navigateur: string | null;
  ip_masquee: string | null;
}

export interface PageResultats<T> {
  count: number;
  page: number;
  page_size: number;
  results: T[];
}

export interface PresenceEnLigne {
  genere_at: string;
  fenetre_minutes: number;
  utilisateurs: number;
  appareils: number;
  par_appareil: { cle: string; libelle: string; nombre: number }[];
  par_role: { cle: string; libelle: string; nombre: number }[];
  liste: {
    utilisateur_id: string;
    utilisateur: string;
    role: string;
    role_libelle: string;
    appareil: string;
    appareil_libelle: string;
    systeme: string | null;
    navigateur: string | null;
    ip_masquee: string | null;
    connecte_depuis: string | null;
    derniere_activite: string | null;
  }[];
}

export type StatutDemande = 'EN_ATTENTE' | 'VALIDEE' | 'REJETEE';

export interface DemandeInscription {
  date: string;
  type_demande: string;
  type_libelle: string;
  demandeur: string;
  email: string | null;
  statut: StatutDemande;
  statut_libelle: string;
  decide_at: string | null;
  decideur: string | null;
  delai_heures: number | null;
  motif: string | null;
  table_cible: string;
  enregistrement_id: string | null;
}

export interface CompteursInscriptions {
  recues: number;
  en_attente: number;
  validees: number;
  rejetees: number;
  delai_moyen_heures: number | null;
}

export interface StatistiquesInscriptions extends PageResultats<DemandeInscription> {
  periode: PeriodeRapport;
  totaux: CompteursInscriptions;
  par_type: ({ cle: string; libelle: string } & CompteursInscriptions)[];
  serie: { periode: string; recues: number; validees: number; rejetees: number; en_attente: number }[];
  motifs_rejet: { motif: string; nombre: number }[];
}

export interface StatistiquesFiliere {
  periode: PeriodeRapport;
  totaux: {
    lots: number;
    lots_brouillon: number;
    lots_valide: number;
    lots_commercialise: number;
    producteurs_actifs: number;
    cooperatives_actives: number;
    certifications_valides: number;
    annonces_publiees: number;
  };
  par_statut: { cle: string; libelle: string; nombre: number }[];
  serie: { periode: string; brouillon: number; valide: number; commercialise: number }[];
  par_produit: {
    produit: string;
    unite: string | null;
    lots: number;
    quantite: number;
    brouillon: number;
    valide: number;
    commercialise: number;
  }[];
  par_province: { province: string; lots: number }[];
}

export type RapportExportable = 'connexions' | 'en-ligne' | 'inscriptions' | 'filiere' | 'visites';

export type SectionATraiter = 'producteurs' | 'cooperatives' | 'certifications' | 'lots' | 'offres' | 'acheteurs' | 'images';

/** Synthèse par rôle renvoyée par `GET /dashboard/resume/`. */
export interface CompteursParStatut {
  total: number;
  par_statut: { cle: string; libelle: string; nombre: number }[];
}

export interface ResumeTableauDeBord {
  role: string;
  role_libelle: string;
  genere_at: string;
  messages: { non_lus: number; conversations_non_lues: number; conversations: number };
  notifications_non_lues: number;
  annonces: {
    miennes: CompteursParStatut;
    marche: { offres: number; demandes: number };
  };
  a_traiter?: Partial<Record<SectionATraiter, { autorise: boolean; count: number }>>;
  a_traiter_total?: number;
  lots?: CompteursParStatut;
  producteurs?: CompteursParStatut;
  cooperatives?: CompteursParStatut;
  certifications?: CompteursParStatut & { valides: number; en_instruction: number };
  activite?: {
    en_ligne: number;
    appareils_en_ligne: number;
    connexions_jour: number;
    utilisateurs_jour: number;
    echecs_jour: number;
    visites_jour: number;
  };
  fiche?: {
    id: string;
    statut: string;
    statut_libelle: string;
    nom?: string;
    cooperative?: string | null;
    cooperative_id?: string | null;
  } | null;
  cooperative?: {
    invitations_recues?: number;
    adhesion_en_attente?: boolean;
    membres_actifs?: number;
    demandes_adhesion?: number;
    invitations_en_attente?: number;
  };
  lots_disponibles?: number;
}
