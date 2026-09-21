import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { AppareilSync, SyncConflict } from '../models/sync.model';

@Injectable({ providedIn: 'root' })
export class SyncService {
  constructor(private readonly http: HttpClient) {}

  enregistrerAppareil(payload: { device_id: string; libelle?: string }): Observable<AppareilSync> {
    return this.http.post<AppareilSync>(`${environment.apiUrl}/appareils-sync/`, payload);
  }

  appareils(): Observable<ApiListResponse<AppareilSync>> {
    return this.http.get<ApiListResponse<AppareilSync>>(`${environment.apiUrl}/appareils-sync/`);
  }

  conflits(): Observable<ApiListResponse<SyncConflict>> {
    return this.http.get<ApiListResponse<SyncConflict>>(`${environment.apiUrl}/sync-conflicts/`);
  }

  resoudre(id: string, resolution: string): Observable<SyncConflict> {
    return this.http.post<SyncConflict>(`${environment.apiUrl}/sync-conflicts/${id}/resoudre/`, { resolution });
  }
}
