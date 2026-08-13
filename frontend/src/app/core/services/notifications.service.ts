import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, signal } from '@angular/core';
import { catchError, of, tap } from 'rxjs';

import { environment } from '../../../environments/environment';
import { unwrapList } from '../models/common.model';
import { PnlfNotification } from '../models/notification.model';
import { SKIP_LOADING_BAR } from '../http/http-context-tokens';

@Injectable({ providedIn: 'root' })
export class NotificationsService {
  private readonly _items = signal<PnlfNotification[]>([]);
  readonly items = this._items.asReadonly();

  constructor(private readonly http: HttpClient) {}

  get unreadCount(): number {
    return this._items().filter((n) => !n.lue).length;
  }

  refresh() {
    return this.http
      .get<PnlfNotification[] | { results: PnlfNotification[] }>(
        `${environment.apiUrl}/notifications/`,
        { params: { page_size: '20' }, context: new HttpContext().set(SKIP_LOADING_BAR, true) },
      )
      .pipe(
        tap((res) => this._items.set(unwrapList(res as any))),
        catchError(() => of(null)),
      );
  }

  markAsRead(id: string) {
    return this.http
      .patch(`${environment.apiUrl}/notifications/${id}/`, { lue: true })
      .pipe(
        tap(() =>
          this._items.update((list) =>
            list.map((n) => (n.id === id ? { ...n, lue: true } : n)),
          ),
        ),
        catchError(() => of(null)),
      );
  }
}
