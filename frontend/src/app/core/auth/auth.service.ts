import { HttpClient } from '@angular/common/http';
import { Injectable, computed, signal } from '@angular/core';
import { Observable, catchError, map, of, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { LoginRequest, LoginResponse, RefreshResponse } from '../models/auth.model';
import { RoleUtilisateur, Utilisateur } from '../models/user.model';
import { TokenStorageService } from './token-storage.service';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly _currentUser = signal<Utilisateur | null>(null);
  private readonly _bootstrapped = signal(false);

  readonly currentUser = this._currentUser.asReadonly();
  readonly bootstrapped = this._bootstrapped.asReadonly();
  readonly isAuthenticated = computed(() => !!this._currentUser());
  readonly fullName = computed(() => {
    const u = this._currentUser();
    return u ? `${u.prenoms} ${u.nom}`.trim() : '';
  });
  readonly initials = computed(() => {
    const u = this._currentUser();
    if (!u) return '';
    return `${u.prenoms?.[0] ?? ''}${u.nom?.[0] ?? ''}`.toUpperCase();
  });

  constructor(
    private readonly http: HttpClient,
    private readonly tokens: TokenStorageService,
  ) {}

  login(payload: LoginRequest): Observable<LoginResponse> {
    return this.http
      .post<LoginResponse>(`${environment.apiUrl}/auth/login/`, payload)
      .pipe(
        tap((res) => {
          this.tokens.setTokens(res.access, res.refresh);
          this._currentUser.set(res.user);
        }),
      );
  }

  logout(): void {
    this.tokens.clear();
    this._currentUser.set(null);
  }

  refresh(): Observable<string> {
    const refreshToken = this.tokens.getRefreshToken();
    if (!refreshToken) {
      return of('');
    }
    return this.http
      .post<RefreshResponse>(`${environment.apiUrl}/auth/refresh/`, {
        refresh: refreshToken,
      })
      .pipe(
        tap((res) => this.tokens.setTokens(res.access)),
        map((res) => res.access),
        catchError(() => {
          this.logout();
          return of('');
        }),
      );
  }

  fetchMe(): Observable<Utilisateur | null> {
    return this.http.get<Utilisateur>(`${environment.apiUrl}/accounts/me/`).pipe(
      tap((user) => this._currentUser.set(user)),
      catchError(() => {
        this.logout();
        return of(null);
      }),
    );
  }

  /** Réhydrate la session au démarrage de l'application (rechargement de page). */
  bootstrap(): Observable<boolean> {
    if (!this.tokens.getAccessToken()) {
      this._bootstrapped.set(true);
      return of(false);
    }
    return this.fetchMe().pipe(
      map((user) => {
        this._bootstrapped.set(true);
        return !!user;
      }),
    );
  }

  hasRole(...roles: RoleUtilisateur[]): boolean {
    const role = this._currentUser()?.role;
    return !!role && roles.includes(role);
  }

  updateCurrentUser(patch: Partial<Utilisateur>): void {
    const current = this._currentUser();
    if (current) {
      this._currentUser.set({ ...current, ...patch });
    }
  }
}
