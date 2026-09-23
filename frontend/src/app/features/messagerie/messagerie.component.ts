import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, inject, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { AuthService } from '../../core/auth/auth.service';
import { toApiError } from '../../core/http/api-error.util';
import { unwrapList } from '../../core/models/common.model';
import {
  ChatContact,
  ChatMessage,
  Conversation,
  CoopGroupeOption,
  MessageStatut,
} from '../../core/models/chat.model';
import { ROLE_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { ChatService } from '../../core/services/chat.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-messagerie',
  imports: [
    DatePipe,
    FormsModule,
    CardComponent,
    ButtonComponent,
    ConfirmDialogComponent,
    EmptyStateComponent,
    IconComponent,
    SkeletonComponent,
  ],
  templateUrl: './messagerie.component.html',
  styleUrl: './messagerie.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MessagerieComponent implements OnDestroy {
  private readonly chat = inject(ChatService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  private readonly threadEl = viewChild<ElementRef<HTMLElement>>('thread');
  private readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');

  readonly conversations = signal<Conversation[]>([]);
  readonly loadingList = signal(true);
  readonly activeId = signal<string | null>(null);
  readonly messages = signal<ChatMessage[]>([]);
  readonly loadingThread = signal(false);
  readonly sending = signal(false);
  readonly draft = signal('');
  readonly recording = signal(false);
  readonly showNew = signal(false);
  readonly showGroupe = signal(false);
  readonly contacts = signal<ChatContact[]>([]);
  readonly contactQuery = signal('');
  readonly inboxQuery = signal('');
  readonly coops = signal<CoopGroupeOption[]>([]);
  readonly groupeCoopId = signal('');
  readonly groupeSujet = signal('');
  readonly groupeSelected = signal<Set<string>>(new Set());
  readonly creatingGroupe = signal(false);
  readonly loadingGroupe = signal(false);
  readonly confirmDeleteOpen = signal(false);
  readonly deleting = signal(false);

  /** Mode supervision admin : lecture seule hors inbox personnelle */
  readonly supervisionMode = signal(false);
  readonly supervisionQuery = signal('');
  readonly supervisionLoading = signal(false);
  readonly lectureSeule = signal(false);

  readonly currentUserId = this.auth.currentUser()?.id;
  readonly isAdmin = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR);
  readonly canStartAny = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.ACHETEUR,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canCreateGroupe = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private recorder: MediaRecorder | null = null;
  private chunks: Blob[] = [];
  private recStream: MediaStream | null = null;
  private opening = false;
  private readonly search$ = new Subject<void>();
  private readonly supervisionSearch$ = new Subject<void>();

  constructor() {
    this.search$.pipe(debounceTime(280), takeUntilDestroyed()).subscribe(() => this.refreshList(false));
    this.supervisionSearch$.pipe(debounceTime(320), takeUntilDestroyed()).subscribe(() => this.runSupervisionSearch());
    this.refreshList(true);
    this.pollTimer = setInterval(() => this.poll(), 4000);
    this.route.queryParamMap.subscribe((params) => {
      const conv = params.get('conversation');
      const producteur = params.get('producteur');
      const cooperative = params.get('cooperative');
      const destinataire = params.get('destinataire');
      if (conv) {
        this.exitSupervision();
        this.select(conv);
        return;
      }
      if (producteur) this.ouvrirFil({ producteur_id: producteur });
      else if (cooperative) this.ouvrirFil({ cooperative_id: cooperative });
      else if (destinataire) this.ouvrirFil({ destinataire_id: destinataire });
    });
  }

  ngOnDestroy(): void {
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.stopRecording(false);
  }

  filteredConversations(): Conversation[] {
    // Filtre local complémentaire (la recherche serveur est déjà appliquée)
    const q = this.inboxQuery().trim().toLowerCase();
    const list = this.conversations();
    if (!q || this.supervisionMode()) return list;
    return list.filter((c) => {
      const hay = `${c.interlocuteur_nom} ${c.sujet || ''} ${c.dernier_message || ''}`.toLowerCase();
      return hay.includes(q);
    });
  }

  filteredContacts(): ChatContact[] {
    const q = this.contactQuery().trim().toLowerCase();
    const list = this.contacts();
    if (!q) return list;
    return list.filter((c) => `${c.libelle} ${c.role}`.toLowerCase().includes(q));
  }

  roleLabel(role: string): string {
    return ROLE_LABELS[role as RoleUtilisateur] ?? role;
  }

  activeConversation(): Conversation | undefined {
    const id = this.activeId();
    return this.conversations().find((c) => c.id === id);
  }

  isMine(m: ChatMessage): boolean {
    return m.expediteur_id === this.currentUserId;
  }

  initials(name: string | null | undefined): string {
    const parts = (name || '?').trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return '?';
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }

  statutTitle(statut: MessageStatut | null | undefined): string {
    if (statut === 'LU') return 'Lu';
    if (statut === 'RECU') return 'Reçu';
    if (statut === 'ENVOYE') return 'Envoyé';
    return '';
  }

  onInboxSearch(value: string): void {
    this.inboxQuery.set(value);
    if (this.supervisionMode()) return;
    this.search$.next();
  }

  enterSupervision(): void {
    this.supervisionMode.set(true);
    this.lectureSeule.set(true);
    this.activeId.set(null);
    this.messages.set([]);
    this.conversations.set([]);
    this.supervisionQuery.set('');
    this.loadSupervisionList();
  }

  exitSupervision(): void {
    if (!this.supervisionMode()) return;
    this.supervisionMode.set(false);
    this.lectureSeule.set(false);
    this.supervisionQuery.set('');
    this.activeId.set(null);
    this.messages.set([]);
    this.refreshList(true);
  }

  onSupervisionSearch(value: string): void {
    this.supervisionQuery.set(value);
    this.supervisionSearch$.next();
  }

  runSupervisionSearch(): void {
    this.loadSupervisionList();
  }

  private loadSupervisionList(): void {
    const q = this.supervisionQuery().trim();
    this.supervisionLoading.set(true);
    this.chat.supervision(q).subscribe({
      next: (res) => {
        this.conversations.set(unwrapList(res).map((c) => ({ ...c, lecture_seule: true })));
        this.supervisionLoading.set(false);
      },
      error: (err) => {
        this.supervisionLoading.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  select(id: string): void {
    this.activeId.set(id);
    this.loadThread(id, true);
  }

  /** Sur mobile : quitter le fil et revenir à la liste des conversations. */
  clearSelection(): void {
    this.activeId.set(null);
    this.messages.set([]);
    this.router.navigate([], { relativeTo: this.route, queryParams: {}, replaceUrl: true });
  }

  askDelete(): void {
    if (!this.activeId() || this.lectureSeule()) return;
    this.confirmDeleteOpen.set(true);
  }

  confirmDelete(): void {
    const id = this.activeId();
    if (!id || this.lectureSeule()) return;
    this.deleting.set(true);
    this.chat.supprimer(id).subscribe({
      next: () => {
        this.deleting.set(false);
        this.confirmDeleteOpen.set(false);
        this.conversations.update((list) => list.filter((c) => c.id !== id));
        this.activeId.set(null);
        this.messages.set([]);
        this.toast.success('Conversation supprimée');
        this.router.navigate([], { relativeTo: this.route, queryParams: {}, replaceUrl: true });
      },
      error: (err) => {
        this.deleting.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  envoyer(): void {
    if (this.lectureSeule()) return;
    const contenu = this.draft().trim();
    const id = this.activeId();
    if (!contenu || !id || this.sending()) return;
    this.sending.set(true);
    this.chat.envoyer(id, { contenu }).subscribe({
      next: (msg) => {
        this.draft.set('');
        this.sending.set(false);
        this.append(msg);
        this.refreshList(false);
      },
      error: (err) => {
        this.sending.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  onEnter(event: Event): void {
    const e = event as KeyboardEvent;
    if (e.shiftKey) return;
    e.preventDefault();
    this.envoyer();
  }

  pickImage(): void {
    if (this.lectureSeule()) return;
    this.fileInput()?.nativeElement.click();
  }

  onFile(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file || this.lectureSeule()) return;
    this.sendPiece(file);
  }

  async toggleMic(): Promise<void> {
    if (this.lectureSeule()) return;
    if (this.recording()) {
      this.stopRecording(true);
      return;
    }
    try {
      this.recStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mime = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
        ? 'audio/webm;codecs=opus'
        : MediaRecorder.isTypeSupported('audio/webm')
          ? 'audio/webm'
          : '';
      this.chunks = [];
      this.recorder = mime ? new MediaRecorder(this.recStream, { mimeType: mime }) : new MediaRecorder(this.recStream);
      this.recorder.ondataavailable = (e) => {
        if (e.data.size) this.chunks.push(e.data);
      };
      this.recorder.onstop = () => {
        const type = this.recorder?.mimeType || 'audio/webm';
        const blob = new Blob(this.chunks, { type });
        this.recStream?.getTracks().forEach((t) => t.stop());
        this.recStream = null;
        this.recording.set(false);
        if (blob.size > 0) {
          const ext = type.includes('mp4') ? 'm4a' : 'webm';
          this.sendPiece(new File([blob], `vocal.${ext}`, { type }));
        }
      };
      this.recorder.start();
      this.recording.set(true);
    } catch {
      this.toast.error("Le microphone n'est pas accessible. Autorisez-le dans le navigateur.");
    }
  }

  openNew(): void {
    this.showNew.set(true);
    this.contactQuery.set('');
    this.chat.contacts().subscribe({
      next: (c) => this.contacts.set(c),
      error: (err) => this.toast.error(toApiError(err).message),
    });
  }

  openGroupe(): void {
    this.showGroupe.set(true);
    this.groupeSujet.set('');
    this.groupeSelected.set(new Set());
    this.groupeCoopId.set('');
    this.coops.set([]);
    this.loadingGroupe.set(true);
    this.chat.membresCoop().subscribe({
      next: (rows) => {
        this.loadingGroupe.set(false);
        this.coops.set(rows);
        if (rows.length === 1) {
          this.onCoopChange(rows[0].id);
        }
      },
      error: (err) => {
        this.loadingGroupe.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  selectedCoop(): CoopGroupeOption | undefined {
    return this.coops().find((c) => c.id === this.groupeCoopId());
  }

  onCoopChange(id: string): void {
    this.groupeCoopId.set(id);
    const coop = this.coops().find((c) => c.id === id);
    if (coop) {
      // Tous les membres cochés par défaut
      this.groupeSelected.set(new Set(coop.membres.map((m) => m.id)));
      if (!this.groupeSujet().trim()) {
        this.groupeSujet.set(`Groupe — ${coop.nom}`);
      }
    } else {
      this.groupeSelected.set(new Set());
    }
  }

  toggleMembre(id: string): void {
    const next = new Set(this.groupeSelected());
    if (next.has(id)) next.delete(id);
    else next.add(id);
    this.groupeSelected.set(next);
  }

  isMembreSelected(id: string): boolean {
    return this.groupeSelected().has(id);
  }

  selectAllMembres(): void {
    const coop = this.selectedCoop();
    if (coop) this.groupeSelected.set(new Set(coop.membres.map((m) => m.id)));
  }

  clearMembres(): void {
    this.groupeSelected.set(new Set());
  }

  creerGroupe(): void {
    const cooperative_id = this.groupeCoopId();
    const participants = [...this.groupeSelected()];
    if (!cooperative_id) {
      this.toast.error('Choisissez votre coopérative.');
      return;
    }
    if (!participants.length) {
      this.toast.error('Cochez au moins un autre membre.');
      return;
    }
    this.creatingGroupe.set(true);
    this.chat
      .ouvrir({
        est_groupe: true,
        cooperative_id,
        participants,
        sujet: this.groupeSujet().trim() || undefined,
      })
      .subscribe({
        next: (conv) => {
          this.creatingGroupe.set(false);
          this.showGroupe.set(false);
          this.exitSupervision();
          this.mergeConv(conv);
          this.select(conv.id);
          this.router.navigate([], {
            relativeTo: this.route,
            queryParams: { conversation: conv.id },
            replaceUrl: true,
          });
          this.toast.success('Groupe prêt');
        },
        error: (err) => {
          this.creatingGroupe.set(false);
          this.toast.error(toApiError(err).message);
        },
      });
  }

  startWith(contact: ChatContact): void {
    this.showNew.set(false);
    this.ouvrirFil({ destinataire_id: contact.id, sujet: `Discussion avec ${contact.libelle}` });
  }

  private loadThread(id: string, showLoading: boolean): void {
    if (showLoading) this.loadingThread.set(true);
    if (this.supervisionMode()) {
      this.lectureSeule.set(true);
      this.chat.supervisionLire(id).subscribe({
        next: (res) => {
          this.messages.set(res.results || []);
          this.loadingThread.set(false);
          this.scrollBottom();
        },
        error: (err) => {
          this.loadingThread.set(false);
          this.toast.error(toApiError(err).message);
        },
      });
      return;
    }
    this.lectureSeule.set(false);
    this.chat.messages(id).subscribe({
      next: (msgs) => {
        this.messages.set(msgs);
        this.loadingThread.set(false);
        this.scrollBottom();
        this.conversations.update((list) =>
          list.map((c) => (c.id === id ? { ...c, non_lus: 0 } : c)),
        );
      },
      error: (err) => {
        this.loadingThread.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  private ouvrirFil(payload: {
    producteur_id?: string;
    cooperative_id?: string;
    destinataire_id?: string;
    sujet?: string;
  }): void {
    if (this.opening) return;
    this.opening = true;
    this.exitSupervision();
    this.chat.ouvrir(payload).subscribe({
      next: (conv) => {
        this.opening = false;
        this.mergeConv(conv);
        this.select(conv.id);
        this.router.navigate([], {
          relativeTo: this.route,
          queryParams: { conversation: conv.id },
          replaceUrl: true,
        });
      },
      error: (err) => {
        this.opening = false;
        this.toast.error(toApiError(err).message);
      },
    });
  }

  private sendPiece(file: File): void {
    const id = this.activeId();
    if (!id || this.lectureSeule()) return;
    this.sending.set(true);
    this.chat.envoyer(id, { piece: file, contenu: this.draft().trim() || undefined }).subscribe({
      next: (msg) => {
        this.draft.set('');
        this.sending.set(false);
        this.append(msg);
        this.refreshList(false);
      },
      error: (err) => {
        this.sending.set(false);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  private append(msg: ChatMessage): void {
    if (this.messages().some((m) => m.id === msg.id)) return;
    this.messages.update((list) => [...list, msg]);
    this.scrollBottom();
  }

  private poll(): void {
    if (this.supervisionMode()) return;
    this.refreshList(false);
    const id = this.activeId();
    if (!id || this.lectureSeule()) return;
    this.chat.messages(id).subscribe({
      next: (msgs) => {
        const prevLen = this.messages().length;
        this.messages.set(msgs);
        this.conversations.update((list) =>
          list.map((c) => (c.id === id ? { ...c, non_lus: 0 } : c)),
        );
        if (msgs.length > prevLen) this.scrollBottom();
      },
    });
  }

  private refreshList(initial: boolean): void {
    if (this.supervisionMode()) return;
    if (initial) this.loadingList.set(true);
    const params: Record<string, string> = { page_size: '80' };
    const q = this.inboxQuery().trim();
    if (q) params['q'] = q;
    this.chat.list(params).subscribe({
      next: (res) => {
        this.conversations.set(unwrapList(res));
        this.loadingList.set(false);
        const id = this.activeId();
        // Auto-sélection desktop uniquement : sur mobile, la liste doit rester visible.
        const isDesktop = typeof window !== 'undefined' && window.matchMedia('(min-width: 721px)').matches;
        if (
          !id &&
          isDesktop &&
          this.conversations().length &&
          initial &&
          !this.route.snapshot.queryParamMap.keys.length
        ) {
          this.select(this.conversations()[0].id);
        }
      },
      error: () => this.loadingList.set(false),
    });
  }

  private mergeConv(conv: Conversation): void {
    const rest = this.conversations().filter((c) => c.id !== conv.id);
    this.conversations.set([conv, ...rest]);
  }

  private stopRecording(save: boolean): void {
    if (!this.recorder || this.recorder.state === 'inactive') {
      this.recording.set(false);
      return;
    }
    if (!save) {
      this.recorder.onstop = () => {
        this.recStream?.getTracks().forEach((t) => t.stop());
        this.recStream = null;
        this.recording.set(false);
      };
    }
    this.recorder.stop();
  }

  private scrollBottom(): void {
    setTimeout(() => {
      const el = this.threadEl()?.nativeElement;
      if (el) el.scrollTop = el.scrollHeight;
    }, 40);
  }
}
