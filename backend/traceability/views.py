from django.conf import settings
from django.db import DatabaseError
from django.http import FileResponse, Http404
from django.utils import timezone
import uuid
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.audit import request_meta, write_audit
from config import media_store
from accounts.messaging import envoyer_email, envoyer_sms
from accounts.models import Utilisateur
from accounts.permissions import (
    CanImportZones,
    CanManageCertifications,
    CanManageCooperatives,
    CanManageLots,
    CanManageProducteurs,
    CanManageReferentiel,
    CanManageZones,
    CanReadGeo,
    CanValidateCertifications,
    CanValidateCooperatives,
    CanValidateProducteurs,
    scope_lots_qs,
    scope_mouvements_qs,
    scope_producteurs_qs,
    user_can_access_lot,
    user_can_access_producteur,
)

from .models import (
    CategorieProduit,
    Certification,
    Cooperative,
    CooperativeMembre,
    Departement,
    Lot,
    Mouvement,
    Producteur,
    Produit,
    Province,
    TypeCertification,
    Village,
    ZoneCollecte,
)
from .serializers import (
    CategorieProduitSerializer,
    CertificationSerializer,
    CooperativeMembreSerializer,
    CooperativeSerializer,
    DepartementSerializer,
    LotSerializer,
    LotVerifySerializer,
    MouvementSerializer,
    ProducteurSerializer,
    ProduitSerializer,
    ProvinceSerializer,
    TypeCertificationSerializer,
    VillageSerializer,
    ZoneCollecteSerializer,
)
from .services import (
    appliquer_mouvement_sur_lot,
    chemin_photo,
    enregistrer_photo,
    generer_qr_image,
    qr_image_bytes,
    transition_lot_statut,
    valider_type_mouvement,
)


def _user_id(user):
    return getattr(user, 'id', None)


def _activer_compte_lie(utilisateur_id, *, type_libelle: str) -> None:
    """Active le compte lié à une fiche self-inscrite validée, puis notifie par email/SMS."""
    if not utilisateur_id:
        return
    try:
        user = Utilisateur.objects.get(pk=utilisateur_id, deleted_at__isnull=True)
    except Utilisateur.DoesNotExist:
        return
    if user.statut != Utilisateur.Statut.EN_ATTENTE:
        return
    user.statut = Utilisateur.Statut.ACTIF
    user.updated_at = timezone.now()
    user.save(update_fields=['statut', 'updated_at'])

    lien = f'{settings.PNLF_FRONTEND_URL}/connexion'
    sujet = 'PFNL — Votre inscription a été validée'
    corps = (
        f'Bonjour {user.prenoms} {user.nom},\n\n'
        f'Votre inscription en tant que {type_libelle} sur la plateforme PFNL a été validée '
        'par un administrateur.\n'
        'Vous pouvez désormais vous connecter avec votre adresse email et le mot de passe choisi '
        f'lors de votre inscription :\n{lien}\n\n'
        "Cordialement,\nL'équipe PFNL — École Nationale des Eaux et Forêts"
    )
    envoyer_email(destinataire_id=user.id, email=user.email, sujet=sujet, corps_texte=corps)
    envoyer_sms(
        destinataire_id=user.id, telephone=user.telephone,
        message=f'PFNL : votre inscription a ete validee. Connectez-vous sur {lien}',
    )


def _rejeter_compte_lie(utilisateur_id, *, type_libelle: str, motif: str) -> None:
    """Notifie le rejet d'une fiche self-inscrite puis libère l'email pour une nouvelle tentative."""
    if not utilisateur_id:
        return
    try:
        user = Utilisateur.objects.get(pk=utilisateur_id, deleted_at__isnull=True)
    except Utilisateur.DoesNotExist:
        return
    if user.statut != Utilisateur.Statut.EN_ATTENTE:
        return

    motif_txt = motif or 'les informations fournies ne permettent pas de valider votre dossier.'
    sujet = "PFNL — Votre demande d'inscription n'a pas été retenue"
    corps = (
        f'Bonjour {user.prenoms} {user.nom},\n\n'
        f"Votre demande d'inscription en tant que {type_libelle} sur la plateforme PFNL "
        "n'a pas pu être validée.\n"
        f'Motif : {motif_txt}\n\n'
        'Vous pouvez soumettre une nouvelle demande en corrigeant les éléments concernés.\n\n'
        "Cordialement,\nL'équipe PFNL"
    )
    envoyer_email(destinataire_id=user.id, email=user.email, sujet=sujet, corps_texte=corps)
    envoyer_sms(
        destinataire_id=user.id, telephone=user.telephone,
        message=f"PFNL : votre demande d'inscription n'a pas ete retenue. Motif : {motif_txt[:100]}",
    )

    # Suppression définitive (et non un simple soft-delete) : le compte n'a jamais été
    # activé, la contrainte UNIQUE(email) est stricte en base et un soft-delete ne
    # libérerait donc pas l'adresse pour une nouvelle tentative d'inscription légitime.
    user.delete()


class ProvinceViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Province.objects.filter(actif=True)
    serializer_class = ProvinceSerializer
    search_fields = ('nom', 'code')


class DepartementViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Departement.objects.filter(actif=True).select_related('province')
    serializer_class = DepartementSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('province',)


class VillageViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanReadGeo]
    queryset = Village.objects.filter(actif=True).select_related('departement')
    serializer_class = VillageSerializer
    search_fields = ('nom',)
    filterset_fields = ('departement',)


class CategorieProduitViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = CategorieProduit.objects.filter(actif=True)
    serializer_class = CategorieProduitSerializer
    search_fields = ('libelle', 'code')


class ProduitViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageReferentiel]
    queryset = Produit.objects.filter(actif=True).select_related('categorie')
    serializer_class = ProduitSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('categorie', 'soumis_cites')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def perform_create(self, serializer):
        now = timezone.now()
        obj = serializer.save(created_at=now, updated_at=now)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='CREATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'code': obj.code},
        )

    def perform_update(self, serializer):
        obj = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(self.request.user),
            action='UPDATE', table_cible='produits', enregistrement_id=obj.id,
            ip_adresse=ip, user_agent=ua,
        )

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def image(self, request, pk=None):
        """Upload de la photo représentative du produit (référentiel — admin/agent ministère)."""
        produit = self.get_object()
        fichier = request.FILES.get('image')
        if not fichier:
            raise ValidationError({'image': 'Fichier « image » manquant.'})
        enregistrer_photo(fichier, 'produits', produit.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='UPDATE_IMAGE', table_cible='produits',
            enregistrement_id=produit.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProduitSerializer(produit, context={'request': request}).data)


class CooperativeViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCooperatives]
    serializer_class = CooperativeSerializer
    search_fields = ('nom', 'code')
    filterset_fields = ('province', 'actif', 'statut')

    def get_queryset(self):
        qs = Cooperative.objects.select_related('province')
        user = self.request.user
        if user.role == Utilisateur.Role.COOPERATIVE:
            return qs.filter(utilisateur_id=user.id)
        if user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            # Agents institutionnels voient aussi les demandes en attente.
            return qs
        return qs.filter(actif=True)

    def perform_create(self, serializer):
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now}
        if self.request.user.role == Utilisateur.Role.COOPERATIVE:
            extra['utilisateur_id'] = self.request.user.id
        serializer.save(**extra)

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.COOPERATIVE and instance.utilisateur_id != user.id:
            raise PermissionDenied('Accès refusé.')
        serializer.save(updated_at=timezone.now())

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def valider(self, request, pk=None):
        """Valide une demande d'inscription de coopérative et active le compte lié."""
        coop = self.get_object()
        coop.actif = True
        coop.statut = 'ACTIF'
        coop.updated_at = timezone.now()
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        _activer_compte_lie(coop.utilisateur_id, type_libelle='coopérative')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def rejeter(self, request, pk=None):
        """Rejette une demande d'inscription de coopérative."""
        coop = self.get_object()
        motif = (request.data.get('motif') or '').strip()
        now = timezone.now()
        _rejeter_compte_lie(coop.utilisateur_id, type_libelle='coopérative', motif=motif)
        # Le nom de la coopérative est contraint UNIQUE en base : on le suffixe pour
        # libérer ce nom en vue d'une nouvelle demande, tout en conservant l'historique.
        if '[REJETÉ ' not in coop.nom:
            coop.nom = f"{coop.nom} [REJETÉ {now:%Y%m%d%H%M%S}]"
        coop.actif = False
        coop.statut = 'REJETE'
        coop.updated_at = now
        coop.save(update_fields=['nom', 'actif', 'statut', 'updated_at'])
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='pdf')
    def pdf(self, request, pk=None):
        """Génère et renvoie directement la fiche PDF de cette coopérative (octets bruts)."""
        from pnlf_platform.pdf_export import cooperative_fiche_pdf_bytes

        coop = self.get_object()
        try:
            pdf, filename = cooperative_fiche_pdf_bytes(coop)
        except Exception:
            return Response({'detail': 'Impossible de générer la fiche PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['post'], url_path='pdf-liste')
    def pdf_liste(self, request):
        """Génère et renvoie directement la liste PDF des coopératives visibles."""
        from pnlf_platform.pdf_export import cooperatives_liste_pdf_bytes

        qs = self.filter_queryset(self.get_queryset())
        try:
            pdf, filename = cooperatives_liste_pdf_bytes(qs)
        except Exception:
            return Response({'detail': 'Impossible de générer la liste PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='cooperatives',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def desactiver(self, request, pk=None):
        """Désactive une coopérative active (la retire de l'annuaire public et bloque son compte)."""
        coop = self.get_object()
        if coop.statut != 'ACTIF':
            raise ValidationError({'detail': 'Seule une coopérative active peut être désactivée.'})
        now = timezone.now()
        coop.actif = False
        coop.statut = 'INACTIF'
        coop.updated_at = now
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        if coop.utilisateur_id:
            Utilisateur.objects.filter(pk=coop.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.INACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='DEACTIVATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCooperatives])
    def activer(self, request, pk=None):
        """Réactive une coopérative précédemment désactivée."""
        coop = self.get_object()
        if coop.statut != 'INACTIF':
            raise ValidationError({'detail': 'Seule une coopérative inactive peut être réactivée.'})
        now = timezone.now()
        coop.actif = True
        coop.statut = 'ACTIF'
        coop.updated_at = now
        coop.save(update_fields=['actif', 'statut', 'updated_at'])
        if coop.utilisateur_id:
            Utilisateur.objects.filter(pk=coop.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.ACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='ACTIVATE', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Upload du logo/photo de la coopérative (admin, agent ministère ou la coopérative elle-même)."""
        coop = self.get_object()
        user = request.user
        if user.role == Utilisateur.Role.COOPERATIVE and coop.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre coopérative.')
        if user.role in (Utilisateur.Role.ACHETEUR, Utilisateur.Role.PRODUCTEUR, Utilisateur.Role.AGENT_FORESTIER):
            raise PermissionDenied('Action non autorisée.')
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Fichier « photo » manquant.'})
        enregistrer_photo(fichier, 'cooperatives', coop.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE_PHOTO', table_cible='cooperatives',
            enregistrement_id=coop.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(CooperativeSerializer(coop, context={'request': request}).data)

    @action(detail=True, methods=['get', 'post'], url_path='membres')
    def membres(self, request, pk=None):
        coop = self.get_object()
        if request.method == 'GET':
            membres = CooperativeMembre.objects.filter(cooperative=coop, actif=True).select_related('producteur')
            return Response(CooperativeMembreSerializer(membres, many=True).data)
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied()
        if request.user.role == Utilisateur.Role.COOPERATIVE and coop.utilisateur_id != request.user.id:
            raise PermissionDenied('Vous ne pouvez gérer que les membres de votre coopérative.')
        if request.user.role not in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.COOPERATIVE,
        ):
            raise PermissionDenied()
        ser = CooperativeMembreSerializer(data={**request.data, 'cooperative': str(coop.id)})
        ser.is_valid(raise_exception=True)
        now = timezone.now()
        obj, _ = CooperativeMembre.objects.update_or_create(
            cooperative=coop,
            producteur=ser.validated_data['producteur'],
            defaults={
                'date_adhesion': ser.validated_data.get('date_adhesion') or timezone.localdate(),
                'actif': True,
                'created_at': now,
            },
        )
        Producteur.objects.filter(pk=obj.producteur_id).update(cooperative=coop, updated_at=now)
        return Response(CooperativeMembreSerializer(obj).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='membres/retirer')
    def retirer_membre(self, request, pk=None):
        coop = self.get_object()
        if request.user.role == Utilisateur.Role.COOPERATIVE and coop.utilisateur_id != request.user.id:
            raise PermissionDenied('Vous ne pouvez gérer que les membres de votre coopérative.')
        if request.user.role not in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.COOPERATIVE,
        ):
            raise PermissionDenied()
        producteur_id = request.data.get('producteur')
        if not producteur_id:
            raise ValidationError({'producteur': 'Requis.'})
        now = timezone.now()
        CooperativeMembre.objects.filter(cooperative=coop, producteur_id=producteur_id).update(actif=False)
        Producteur.objects.filter(pk=producteur_id, cooperative=coop).update(
            cooperative=None, updated_at=now,
        )
        return Response({'detail': 'Membre retiré.'})

    @action(detail=True, methods=['post'], url_path='demander-adhesion', permission_classes=[IsAuthenticated])
    def demander_adhesion(self, request, pk=None):
        coop = self.get_object()
        if request.user.role != Utilisateur.Role.PRODUCTEUR:
            raise PermissionDenied('Seuls les producteurs peuvent demander à rejoindre une coopérative.')
        prod = Producteur.objects.filter(utilisateur_id=request.user.id, deleted_at__isnull=True).first()
        if not prod:
            raise ValidationError({'detail': 'Aucune fiche producteur n’est liée à votre compte.'})
        from pnlf_platform.services import creer_notification
        if coop.utilisateur_id:
            creer_notification(
                coop.utilisateur_id,
                'Demande d’adhésion',
                f'{prod.prenoms} {prod.nom} ({prod.code_producteur}) souhaite rejoindre {coop.nom}.',
            )
        return Response({'detail': 'Demande transmise à la coopérative.'}, status=status.HTTP_201_CREATED)


def _normaliser_entetes(entetes: list) -> list:
    return [(str(e or '')).strip().lower() for e in entetes]


def _lire_lignes_csv(fichier):
    import csv
    import io

    contenu = fichier.read().decode('utf-8-sig', errors='replace')
    lecteur = csv.reader(io.StringIO(contenu), delimiter=';' if ';' in contenu.splitlines()[0] else ',')
    lignes = list(lecteur)
    if not lignes:
        return
    entetes = _normaliser_entetes(lignes[0])
    for ligne in lignes[1:]:
        if not any((c or '').strip() for c in ligne):
            continue
        yield dict(zip(entetes, ligne))


def _lire_lignes_xlsx(fichier):
    from openpyxl import load_workbook

    classeur = load_workbook(filename=fichier, data_only=True, read_only=True)
    feuille = classeur.active
    lignes_iter = feuille.iter_rows(values_only=True)
    try:
        entetes = _normaliser_entetes(list(next(lignes_iter)))
    except StopIteration:
        return
    for ligne in lignes_iter:
        if not any(c is not None and str(c).strip() for c in ligne):
            continue
        yield dict(zip(entetes, ligne))


class ZoneCollecteViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageZones]
    serializer_class = ZoneCollecteSerializer
    search_fields = ('libelle', 'code')
    filterset_fields = ('province', 'actif')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']
    parser_classes = [FormParser, MultiPartParser, JSONParser]

    def get_queryset(self):
        return ZoneCollecte.objects.filter(actif=True).select_related('province')

    @action(detail=False, methods=['get'], url_path='modele-import')
    def modele_import(self, request):
        import csv
        from django.http import HttpResponse

        # Pas de Content-Disposition : fichier récupéré en Blob XHR (voir export_lots_csv).
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        writer = csv.writer(response)
        writer.writerow(['code', 'libelle', 'province_code', 'description', 'latitude', 'longitude'])
        writer.writerow(['ZC-EXEMPLE', 'Forêt de Minkébé — secteur nord', 'WOL', 'Zone d’exemple', '-0.5546', '11.6642'])
        return response

    def perform_create(self, serializer):
        now = timezone.now()
        extra = {}
        if not serializer.validated_data.get('code'):
            extra['code'] = f'ZC-{uuid.uuid4().hex[:8].upper()}'
        zone = serializer.save(created_at=now, updated_at=now, **extra)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='CREATE', table_cible='zones_collecte',
            enregistrement_id=zone.id, ip_adresse=ip, user_agent=ua,
        )

    def perform_update(self, serializer):
        if self.request.user.role in (
            Utilisateur.Role.PRODUCTEUR,
            Utilisateur.Role.COOPERATIVE,
        ):
            raise PermissionDenied(
                'Vous pouvez déclarer une nouvelle zone depuis le formulaire de lot, '
                'pas modifier le référentiel existant.'
            )
        zone = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=self.request.user.id, action='UPDATE', table_cible='zones_collecte',
            enregistrement_id=zone.id, ip_adresse=ip, user_agent=ua,
        )

    @action(detail=False, methods=['post'], url_path='import', permission_classes=[CanImportZones])
    def import_fichier(self, request):
        """Import en masse de zones de collecte depuis un fichier CSV ou XLSX.

        Colonnes attendues (en-tête, insensible à la casse, ordre libre) :
        ``code``, ``libelle``, ``province`` (code ou nom de la province),
        ``description`` (optionnel), ``latitude`` (optionnel), ``longitude`` (optionnel).
        Une ligne existante (même ``code``) est mise à jour plutôt que dupliquée.
        Réservé aux administrateurs et agents (SEC-06).
        """
        fichier = request.FILES.get('fichier')
        if not fichier:
            raise ValidationError({'fichier': 'Aucun fichier reçu.'})

        nom = (fichier.name or '').lower()
        try:
            if nom.endswith('.xlsx'):
                lignes = list(_lire_lignes_xlsx(fichier))
            else:
                lignes = list(_lire_lignes_csv(fichier))
        except Exception as exc:  # fichier corrompu / format invalide
            raise ValidationError({'fichier': f'Impossible de lire le fichier : {exc}'})

        if not lignes:
            raise ValidationError({'fichier': 'Le fichier ne contient aucune donnée exploitable.'})

        provinces_par_code = {p.code.strip().upper(): p for p in Province.objects.all()}
        provinces_par_nom = {p.nom.strip().upper(): p for p in Province.objects.all()}

        now = timezone.now()
        crees, mis_a_jour, erreurs = 0, 0, []

        for i, ligne in enumerate(lignes, start=2):  # ligne 1 = en-tête
            code = (ligne.get('code') or '').strip()
            libelle = (ligne.get('libelle') or '').strip()
            province_ref = (ligne.get('province') or '').strip()
            if not code or not libelle or not province_ref:
                erreurs.append(f'Ligne {i} : code, libellé et province sont obligatoires.')
                continue
            province = provinces_par_code.get(province_ref.upper()) or provinces_par_nom.get(province_ref.upper())
            if not province:
                erreurs.append(f'Ligne {i} : province « {province_ref} » introuvable.')
                continue

            def _parse_coord(valeur):
                valeur = (str(valeur).strip() if valeur is not None else '')
                if not valeur:
                    return None
                try:
                    return round(float(valeur.replace(',', '.')), 7)
                except ValueError:
                    return '__INVALID__'

            latitude = _parse_coord(ligne.get('latitude'))
            longitude = _parse_coord(ligne.get('longitude'))
            if latitude == '__INVALID__' or longitude == '__INVALID__':
                erreurs.append(f'Ligne {i} : coordonnées GPS invalides.')
                continue

            defaults = {
                'libelle': libelle,
                'province': province,
                'description': (ligne.get('description') or '').strip() or None,
                'latitude': latitude,
                'longitude': longitude,
                'actif': True,
                'updated_at': now,
            }
            existante = ZoneCollecte.objects.filter(code=code).first()
            if existante:
                for champ, valeur in defaults.items():
                    setattr(existante, champ, valeur)
                existante.save(update_fields=list(defaults.keys()))
                mis_a_jour += 1
            else:
                ZoneCollecte.objects.create(code=code, created_at=now, **defaults)
                crees += 1

        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='IMPORT', table_cible='zones_collecte',
            ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'crees': crees, 'mis_a_jour': mis_a_jour, 'erreurs': len(erreurs)},
        )
        return Response({
            'crees': crees,
            'mis_a_jour': mis_a_jour,
            'total_lignes': len(lignes),
            'erreurs': erreurs,
        })


class ProducteurViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageProducteurs]
    serializer_class = ProducteurSerializer
    search_fields = ('nom', 'prenoms', 'code_producteur', 'telephone')
    filterset_fields = ('province', 'statut', 'cooperative')

    def get_queryset(self):
        qs = Producteur.objects.filter(deleted_at__isnull=True).select_related('province')
        user = self.request.user
        if self.request.query_params.get('candidats_adhesion') == '1' and user.role in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.COOPERATIVE,
        ):
            qs = qs.filter(statut='ACTIF', cooperative__isnull=True)
            return qs
        return scope_producteurs_qs(qs, user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if request.method not in ('GET', 'HEAD', 'OPTIONS') and not user_can_access_producteur(request.user, obj):
            raise PermissionDenied('Accès refusé à ce producteur.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {'created_at': now, 'updated_at': now, 'sync_statut': 'SYNCED', 'statut': 'EN_VALIDATION'}
        if user.role == Utilisateur.Role.PRODUCTEUR:
            extra['utilisateur_id'] = user.id
        obj = serializer.save(**extra)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='producteurs',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'code_producteur': obj.code_producteur},
        )

    def perform_update(self, serializer):
        user = self.request.user
        instance = self.get_object()
        if user.role == Utilisateur.Role.PRODUCTEUR and instance.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre fiche.')
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        # SEC-15 : un producteur ne peut pas s'auto-rattacher à une coopérative.
        if user.role == Utilisateur.Role.PRODUCTEUR and 'cooperative' in serializer.validated_data:
            raise PermissionDenied(
                'Le rattachement à une coopérative se fait via le workflow d’adhésion.'
            )
        obj = serializer.save(updated_at=timezone.now())
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE', table_cible='producteurs',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
        )

    def perform_destroy(self, instance):
        user = self.request.user
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='SOFT_DELETE', table_cible='producteurs',
            enregistrement_id=instance.id, ip_adresse=ip, user_agent=ua,
        )

    @action(detail=True, methods=['post'], url_path='pdf')
    def pdf(self, request, pk=None):
        """Génère et renvoie directement la fiche PDF de ce producteur/collecteur (octets bruts).

        Le frontend récupère ce PDF en Blob authentifié puis l'affiche dans un aperçu
        intégré à la page (plus robuste multi-navigateurs que la navigation d'un onglet
        ouvert via window.open(), que Chrome peut bloquer/annuler silencieusement).
        """
        from pnlf_platform.pdf_export import producteur_fiche_pdf_bytes

        prod = self.get_object()
        try:
            pdf, filename = producteur_fiche_pdf_bytes(prod)
        except Exception:
            return Response({'detail': 'Impossible de générer la fiche PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['post'], url_path='pdf-liste')
    def pdf_liste(self, request):
        """Génère et renvoie directement la liste PDF des producteurs/collecteurs visibles."""
        from pnlf_platform.pdf_export import producteurs_liste_pdf_bytes

        qs = self.filter_queryset(self.get_queryset())
        try:
            pdf, filename = producteurs_liste_pdf_bytes(qs)
        except Exception:
            return Response({'detail': 'Impossible de générer la liste PDF.'}, status=500)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='EXPORT', table_cible='producteurs',
            ip_adresse=ip, user_agent=ua, nouvelles_valeurs={'format': 'pdf'},
        )
        from pnlf_platform.pdf_export import pdf_file_response

        return pdf_file_response(pdf, filename)

    @action(detail=False, methods=['get'], url_path='en-attente/compte', permission_classes=[CanValidateProducteurs])
    def en_attente_compte(self, request):
        """Nombre de demandes d'inscription (producteurs/collecteurs + coopératives) non encore traitées.

        Utilisé par la cloche de notifications du back-office pour afficher un
        compteur fiable, indépendant du statut de lecture des notifications.
        """
        nb_producteurs = Producteur.objects.filter(deleted_at__isnull=True, statut='EN_VALIDATION').count()
        nb_cooperatives = 0
        if request.user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE):
            try:
                nb_cooperatives = Cooperative.objects.filter(statut='EN_VALIDATION').count()
            except DatabaseError:
                # Filet de sécurité tant que la migration 07_cooperatives_statut.sql
                # (colonne « statut ») n'a pas encore été appliquée en base.
                nb_cooperatives = Cooperative.objects.filter(actif=False).count()
        return Response({
            'producteurs_en_attente': nb_producteurs,
            'cooperatives_en_attente': nb_cooperatives,
            'total': nb_producteurs + nb_cooperatives,
        })

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def valider(self, request, pk=None):
        prod = self.get_object()
        now = timezone.now()
        prod.statut = 'ACTIF'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.updated_at = now
        prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'updated_at'])
        _activer_compte_lie(prod.utilisateur_id, type_libelle='producteur/collecteur')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='VALIDATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def desactiver(self, request, pk=None):
        """Désactive un producteur/collecteur actif (le retire de l'annuaire public et bloque son compte)."""
        prod = self.get_object()
        if prod.statut != 'ACTIF':
            raise ValidationError({'detail': 'Seule une fiche active peut être désactivée.'})
        now = timezone.now()
        prod.statut = 'INACTIF'
        prod.updated_at = now
        prod.save(update_fields=['statut', 'updated_at'])
        if prod.utilisateur_id:
            Utilisateur.objects.filter(pk=prod.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.INACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='DEACTIVATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def activer(self, request, pk=None):
        """Réactive un producteur/collecteur précédemment désactivé."""
        prod = self.get_object()
        if prod.statut != 'INACTIF':
            raise ValidationError({'detail': 'Seule une fiche inactive peut être réactivée.'})
        now = timezone.now()
        prod.statut = 'ACTIF'
        prod.updated_at = now
        prod.save(update_fields=['statut', 'updated_at'])
        if prod.utilisateur_id:
            Utilisateur.objects.filter(pk=prod.utilisateur_id, deleted_at__isnull=True).update(
                statut=Utilisateur.Statut.ACTIF, updated_at=now,
            )
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='ACTIVATE', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateProducteurs])
    def rejeter(self, request, pk=None):
        prod = self.get_object()
        now = timezone.now()
        motif = (request.data.get('motif') or '').strip()
        prod.statut = 'REJETE'
        prod.valide_par_id = request.user.id
        prod.valide_at = now
        prod.notes = motif or prod.notes
        prod.updated_at = now
        prod.save(update_fields=['statut', 'valide_par_id', 'valide_at', 'notes', 'updated_at'])
        _rejeter_compte_lie(prod.utilisateur_id, type_libelle='producteur/collecteur', motif=motif)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=request.user.id, action='REJECT', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photo(self, request, pk=None):
        """Upload de la photo de profil (producteur/collecteur lui-même, agent ou admin)."""
        prod = self.get_object()
        user = request.user
        if user.role == Utilisateur.Role.PRODUCTEUR and prod.utilisateur_id != user.id:
            raise PermissionDenied('Vous ne pouvez modifier que votre propre photo.')
        if user.role in (Utilisateur.Role.ACHETEUR, Utilisateur.Role.COOPERATIVE):
            raise PermissionDenied('Action non autorisée.')
        fichier = request.FILES.get('photo')
        if not fichier:
            raise ValidationError({'photo': 'Fichier « photo » manquant.'})
        enregistrer_photo(fichier, 'producteurs', prod.id)
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(user), action='UPDATE_PHOTO', table_cible='producteurs',
            enregistrement_id=prod.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(ProducteurSerializer(prod, context={'request': request}).data)


class LotViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = LotSerializer
    search_fields = ('code_lot', 'uuid_public')
    filterset_fields = ('produit', 'producteur', 'statut', 'cooperative', 'zone_collecte')

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def get_queryset(self):
        qs = (
            Lot.objects.filter(deleted_at__isnull=True)
            .select_related('produit', 'producteur', 'producteur__province', 'zone_collecte')
            .prefetch_related('mouvements')
        )
        return scope_lots_qs(qs, self.request.user)

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)
        if request.method not in ('GET', 'HEAD', 'OPTIONS') and not user_can_access_lot(request.user, obj):
            raise PermissionDenied('Accès refusé à ce lot.')

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        producteur = serializer.validated_data.get('producteur')
        if user.role == Utilisateur.Role.PRODUCTEUR:
            if not producteur or producteur.utilisateur_id != user.id:
                raise PermissionDenied('Lot autorisé uniquement pour votre profil.')
        elif user.role == Utilisateur.Role.COOPERATIVE:
            if not producteur:
                raise PermissionDenied('Indiquez le producteur membre concerné.')
            from .models import Cooperative
            coop_ids = set(
                Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            )
            if producteur.cooperative_id not in coop_ids:
                raise PermissionDenied('Ce producteur n’appartient pas à votre coopérative.')
        extra = {}
        if not serializer.validated_data.get('cooperative') and producteur and producteur.cooperative_id:
            extra['cooperative_id'] = producteur.cooperative_id
        zone = serializer.validated_data.get('zone_collecte')
        if zone and serializer.validated_data.get('latitude') is None and zone.latitude is not None:
            extra['latitude'] = zone.latitude
            extra['longitude'] = zone.longitude
        extra['statut'] = 'BROUILLON' if self.request.data.get('brouillon') in (True, 'true', '1', 'True') else 'DECLARE'
        # Code unique côté appli : évite l'INSERT avec code_lot='' (contrainte UNIQUE
        # + lots orphelins vides en prod si le trigger SQL ne s'applique pas).
        code_lot = (
            f"PNLF-{now.strftime('%Y%m%d')}-{uuid.uuid4().hex[:10].upper()}"
        )
        lot = serializer.save(
            created_at=now, updated_at=now, sync_statut='SYNCED',
            declare_par_id=user.id, code_lot=code_lot,
            **extra,
        )
        lot.refresh_from_db()
        from .services import generer_qr_payload
        lot.qr_payload = generer_qr_payload(lot)
        lot.save(update_fields=['qr_payload'])
        generer_qr_image(lot)
        if lot.statut != 'BROUILLON':
            Mouvement.objects.create(
                lot=lot, type_mouvement='COLLECTE', date_mouvement=now,
                lieu_libelle=(lot.zone_collecte.libelle if lot.zone_collecte_id else 'Déclaration initiale'),
                quantite=lot.quantite, unite=lot.unite,
                latitude=lot.latitude, longitude=lot.longitude,
                acteur_utilisateur_id=user.id, acteur_producteur_id=lot.producteur_id,
                created_at=now, sync_statut='SYNCED',
            )
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'code_lot': lot.code_lot},
        )

    def perform_update(self, serializer):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        # Interdit de réaffecter producteur / coopérative après création (SEC-05).
        instance = serializer.instance
        for field in ('producteur', 'cooperative'):
            if field in serializer.validated_data and serializer.validated_data[field] != getattr(instance, field):
                raise PermissionDenied(
                    f'Le champ « {field} » ne peut pas être modifié après la création du lot.'
                )
            serializer.validated_data.pop(field, None)
        serializer.save(updated_at=timezone.now())

    def perform_destroy(self, instance):
        if self.request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        instance.deleted_at = timezone.now()
        instance.updated_at = timezone.now()
        instance.save(update_fields=['deleted_at', 'updated_at'])

    @action(detail=True, methods=['get'], url_path='tracabilite')
    def tracabilite(self, request, pk=None):
        lot = self.get_object()
        return Response(LotSerializer(lot, context={'request': request}).data)

    @action(detail=True, methods=['get'], url_path='qr')
    def qr(self, request, pk=None):
        lot = self.get_object()
        return FileResponse(
            __import__('io').BytesIO(qr_image_bytes(lot)),
            content_type='image/png',
            as_attachment=False,
            filename=f'{lot.code_lot}.png',
        )

    @action(detail=True, methods=['post'], url_path='changer-statut')
    def changer_statut(self, request, pk=None):
        lot = self.get_object()
        if request.user.role not in (
            Utilisateur.Role.ADMINISTRATEUR,
            Utilisateur.Role.AGENT_MINISTERE,
            Utilisateur.Role.AGENT_FORESTIER,
        ):
            raise PermissionDenied()
        nouveau = request.data.get('statut')
        force = request.data.get('force', False)
        transition_lot_statut(lot, nouveau, force=bool(force))
        return Response(LotSerializer(lot, context={'request': request}).data)

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def photos(self, request, pk=None):
        """Upload d'1 à 2 photos illustrant la marchandise du lot (comble les emplacements libres)."""
        lot = self.get_object()
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        fichiers = request.FILES.getlist('photos') or ([request.FILES['photo']] if 'photo' in request.FILES else [])
        if not fichiers:
            raise ValidationError({'photos': 'Au moins un fichier « photos » requis.'})
        emplacements_libres = [i for i in (1, 2) if not chemin_photo('lots', lot.id, suffixe=f'_{i}').exists()]
        if len(fichiers) > len(emplacements_libres):
            raise ValidationError({
                'photos': f'Il ne reste que {len(emplacements_libres)} emplacement(s) photo disponible(s) (2 maximum par lot).',
            })
        for index, fichier in zip(emplacements_libres, fichiers):
            enregistrer_photo(fichier, 'lots', lot.id, suffixe=f'_{index}')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='UPDATE_PHOTO', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(LotSerializer(lot, context={'request': request}).data)

    @photos.mapping.delete
    def supprimer_photo(self, request, pk=None):
        """Retire une des photos du lot (paramètre ?index=1|2)."""
        lot = self.get_object()
        if request.user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Action non autorisée.')
        try:
            index = int(request.query_params.get('index', ''))
        except (TypeError, ValueError):
            raise ValidationError({'index': 'Paramètre "index" (1 ou 2) requis.'})
        if index not in (1, 2):
            raise ValidationError({'index': 'Paramètre "index" doit être 1 ou 2.'})
        chemin = chemin_photo('lots', lot.id, suffixe=f'_{index}')
        if chemin.exists():
            chemin.unlink()
        media_store.supprimer(f'photos/lots/{lot.id}_{index}.jpg')
        ip, ua = request_meta(request)
        write_audit(
            utilisateur_id=_user_id(request.user), action='DELETE_PHOTO', table_cible='lots',
            enregistrement_id=lot.id, ip_adresse=ip, user_agent=ua,
        )
        return Response(LotSerializer(lot, context={'request': request}).data)


class MouvementViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageLots]
    serializer_class = MouvementSerializer
    http_method_names = ['get', 'post', 'head', 'options']
    filterset_fields = ('lot', 'type_mouvement')

    def get_queryset(self):
        qs = Mouvement.objects.select_related('lot', 'lot__producteur').filter(lot__deleted_at__isnull=True)
        return scope_mouvements_qs(qs, self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == Utilisateur.Role.ACHETEUR:
            raise PermissionDenied('Lecture seule.')
        lot = serializer.validated_data.get('lot')
        if lot is None:
            raise ValidationError({'lot': 'Lot obligatoire.'})
        if lot.deleted_at is not None:
            raise ValidationError({'lot': 'Lot archivé.'})
        if not user_can_access_lot(user, lot):
            raise PermissionDenied('Accès refusé à ce lot.')
        type_mvt = valider_type_mouvement(serializer.validated_data.get('type_mouvement'))
        now = timezone.now()
        obj = serializer.save(
            created_at=now, sync_statut='SYNCED', acteur_utilisateur_id=user.id,
            type_mouvement=type_mvt,
            date_mouvement=serializer.validated_data.get('date_mouvement') or now,
        )
        appliquer_mouvement_sur_lot(lot, type_mvt)
        ip, ua = request_meta(self.request)
        write_audit(
            utilisateur_id=_user_id(user), action='CREATE', table_cible='mouvements',
            enregistrement_id=obj.id, ip_adresse=ip, user_agent=ua,
            nouvelles_valeurs={'type_mouvement': type_mvt},
        )


class TypeCertificationViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [CanManageCertifications]
    queryset = TypeCertification.objects.filter(actif=True)
    serializer_class = TypeCertificationSerializer
    search_fields = ('libelle', 'code')


class CertificationViewSet(viewsets.ModelViewSet):
    permission_classes = [CanManageCertifications]
    serializer_class = CertificationSerializer
    filterset_fields = ('statut', 'lot', 'producteur', 'type_certification')
    http_method_names = ['get', 'post', 'put', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = Certification.objects.select_related('type_certification', 'lot', 'producteur')
        user = self.request.user
        if user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER):
            return qs
        if user.role == Utilisateur.Role.COOPERATIVE:
            from traceability.models import Cooperative
            coop_ids = Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            return qs.filter(lot__cooperative_id__in=coop_ids) | qs.filter(producteur__cooperative_id__in=coop_ids)
        if user.role == Utilisateur.Role.PRODUCTEUR:
            return qs.filter(producteur__utilisateur_id=user.id)
        return qs.none()

    def perform_create(self, serializer):
        user = self.request.user
        now = timezone.now()
        extra = {
            'created_at': now,
            'updated_at': now,
            'date_demande': timezone.localdate(),
            'statut': 'DEMANDEE',
        }
        if user.role == Utilisateur.Role.PRODUCTEUR:
            prod = Producteur.objects.filter(
                utilisateur_id=user.id, deleted_at__isnull=True,
            ).first()
            if not prod:
                raise ValidationError({
                    'producteur': 'Aucune fiche producteur n’est liée à votre compte.',
                })
            extra['producteur'] = prod
        elif user.role == Utilisateur.Role.COOPERATIVE:
            prod = serializer.validated_data.get('producteur')
            if not prod:
                raise ValidationError({'producteur': 'Indiquez le producteur membre concerné.'})
            from traceability.models import Cooperative
            coop_ids = set(
                Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True)
            )
            if prod.cooperative_id not in coop_ids:
                raise PermissionDenied('Ce producteur n’appartient pas à votre coopérative.')
        serializer.save(**extra)

    def perform_update(self, serializer):
        user = self.request.user
        nouveau_statut = serializer.validated_data.get('statut')
        if nouveau_statut and nouveau_statut != self.get_object().statut:
            if user.role not in (
                Utilisateur.Role.ADMINISTRATEUR,
                Utilisateur.Role.AGENT_MINISTERE,
            ):
                raise PermissionDenied(
                    'Seuls un administrateur ou un agent du ministère peuvent valider une certification.'
                )
        serializer.save(updated_at=timezone.now())

    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser, FormParser])
    def document(self, request, pk=None):
        """Joindre ou remplacer le document justificatif d'une certification (PDF/JPG/PNG)."""
        cert = self.get_object()
        user = request.user
        est_proprietaire = bool(
            cert.producteur_id
            and Producteur.objects.filter(id=cert.producteur_id, utilisateur_id=user.id).exists()
        )
        est_coop_gestionnaire = False
        if not est_proprietaire and user.role == Utilisateur.Role.COOPERATIVE and cert.producteur_id:
            from traceability.models import Cooperative

            coop_ids = set(Cooperative.objects.filter(utilisateur_id=user.id).values_list('id', flat=True))
            est_coop_gestionnaire = cert.producteur.cooperative_id in coop_ids
        if not (
            est_proprietaire
            or est_coop_gestionnaire
            or user.role in (Utilisateur.Role.ADMINISTRATEUR, Utilisateur.Role.AGENT_MINISTERE, Utilisateur.Role.AGENT_FORESTIER)
        ):
            raise PermissionDenied("Vous n'êtes pas autorisé à modifier ce document.")
        fichier = request.FILES.get('document')
        if not fichier:
            raise ValidationError({'document': 'Aucun fichier reçu.'})
        from .services import enregistrer_document

        rel = enregistrer_document(fichier, 'certifications', cert.id)
        cert.document_path = rel
        cert.updated_at = timezone.now()
        cert.save(update_fields=['document_path', 'updated_at'])
        return Response(CertificationSerializer(cert, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCertifications])
    def valider(self, request, pk=None):
        cert = self.get_object()
        if cert.statut not in ('DEMANDEE', 'EN_COURS'):
            raise ValidationError({'detail': 'Cette demande a déjà été traitée.'})
        now = timezone.now()
        cert.statut = 'OBTENUE'
        cert.date_obtention = timezone.localdate()
        cert.valide_par_id = request.user.id
        cert.updated_at = now
        numero = (request.data.get('numero_certificat') or '').strip()
        if numero:
            cert.numero_certificat = numero
        cert.save()
        return Response(CertificationSerializer(cert).data)

    @action(detail=True, methods=['post'], permission_classes=[CanValidateCertifications])
    def refuser(self, request, pk=None):
        cert = self.get_object()
        if cert.statut not in ('DEMANDEE', 'EN_COURS'):
            raise ValidationError({'detail': 'Cette demande a déjà été traitée.'})
        cert.statut = 'REFUSEE'
        cert.updated_at = timezone.now()
        cert.valide_par_id = request.user.id
        motif = (request.data.get('motif') or '').strip()
        if motif:
            cert.observations = ((cert.observations or '') + f'\nRefus : {motif}').strip()
        cert.save()
        return Response(CertificationSerializer(cert).data)


class LotVerifyView(generics.RetrieveAPIView):
    """Vérification publique QR — sans authentification."""
    permission_classes = [AllowAny]
    serializer_class = LotVerifySerializer
    lookup_field = 'uuid_public'

    def get_queryset(self):
        from traceability.public_views import STATUTS_LOTS_PUBLICS
        return Lot.objects.filter(
            deleted_at__isnull=True, statut__in=STATUTS_LOTS_PUBLICS,
        ).select_related(
            'produit', 'producteur', 'producteur__province'
        ).prefetch_related('mouvements')

    def retrieve(self, request, *args, **kwargs):
        try:
            lot = self.get_object()
        except Http404:
            return Response({'detail': 'Lot introuvable ou invalide.'}, status=404)
        data = self.get_serializer(lot).data
        data['authenticite'] = 'VERIFIE'
        data['mouvements_count'] = lot.mouvements.count()
        return Response(data)
