import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, signal } from '@angular/core';
import { catchError, of, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { unwrapCount, unwrapList } from '../models/common.model';
import { PnlfNotification } from '../models/notification.model';
import { SKIP_LOADING_BAR, SKIP_GLOBAL_ERROR_TOAST } from '../http/http-context-tokens';

@Injectable({ providedIn: 'root' })
export class NotificationsService {
  private readonly _items = signal<PnlfNotification[]>([]);
  private readonly _total = signal(0);
  private readonly _unreadCount = signal(0);
  private readonly _pendingRegistrations = signal(0);
  readonly items = this._items.asReadonly();
  readonly total = this._total.asReadonly();
  readonly unreadCount = this._unreadCount.asReadonly();
  /** Nombre de demandes d'inscription (producteurs/collecteurs + coopératives) non encore validées ou rejetées. */
  readonly pendingRegistrations = this._pendingRegistrations.asReadonly();

  constructor(private readonly http: HttpClient) {}

  refresh(page = 1, pageSize = 20) {
    return this.http
      .get<PnlfNotification[] | { count: number; results: PnlfNotification[] }>(
        `${environment.apiUrl}/notifications/`,
        {
          params: { page: String(page), page_size: String(pageSize) },
          context: new HttpContext()
            .set(SKIP_LOADING_BAR, true)
            .set(SKIP_GLOBAL_ERROR_TOAST, true),
        },
      )
      .pipe(
        tap((res) => {
          this._items.set(unwrapList(res as any));
          this._total.set(unwrapCount(res as any));
        }),
        catchError(() => of(null)),
      );
  }

  refreshUnreadCount() {
    return this.http
      .get<{ count: number }>(`${environment.apiUrl}/notifications/non-lues/`, {
        context: new HttpContext()
          .set(SKIP_LOADING_BAR, true)
          .set(SKIP_GLOBAL_ERROR_TOAST, true),
      })
      .pipe(
        tap((res) => this._unreadCount.set(res.count)),
        catchError(() => of(null)),
      );
  }

  refreshPendingRegistrations() {
    return this.http
      .get<{ total: number }>(`${environment.apiUrl}/producteurs/en-attente/compte/`, {
        context: new HttpContext()
          .set(SKIP_LOADING_BAR, true)
          .set(SKIP_GLOBAL_ERROR_TOAST, true),
      })
      .pipe(
        tap((res) => this._pendingRegistrations.set(res.total)),
        catchError(() => of(null)),
      );
  }

  markAsRead(id: string) {
    return this.http
      .post(`${environment.apiUrl}/notifications/${id}/lire/`, {})
      .pipe(
        tap(() => {
          this._items.update((list) => list.map((n) => (n.id === id ? { ...n, lue: true } : n)));
          this._unreadCount.update((n) => Math.max(0, n - 1));
        }),
        catchError(() => of(null)),
      );
  }

  markAllAsRead() {
    return this.http
      .post(`${environment.apiUrl}/notifications/lire-tout/`, {})
      .pipe(
        tap(() => {
          this._items.update((list) => list.map((n) => ({ ...n, lue: true })));
          this._unreadCount.set(0);
        }),
        catchError(() => of(null)),
      );
  }
}
