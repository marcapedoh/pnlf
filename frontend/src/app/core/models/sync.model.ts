export interface AppareilSync {
  id: string;
  device_id: string;
  libelle: string | null;
  dernier_sync_at: string | null;
  actif: boolean;
  created_at: string;
}

export interface SyncConflict {
  id: string;
  appareil_id: string | null;
  entite: string;
  client_uuid: string;
  payload_client: Record<string, unknown>;
  payload_serveur: Record<string, unknown> | null;
  resolu: boolean;
  resolution: string | null;
  created_at: string;
  resolved_at: string | null;
}
