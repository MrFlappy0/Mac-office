# Paper (paper-mac)

Traitement de texte natif pour macOS, inspiré de Microsoft Word. Application 100 % native (Swift + AppKit + WebKit), sans dépendance externe, en français.

![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![Licence](https://img.shields.io/badge/licence-MIT-green)

## Fonctionnalités

### Édition et mise en forme
- Page A4 avec marges, correction orthographique
- Gras, italique, souligné, barré, exposant, indice
- 11 polices, 9 tailles (8 à 72 pt), couleur du texte, surlignage
- Styles de paragraphe : Titres 1-3, citation, code
- Alignements (gauche, centre, droite, justifié), listes à puces et numérotées, retraits

### Navigation et outils
- **Plan du document** : panneau latéral généré depuis les titres, clic pour naviguer
- Recherche et remplacement (occurrence par occurrence ou tout)
- Undo/redo, zoom 75 à 200 % (clavier inclus), compteur mots/caractères/temps de lecture
- **Sauvegarde automatique** : un document non enregistré est récupéré au prochain lancement

### Tableaux
- Insertion de tableaux (dimensions au choix)
- Barre contextuelle : ajouter/supprimer lignes et colonnes, supprimer le tableau

### Insertions
- Liens (création et suppression), images (PNG, JPEG, GIF, TIFF)
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

- v0.3 : en-têtes et pieds de page, numérotation des pages
- v0.4 : préférences (police par défaut, marges), thème sombre
- v0.5 : ouverture .docx, export .docx

Voir [docs/AVANCEMENT.md](docs/AVANCEMENT.md) pour le journal détaillé.

## Licence

MIT — voir [LICENSE](LICENSE).
