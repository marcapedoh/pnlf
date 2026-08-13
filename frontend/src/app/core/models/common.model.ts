export interface Paginated<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

export type ApiListResponse<T> = Paginated<T> | T[];

export function unwrapList<T>(response: ApiListResponse<T>): T[] {
  if (Array.isArray(response)) {
    return response;
  }
  return response?.results ?? [];
}

export function unwrapCount<T>(response: ApiListResponse<T>): number {
  if (Array.isArray(response)) {
    return response.length;
  }
  return response?.count ?? 0;
}

export interface ApiError {
  status: number;
  message: string;
  fieldErrors?: Record<string, string[]>;
  raw?: unknown;
}
