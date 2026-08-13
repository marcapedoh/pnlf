import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Cooperative } from '../models/producteur.model';

@Injectable({ providedIn: 'root' })
export class CooperativesService {
  private readonly base = `${environment.apiUrl}/cooperatives/`;

  constructor(private readonly http: HttpClient) {}

  list(params: Record<string, string> = {}): Observable<ApiListResponse<Cooperative>> {
    return this.http.get<ApiListResponse<Cooperative>>(this.base, {
      params: { page_size: '50', ...params },
    });
  }

  get(id: string): Observable<Cooperative> {
    return this.http.get<Cooperative>(`${this.base}${id}/`);
  }

  create(payload: Partial<Cooperative>): Observable<Cooperative> {
    return this.http.post<Cooperative>(this.base, payload);
  }

  update(id: string, payload: Partial<Cooperative>): Observable<Cooperative> {
    return this.http.patch<Cooperative>(`${this.base}${id}/`, payload);
  }
}
