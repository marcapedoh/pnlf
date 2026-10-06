"""Inscription publique — producteurs, collecteurs, coopératives et acheteurs (sans authentification).

Flux : le visiteur choisit son mot de passe et dépose sa photo ; le compte
(``Utilisateur``) et la fiche (``Producteur``/``Cooperative``) sont créés
immédiatement mais restent bloqués (``EN_ATTENTE`` / ``EN_VALIDATION`` /
``actif=False``) jusqu'à validation par un administrateur ou un agent du
ministère, qui déclenche l'activation du compte et l'envoi d'un email + SMS
de confirmation (voir ``traceability.views._activer_compte_lie``).
"""

from __future__ import annotations

import uuid

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.utils import timezone
from rest_framework import generics, serializers, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle

from accounts.audit import request_meta, write_audit
from accounts.messaging import envoyer_email, envoyer_sms
from accounts.models import Utilisateur
from config.validators import CoordonneesGabonMixin, TelephoneField

from .db_utils import set_optional_column
from .models import Cooperative, Departement, DocumentInscription, Producteur, Province, Village
from .numerotation import numero_agrement
from .services import enregistrer_document, enregistrer_photo

DOCUMENT_MAX_SIZE_BYTES = 8 * 1024 * 1024
DOCUMENT_CONTENT_TYPES = {
    'application/pdf', 'image/jpeg', 'image/jpg', 'image/png',
}

TYPES_DEMANDE = ('PRODUCTEUR', 'COLLECTEUR', 'COOPERATIVE', 'ACHETEUR')

LIBELLES_TYPE = {
    'PRODUCTEUR': 'producteur',
    'COLLECTEUR': 'collecteur',
    'COOPERATIVE': 'coopérative',
    'ACHETEUR': 'acheteur',
}


