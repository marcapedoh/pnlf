import { HttpClient } from '@angular/common/http';
import { Injectable, computed, effect, inject, signal } from '@angular/core';
import { Observable, catchError, map, of, switchMap, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { LoginRequest, LoginResponse, RefreshResponse } from '../models/auth.model';
import { RoleUtilisateur, Utilisateur } from '../models/user.model';
import { displayInitials, displayName } from './display-name.util';
import { PresenceService } from './presence.service';
import { TokenStorageService } from './token-storage.service';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly _currentUser = signal<Utilisateur | null>(null);
  private readonly _bootstrapped = signal(false);

  readonly currentUser = this._currentUser.asReadonly();
  readonly bootstrapped = this._bootstrapped.asReadonly();
  readonly isAuthenticated = computed(() => !!this._currentUser());
  readonly mustChangePassword = computed(() => !!this._currentUser()?.doit_changer_mdp);
  readonly fullName = computed(() => displayName(this._currentUser()));
  readonly initials = computed(() => displayInitials(this._currentUser()));

  constructor(
    private readonly http: HttpClient,
    private readonly tokens: TokenStorageService,
  ) {
    const presence = inject(PresenceService);
    effect(() => (this.isAuthenticated() ? presence.demarrer() : presence.arreter()));
  }

  login(payload: LoginRequest): Observable<LoginResponse> {
    return this.http
      .post<LoginResponse>(`${environment.apiUrl}/auth/login/`, payload, { withCredentials: true })
      .pipe(
        tap((res) => {
          this.tokens.setTokens(res.access);
          this._currentUser.set(res.user);
        }),
      );
  }

  /** Enregistre une nouvelle session (ex. après changement de mot de passe). */
  applySession(access: string, user?: Utilisateur): void {
    this.tokens.setTokens(access);
    if (user) this._currentUser.set(user);
  }

  logout(): void {
    this.http.post(`${environment.apiUrl}/auth/logout/`, {}, { withCredentials: true }).subscribe({
      error: () => undefined,
    });
    this.tokens.clear();
    this._currentUser.set(null);
  }

  refresh(): Observable<string> {
    return this.http
      .post<RefreshResponse>(`${environment.apiUrl}/auth/refresh/`, {}, { withCredentials: true })
      .pipe(
        tap((res) => this.tokens.setTokens(res.access)),
        map((res) => res.access),
        catchError(() => {
          this.tokens.clear();
          this._currentUser.set(null);
          return of('');
        }),
      );
  }

  fetchMe(): Observable<Utilisateur | null> {
    return this.http.get<Utilisateur>(`${environment.apiUrl}/accounts/me/`).pipe(
      tap((user) => this._currentUser.set(user)),
      catchError(() => {
        this.tokens.clear();
        this._currentUser.set(null);
        return of(null);
      }),
    );
  }

  /** Réhydrate la session au démarrage (access en sessionStorage ou refresh cookie). */
  bootstrap(): Observable<boolean> {
    if (this.tokens.getAccessToken()) {
      return this.fetchMe().pipe(
        map((user) => {
          this._bootstrapped.set(true);
          return !!user;
        }),
      );
    }
    if (!this.tokens.hasSessionHint()) {
      this._bootstrapped.set(true);
      return of(false);
    }
    return this.refresh().pipe(
      switchMap((access) => {
        if (!access) {
          this._bootstrapped.set(true);
          return of(false);
        }
        return this.fetchMe().pipe(
          map((user) => {
            this._bootstrapped.set(true);
            return !!user;
          }),
        );
      }),
    );
  }

  hasRole(...roles: RoleUtilisateur[]): boolean {
    const role = this._currentUser()?.role;
    return !!role && roles.includes(role);
  }

  /** Mise à jour de son propre profil (nom, prénoms, téléphone). */
  updateMonProfil(payload: Pick<Utilisateur, 'nom' | 'prenoms' | 'telephone'>): Observable<Utilisateur> {
    return this.http
      .patch<Utilisateur>(`${environment.apiUrl}/accounts/me/`, payload)
      .pipe(tap((user) => this._currentUser.set(user)));
  }

  uploadMaPhoto(file: File): Observable<Utilisateur> {
    const form = new FormData();
    form.append('photo', file);
    return this.http
      .post<Utilisateur>(`${environment.apiUrl}/accounts/me/photo/`, form)
      .pipe(tap((user) => this._currentUser.set(user)));
  }

  updateCurrentUser(patch: Partial<Utilisateur>): void {
    const current = this._currentUser();
    if (current) {
      this._currentUser.set({ ...current, ...patch });
    }
  }
}
