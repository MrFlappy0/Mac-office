# paper-mac

Traitement de texte natif pour macOS, inspiré de Microsoft Word. Projet personnel en cours de développement.

## État : v0.1 (MinWord)

Première version fonctionnelle. Application macOS native (Swift + AppKit + WebKit), sans dépendance externe.

### Fonctionnalités v0.1

- Éditeur riche sur page A4 avec marges
- Mise en forme : gras, italique, souligné, barré, exposant, indice
- Polices, tailles, couleur du texte, surlignage
- Styles de paragraphe : Titres 1-3, citation, code
- Alignements, listes à puces et numérotées, retraits
- Insertion : liens, images, tableaux, lignes horizontales, date
- Recherche et remplacement
- Compteur de mots et de caractères, zoom
- Ouverture : HTML, RTF, TXT, MD
- Enregistrement : HTML, Word (.doc), texte brut
- Export PDF et impression
- Menus macOS natifs avec raccourcis clavier

## Compilation

```bash
./build.sh
open MinWord.app
```

Nécessite Xcode Command Line Tools (Swift 5+, macOS 12+).

## Structure

```
src/main.swift     Fenêtre, menus, fichiers, PDF, impression (AppKit/WebKit)
src/editor.html    Interface d'édition : barre d'outils, page, commandes JS
src/Info.plist     Métadonnées du bundle
build.sh           Compilation, signature et empactage .app
```

## Feuille de route

- v0.2 : refonte de l'interface, plan de navigation du document, édition avancée des tableaux, sauvegarde automatique, icône d'application, renommage en Paper
- v0.3 : en-têtes et pieds de page, numérotation des pages
- v0.4 : thèmes clair/sombre, préférences

Voir [docs/AVANCEMENT.md](docs/AVANCEMENT.md) pour le journal détaillé.

## Licence

MIT — voir [LICENSE](LICENSE).
