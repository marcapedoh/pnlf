import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, computed, inject, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { AuthService } from '../../core/auth/auth.service';
import { toApiError } from '../../core/http/api-error.util';
import { unwrapList } from '../../core/models/common.model';
import {
  CONTACT_FILTRES,
  ChatContact,
  ChatMessage,
  ContactFiltreRole,
  Conversation,
  CoopGroupeOption,
  MessageStatut,
} from '../../core/models/chat.model';
import { ROLE_LABELS, RoleUtilisateur } from '../../core/models/user.model';
import { ChatService } from '../../core/services/chat.service';
import { PdfPreviewService } from '../../core/services/pdf-preview.service';
import {
  EnregistreurVocal,
  ErreurMicro,
  etatAutorisationMicro,
  incompatibiliteMicro,
  messageErreurMicro,
} from './voice-recorder';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { ModalA11yDirective } from '../../design-system/modal/modal-a11y.directive';

const MAX_VOCAL_SECONDES = 300;
/** Les liens signés des pièces expirent au bout d'une heure : on les renouvelle avant. */
const RENOUVELLEMENT_URLS_MS = 45 * 60 * 1000;
const COULEURS_AVATAR = 8;

export interface GroupeContacts {
  lettre: string;
  contacts: ChatContact[];
}

