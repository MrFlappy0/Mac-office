<div align="center">

# Paper

**Traitement de texte open source pour macOS, 100 % natif.**

Interface à onglets façon Word (Accueil, Insertion, Mise en page, Affichage) sur le design Apple de Pages, portée par une coquille native Swift/AppKit : fenêtres, menus, fichiers, impression. Le format se choisit au moment d'enregistrer — **Word (.docx) par défaut**.

`Swift` `AppKit` `WebKit` `Onglets` `Zéro dépendance` `Open source (MIT)`

[![macOS](https://img.shields.io/badge/macOS-12%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos) [![Version](https://img.shields.io/badge/version-0.8-0a66c2)](../../releases) [![Licence](https://img.shields.io/badge/licence-MIT-green)](LICENSE) [![Release](https://img.shields.io/badge/release-DMG%20auto--publi%C3%A9-blueviolet)](../../releases)

</div>

---

## Sommaire

1. [Installation](#installation)
2. [Philosophie](#philosophie)
3. [Fonctionnalités](#fonctionnalités)
4. [Formats de documents](#formats-de-documents)
5. [Réglages](#réglages)
6. [Raccourcis clavier](#raccourcis-clavier)
7. [Architecture](#architecture)
8. [Versions](#versions)

## Installation

Dernière version en DMG sur la [page des releases](../../releases), publiée automatiquement à chaque version par GitHub Actions.

1. Ouvrez le DMG, faites glisser `Paper.app` dans `Applications`.
2. Au premier lancement, si macOS signale l'absence de signature de développeur : **clic droit → Ouvrir**.

Compiler depuis les sources (Xcode Command Line Tools, macOS 12+) :

```bash
git clone https://github.com/MrFlappy0/Mac-office.git
cd Mac-office
./build.sh
open Paper.app
```

## Philosophie

- **Ergonomie Word 365** : titre de document éditable avec état de sauvegarde en temps réel, recherche de commandes Tell Me, ruban structuré en groupes (Presse-papiers, Police, Paragraphe, Styles rapides, Édition), règles graduées avec poignées de marges, sauts de page visuels, barre d'état complète (pages, mots, langue, zoom).
- **Machine à états d'enregistrement** : clean / dirty / saving / error — Cmd+S, autosauvegarde 2 s, protection beforeunload, réessai après erreur. Spécification : [docs/INTERFACE.md](docs/INTERFACE.md).
- **Coquille 100 % native** : menus, fenêtres, panneaux d'enregistrement, impression — Swift/AppKit.
- **L'extension se choisit à l'enregistrement** : un seul bouton Enregistrer ; le panneau propose Word (.docx, par défaut), Word 97 (.doc), HTML et PDF.
- **Zéro dépendance** : l'export .docx est écrit à la main (conteneur ZIP + Office Open XML), la lecture .docx passe par textutil.

## Fonctionnalités

- Mise en forme : gras, italique, souligné, barré, exposant, indice, couleurs (palette système), polices (panneau Fontes natif)
- Tailles et styles : Titres 1-3, corps de texte, interligne (simple, compact, normal, large)
- Alignements : gauche, centre, droite, justifié
- Listes à puces et numérotées (avec imbrication)
- Insertions : images, liens, date, page de garde, 54 caractères spéciaux
- Plan du document : panneau latéral des titres, clic pour naviguer
- Recherche et remplacement : barre de recherche native NSTextFinder (incrémentale)
- Correcteur orthographique, corrections automatiques (guillemets français, tirets)
- Barre d'état : mots, caractères, temps de lecture estimé
- Undo/redo complet, alertes de document non enregistré
- **Zoom** : Cmd+ / Cmd- / Cmd+0 et pincement trackpad (50 % à 300 %)
- **Export PDF direct** (Cmd+E) : pagination A4 avec marges, sans passer par l'impression
- **Documents récents** dans le menu Fichier
- Impression A4 native avec panneau macOS et format d'impression configurable

## Formats de documents

L'extension est choisie dans le panneau d'enregistrement — **par défaut : Word (.docx)**.

| Format | Ouvrir | Enregistrer | Notes |
|---|---|---|---|
| **.docx** | oui | oui | Écriture OOXML native (styles, titres, listes, couleurs, liens). Lecture via textutil |
| **.doc** | oui | oui | Word 97 binaire via AppKit, repli HTML compatible |
| **.rtf** | oui | oui | Natif |
| **.html** | oui | oui | Natif |
| **.txt** | oui | oui | Natif |

L'outil `docxprobe` (cible SwiftPM) vérifie en CI que le .docx généré est un ZIP valide lisible par macOS.

## Réglages

Menu **Paper → Réglages… (Cmd+,)** :

- Police et taille par défaut des nouveaux documents
- Marges du document
- Correcteur orthographique
- Affichage du plan du document

Les changements s'appliquent immédiatement aux documents ouverts.

## Raccourcis clavier

| Raccourci | Action |
|---|---|
| `Cmd+N` / `Cmd+O` | Nouveau / Ouvrir |
| `Cmd+S` / `Cmd+Maj+S` | Enregistrer / Enregistrer sous |
| `Cmd+E` | Exporter en PDF |
| `Cmd+P` | Imprimer |
| `Cmd+B` / `Cmd+I` / `Cmd+U` | Gras / italique / souligné |
| `Cmd+F` | Rechercher |
| `Cmd+Alt+F` | Remplacer |
| `Cmd+G` / `Cmd+Maj+G` | Occurrence suivante / précédente |
| `Cmd+Alt+Maj+V` | Coller sans mise en forme |
| `Cmd+T` | Panneau Fontes |
| `Cmd+,` | Réglages |

## Architecture

```
Package.swift              Swift Package Manager : 3 cibles
Sources/PaperCore/         Bibliothèque : formats, export .docx, styles, ZIP
Sources/Paper/            Application : AppDelegate, PaperDocument, éditeur, plan, symboles, réglages
Tools/docxprobe/          Outil de vérification CI du .docx
Resources/                Info.plist (types de documents déclarés) et icône
build.sh                  Compilation release, bundle .app, signature, DMG
VERSION                   Version courante (pilote les releases automatiques)
.github/workflows/        Build macOS + publication du DMG en release à chaque version
```

**Choix techniques**

- `PaperCore` (bibliothèque pure) : lecture/écriture des formats, générateur Office Open XML à la main (CRC32, ZIP stockage, document.xml/styles.xml/numbering.xml), styles de paragraphe. Testable et réutilisable.
- `Paper` (exécutable) : `NSDocument` pour le cycle de vie, `NSTextView` enrichi pour l'édition, actions adressées par la chaîne de répondeurs (menus et ruban partagent les mêmes sélecteurs), `UserDefaults` pour les réglages.
- Types de documents déclarés dans `Info.plist` : Paper apparaît dans le menu « Ouvrir avec » du Finder pour .docx, .doc, .rtf, .html et .txt.

## Versions

Chaque version est documentée dans [docs/AVANCEMENT.md](docs/AVANCEMENT.md) et publiée automatiquement en release avec son DMG (GitHub Actions sur runner macOS).

**Feuille de route**

- v0.6 : thème sombre, pagination multi-pages à l'écran
- v0.7 : en-têtes et pieds de page, numérotation des pages
- v0.8 : lecture .docx fidèle (sans textutil), tableaux natifs

---

Licence MIT — voir [LICENSE](LICENSE). Projet développé par Théo Noël.
