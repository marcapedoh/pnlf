from datetime import timedelta

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from config.validators import TelephoneField

from .models import Utilisateur


def _utilisateur_photo_url(user, request=None):
    from traceability.services import photo_url as _photo_url

    return _photo_url('utilisateurs', user.id, request)


def valider_mot_de_passe(valeur: str, user=None) -> str:
    """Applique AUTH_PASSWORD_VALIDATORS et renvoie des messages en français."""
    try:
        validate_password(valeur, user=user)
    except DjangoValidationError as exc:
        raise serializers.ValidationError(list(exc.messages)) from exc
    return valeur


_MDP_ERREURS = {
    'required': 'Le mot de passe est requis.',
    'blank': 'Le mot de passe est requis.',
    'min_length': 'Le mot de passe doit contenir au moins 8 caractères.',
}


_CHAMPS_ACTIONS_DEDIEES = {
    'statut': 'Le statut d’un compte se modifie avec les actions dédiées (activer, suspendre, rejeter, désactiver).',
    'role': 'Le rôle d’un compte se modifie avec l’action dédiée « Changer le rôle ».',
}

IDENTIFIANTS_INVALIDES = 'Identifiants invalides.'
VERROU_TENTATIVES = 5
VERROU_MINUTES = 15

_HASH_FACTICE: str | None = None


def _hash_factice() -> str:
    global _HASH_FACTICE
    if _HASH_FACTICE is None:
        import secrets

        import bcrypt as bcrypt_lib

        _HASH_FACTICE = bcrypt_lib.hashpw(
            secrets.token_bytes(16), bcrypt_lib.gensalt(rounds=12),
        ).decode('utf-8')
    return _HASH_FACTICE


def _telephone_field():
    return TelephoneField(required=False, allow_blank=True, allow_null=True)


class UtilisateurSerializer(serializers.ModelSerializer):
    telephone = _telephone_field()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Utilisateur
        fields = (
            'id', 'email', 'telephone', 'role', 'statut', 'nom', 'prenoms', 'photo_url',
            'doit_changer_mdp', 'preferences_notif', 'derniere_connexion', 'created_at',
        )
        read_only_fields = (
            'id', 'derniere_connexion', 'created_at',
        )

    def get_photo_url(self, obj):
        return _utilisateur_photo_url(obj, self.context.get('request'))


class MonProfilSerializer(serializers.ModelSerializer):
    """Modification de son propre profil : identité et téléphone uniquement."""
    telephone = _telephone_field()

    class Meta:
        model = Utilisateur
        fields = ('nom', 'prenoms', 'telephone')
        extra_kwargs = {
            'nom': {'error_messages': {'blank': 'Le nom est requis.'}},
            'prenoms': {'required': False, 'allow_blank': True},
        }

    def validate_nom(self, valeur):
        valeur = (valeur or '').strip()
        if not valeur:
            raise serializers.ValidationError('Le nom est requis.')
        return valeur

    def validate(self, attrs):
        if 'prenoms' in attrs:
            attrs['prenoms'] = (attrs['prenoms'] or '').strip()
            if self.instance.role != Utilisateur.Role.COOPERATIVE and not attrs['prenoms']:
                raise serializers.ValidationError({'prenoms': 'Les prénoms sont requis.'})
        return attrs

    def update(self, instance, validated_data):
        for champ, valeur in validated_data.items():
            setattr(instance, champ, valeur)
        instance.updated_at = timezone.now()
        instance.save(update_fields=[*validated_data.keys(), 'updated_at'])
        return instance


class UtilisateurAdminSerializer(serializers.ModelSerializer):
    """Création / édition comptes par admin."""
    password = serializers.CharField(
        write_only=True, required=False, min_length=8, error_messages=_MDP_ERREURS,
    )
    telephone = _telephone_field()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Utilisateur
        fields = (
            'id', 'email', 'telephone', 'role', 'statut', 'nom', 'prenoms', 'photo_url',
            'password', 'doit_changer_mdp', 'preferences_notif', 'derniere_connexion',
            'created_at', 'updated_at',
        )
        read_only_fields = ('id', 'derniere_connexion', 'created_at', 'updated_at')
        extra_kwargs = {'prenoms': {'required': False, 'allow_blank': True}}

    def get_photo_url(self, obj):
        return _utilisateur_photo_url(obj, self.context.get('request'))

    def validate(self, attrs):
        if self.instance is not None:
            for champ, message in _CHAMPS_ACTIONS_DEDIEES.items():
                if champ in attrs and attrs[champ] != getattr(self.instance, champ):
                    raise serializers.ValidationError({champ: message})
                attrs.pop(champ, None)
        role = attrs.get('role', getattr(self.instance, 'role', None))
        prenoms = attrs.get('prenoms', getattr(self.instance, 'prenoms', '') or '')
        if role != Utilisateur.Role.COOPERATIVE and not (prenoms or '').strip():
            raise serializers.ValidationError({'prenoms': 'Les prénoms sont requis.'})
        if role == Utilisateur.Role.COOPERATIVE and 'prenoms' not in attrs and self.instance is None:
            attrs['prenoms'] = ''
        return attrs

    def validate_role(self, value):
        request = self.context.get('request')
        actor = getattr(request, 'user', None)
        if value == Utilisateur.Role.ADMINISTRATEUR and getattr(actor, 'role', None) != Utilisateur.Role.ADMINISTRATEUR:
            raise serializers.ValidationError(
                'Seul un administrateur peut attribuer le rôle administrateur.'
            )
        return value

    def validate_password(self, value):
        return valider_mot_de_passe(value, user=self.instance)

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({'password': 'Le mot de passe est requis.'})
        # Mot de passe provisoire communiqué par un tiers : changement exigé à la 1re connexion.
        validated_data['doit_changer_mdp'] = True
        now = timezone.now()
        user = Utilisateur(**validated_data, created_at=now, updated_at=now)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        request = self.context.get('request')
        actor = getattr(request, 'user', None)
        password = validated_data.pop('password', None)
        if password and getattr(actor, 'role', None) != Utilisateur.Role.ADMINISTRATEUR:
            raise serializers.ValidationError({
                'password': 'Seul un administrateur peut définir le mot de passe d’un compte.',
            })
        for k, v in validated_data.items():
            setattr(instance, k, v)
        if password:
            instance.set_password(password)
        instance.updated_at = timezone.now()
        instance.save()
        return instance