class InscriptionPubliqueSerializer(CoordonneesGabonMixin, serializers.Serializer):
    type_demande = serializers.ChoiceField(choices=TYPES_DEMANDE)
    nom = serializers.CharField(max_length=150)
    prenoms = serializers.CharField(max_length=150, required=False, allow_blank=True)
    email = serializers.EmailField()
    telephone = TelephoneField(error_messages={
        'required': 'Le numéro de téléphone est requis.',
        'blank': 'Le numéro de téléphone est requis.',
    })
    date_naissance = serializers.DateField(required=False, allow_null=True)
    latitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True,
    )
    longitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True,
    )
    password = serializers.CharField(write_only=True, min_length=8, error_messages={
        'required': 'Le mot de passe est requis.',
        'blank': 'Le mot de passe est requis.',
        'min_length': 'Le mot de passe doit contenir au moins 8 caractères.',
    })
    password_confirmation = serializers.CharField(write_only=True, error_messages={
        'required': 'Confirmez votre mot de passe.',
        'blank': 'Confirmez votre mot de passe.',
    })
    photo = serializers.FileField(required=False, allow_null=True)
    # Documents administratifs (facultatifs selon le profil — validés après coup dans validate()).
    document_cni = serializers.FileField(required=False, allow_null=True)
    document_fiche_circuit = serializers.FileField(required=False, allow_null=True)
    document_agrement_nagoya = serializers.FileField(required=False, allow_null=True)
    province = serializers.PrimaryKeyRelatedField(
        queryset=Province.objects.filter(actif=True), required=False, allow_null=True,
    )
    departement = serializers.PrimaryKeyRelatedField(
        queryset=Departement.objects.filter(actif=True), required=False, allow_null=True,
    )
    village = serializers.PrimaryKeyRelatedField(
        queryset=Village.objects.filter(actif=True), required=False, allow_null=True,
    )
    communaute = serializers.CharField(max_length=120, required=False, allow_blank=True)
    adresse = serializers.CharField(max_length=255, required=False, allow_blank=True)
    message = serializers.CharField(required=False, allow_blank=True, max_length=2000)
    accepte_conditions = serializers.BooleanField()
    # Honeypot anti-bot : champ invisible côté formulaire, jamais rempli par un humain.
    site_web = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_site_web(self, value):
        if value:
            raise serializers.ValidationError('Requête invalide.')
        return value

    def validate_accepte_conditions(self, value):
        if not value:
            raise serializers.ValidationError("Vous devez certifier l'exactitude des informations fournies.")
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        existant = Utilisateur.objects.filter(email__iexact=value).only('deleted_at').first()
        if existant is not None:
            if existant.deleted_at is not None:
                raise serializers.ValidationError(
                    'Cette adresse e-mail est liée à un ancien compte supprimé : '
                    'utilisez une autre adresse ou contactez l’administration pour la réactiver.'
                )
            raise serializers.ValidationError('Un compte existe déjà avec cette adresse e-mail.')
        return value

    def validate_date_naissance(self, value):
        if value is not None and value >= timezone.localdate():
            raise serializers.ValidationError('La date de naissance doit être antérieure à aujourd’hui.')
        return value

    def validate_password(self, value):
        try:
            validate_password(value)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(list(exc.messages)) from exc
        return value

    def validate_photo(self, value):
        if value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError('Image trop volumineuse (5 Mo maximum).')
        if not (value.content_type or '').startswith('image/'):
            raise serializers.ValidationError('Fichier image invalide (JPEG/PNG/WEBP attendu).')
        return value

    def _validate_document(self, value, champ: str):
        if value.size > DOCUMENT_MAX_SIZE_BYTES:
            raise serializers.ValidationError({champ: 'Fichier trop volumineux (8 Mo maximum).'})
        if (value.content_type or '').lower() not in DOCUMENT_CONTENT_TYPES:
            raise serializers.ValidationError({champ: 'Formats acceptés : PDF, JPEG, PNG.'})
        return value

    def validate_document_cni(self, value):
        return self._validate_document(value, 'document_cni')

    def validate_document_fiche_circuit(self, value):
        return self._validate_document(value, 'document_fiche_circuit')

    def validate_document_agrement_nagoya(self, value):
        return self._validate_document(value, 'document_agrement_nagoya')

    def validate(self, attrs):
        if attrs.get('password') != attrs.get('password_confirmation'):
            raise serializers.ValidationError({'password_confirmation': 'Les mots de passe ne correspondent pas.'})
        type_demande = attrs['type_demande']
        if type_demande in ('PRODUCTEUR', 'COLLECTEUR', 'ACHETEUR') and not attrs.get('prenoms', '').strip():
            raise serializers.ValidationError({'prenoms': 'Le prénom est requis.'})
        if type_demande == 'COOPERATIVE' and not attrs.get('nom', '').strip():
            raise serializers.ValidationError({'nom': 'Le nom de la coopérative est requis.'})
        if type_demande == 'COOPERATIVE' and Cooperative.objects.filter(nom__iexact=attrs['nom'].strip()).exists():
            raise serializers.ValidationError({'nom': 'Une coopérative porte déjà ce nom.'})
        # La date de naissance est indispensable à l'instruction du dossier (producteur/collecteur) :
        # elle est obligatoire, contrairement à la géolocalisation (latitude/longitude) qui reste
        # un complément optionnel à la localisation administrative (province/département/village).
        if type_demande in ('PRODUCTEUR', 'COLLECTEUR') and not attrs.get('date_naissance'):
            raise serializers.ValidationError({'date_naissance': 'La date de naissance est requise.'})
        if type_demande != 'ACHETEUR':
            if not attrs.get('photo'):
                raise serializers.ValidationError({'photo': 'La photo est requise.'})
            if not attrs.get('province'):
                raise serializers.ValidationError({'province': 'La province est requise.'})
            # Pièce d'identité obligatoire pour les profils métier (producteur, collecteur, coopérative) :
            # elle est examinée par un administrateur avant validation du dossier.
            if not attrs.get('document_cni'):
                raise serializers.ValidationError(
                    {'document_cni': "La copie de votre pièce d'identité (CNI) est requise."}
                )
        return attrs


