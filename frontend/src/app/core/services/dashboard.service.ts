import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { DashboardStats } from '../models/dashboard.model';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  constructor(private readonly http: HttpClient) {}

  stats(params: Record<string, string> = {}): Observable<DashboardStats> {
    return this.http.get<DashboardStats>(`${environment.apiUrl}/dashboard/stats/`, { params });
  }

  exportUrl(format: 'csv' | 'xlsx' | 'pdf'): string {
    return `${environment.apiUrl}/exports/lots/?export_format=${format}`;
  }
}
