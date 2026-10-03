export type StatutModerationImage = 'EN_ATTENTE' | 'APPROUVEE' | 'REJETEE' | 'REMPLACEE';

export interface ModerationImage {
  id: string;
  chemin: string;
  type_objet: string;
  type_objet_libelle: string;
  objet_id: string | null;
  objet_libelle: string | null;
  objet_route: string[] | null;
  envoye_par: { id: string; nom: string | null; email: string; role: string } | null;
  verdict: 'DOUTEUX' | 'EXPLICITE';
  score_nsfw: number | null;
  scores: {
    nsfw?: number | null;
    vues?: number[];
    duree_ms?: number;
    seuil_douteux?: number;
    seuil_explicite?: number;
    motif?: string | null;
    modele?: string;
  };
  statut: StatutModerationImage;
  statut_libelle: string;
  motif: string | null;
  traite_par_nom: string | null;
  traite_at: string | null;
  created_at: string;
  apercu_url: string | null;
}

export type FiltreModerationImages = 'EN_ATTENTE' | 'TRAITEES';
