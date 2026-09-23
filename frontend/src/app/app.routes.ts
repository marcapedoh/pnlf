import { Routes } from '@angular/router';

import { authGuard, guestGuard } from './core/auth/auth.guard';
import { roleGuard } from './core/auth/role.guard';
import { RoleUtilisateur } from './core/models/user.model';

const R = RoleUtilisateur;

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./layout/public-shell/public-shell.component').then((m) => m.PublicShellComponent),
    children: [
      {
        path: '',
        pathMatch: 'full',
        loadComponent: () => import('./features/public/home/home-page.component').then((m) => m.HomePageComponent),
        title: 'PFNL | Traçabilité des PFNL du Gabon',
      },
      {
        path: 'annuaire',
        loadComponent: () =>
          import('./features/public/annuaire/annuaire-public.component').then((m) => m.AnnuairePublicComponent),
        title: 'Annuaire des producteurs — PFNL',
      },
      {
        path: 'annuaire/lot/:id',
        loadComponent: () =>
          import('./features/public/lot-public/lot-public-detail.component').then(
            (m) => m.LotPublicDetailComponent,
          ),
        title: 'Fiche du lot — PFNL',
      },
      {
        path: 'annuaire/:id',
        loadComponent: () =>
          import('./features/public/producteur-public/producteur-public-detail.component').then(
            (m) => m.ProducteurPublicDetailComponent,
          ),
        title: 'Fiche producteur — PFNL',
      },
      {
        path: 'offres-demandes',
        loadComponent: () =>
          import('./features/public/offres/offres-publiques.component').then((m) => m.OffresPubliquesComponent),
        title: 'Offres & demandes — PFNL',
      },
      {
        path: 'offres-demandes/:id',
        loadComponent: () =>
          import('./features/public/offres/offre-publique-detail.component').then(
            (m) => m.OffrePubliqueDetailComponent,
          ),
        title: "Fiche d'annonce — PFNL",
      },
      {
        path: 'inscription',
        canActivate: [guestGuard],
        loadComponent: () =>
          import('./features/public/inscription/inscription-publique.component').then(
            (m) => m.InscriptionPubliqueComponent,
          ),
        title: 'Inscription — PFNL',
      },
      {
        path: 'verifier',
        loadComponent: () =>
          import('./features/verify/verify-public.component').then((m) => m.VerifyPublicComponent),
        title: 'Vérifier un produit — PFNL',
      },
      {
        path: 'verifier/:uuid',
        loadComponent: () =>
          import('./features/verify/verify-public.component').then((m) => m.VerifyPublicComponent),
        title: 'Vérifier un produit — PFNL',
      },
      {
        path: 'faq',
        loadComponent: () => import('./features/public/legal/faq/faq.component').then((m) => m.FaqComponent),
        title: 'Foire aux questions — PFNL',
      },
      {
        path: 'politique-confidentialite',
        loadComponent: () =>
          import('./features/public/legal/confidentialite/confidentialite.component').then(
            (m) => m.ConfidentialiteComponent,
          ),
        title: 'Politique de confidentialité — PFNL',
      },
      {
        path: 'conditions-utilisation',
        loadComponent: () =>
          import('./features/public/legal/conditions-utilisation/conditions-utilisation.component').then(
            (m) => m.ConditionsUtilisationComponent,
          ),
        title: "Conditions d'utilisation — PFNL",
      },
      {
        path: 'politique-cookies',
        loadComponent: () =>
          import('./features/public/legal/cookies/politique-cookies.component').then(
            (m) => m.PolitiqueCookiesComponent,
          ),
        title: 'Politique de cookies — PFNL',
      },
    ],
  },
  {
    path: 'connexion',
    canActivate: [guestGuard],
    loadComponent: () => import('./features/auth/login/login.component').then((m) => m.LoginComponent),
    title: 'Connexion — PFNL',
  },
  {
    path: 'mot-de-passe-oublie',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/auth/forgot-password/forgot-password.component').then(
        (m) => m.ForgotPasswordComponent,
      ),
    title: 'Mot de passe oublié — PFNL',
  },
  {
    path: 'reinitialiser-mot-de-passe',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/auth/reset-password/reset-password.component').then(
        (m) => m.ResetPasswordComponent,
      ),
    title: 'Réinitialiser le mot de passe — PFNL',
  },
  {
    path: 'changer-mot-de-passe',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/auth/change-password/change-password.component').then(
        (m) => m.ChangePasswordComponent,
      ),
    title: 'Changer le mot de passe — PFNL',
  },
  {
    path: 'app',
    canActivate: [authGuard],
    loadComponent: () => import('./layout/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'tableau-de-bord' },
      {
        path: 'tableau-de-bord',
        loadComponent: () => import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
        title: 'Tableau de bord — PFNL',
      },
      {
        path: 'a-traiter',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER)],
        loadComponent: () =>
          import('./features/validation/a-traiter.component').then((m) => m.ATraiterComponent),
        title: 'À traiter — PFNL',
      },
      {
        path: 'producteurs',
        canActivate: [
          roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE, R.PRODUCTEUR),
        ],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/producteurs/producteurs-list/producteurs-list.component').then(
                (m) => m.ProducteursListComponent,
              ),
            title: 'Producteurs & collecteurs — PFNL',
          },
          {
            path: 'nouveau',
            canActivate: [
              roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE),
            ],
            loadComponent: () =>
              import('./features/producteurs/producteur-form/producteur-form.component').then(
                (m) => m.ProducteurFormComponent,
              ),
            title: 'Nouvelle fiche producteur — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/producteurs/producteur-detail/producteur-detail.component').then(
                (m) => m.ProducteurDetailComponent,
              ),
            title: 'Fiche producteur — PFNL',
          },
          {
            path: ':id/modifier',
            loadComponent: () =>
              import('./features/producteurs/producteur-form/producteur-form.component').then(
                (m) => m.ProducteurFormComponent,
              ),
            title: 'Modifier la fiche producteur — PFNL',
          },
        ],
      },
      {
        path: 'lots',
        canActivate: [
          roleGuard(
            R.ADMINISTRATEUR,
            R.AGENT_MINISTERE,
            R.AGENT_FORESTIER,
            R.PRODUCTEUR,
            R.COOPERATIVE,
            R.ACHETEUR,
          ),
        ],
        children: [
          {
            path: '',
            loadComponent: () => import('./features/lots/lots-list/lots-list.component').then((m) => m.LotsListComponent),
            title: 'Lots de produits — PFNL',
          },
          {
            path: 'nouveau',
            canActivate: [
              roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.PRODUCTEUR, R.COOPERATIVE),
            ],
            loadComponent: () => import('./features/lots/lot-form/lot-form.component').then((m) => m.LotFormComponent),
            title: 'Déclarer un lot — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/lots/lot-detail/lot-detail.component').then((m) => m.LotDetailComponent),
            title: 'Détail du lot — PFNL',
          },
        ],
      },
      {
        path: 'zones-collecte',
        canActivate: [
          roleGuard(
            R.ADMINISTRATEUR,
            R.AGENT_MINISTERE,
            R.AGENT_FORESTIER,
            R.PRODUCTEUR,
            R.COOPERATIVE,
          ),
        ],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/zones-collecte/zones-collecte-list.component').then(
                (m) => m.ZonesCollecteListComponent,
              ),
            title: 'Zones de collecte — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/zones-collecte/zone-collecte-detail/zone-collecte-detail.component').then(
                (m) => m.ZoneCollecteDetailComponent,
              ),
            title: 'Détail de la zone — PFNL',
          },
        ],
      },
      {
        path: 'certifications',
        canActivate: [
          roleGuard(
            R.ADMINISTRATEUR,
            R.AGENT_MINISTERE,
            R.AGENT_FORESTIER,
            R.PRODUCTEUR,
            R.COOPERATIVE,
          ),
        ],
        loadComponent: () =>
          import('./features/certifications/certifications-list.component').then(
            (m) => m.CertificationsListComponent,
          ),
        title: 'Certifications — PFNL',
      },
      {
        path: 'cooperatives',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE)],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/cooperatives/cooperatives-list.component').then((m) => m.CooperativesListComponent),
            title: 'Coopératives — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/cooperatives/cooperative-detail/cooperative-detail.component').then(
                (m) => m.CooperativeDetailComponent,
              ),
            title: 'Détail de la coopérative — PFNL',
          },
        ],
      },
      {
        path: 'marketplace/annuaire',
        loadComponent: () =>
          import('./features/marketplace/annuaire/annuaire.component').then((m) => m.AnnuaireComponent),
        title: 'Annuaire de la filière — PFNL',
      },
      {
        path: 'messagerie',
        canActivate: [
          roleGuard(
            R.PRODUCTEUR,
            R.COOPERATIVE,
            R.ACHETEUR,
            R.ADMINISTRATEUR,
            R.AGENT_MINISTERE,
            R.AGENT_FORESTIER,
          ),
        ],
        loadComponent: () =>
          import('./features/messagerie/messagerie.component').then((m) => m.MessagerieComponent),
        title: 'Messagerie — PFNL',
      },
      {
        path: 'marketplace/offres',
        canActivate: [
          roleGuard(
            R.PRODUCTEUR,
            R.COOPERATIVE,
            R.ACHETEUR,
            R.ADMINISTRATEUR,
            R.AGENT_MINISTERE,
            R.AGENT_FORESTIER,
          ),
        ],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/marketplace/offres/offres-list.component').then((m) => m.OffresListComponent),
            title: 'Offres & demandes — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/marketplace/offres/offre-detail/offre-detail.component').then(
                (m) => m.OffreDetailComponent,
              ),
            title: "Détail de l'annonce — PFNL",
          },
        ],
      },
      {
        path: 'utilisateurs',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE)],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/utilisateurs/utilisateurs-list.component').then((m) => m.UtilisateursListComponent),
            title: 'Comptes utilisateurs — PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/utilisateurs/utilisateur-detail/utilisateur-detail.component').then(
                (m) => m.UtilisateurDetailComponent,
              ),
            title: 'Fiche utilisateur — PFNL',
          },
        ],
      },
      {
        path: 'rapports',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER)],
        loadComponent: () => import('./features/rapports/rapports.component').then((m) => m.RapportsComponent),
        title: 'Rapports & exports — PFNL',
      },
      {
        path: 'synchronisation',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER)],
        loadComponent: () =>
          import('./features/synchronisation/synchronisation.component').then((m) => m.SynchronisationComponent),
        title: 'Synchronisation terrain — PFNL',
      },
      {
        path: 'notifications',
        loadComponent: () =>
          import('./features/notifications/notifications-page.component').then(
            (m) => m.NotificationsPageComponent,
          ),
        title: 'Notifications — PFNL',
      },
      {
        path: 'parametres',
        loadComponent: () => import('./features/parametres/parametres.component').then((m) => m.ParametresComponent),
        title: 'Mon profil — PFNL',
      },
      {
        path: 'acces-refuse',
        loadComponent: () =>
          import('./features/errors/access-denied/access-denied.component').then((m) => m.AccessDeniedComponent),
        title: 'Accès refusé — PFNL',
      },
    ],
  },
  {
    path: 'erreur-400',
    loadComponent: () =>
      import('./features/errors/bad-request/bad-request.component').then((m) => m.BadRequestComponent),
    title: 'Requête invalide — PFNL',
  },
  { path: '**', loadComponent: () => import('./features/errors/not-found/not-found.component').then((m) => m.NotFoundComponent), title: 'Page introuvable — PFNL' },
];
