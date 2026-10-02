export interface DashboardProducteurRow {
  province?: string | null;
  province__nom?: string | null;
  type_acteur?: string | null;
  statut?: string | null;
  nombre: number;
}

export interface DashboardLotRow {
  province?: string | null;
  province__nom?: string | null;
  produit?: string | null;
  produit__nom?: string | null;
  statut: string;
  periode?: string | null;
  nb_lots: number;
  quantite?: number | null;
  quantite_totale?: number | null;
  unite?: string | null;
}

export interface DashboardMouvementRow {
  type?: string;
  type_mouvement?: string;
  periode?: string | null;
  nombre: number;
}

export interface DashboardStats {
  producteurs: DashboardProducteurRow[];
  lots: DashboardLotRow[];
  mouvements: DashboardMouvementRow[];
  filtres?: {
    province: string | null;
    produit: string | null;
    date_debut: string | null;
    date_fin: string | null;
  };
  totaux: {
    producteurs_actifs: number;
    lots_actifs: number;
    produits_referentiel: number;
  };
}
