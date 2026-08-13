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
        Utilisateur.Role.ACHETEUR,
    ):
        return qs
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(cooperative_id__in=coop_ids)
    return qs.none()


def scope_lots_qs(qs, user):
    """Filtre les lots selon le rôle."""
    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.ACHETEUR,
    ):
        return qs
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(producteur__utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(cooperative_id__in=coop_ids)
    return qs.none()


def scope_mouvements_qs(qs, user):
    role = getattr(user, 'role', None)
    if role in (
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.ACHETEUR,
    ):
        return qs
    if role == Utilisateur.Role.PRODUCTEUR:
        return qs.filter(lot__producteur__utilisateur_id=user.id)
    if role == Utilisateur.Role.COOPERATIVE:
        from traceability.models import Cooperative

        coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
        return qs.filter(lot__cooperative_id__in=coop_ids)
    return qs.none()


class CanManageUsers(RolePermission):
    """CRUD utilisateurs — admin + agent ministère."""
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
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
    }


class CanManageCertifications(RolePermission):
    read_roles = CanManageLots.read_roles
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.AGENT_FORESTIER,
        Utilisateur.Role.COOPERATIVE,
    }


class CanUseMarketplace(RolePermission):
    """Offres/demandes + messagerie."""
    read_roles = CanManageLots.read_roles
    write_roles = {
        Utilisateur.Role.ADMINISTRATEUR,
        Utilisateur.Role.AGENT_MINISTERE,
        Utilisateur.Role.PRODUCTEUR,
        Utilisateur.Role.COOPERATIVE,
        Utilisateur.Role.ACHETEUR,
    }


class CanViewDashboard(BasePermission):
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