class InscriptionPublicThrottle(AnonRateThrottle):
    scope = 'inscription_public'


class PublicInscriptionView(generics.CreateAPIView):
    """``POST /api/public/inscription/`` — création d'une demande d'inscription."""

    permission_classes = [AllowAny]
    serializer_class = InscriptionPubliqueSerializer
    parser_classes = [MultiPartParser, FormParser]
    throttle_classes = [InscriptionPublicThrottle]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        ip, ua = request_meta(request)

        type_demande = data['type_demande']
        nom = data['nom'].strip()
        # Une coopérative n'a pas de prénom : le nom affiché est celui de la structure.
        prenoms = '' if type_demande == 'COOPERATIVE' else (data.get('prenoms') or '').strip()

        with transaction.atomic():
            now = timezone.now()
            role = Utilisateur.Role.COOPERATIVE if type_demande == 'COOPERATIVE' else (
                Utilisateur.Role.ACHETEUR if type_demande == 'ACHETEUR' else Utilisateur.Role.PRODUCTEUR
            )
            user = Utilisateur(
                id=uuid.uuid4(), email=data['email'], telephone=data['telephone'],
                role=role, statut=Utilisateur.Statut.EN_ATTENTE, nom=nom, prenoms=prenoms,
                preferences_notif='EMAIL', created_at=now, updated_at=now,
            )
            user.set_password(data['password'])
            user.save()

            entite_id = uuid.uuid4()
            notes = f"Inscription publique le {now:%d/%m/%Y %H:%M} (IP {ip or 'inconnue'})."
            if data.get('message', '').strip():
                notes += f" Message du demandeur : {data['message'].strip()[:500]}"

            if type_demande in ('PRODUCTEUR', 'COLLECTEUR'):
                fiche = Producteur(
                    id=entite_id,
                    code_producteur=f'PRD-{entite_id.hex[:8].upper()}',
                    nom=nom, prenoms=prenoms,
                    date_naissance=data.get('date_naissance'),
                    telephone=data['telephone'], email=data['email'],
                    communaute=data.get('communaute') or None,
                    province=data['province'], departement=data.get('departement'), village=data.get('village'),
                    latitude=data.get('latitude'), longitude=data.get('longitude'),
                    utilisateur_id=user.id, statut='EN_VALIDATION', notes=notes,
                    sync_statut='SYNCED', sync_version=1,
                    created_at=now, updated_at=now,
                )
                fiche.save()
                set_optional_column('producteurs', 'type_acteur', fiche.id, type_demande)
                set_optional_column('producteurs', 'visible_public', fiche.id, True)
                sous_dossier, table_cible = 'producteurs', 'producteurs'
                enregistrer_photo(data['photo'], sous_dossier, fiche.id)
                dossier_id = fiche.id
                entite_type_doc = DocumentInscription.EntiteType.PRODUCTEUR
            elif type_demande == 'COOPERATIVE':
                fiche = Cooperative(
                    id=entite_id,
                    code=f'COOP-{entite_id.hex[:8].upper()}',
                    nom=nom, numero_agrement=numero_agrement(data['province']),
                    telephone=data['telephone'], email=data['email'],
                    adresse=data.get('adresse') or None,
                    province=data['province'], utilisateur_id=user.id, actif=False,
                    statut='EN_VALIDATION', created_at=now, updated_at=now,
                )
                fiche.save()
                sous_dossier, table_cible = 'cooperatives', 'cooperatives'
                enregistrer_photo(data['photo'], sous_dossier, fiche.id)
                dossier_id = fiche.id
                entite_type_doc = DocumentInscription.EntiteType.COOPERATIVE
            else:
                table_cible = 'utilisateurs'
                dossier_id = user.id
                if data.get('photo'):
                    enregistrer_photo(data['photo'], 'acheteurs', user.id)
                entite_type_doc = DocumentInscription.EntiteType.UTILISATEUR

            _enregistrer_documents_administratifs(
                entite_type_doc, dossier_id, table_cible, data, now,
            )

            write_audit(
                utilisateur_id=None, action='INSCRIPTION_PUBLIQUE', table_cible=table_cible,
                enregistrement_id=dossier_id, ip_adresse=ip, user_agent=ua,
                nouvelles_valeurs={'email': user.email, 'type_demande': type_demande},
            )

        type_libelle = LIBELLES_TYPE[type_demande]
        _notifier_accuse_reception(user, type_libelle)
        _notifier_admins(user, type_libelle, table_cible, dossier_id)

        payload = {
            'detail': (
                "Votre demande d'inscription a été enregistrée. "
                'Elle sera examinée par un administrateur ; vous recevrez un email et un SMS '
                'dès qu\'elle sera validée.'
            ),
            'email': user.email,
            'numero_dossier': f'PFNL-{str(dossier_id).replace("-", "")[:10].upper()}',
        }
        if type_demande != 'ACHETEUR':
            payload['fiche_id'] = str(dossier_id)
        return Response(payload, status=status.HTTP_201_CREATED)


