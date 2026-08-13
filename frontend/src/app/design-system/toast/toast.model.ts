export type ToastVariant = 'success' | 'error' | 'info' | 'warning';

export interface ToastMessage {
  id: number;
  variant: ToastVariant;
  title: string;
  description?: string;
  duration: number;
}
