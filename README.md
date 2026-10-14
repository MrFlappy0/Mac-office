<div align="center">

# Paper

**Traitement de texte open source pour macOS, 100 % natif.**

Refonte complète en Swift/AppKit : plus de WebView, plus de HTML — un vrai `NSDocument` + `NSTextView`, comme TextEdit, avec tout le confort d'un traitement de texte moderne.

`Swift` `AppKit` `NSDocument` `Zéro dépendance` `Open source (MIT)`

[![macOS](https://img.shields.io/badge/macOS-12%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos) [![Version](https://img.shields.io/badge/version-0.6-0a66c2)](../../releases) [![Licence](https://img.shields.io/badge/licence-MIT-green)](LICENSE) [![Release](https://img.shields.io/badge/release-DMG%20auto--publi%C3%A9-blueviolet)](../../releases)

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

- **100 % natif** : Swift + AppKit uniquement. La consommation mémoire et la réactivité sont celles d'un composant système, pas d'un navigateur embarqué.
- **Vraie application document** : `NSDocument` apporte l'enregistrement, la gestion des fenêtres, les alertes de fermeture, l'undo natif.
- **L'extension se choisit à l'enregistrement** : plus de boutons de format dans l'interface. Un seul bouton Enregistrer ; le panneau propose les formats, **Word (.docx) par défaut**.
- **Zéro dépendance** : même l'export .docx est écrit à la main (conteneur ZIP + Office Open XML).

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
