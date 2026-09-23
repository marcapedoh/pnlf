import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { IconComponent } from '../../../../design-system/icon/icon.component';

interface FaqItem {
  question: string;
  reponse: string;
}

interface FaqGroupe {
  titre: string;
  items: FaqItem[];
}

@Component({
  selector: 'app-faq',
  standalone: true,
  imports: [RouterLink, IconComponent],
  templateUrl: './faq.component.html',
  styleUrl: './faq.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FaqComponent {
  readonly openKey = signal<string | null>('g0-0');

  readonly groupes: FaqGroupe[] = [
    {
      titre: 'À propos de la plateforme',
      items: [
        {
          question: "Qu'est-ce que la plateforme PFNL ?",
          reponse:
            "PFNL est la plateforme officielle de traçabilité des Produits Forestiers Non Ligneux (PFNL) du Gabon, portée par l'École Nationale des Eaux et Forêts (ENEF). Elle permet de suivre un produit de sa récolte jusqu'à sa commercialisation, de mettre en relation producteurs et acheteurs, et de vérifier l'authenticité d'un produit via un QR code.",
        },
        {
          question: "L'utilisation de la plateforme est-elle gratuite ?",
          reponse:
            "Oui. L'inscription, la déclaration de lots, la consultation de l'annuaire et la vérification d'authenticité sont entièrement gratuites, car il s'agit d'un service public.",
        },
      ],
    },
    {
      titre: 'Inscription et compte',
      items: [
        {
          question: 'Comment créer un compte producteur, coopérative ou acheteur ?',
          reponse:
            "Rendez-vous sur la page « S'inscrire », choisissez votre profil (producteur, collecteur, coopérative ou acheteur), renseignez vos informations et joignez les documents administratifs demandés (pièce d'identité, et selon le cas fiche circuit, agrément CITES/Nagoya, etc.). Votre dossier est ensuite examiné par un administrateur.",
        },
        {
          question: "Combien de temps prend la validation d'un dossier ?",
          reponse:
            "La validation est effectuée par un agent du ministère ou un administrateur après vérification des informations et documents fournis. Vous recevez un e-mail et un SMS dès que votre compte est activé ou si des informations complémentaires sont nécessaires.",
        },
        {
          question: "Quels documents administratifs dois-je fournir ?",
          reponse:
            "Selon votre profil : une copie de votre pièce d'identité (CNI) est toujours demandée. Les producteurs/collecteurs peuvent également joindre leur fiche circuit, et les acteurs manipulant des espèces protégées un agrément CITES/Nagoya ou toute autorisation d'exploitation en vigueur.",
        },
        {
          question: 'J\'ai oublié mon mot de passe, que faire ?',
          reponse:
            'Utilisez le lien « Mot de passe oublié » sur la page de connexion. Un e-mail de réinitialisation vous sera envoyé.',
        },
      ],
    },
    {
      titre: 'Traçabilité et vérification',
      items: [
        {
          question: 'Comment déclarer un lot et obtenir un QR code ?',
          reponse:
            "Depuis votre espace « Lots », cliquez sur « Déclarer un lot », renseignez le produit, la quantité et l'origine. Une fois le lot enregistré, un QR code unique est généré automatiquement et peut être imprimé pour être apposé sur l'emballage.",
        },
        {
          question: "Comment vérifier l'authenticité d'un produit ?",
          reponse:
            "Rendez-vous sur la page « Vérifier un produit », puis scannez le QR code avec votre appareil photo, importez une photo du QR code, ou saisissez manuellement le code de traçabilité affiché sur l'emballage.",
        },
      ],
    },
    {
      titre: 'Offres, demandes et mise en relation',
      items: [
        {
          question: 'Comment contacter un producteur ou répondre à une offre ?',
          reponse:
            "Depuis l'annuaire public ou la fiche d'une annonce, utilisez le bouton de contact pour ouvrir une discussion via la messagerie intégrée à la plateforme.",
        },
        {
          question: 'Puis-je publier une demande en tant qu\'acheteur ?',
          reponse:
            'Oui, depuis votre espace « Offres & demandes », vous pouvez publier une demande d\'achat qui sera visible par les producteurs et coopératives inscrits.',
        },
      ],
    },
    {
      titre: 'Confidentialité et sécurité',
      items: [
        {
          question: 'Mes données personnelles sont-elles protégées ?',
          reponse:
            "Oui. Consultez notre politique de confidentialité pour le détail des données collectées, de leur usage et de vos droits.",
        },
      ],
    },
  ];

  toggle(key: string): void {
    this.openKey.update((current) => (current === key ? null : key));
  }

  isOpen(key: string): boolean {
    return this.openKey() === key;
  }
}