class ChangePasswordSerializer(serializers.Serializer):
    ancien_mot_de_passe = serializers.CharField(write_only=True, error_messages={
        'required': 'Le mot de passe actuel est requis.',
        'blank': 'Le mot de passe actuel est requis.',
    })
    nouveau_mot_de_passe = serializers.CharField(
        write_only=True, min_length=8, error_messages=_MDP_ERREURS,
    )

    def validate_nouveau_mot_de_passe(self, value):
        return valider_mot_de_passe(value, user=self.context.get('user'))

    def validate(self, attrs):
        if attrs.get('ancien_mot_de_passe') == attrs.get('nouveau_mot_de_passe'):
            raise serializers.ValidationError({
                'nouveau_mot_de_passe': 'Le nouveau mot de passe doit être différent de l’actuel.',
            })
        return attrs


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    nouveau_mot_de_passe = serializers.CharField(min_length=8, error_messages=_MDP_ERREURS)

    def validate_nouveau_mot_de_passe(self, value):
        return valider_mot_de_passe(value)


class PnlfTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'email'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['email'] = serializers.EmailField()
        self.fields['password'] = serializers.CharField(write_only=True)
        # retire le champ username hérité si présent
        self.fields.pop('username', None)

    @classmethod
    def get_token(cls, user):
        from .token_utils import password_fingerprint

        token = RefreshToken.for_user(user)
        token['email'] = user.email
        token['role'] = user.role
        token['pwd'] = password_fingerprint(user)
        return token

    def _tracer_echec(self, motif: str, email: str, user=None) -> None:
        from .connexions import enregistrer_connexion

        enregistrer_connexion(
            self.context.get('request'), succes=False, utilisateur=user, email=email, motif_echec=motif,
        )

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        user = Utilisateur.objects.filter(email__iexact=email, deleted_at__isnull=True).first()
        if user is None:
            # Même coût de vérification qu'un compte existant (pas d'oracle temporel).
            Utilisateur(mot_de_passe_hash=_hash_factice()).check_password(password)
            self._tracer_echec('IDENTIFIANTS', email)
            raise serializers.ValidationError(IDENTIFIANTS_INVALIDES)

        maintenant = timezone.now()
        verrouille = bool(user.verrouille_jusquau and user.verrouille_jusquau > maintenant)

        if not user.check_password(password):
            if not verrouille:
                tentatives = (user.tentatives_echec or 0) + 1
                fin_verrou = maintenant + timedelta(minutes=VERROU_MINUTES) if tentatives >= VERROU_TENTATIVES else None
                Utilisateur.objects.filter(pk=user.pk).update(
                    tentatives_echec=tentatives,
                    verrouille_jusquau=fin_verrou,
                )
            self._tracer_echec('IDENTIFIANTS', email, user)
            raise serializers.ValidationError(IDENTIFIANTS_INVALIDES)

        if verrouille:
            self._tracer_echec('VERROUILLE', email, user)
            raise serializers.ValidationError(
                'Compte temporairement verrouillé après plusieurs tentatives infructueuses. '
                f'Réessayez dans {VERROU_MINUTES} minutes ou réinitialisez votre mot de passe.'
            )

        if user.statut == Utilisateur.Statut.EN_ATTENTE:
            self._tracer_echec('EN_ATTENTE', email, user)
            raise serializers.ValidationError(
                'Votre compte est en cours de validation (délai indicatif : 5 jours ouvrés). '
                'Vous recevrez un e-mail et un SMS dès qu’il sera activé.'
            )
        if user.statut != Utilisateur.Statut.ACTIF:
            self._tracer_echec('INACTIF', email, user)
            raise serializers.ValidationError(
                'Compte inactif ou suspendu. Contactez l’École Nationale des Eaux et Forêts.'
            )

        Utilisateur.objects.filter(pk=user.pk).update(
            tentatives_echec=0,
            verrouille_jusquau=None,
            derniere_connexion=timezone.now(),
        )

        refresh = self.get_token(user)
        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UtilisateurSerializer(user).data,
        }


class PnlfTokenRefreshSerializer(TokenRefreshSerializer):
    """Refresh vérifié sur pnlf.utilisateurs (UUID) : AUTH_USER_MODEL reste le modèle auth Django."""

    def validate(self, attrs):
        from .token_utils import password_fingerprint

        refresh = self.token_class(attrs['refresh'])
        user = Utilisateur.objects.filter(pk=refresh.get('user_id'), deleted_at__isnull=True).first()
        if user is None or not user.is_active:
            raise AuthenticationFailed('Compte inactif ou introuvable.', code='user_inactive')
        if refresh.get('pwd') != password_fingerprint(user):
            raise AuthenticationFailed('Session révoquée.', code='password_changed')
        return {'access': str(refresh.access_token)}
