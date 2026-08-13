from datetime import timedelta

import bcrypt
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Utilisateur


class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = (
            'id', 'email', 'telephone', 'role', 'statut', 'nom', 'prenoms',
            'doit_changer_mdp', 'preferences_notif', 'derniere_connexion', 'created_at',
        )
        read_only_fields = (
            'id', 'derniere_connexion', 'created_at',
        )


class UtilisateurAdminSerializer(serializers.ModelSerializer):
    """Création / édition comptes par admin."""
    password = serializers.CharField(write_only=True, required=False, min_length=8)

    class Meta:
        model = Utilisateur
        fields = (
            'id', 'email', 'telephone', 'role', 'statut', 'nom', 'prenoms',
            'password', 'doit_changer_mdp', 'preferences_notif', 'created_at', 'updated_at',
        )
        read_only_fields = ('id', 'created_at', 'updated_at')

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({'password': 'Mot de passe requis.'})
        now = timezone.now()
        user = Utilisateur(**validated_data, created_at=now, updated_at=now)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for k, v in validated_data.items():
            setattr(instance, k, v)
        if password:
            instance.set_password(password)
        instance.updated_at = timezone.now()
        instance.save()
        return instance


class ChangePasswordSerializer(serializers.Serializer):
    ancien_mot_de_passe = serializers.CharField(write_only=True)
    nouveau_mot_de_passe = serializers.CharField(write_only=True, min_length=8)


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    nouveau_mot_de_passe = serializers.CharField(min_length=8)


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
        token = RefreshToken.for_user(user)
        token['email'] = user.email
        token['role'] = user.role
        return token

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        try:
            user = Utilisateur.objects.get(email__iexact=email, deleted_at__isnull=True)
        except Utilisateur.DoesNotExist as exc:
            raise serializers.ValidationError('Identifiants invalides.') from exc

        if user.verrouille_jusquau and user.verrouille_jusquau > timezone.now():
            raise serializers.ValidationError('Compte temporairement verrouillé.')

        if not user.check_password(password):
            user.tentatives_echec = (user.tentatives_echec or 0) + 1
            if user.tentatives_echec >= 5:
                user.verrouille_jusquau = timezone.now() + timedelta(minutes=15)
            Utilisateur.objects.filter(pk=user.pk).update(
                tentatives_echec=user.tentatives_echec,
                verrouille_jusquau=user.verrouille_jusquau,
            )
            raise serializers.ValidationError('Identifiants invalides.')

        if user.statut != Utilisateur.Statut.ACTIF:
            raise serializers.ValidationError('Compte inactif ou en attente de validation.')

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
