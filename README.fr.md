# Wiki Tianyi pour iOS

[简体中文](README.md) | [English](README.en.md) | Français | [日本語](README.ja.md) | [한국어](README.ko.md) | [文言](README.lzh.md)

Client iPhone et iPad du **wiki non officiel du lycée Tianyi du Jiangsu**. La communauté documente l’histoire du lycée, les lieux du campus, les clubs, les événements et la culture scolaire. Ce projet ne représente ni le lycée ni la Wikimedia Foundation.

Ce dépôt est un fork de [Wikipedia iOS](https://github.com/wikimedia/wikipedia-ios). Il réutilise les services réseau, l’annulation des requêtes et le stockage de `WMFData`, ainsi que la navigation, les polices et le traitement des extraits HTML de `WMFComponents`. Une couche spécifique adapte les API MediaWiki de Tianyi. Le [README d’origine](docs/upstream-wikipedia-ios.md) et les mentions de droits sont conservés.

## Accueil natif et lecture hors ligne

L’accueil chinois est reconstruit en cartes natives avec le lettrage transparent fourni et les photos du campus. Le texte et les images sont intégrés, disponibles au premier démarrage hors ligne ; cet instantané est actualisé avec les versions. Les modifications récentes sont mises en cache : cinq articles au maximum, dernière modification de chacun uniquement.

Sous iOS 26+, les commandes de lecture utilisent glassEffect. Le mode sombre couvre légendes, tableaux et pages web de compatibilité, dont les annonces et la navigation sont masquées.

Bad Apple!! utilise AVPlayer et une animation du texte pilotée par le temps natif. La première visite télécharge musique et images binaires de l’animation et conserve le texte. Ensuite la lecture utilise les fichiers locaux, sans charger la page d’origine ; les médias liés peuvent nécessiter Internet. Effacer les articles hors ligne supprime aussi ces données.

Les commentaires conservent l’authentification et les autorisations du site. Sans zone de commentaires, l’app indique qu’ils sont désactivés, sans remplacer cette fonction par une discussion. Ils nécessitent Internet ; aucun commentaire de test n’a été publié. Les textes masqués se révèlent au toucher.

## Fonctionnalités et langues

- Sous iOS / iPadOS 26 et ultérieur, la navigation et les onglets natifs utilisent Liquid Glass et suivent les réglages système. Le fond des articles privilégie la lecture ; les systèmes antérieurs gardent un style natif compatible.
- Interface en chinois simplifié, anglais, français, japonais, coréen et chinois classique.
- Langue de l’interface et langue du wiki indépendantes : une interface française peut afficher un article chinois ou japonais.
- Recherche native, navigation sur le campus, modifications récentes et article au hasard.
- Lecture via `action=parse`, sommaire, taille du texte, partage et historique des versions.
- Le menu des langues d’un article utilise les liens interlangues existants. Il ne traduit pas automatiquement les articles sans équivalent.
- Les favoris conservent le texte hors ligne ; les images et les médias nécessitent encore une connexion. Historique local limité à 200 articles.
- Icône composée du lettrage fourni par le mainteneur sur fond blanc, sans redessiner les caractères.

| Langue du wiki | Adresse |
| --- | --- |
| 中文 | https://zh-wiki.tyzx.org |
| English | https://en-wiki.tyzx.org |
| Français | https://fr-wiki.tyzx.org |
| 日本語 | https://ja-wiki.tyzx.org |
| 한국어 | https://ko-wiki.tyzx.org |
| 文言 | https://lzh-wiki.tyzx.org |

Le contenu varie selon les sites. Certains liens interlangues pointent vers des pages encore absentes. Le client signale cette absence et propose l’accueil du wiki choisi, sans générer de traduction.

## Exécution

Xcode compatible Swift 6.2 ou ultérieur ; cible minimale iOS / iPadOS 17. Le développement a été vérifié avec Xcode 27.2.

Ouvrez **`TianyiWiki.xcodeproj`** et sélectionnez le schéma **`TianyiWiki`**. Attendez la résolution des paquets Swift. Pour un appareil physique, sélectionnez votre propre équipe Apple et adaptez l’identifiant `org.tyzx.TianyiWiki` si nécessaire. L’ancien `Wikipedia.xcodeproj` reste le projet amont, pas le point d’entrée de Tianyi.

```sh
xcodebuild -project TianyiWiki.xcodeproj -scheme TianyiWiki \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  -derivedDataPath /tmp/tyzx-fork-build CODE_SIGNING_ALLOWED=NO build
```

## État, confidentialité et licence

Version de développement, non publiée sur l’App Store. La connexion et l’édition natives, les notifications, les recommandations Wikimedia et la synchronisation ne sont pas portées. Les catégories et pages spéciales utilisent le site existant. Le texte enregistré peut être ancien et doit être actualisé manuellement.

Les favoris et l’historique restent sur l’appareil. Le client n’initialise pas les services de connexion, statistiques ou dons de Wikimedia. Les requêtes vers Tianyi et les fournisseurs de médias restent soumises à leurs pratiques de confidentialité.

Le code amont et les ajouts Tianyi utilisent la [licence MIT](LICENSE.txt), avec conservation des droits © 2013–2025 Wikimedia Foundation et al. Les images de marque, textes et médias ont leurs propres droits ; la licence du code ne les remplace pas. Avant publication, il faut encore traiter la modération, les signalements, la confidentialité, la gestion des comptes, les tests sur appareil et les obligations régionales. Voir [l’évaluation App Store](TianyiWiki/APP_STORE.md), en chinois simplifié. Une compilation réussie ne garantit pas l’acceptation par Apple.