def _enregistrer_documents_administratifs(entite_type, entite_id, sous_dossier, data, now) -> None:
    """Enregistre les documents administratifs joints (CNI, fiche circuit, agrément Nagoya)."""
    mapping = (
        ('document_cni', DocumentInscription.TypeDocument.CNI),
        ('document_fiche_circuit', DocumentInscription.TypeDocument.FICHE_CIRCUIT),
        ('document_agrement_nagoya', DocumentInscription.TypeDocument.AGREMENT_NAGOYA),
    )
    for champ, type_document in mapping:
        fichier = data.get(champ)
        if not fichier:
            continue
        chemin = enregistrer_document(fichier, f'inscriptions/{sous_dossier}', f'{entite_id}_{type_document.lower()}')
        DocumentInscription.objects.create(
            id=uuid.uuid4(), entite_type=entite_type, entite_id=entite_id,
            type_document=type_document, chemin=chemin,
            nom_original=getattr(fichier, 'name', '') or None,
            created_at=now,
        )


def _notifier_accuse_reception(user: Utilisateur, type_libelle: str) -> None:
    sujet = "PFNL : accusé de réception de votre inscription"
    corps = (
        f'Bonjour {user.get_full_name()},\n\n'
        f"Nous avons bien reçu votre demande d'inscription en tant que {type_libelle} sur la "
        'plateforme PFNL (École Nationale des Eaux et Forêts).\n'
        'Un administrateur va examiner votre dossier. Vous recevrez un email et un SMS de '
        'confirmation dès que votre compte sera validé et activé.\n\n'
        "Cordialement,\nL'équipe PFNL"
    )
    envoyer_email(destinataire_id=user.id, email=user.email, sujet=sujet, corps_texte=corps)
    envoyer_sms(
        destinataire_id=user.id, telephone=user.telephone,
        message="PFNL : votre demande d'inscription a ete recue et est en cours d'examen.",
    )


def _notifier_admins(user: Utilisateur, type_libelle: str, table_cible: str, fiche_id) -> None:
    from pnlf_platform.services import creer_notification

    destinataires = Utilisateur.objects.filter(
        role__in=[Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE],
        deleted_at__isnull=True, statut=Utilisateur.Statut.ACTIF,
    ).values_list('id', flat=True)[:10]
    for admin_id in destinataires:
        creer_notification(
            admin_id,
            "Nouvelle demande d'inscription",
            f'{user.get_full_name()} ({type_libelle}) a soumis une demande d\'inscription. '
            'Ouvrez sa fiche pour la valider ou la rejeter.',
            metadata={'table_cible': table_cible, 'enregistrement_id': str(fiche_id)},
        )
