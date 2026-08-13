import { Routes } from '@angular/router';

import { authGuard, guestGuard } from './core/auth/auth.guard';
import { roleGuard } from './core/auth/role.guard';
import { RoleUtilisateur } from './core/models/user.model';

const R = RoleUtilisateur;

export const routes: Routes = [
  {
    path: 'connexion',
    canActivate: [guestGuard],
    loadComponent: () => import('./features/auth/login/login.component').then((m) => m.LoginComponent),
    title: 'Connexion — PNLF-PFNL',
  },
  {
    path: 'mot-de-passe-oublie',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/auth/forgot-password/forgot-password.component').then(
        (m) => m.ForgotPasswordComponent,
      ),
    title: 'Mot de passe oublié — PNLF-PFNL',
  },
  {
    path: 'reinitialiser-mot-de-passe',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/auth/reset-password/reset-password.component').then(
        (m) => m.ResetPasswordComponent,
      ),
    title: 'Réinitialiser le mot de passe — PNLF-PFNL',
  },
  {
    path: 'changer-mot-de-passe',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/auth/change-password/change-password.component').then(
        (m) => m.ChangePasswordComponent,
      ),
    title: 'Changer le mot de passe — PNLF-PFNL',
  },
  {
    path: 'verifier',
    loadComponent: () => import('./features/verify/verify-public.component').then((m) => m.VerifyPublicComponent),
    title: 'Vérification de traçabilité — PNLF-PFNL',
  },
  {
    path: 'verifier/:uuid',
    loadComponent: () => import('./features/verify/verify-public.component').then((m) => m.VerifyPublicComponent),
    title: 'Vérification de traçabilité — PNLF-PFNL',
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
        title: 'Tableau de bord — PNLF-PFNL',
      },
      {
        path: 'producteurs',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE)],
        children: [
          {
            path: '',
            loadComponent: () =>
              import('./features/producteurs/producteurs-list/producteurs-list.component').then(
                (m) => m.ProducteursListComponent,
              ),
            title: 'Producteurs & collecteurs — PNLF-PFNL',
          },
          {
            path: 'nouveau',
            loadComponent: () =>
              import('./features/producteurs/producteur-form/producteur-form.component').then(
                (m) => m.ProducteurFormComponent,
              ),
            title: 'Nouvelle fiche producteur — PNLF-PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/producteurs/producteur-detail/producteur-detail.component').then(
                (m) => m.ProducteurDetailComponent,
              ),
            title: 'Fiche producteur — PNLF-PFNL',
          },
          {
            path: ':id/modifier',
            loadComponent: () =>
              import('./features/producteurs/producteur-form/producteur-form.component').then(
                (m) => m.ProducteurFormComponent,
              ),
            title: 'Modifier la fiche producteur — PNLF-PFNL',
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
            title: 'Lots de produits — PNLF-PFNL',
          },
          {
            path: 'nouveau',
            canActivate: [
              roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.PRODUCTEUR, R.COOPERATIVE),
            ],
            loadComponent: () => import('./features/lots/lot-form/lot-form.component').then((m) => m.LotFormComponent),
            title: 'Déclarer un lot — PNLF-PFNL',
          },
          {
            path: ':id',
            loadComponent: () =>
              import('./features/lots/lot-detail/lot-detail.component').then((m) => m.LotDetailComponent),
            title: 'Détail du lot — PNLF-PFNL',
          },
        ],
      },
      {
        path: 'zones-collecte',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER)],
        loadComponent: () =>
          import('./features/zones-collecte/zones-collecte-list.component').then(
            (m) => m.ZonesCollecteListComponent,
          ),
        title: 'Zones de collecte — PNLF-PFNL',
      },
      {
        path: 'certifications',
        loadComponent: () =>
          import('./features/certifications/certifications-list.component').then(
            (m) => m.CertificationsListComponent,
          ),
        title: 'Certifications — PNLF-PFNL',
      },
      {
        path: 'cooperatives',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE)],
        loadComponent: () =>
          import('./features/cooperatives/cooperatives-list.component').then((m) => m.CooperativesListComponent),
        title: 'Coopératives — PNLF-PFNL',
      },
      {
        path: 'marketplace/annuaire',
        loadComponent: () =>
          import('./features/marketplace/annuaire/annuaire.component').then((m) => m.AnnuaireComponent),
        title: 'Annuaire de la filière — PNLF-PFNL',
      },
      {
        path: 'marketplace/offres',
        canActivate: [roleGuard(R.PRODUCTEUR, R.COOPERATIVE, R.ACHETEUR, R.ADMINISTRATEUR, R.AGENT_MINISTERE)],
        loadComponent: () =>
          import('./features/marketplace/offres/offres-list.component').then((m) => m.OffresListComponent),
        title: 'Offres & demandes — PNLF-PFNL',
      },
      {
        path: 'utilisateurs',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE)],
        loadComponent: () =>
          import('./features/utilisateurs/utilisateurs-list.component').then((m) => m.UtilisateursListComponent),
        title: 'Comptes utilisateurs — PNLF-PFNL',
      },
      {
        path: 'rapports',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_MINISTERE)],
        loadComponent: () => import('./features/rapports/rapports.component').then((m) => m.RapportsComponent),
        title: 'Rapports & exports — PNLF-PFNL',
      },
      {
        path: 'synchronisation',
        canActivate: [roleGuard(R.ADMINISTRATEUR, R.AGENT_FORESTIER)],
        loadComponent: () =>
          import('./features/synchronisation/synchronisation.component').then((m) => m.SynchronisationComponent),
        title: 'Synchronisation terrain — PNLF-PFNL',
      },
      {
        path: 'notifications',
        loadComponent: () =>
          import('./features/notifications/notifications-page.component').then(
            (m) => m.NotificationsPageComponent,
          ),
        title: 'Notifications — PNLF-PFNL',
      },
      {
        path: 'parametres',
        loadComponent: () => import('./features/parametres/parametres.component').then((m) => m.ParametresComponent),
        title: 'Mon profil — PNLF-PFNL',
      },
      {
        path: 'acces-refuse',
        loadComponent: () =>
          import('./features/errors/access-denied/access-denied.component').then((m) => m.AccessDeniedComponent),
        title: 'Accès refusé — PNLF-PFNL',
      },
    ],
  },
  { path: '', pathMatch: 'full', redirectTo: 'connexion' },
  {
    path: '**',
    loadComponent: () => import('./features/errors/not-found/not-found.component').then((m) => m.NotFoundComponent),
    title: 'Page introuvable — PNLF-PFNL',
  },
];