function lettreDe(libelle: string): string {
  const c = (libelle || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim().charAt(0).toUpperCase();
  return /[A-Z]/.test(c) ? c : '#';
}

function grouperParLettre(contacts: ChatContact[]): GroupeContacts[] {
  const groupes: GroupeContacts[] = [];
  for (const contact of contacts) {
    const lettre = lettreDe(contact.libelle);
    const dernier = groupes[groupes.length - 1];
    if (dernier?.lettre === lettre) dernier.contacts.push(contact);
    else groupes.push({ lettre, contacts: [contact] });
  }
  return groupes;
}

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
    ModalA11yDirective,
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
  private readonly pdfPreview = inject(PdfPreviewService);

  private readonly threadEl = viewChild<ElementRef<HTMLElement>>('thread');
  private readonly fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');
  private readonly contactSearchEl = viewChild<ElementRef<HTMLInputElement>>('contactSearch');

  readonly conversations = signal<Conversation[]>([]);
  readonly loadingList = signal(true);
  readonly activeId = signal<string | null>(null);
  readonly messages = signal<ChatMessage[]>([]);
  readonly loadingThread = signal(false);
  readonly sending = signal(false);
  readonly draft = signal('');
  readonly micState = signal<'idle' | 'explain' | 'requesting' | 'recording'>('idle');
  readonly micError = signal('');
  readonly recSeconds = signal(0);
  readonly maxVocalSecondes = MAX_VOCAL_SECONDES;
  readonly showNew = signal(false);
  readonly showGroupe = signal(false);
  readonly contacts = signal<ChatContact[]>([]);
  readonly contactsTotal = signal(0);
  readonly contactsLoading = signal(false);
  readonly contactsError = signal('');
  readonly contactQuery = signal('');
  readonly contactRole = signal<ContactFiltreRole>('');
  readonly contactFiltres = CONTACT_FILTRES;
  readonly contactGroups = computed(() => grouperParLettre(this.contacts()));
  readonly audioIllisibles = signal<ReadonlySet<string>>(new Set());
  readonly avatarsCasses = signal<ReadonlySet<string>>(new Set());
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
  private recTimer: ReturnType<typeof setInterval> | null = null;
  private readonly enregistreur = new EnregistreurVocal();
  private opening = false;
  private contactsPage = 1;
  private contactsReq = 0;
  private urlsMessagesA = 0;
  private urlsConversationsA = 0;
  private readonly lecturesAudio = new Map<string, boolean>();
  private readonly search$ = new Subject<void>();
  private readonly supervisionSearch$ = new Subject<void>();
  private readonly contactSearch$ = new Subject<void>();

  constructor() {
    this.search$.pipe(debounceTime(280), takeUntilDestroyed()).subscribe(() => this.refreshList(false));
    this.supervisionSearch$.pipe(debounceTime(320), takeUntilDestroyed()).subscribe(() => this.runSupervisionSearch());
    this.contactSearch$.pipe(debounceTime(250), takeUntilDestroyed()).subscribe(() => this.chargerContacts(true));
    this.enregistreur.onInterruption = () => {
      this.toast.warning('Enregistrement interrompu', 'Le micro a été coupé : le message vocal enregistré jusque-là va être envoyé.');
      void this.envoyerVocal();
    };
    this.refreshList(true);
    this.pollTimer = setInterval(() => this.poll(), 4000);
    this.route.queryParamMap.pipe(takeUntilDestroyed()).subscribe((params) => {
      const conv = params.get('conversation');
      const producteur = params.get('producteur');
      const cooperative = params.get('cooperative');
      const destinataire = params.get('avec') || params.get('destinataire');
      const offre = params.get('offre');
      if (conv) {
        this.exitSupervision();
        if (conv !== this.activeId()) this.select(conv);
        return;
      }
      if (producteur) this.ouvrirFil({ producteur_id: producteur });
      else if (cooperative) this.ouvrirFil({ cooperative_id: cooperative });
      else if (destinataire) this.ouvrirFil({ destinataire_id: destinataire });
      else if (offre) this.ouvrirDepuisAnnonce(offre);
    });
  }

  ngOnDestroy(): void {
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.arreterChrono();
    this.enregistreur.annuler();
  }

  /** Sur mobile, la liste reste visible tant que le panneau « Nouvelle discussion » est ouvert. */
  threadOpen(): boolean {
    return !!this.activeId() && !this.showNew();
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

  roleLabel(role: string): string {
    return ROLE_LABELS[role as RoleUtilisateur] ?? role;
  }

  couleurAvatar(id: string): string {
    let somme = 0;
    for (const c of id || '') somme = (somme + c.charCodeAt(0)) % 997;
    return `chat-avatar__fallback--c${somme % COULEURS_AVATAR}`;
  }

  photoVisible(cle: string, url: string | null | undefined): boolean {
    return !!url && !this.avatarsCasses().has(cle);
  }

  onAvatarError(cle: string): void {
    this.avatarsCasses.update((s) => new Set(s).add(cle));
  }

  /** Rôle et organisation de l'interlocuteur (ou nombre de participants d'un groupe). */
  interlocuteurInfo(conv: Conversation | undefined): string {
    if (!conv) return '';
    if (conv.est_groupe) return `${conv.participants.length} participants`;
    const autre = conv.participants.find((p) => p.id !== this.currentUserId);
    if (!autre) return '';
    return [autre.role_libelle || this.roleLabel(autre.role), autre.organisation].filter(Boolean).join(' · ');
  }

  participantsSupervision(conv: Conversation | undefined): string {
    return (conv?.participants ?? [])
      .map((p) => `${p.nom} (${p.role_libelle || this.roleLabel(p.role)})`)
      .join(', ');
  }

  audioLisible(m: ChatMessage): boolean {
    if (this.audioIllisibles().has(m.id)) return false;
    const mime = m.piece_mime;
    if (!mime || typeof document === 'undefined') return true;
    let ok = this.lecturesAudio.get(mime);
    if (ok === undefined) {
      ok = document.createElement('audio').canPlayType(mime) !== '';
      this.lecturesAudio.set(mime, ok);
    }
    return ok;
  }

  onAudioError(id: string): void {
    this.audioIllisibles.update((s) => new Set(s).add(id));
  }

  formatAudio(m: ChatMessage): string {
    const mime = (m.piece_mime || '').toLowerCase();
    if (mime.includes('webm')) return 'WebM';
    if (mime.includes('ogg')) return 'Ogg';
    if (mime.includes('mp4')) return 'M4A';
    if (mime.includes('aac')) return 'AAC';
    if (mime.includes('mpeg')) return 'MP3';
    return 'audio';
  }

  dureeVocal(): string {
    const s = this.recSeconds();
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
  }

  /** La recherche remplace la liste : la conversation ouverte peut ne plus y figurer. */
  private derniereActive?: Conversation;

  activeConversation(): Conversation | undefined {
    const id = this.activeId();
    const conv = this.conversations().find((c) => c.id === id);
    if (conv) {
      this.derniereActive = conv;
      return conv;
    }
    return id && this.derniereActive?.id === id ? this.derniereActive : undefined;
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
    this.showNew.set(false);
    this.annulerVocal();
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
    if (this.activeId() !== id) this.annulerVocal();
    this.showNew.set(false);
    this.activeId.set(id);
    this.loadThread(id, true);
  }

  imprimerConversation(): void {
    const conv = this.activeConversation();
    const id = this.activeId();
    if (!id || !this.isAdmin || !this.supervisionMode()) return;
    const titre = conv?.sujet ? `Conversation : ${conv.sujet}` : 'Conversation (PDF)';
    this.pdfPreview.open(titre, `PFNL-conversation-${id.slice(0, 8)}.pdf`, () => this.chat.supervisionPdfBlob(id));
  }

  /** Sur mobile : quitter le fil et revenir à la liste des conversations. */
  clearSelection(): void {
    this.annulerVocal();
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

  /** Micro : explication puis autorisation au premier usage, ou arrêt et envoi pendant l'enregistrement. */
  async onMicClick(): Promise<void> {
    if (this.lectureSeule() || this.sending()) return;
    if (this.micState() === 'recording') {
      await this.envoyerVocal();
      return;
    }
    if (this.micState() === 'requesting') return;
    this.micError.set('');
    const incompatible = incompatibiliteMicro();
    if (incompatible) {
      this.micError.set(incompatible);
      this.micState.set('explain');
      return;
    }
    const etat = await etatAutorisationMicro();
    if (etat === 'granted') {
      await this.demarrerVocal();
      return;
    }
    if (etat === 'denied') this.micError.set(messageErreurMicro({ name: 'NotAllowedError' }));
    this.micState.set('explain');
  }

  async demarrerVocal(): Promise<void> {
    if (!this.activeId() || this.lectureSeule()) return;
    this.micState.set('requesting');
    this.micError.set('');
    try {
      await this.enregistreur.demarrer();
    } catch (err) {
      this.micError.set(err instanceof ErreurMicro ? err.message : messageErreurMicro(err));
      this.micState.set('explain');
      return;
    }
    this.micState.set('recording');
    this.recSeconds.set(0);
    this.recTimer = setInterval(() => {
      const secondes = Math.floor(this.enregistreur.dureeMs() / 1000);
      this.recSeconds.set(secondes);
      if (secondes >= MAX_VOCAL_SECONDES) {
        this.toast.info('Durée maximale atteinte', 'Un message vocal dure au plus 5 minutes : il a été envoyé automatiquement.');
        void this.envoyerVocal();
      }
    }, 250);
  }

  async envoyerVocal(): Promise<void> {
    if (this.micState() !== 'recording') return;
    this.arreterChrono();
    this.micState.set('idle');
    const fichier = await this.enregistreur.arreter();
    if (!fichier) {
      this.toast.warning('Message vocal trop court', 'Parlez au moins une seconde avant d’envoyer.');
      return;
    }
    this.sendPiece(fichier);
  }

  annulerVocal(): void {
    this.arreterChrono();
    this.enregistreur.annuler();
    this.micState.set('idle');
    this.micError.set('');
  }

  openNew(): void {
    if (this.supervisionMode()) return;
    this.showNew.set(true);
    this.contactQuery.set('');
    this.contactRole.set('');
    this.chargerContacts(true);
    setTimeout(() => this.contactSearchEl()?.nativeElement.focus(), 120);
  }

  closeNew(): void {
    this.showNew.set(false);
  }

  onContactSearch(value: string): void {
    this.contactQuery.set(value);
    this.contactSearch$.next();
  }

  setContactRole(role: ContactFiltreRole): void {
    if (this.contactRole() === role) return;
    this.contactRole.set(role);
    this.chargerContacts(true);
  }

  contactsHasMore(): boolean {
    return this.contacts().length < this.contactsTotal();
  }

  onContactsScroll(event: Event): void {
    const el = event.target as HTMLElement;
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 160) this.chargerContacts(false);
  }

  chargerContacts(reset: boolean): void {
    if (!reset && (this.contactsLoading() || !this.contactsHasMore())) return;
    const page = reset ? 1 : this.contactsPage + 1;
    const req = ++this.contactsReq;
    this.contactsLoading.set(true);
    this.contactsError.set('');
    if (reset) {
      this.contacts.set([]);
      this.contactsTotal.set(0);
    }
    this.chat.contacts({ q: this.contactQuery(), role: this.contactRole(), page }).subscribe({
      next: (res) => {
        if (req !== this.contactsReq) return;
        this.contactsPage = page;
        this.contacts.update((list) => (reset ? res.results : [...list, ...res.results]));
        this.contactsTotal.set(res.count);
        this.contactsLoading.set(false);
      },
      error: (err) => {
        if (req !== this.contactsReq) return;
        this.contactsLoading.set(false);
        this.contactsError.set(toApiError(err).message);
      },
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
        this.groupeSujet.set(`Groupe : ${coop.nom}`);
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

  /** Ouvre le fil lié à une annonce : fil existant s'il y en a un, sinon création (hors auteur). */
  private ouvrirDepuisAnnonce(offreId: string): void {
    this.chat.list({ offre_id: offreId, page_size: '20' }).subscribe({
      next: (res) => {
        const convs = unwrapList(res);
        if (!convs.length) {
          this.ouvrirFil({ offre_id: offreId });
          return;
        }
        this.exitSupervision();
        [...convs].reverse().forEach((c) => this.mergeConv(c));
        this.router.navigate([], {
          relativeTo: this.route,
          queryParams: { conversation: convs[0].id },
          replaceUrl: true,
        });
      },
      error: () => this.ouvrirFil({ offre_id: offreId }),
    });
  }

  private loadThread(id: string, showLoading: boolean): void {
    if (showLoading) this.loadingThread.set(true);
    if (this.supervisionMode()) {
      this.lectureSeule.set(true);
      this.chat.supervisionLire(id).subscribe({
        next: (res) => {
          this.messages.set(res.results || []);
          this.urlsMessagesA = Date.now();
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
        this.urlsMessagesA = Date.now();
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
    offre_id?: string;
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
        if (id !== this.activeId()) return;
        const prevLen = this.messages().length;
        this.messages.set(this.conserverUrlsMessages(this.messages(), msgs));
        this.conversations.update((list) =>
          list.map((c) => (c.id === id ? { ...c, non_lus: 0 } : c)),
        );
        if (msgs.length > prevLen) this.scrollBottom();
      },
    });
  }

  /**
   * Chaque réponse contient de nouveaux liens signés : les réutiliser tels quels relancerait
   * le chargement des images et couperait la lecture d'un vocal toutes les 4 secondes.
   */
  private conserverUrlsMessages(prev: ChatMessage[], next: ChatMessage[]): ChatMessage[] {
    if (Date.now() - this.urlsMessagesA > RENOUVELLEMENT_URLS_MS) {
      this.urlsMessagesA = Date.now();
      return next;
    }
    const anciens = new Map(prev.map((m) => [m.id, m]));
    return next.map((m) => {
      const ancien = anciens.get(m.id);
      if (!ancien) return m;
      return {
        ...m,
        piece_url: ancien.piece_url ?? m.piece_url,
        expediteur_photo_url: ancien.expediteur_photo_url ?? m.expediteur_photo_url,
      };
    });
  }

  private conserverUrlsConversations(prev: Conversation[], next: Conversation[]): Conversation[] {
    if (Date.now() - this.urlsConversationsA > RENOUVELLEMENT_URLS_MS) {
      this.urlsConversationsA = Date.now();
      return next;
    }
    const anciennes = new Map(prev.map((c) => [c.id, c]));
    return next.map((c) => {
      const ancienne = anciennes.get(c.id);
      return ancienne?.interlocuteur_photo_url && c.interlocuteur_photo_url
        ? { ...c, interlocuteur_photo_url: ancienne.interlocuteur_photo_url }
        : c;
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
        if (this.supervisionMode()) return;
        this.conversations.set(this.conserverUrlsConversations(this.conversations(), unwrapList(res)));
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

  private arreterChrono(): void {
    if (this.recTimer) clearInterval(this.recTimer);
    this.recTimer = null;
  }

  private scrollBottom(): void {
    setTimeout(() => {
      const el = this.threadEl()?.nativeElement;
      if (el) el.scrollTop = el.scrollHeight;
    }, 40);
  }
}
