import { Utilisateur } from './user.model';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access: string;
  refresh: string;
  user: Utilisateur;
}

export interface RefreshResponse {
  access: string;
}
