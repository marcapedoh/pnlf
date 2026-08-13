import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { ApiListResponse } from '../models/common.model';
import { Certification, TypeCertification } from '../models/certification.model';

@Injectable({ providedIn: 'root' })
export class CertificationsService {
  private readonly base = `${environment.apiUrl}/certifications/`;

  constructor(private readonly http: HttpClient) {}

  list(params: Record<string, string> = {}): Observable<ApiListResponse<Certification>> {
    return this.http.get<ApiListResponse<Certification>>(this.base, {
      params: { page_size: '50', ...params },
    });
  }

  types(): Observable<ApiListResponse<TypeCertification>> {
    return this.http.get<ApiListResponse<TypeCertification>>(
      `${environment.apiUrl}/types-certification/`,
      { params: { page_size: '50' } },
    );
  }

  create(payload: Partial<Certification>): Observable<Certification> {
    return this.http.post<Certification>(this.base, payload);
  }

  update(id: string, payload: Partial<Certification>): Observable<Certification> {
    return this.http.patch<Certification>(`${this.base}${id}/`, payload);
  }
}
