import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Paginated } from '../models/common.model';
import { FiltreModerationImages, ModerationImage } from '../models/moderation-image.model';

@Injectable({ providedIn: 'root' })
export class ModerationImagesService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/moderation-images/`;

  lister(statut: FiltreModerationImages, page = 1, pageSize = 12): Observable<Paginated<ModerationImage>> {
    return this.http.get<Paginated<ModerationImage>>(this.base, {
      params: { statut, page: String(page), page_size: String(pageSize) },
    });
  }

  compteur(): Observable<{ en_attente: number }> {
    return this.http.get<{ en_attente: number }>(`${this.base}compteur/`);
  }

  approuver(id: string): Observable<ModerationImage> {
    return this.http.post<ModerationImage>(`${this.base}${id}/approuver/`, {});
  }

  rejeter(id: string, motif: string): Observable<ModerationImage> {
    return this.http.post<ModerationImage>(`${this.base}${id}/rejeter/`, { motif });
  }
}
