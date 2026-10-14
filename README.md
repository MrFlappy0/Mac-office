# Paper (repo Mac-office)

Traitement de texte natif pour macOS, inspiré de Microsoft Word, avec une interface à la Apple (style Pages). Application 100 % native (Swift + AppKit + WebKit), sans dépendance externe, en français.

![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![Licence](https://img.shields.io/badge/licence-MIT-green)

## Fonctionnalités

### Édition et mise en forme
- Page A4 avec marges, correction orthographique
- Gras, italique, souligné, barré, exposant, indice
- 11 polices, 9 tailles (8 à 72 pt), couleur du texte, surlignage
- **Interligne** : compact, normal, large, très large
- Styles de paragraphe : Titres 1-3, citation, code
- Alignements (gauche, centre, droite, justifié), listes à puces et numérotées, retraits
- **Collage sans mise en forme** (Cmd+Alt+Maj+V)

### Navigation et outils
- **Plan du document** : panneau latéral généré depuis les titres, clic pour naviguer
- Recherche et remplacement (occurrence par occurrence ou tout), carte flottante
- Undo/redo, zoom 75 à 200 % (clavier inclus), compteur mots/caractères/temps de lecture
- **Sauvegarde automatique** : un document non enregistré est récupéré au prochain lancement
- Messages de confirmation (barre d'état) et alertes de document non enregistré

### Tableaux
- Insertion de tableaux (dimensions au choix)
- Barre contextuelle : ajouter/supprimer lignes et colonnes, **bascule en-tête**, supprimer le tableau

### Insertions
- Liens (création et suppression), images (PNG, JPEG, GIF, TIFF)
- **Page de garde** (titre, sous-titre, date centrés)
- Lignes horizontales, date du jour, 56 caractères spéciaux (guillemets français, symboles, accents)

### Fichiers
- Ouverture : HTML, RTF, TXT, MD
- Enregistrement : HTML, **Word (.doc)**, texte brut
- Export PDF, impression avec panneau macOS
- Alertes de document non enregistré (fermeture et quit)

## Compilation

```bash
./build.sh
open Paper.app
```

Nécessite Xcode Command Line Tools (macOS 12+). Le script génère l'icône, compile, signe (ad-hoc) et empacte le .app.

## Structure

```
src/main.swift     Fenêtre, menus, fichiers, PDF, impression (AppKit/WebKit)
src/editor.html    Interface d'édition : ruban, plan, commandes JS
src/icon.swift     Génération de l'icône de l'application
src/Info.plist     Métadonnées du bundle
build.sh           Compilation, icône, signature et empactage
docs/AVANCEMENT.md Journal du projet
```

## Feuille de route

- v0.4 : préférences (police par défaut, marges), thème sombre
- v0.5 : en-têtes et pieds de page, numérotation des pages
- v0.6 : ouverture .docx, export .docx

Voir [docs/AVANCEMENT.md](docs/AVANCEMENT.md) pour le journal détaillé.

## Licence

MIT — voir [LICENSE](LICENSE).
