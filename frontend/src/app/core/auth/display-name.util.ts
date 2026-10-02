import { RoleUtilisateur, Utilisateur } from '../models/user.model';

/** Mots ignorés pour calculer les initiales d'une structure (« Coopérative des Saveurs de l’Ivindo » -> « SI »). */
const MOTS_VIDES = new Set([
  'cooperative', 'coopérative', 'groupement', 'association', 'societe', 'société',
  'de', 'des', 'du', 'la', 'le', 'les', 'et', 'en', 'au', 'aux', 'pour', 'l', 'd',
]);

/** Ancien prénom fictif des comptes coopérative (corrigé côté serveur, toléré ici). */
const PRENOM_COOPERATIVE_HERITE = 'Coopérative';

function estCooperative(user: Pick<Utilisateur, 'role'>): boolean {
  return user.role === RoleUtilisateur.COOPERATIVE;
}

/** Nom affiché d'un compte : « Prénoms Nom », ou seulement le nom d'une structure. */
export function displayName(user: Pick<Utilisateur, 'role' | 'nom' | 'prenoms'> | null | undefined): string {
  if (!user) return '';
  const prenoms = (user.prenoms ?? '').trim();
  if (estCooperative(user) || !prenoms || prenoms === PRENOM_COOPERATIVE_HERITE) {
    return (user.nom ?? '').trim();
  }
  return `${prenoms} ${user.nom ?? ''}`.trim();
}

export function initialesStructure(nom: string): string {
  const mots = nom
    .split(/[\s'’-]+/)
    .map((m) => m.trim())
    .filter((m) => m && !MOTS_VIDES.has(m.toLowerCase()));
  if (mots.length >= 2) return `${mots[0][0]}${mots[1][0]}`.toUpperCase();
  const mot = mots[0] ?? nom.trim();
  return mot.slice(0, 2).toUpperCase();
}

/** Deux lettres significatives pour l'avatar. */
export function displayInitials(user: Pick<Utilisateur, 'role' | 'nom' | 'prenoms'> | null | undefined): string {
  if (!user) return '';
  const prenoms = (user.prenoms ?? '').trim();
  if (estCooperative(user) || !prenoms || prenoms === PRENOM_COOPERATIVE_HERITE) {
    return initialesStructure(user.nom ?? '');
  }
  return `${prenoms[0] ?? ''}${(user.nom ?? '')[0] ?? ''}`.toUpperCase();
}
