export interface Province {
  id: string;
  code: string;
  nom: string;
  actif: boolean;
}

export interface Departement {
  id: string;
  code: string;
  nom: string;
  province: string;
  province_nom: string;
  actif: boolean;
}

export interface Village {
  id: string;
  nom: string;
  departement: string;
  departement_nom: string;
  latitude: number | null;
  longitude: number | null;
  actif: boolean;
}

export interface CategorieProduit {
  id: string;
  code: string;
  libelle: string;
  description: string | null;
  parent: string | null;
  actif: boolean;
}

export interface Produit {
  id: string;
  code: string;
  nom: string;
  nom_scientifique: string | null;
  categorie: string;
  categorie_libelle: string;
  description: string | null;
  unite_defaut: string;
  soumis_cites: boolean;
  code_cites: string | null;
  actif: boolean;
}

export interface ZoneCollecte {
  id: string;
  code: string;
  libelle: string;
  province: string;
  province_nom: string;
  description: string | null;
  latitude: number | null;
  longitude: number | null;
  actif: boolean;
  created_at: string;
  updated_at: string;
}
