"""Permissions RBAC — 6 profils note de cadrage PNLF."""

from rest_framework.permissions import SAFE_METHODS, BasePermission

from accounts.models import Utilisateur


class RolePermission(BasePermission):
    """
    Droits par rôle.
    Sous-classes définissent :
      - read_roles / write_roles
    """

    read_roles: set[str] = set()
    write_roles: set[str] = set()

    def has_permission(self, request, view):
        user = request.user
        if not getattr(user, 'is_authenticated', False):
            return False
        role = getattr(user, 'role', None)
        if role == Utilisateur.Role.ADMINISTRATEUR:
            return True
        if request.method in SAFE_METHODS:
            return role in self.read_roles or role in self.write_roles
        return role in self.write_roles


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        u = request.user
        return bool(
            getattr(u, 'is_authenticated', False)
            and getattr(u, 'role', None) == Utilisateur.Role.ADMINISTRATEUR
        )


class CanManageReferentiel(RolePermission):
    """Produits / catégories : admin + agents ministère."""

    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
    }


class CanManageProducteurs(RolePermission):
    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
    }


class CanManageLots(RolePermission):
    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
    }


class CanReadGeo(RolePermission):
    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }
    write_roles = set()


def scope_producteurs_qs(qs, user):
    """Filtre les producteurs selon le rôle."""
    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
    ):
        return qs
    if role == Utilisateur.Role.ACHETEUR:
        # Lecture marché : fiches actives uniquement, pas les dossiers en instruction.
        return qs.filter(statut='ACTIF')
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(cooperative_id__in=coop_ids)
    return qs.none()


def scope_lots_qs(qs, user):
    """Filtre les lots selon le rôle."""
    from django.db.models import Q

    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
    ):
        return qs
    if role == Utilisateur.Role.ACHETEUR:
        # Un acheteur ne doit voir que des lots réellement disponibles : on masque
        # les brouillons (non publiés), les lots déjà commercialisés (vendus),
        # les archives et les annulations, qui n'ont pas d'intérêt commercial.
        return qs.filter(producteur__statut='ACTIF').exclude(
            statut__in=['BROUILLON', 'COMMERCIALISE', 'ARCHIVE', 'ANNULE'],
        )
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(producteur__utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(Q(cooperative_id__in=coop_ids) | Q(producteur__cooperative_id__in=coop_ids))
    return qs.none()


def scope_mouvements_qs(qs, user):
    from django.db.models import Q

    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
    ):
        return qs
    if role == Utilisateur.Role.ACHETEUR:
        return qs.filter(lot__producteur__statut='ACTIF')
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(lot__producteur__utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(
            Q(lot__cooperative_id__in=coop_ids) | Q(lot__producteur__cooperative_id__in=coop_ids)
        )
    return qs.none()


class CanManageUsers(RolePermission):
    """CRUD utilisateurs — admin + agent ministère (mutations sur ADMIN réservées aux admins)."""
    read_roles = {Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE}
    write_roles = {Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE}


class CanValidateProducteurs(BasePermission):
    """Validation / rejet fiches producteurs-collecteurs."""
    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )


class CanValidateCooperatives(BasePermission):
    """Validation / rejet des demandes d'inscription de coopératives."""
    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
        )


class CanManageCooperatives(RolePermission):
    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.COOPERATIVE,
    }


class CanManageZones(RolePermission):
    read_roles = CanReadGeo.read_roles
    # Création unitaire possible pour producteur/coop (formulaire lot) ;
    # l'import massif est réservé aux agents (voir ZoneViewSet.import_fichier).
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
    }


class CanImportZones(BasePermission):
    """Import CSV/XLSX du référentiel national — agents uniquement."""

    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )


class CanManageCertifications(RolePermission):
    read_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
    }
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
    }


class CanUseMarketplace(RolePermission):
    """Offres/demandes + messagerie."""
    read_roles = CanManageLots.read_roles
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }


class CanValidateCertifications(BasePermission):
    """Acceptation / refus des demandes — administrateur et agent du ministère."""

    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
        )


class CanViewDashboard(BasePermission):
    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )


class CanExportJournal(BasePermission):
    """Export CSV/PDF du journal d'audit — admin et ministère uniquement (SEC-15)."""

    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
        )


class CanSyncTerrain(BasePermission):
    """Push/pull terrain + appareils — admin, ministère, agents forestiers."""

    def has_permission(self, request, view):
        if not getattr(request.user, 'is_authenticated', False):
            return False
        return request.user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        )


def user_can_access_producteur(user, producteur) -> bool:
    return scope_producteurs_qs(
        type(producteur).objects.filter(pk=producteur.pk), user
    ).exists()


def user_can_access_lot(user, lot) -> bool:
    from traceability.models import Lot
    return scope_lots_qs(Lot.objects.filter(pk=lot.pk), user).exists()
