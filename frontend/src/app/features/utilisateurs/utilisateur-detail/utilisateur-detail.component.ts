import { PnlfDatePipe, PnlfTelephonePipe } from '../../../shared/pipes/format.pipes';
import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Observable, of, switchMap } from 'rxjs';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { displayInitials, displayName } from '../../../core/auth/display-name.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import {
  PREFERENCE_NOTIF_LABELS,
  ROLE_LABELS,
  RoleUtilisateur,
  STATUT_COMPTE_LABELS,
  StatutCompte,
  Utilisateur,
  rolesAttribuables,
} from '../../../core/models/user.model';
import { UsersAdminService } from '../../../core/services/users-admin.service';
import { normaliserTelephone, telephoneValidator } from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

type ActionCompte = 'suspendre' | 'activer' | 'reset' | 'desactiver' | 'rejeter';

const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const PHOTO_MAX = 5 * 1024 * 1024;

@Component({
  selector: 'app-utilisateur-detail',
  imports: [
    RouterLink,
    PnlfDatePipe,
    PnlfTelephonePipe,
    ReactiveFormsModule,
    CardComponent,
    ButtonComponent,
    ConfirmDialogComponent,
    SkeletonComponent,
    EmptyStateComponent,
    StatusBadgeComponent,
    TextFieldComponent,
    SelectFieldComponent,
    IconComponent,
    AlertBannerComponent,
  ],
  templateUrl: './utilisateur-detail.component.html',
  styleUrl: './utilisateur-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UtilisateurDetailComponent {
  private readonly service = inject(UsersAdminService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);
  private readonly host = inject(ElementRef<HTMLElement>);
  private readonly fb = inject(FormBuilder);

  @ViewChild('photoInput') photoInputRef?: ElementRef<HTMLInputElement>;

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly user = signal<Utilisateur | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly roleLabels = ROLE_LABELS;
  readonly statutLabels = STATUT_COMPTE_LABELS;
  readonly StatutCompte = StatutCompte;
  readonly displayName = displayName;

  readonly action = signal<ActionCompte | null>(null);
  readonly actionLoading = signal(false);

  readonly editMode = signal(false);
  readonly saving = signal(false);
  readonly formError = signal('');
  readonly uploadingPhoto = signal(false);

  private readonly currentUser = this.auth.currentUser;
  readonly roleOptions = computed<SelectOption[]>(() => rolesAttribuables(this.currentUser()?.role));

  /** Ni action sur son propre compte, ni sur un administrateur sans être administrateur. */
  readonly peutAgir = computed(() => {
    const u = this.user();
    const moi = this.currentUser();
    if (!u || !moi || u.id === moi.id) return false;
    return u.role !== RoleUtilisateur.ADMINISTRATEUR || moi.role === RoleUtilisateur.ADMINISTRATEUR;
  });
  readonly estMoi = computed(() => this.user()?.id === this.currentUser()?.id);

  /** Seules les inscriptions acheteur en attente se rejettent ici ; producteurs et coopératives passent par « À traiter ». */
  readonly peutRejeter = computed(() => {
    const u = this.user();
    return !!u && u.statut === StatutCompte.EN_ATTENTE && u.role === RoleUtilisateur.ACHETEUR;
  });

  readonly actionDialog = computed(() => {
    const a = this.action();
    const u = this.user();
    if (!a || !u) return null;
    const nom = displayName(u);
    switch (a) {
      case 'suspendre':
        return {
          title: `Suspendre le compte de ${nom} ?`,
          message: 'La personne ne pourra plus se connecter tant que le compte n’aura pas été réactivé.',
          confirm: 'Suspendre le compte',
          danger: true,
        };
      case 'activer':
        return {
          title: `Activer le compte de ${nom} ?`,
          message:
            u.statut === StatutCompte.EN_ATTENTE
              ? u.role === RoleUtilisateur.ACHETEUR
                ? 'Cette inscription acheteur est en attente : l’activer valide aussi la fiche acheteur. Vérifiez les informations avant de confirmer.'
                : 'Ce compte est en attente : il ne peut être activé qu’une fois sa fiche (producteur ou coopérative) validée depuis « À traiter ».'
              : 'La personne pourra de nouveau se connecter à la plateforme.',
          confirm: 'Activer le compte',
          danger: false,
        };
      case 'rejeter':
        return {
          title: `Rejeter l’inscription de ${nom} ?`,
          message: 'Le compte en attente sera supprimé et le demandeur informé par e-mail. Cette action est définitive.',
          confirm: 'Rejeter l’inscription',
          danger: true,
        };
      case 'reset':
        return {
          title: `Réinitialiser le mot de passe de ${nom} ?`,
          message: `Un lien de réinitialisation sera envoyé à ${u.email}.`,
          confirm: 'Envoyer le lien',
          danger: false,
        };
      default:
        return {
          title: `Désactiver le compte de ${nom} ?`,
          message: 'Le compte sera désactivé définitivement et retiré de la liste. La personne ne pourra plus se connecter.',
          confirm: 'Désactiver le compte',
          danger: true,
        };
    }
  });

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    prenoms: [''],
    email: ['', [Validators.required, Validators.email]],
    telephone: ['', [telephoneValidator]],
    role: this.fb.nonNullable.control<RoleUtilisateur>(RoleUtilisateur.ACHETEUR),
  });

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id).subscribe({
      next: (u) => {
        this.user.set(u);
        this.title.setTitle(`${displayName(u)} | Comptes utilisateurs | PFNL`);
        this.resetForm(u);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.user.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  private resetForm(u: Utilisateur): void {
    this.form.reset({
      nom: u.nom,
      prenoms: u.prenoms,
      email: u.email,
      telephone: u.telephone || '',
      role: u.role,
    });
  }

  initiales(u: Utilisateur): string {
    return displayInitials(u) || '?';
  }

  preferenceNotif(valeur: string | null | undefined): string {
    if (!valeur) return 'Non renseignée';
    return PREFERENCE_NOTIF_LABELS[valeur.toUpperCase()] ?? valeur;
  }

  err(champ: 'nom' | 'email' | 'telephone'): string {
    const requis: Record<string, string> = { nom: 'Le nom est requis.', email: 'L’adresse e-mail est requise.' };
    return controlError(this.form.get(champ), requis[champ]);
  }

  startEdit(): void {
    this.formError.set('');
    this.editMode.set(true);
  }

  cancelEdit(): void {
    const u = this.user();
    if (u) this.resetForm(u);
    this.formError.set('');
    this.editMode.set(false);
  }

  saveEdit(): void {
    this.formError.set('');
    if (this.form.invalid) {
      this.formError.set(revealFormErrors(this.form, this.host));
      return;
    }
    const raw = this.form.getRawValue();
    const payload: Partial<Utilisateur> = {};
    const controls = this.form.controls;
    if (controls.nom.dirty) payload.nom = raw.nom.trim();
    if (controls.prenoms.dirty) payload.prenoms = raw.prenoms.trim();
    if (controls.email.dirty) payload.email = raw.email.trim();
    if (controls.telephone.dirty) payload.telephone = normaliserTelephone(raw.telephone) || null;
    const nouveauRole = !this.estMoi() && raw.role !== this.user()?.role ? raw.role : null;
    if (Object.keys(payload).length === 0 && !nouveauRole) {
      this.toast.info('Aucune modification à enregistrer');
      this.editMode.set(false);
      return;
    }
    this.saving.set(true);
    const maj$: Observable<Utilisateur | null> = Object.keys(payload).length
      ? this.service.update(this.id, payload)
      : of(null);
    maj$.pipe(
      switchMap((u): Observable<Utilisateur> =>
        nouveauRole ? this.service.changerRole(this.id, nouveauRole) : of(u as Utilisateur),
      ),
    ).subscribe({
      next: (u) => {
        this.saving.set(false);
        this.user.set(u);
        this.resetForm(u);
        this.editMode.set(false);
        this.toast.success('Fiche utilisateur mise à jour');
      },
      error: (err) => {
        this.saving.set(false);
        this.formError.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }

  openPhotoPicker(): void {
    this.photoInputRef?.nativeElement.click();
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    if (!PHOTO_TYPES.includes(file.type)) {
      this.toast.error('Format non pris en charge', 'Choisissez une image JPEG, PNG ou WebP.');
      input.value = '';
      return;
    }
    if (file.size > PHOTO_MAX) {
      this.toast.error('Image trop lourde', 'La photo ne doit pas dépasser 5 Mo.');
      input.value = '';
      return;
    }
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (u) => {
        this.uploadingPhoto.set(false);
        this.user.set(u);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        this.toast.error('Photo non enregistrée', toApiError(err).message);
        input.value = '';
      },
    });
  }

  confirmerAction(motif = ''): void {
    const a = this.action();
    const u = this.user();
    if (!a || !u) return;
    this.actionLoading.set(true);
    const fail = (err: unknown) => {
      this.actionLoading.set(false);
      this.action.set(null);
      this.toast.error('Action impossible', toApiError(err).message);
    };
    const done = (message: string) => {
      this.actionLoading.set(false);
      this.action.set(null);
      this.toast.success(message);
    };
    if (a === 'reset') {
      this.service.envoyerReinitialisation(u.id).subscribe({
        next: (res) => done(res.detail || 'Lien de réinitialisation envoyé'),
        error: fail,
      });
    } else if (a === 'rejeter') {
      this.service.rejeter(u.id, motif.trim()).subscribe({
        next: (res) => {
          done(res.detail || 'Inscription rejetée');
          this.router.navigate(['/app/utilisateurs']);
        },
        error: fail,
      });
    } else if (a === 'desactiver') {
      this.service.delete(u.id).subscribe({
        next: () => {
          done('Compte désactivé');
          this.router.navigate(['/app/utilisateurs']);
        },
        error: fail,
      });
    } else {
      const req$ = a === 'suspendre' ? this.service.suspendre(u.id) : this.service.activer(u.id);
      req$.subscribe({
        next: () => {
          done(a === 'suspendre' ? 'Compte suspendu' : 'Compte activé');
          this.load();
        },
        error: fail,
      });
    }
  }

  statutTone(statut: StatutCompte): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === StatutCompte.ACTIF) return 'success';
    if (statut === StatutCompte.EN_ATTENTE) return 'warning';
    if (statut === StatutCompte.SUSPENDU) return 'danger';
    return 'neutral';
  }
}
