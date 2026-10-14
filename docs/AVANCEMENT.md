# Journal d'avancement

## v0.1 — 14 octobre 2026 — Premier build (MinWord)

Application macOS native complète : Swift/AppKit pour la coquille (fenêtre, menus, boîtes de dialogue, fichiers), WebKit pour l'éditeur.

Fait :
- Éditeur riche sur page A4 (contenteditable) avec marges type Word
- Barre d'outils : mise en forme du texte, styles de paragraphe, couleurs, listes, retraits, insertions (lien, image, tableau, ligne, date)
- Recherche et remacement, undo/redo, compteur mots/caractères, zoom 75-200 %
- Ouverture HTML/RTF/TXT/MD ; enregistrement HTML, Word (.doc), TXT ; export PDF ; impression
- Menus macOS natifs (Fichier, Édition, Format) avec raccourcis clavier
- Bundle .app signé (ad-hoc), compilation par build.sh

Prochaine étape : v0.2 — refonte de l'interface (ruban, barre de titre à la Word), plan de navigation du document, édition avancée des tableaux, sauvegarde automatique, fenêtre de caractères spéciaux, aide des raccourcis, icône d'application, renommage en Paper.

## v0.2 — 14 octobre 2026 — Refonte, renommage en Paper

Fait :
- Refonte complète de l'interface : barre de titre bleue à la Word avec actions rapides (Nouveau, Ouvrir, Enregistrer, Word, PDF, Imprimer, annuler/rétablir, recherche, plan), ruban de mise en forme épuré
- Renommage de l'application : MinWord devient Paper, nouvelle identité (bundle local.theo.paper)
- Icône d'application générée par script (P sur dégradé bleu, iconset complet 16 à 1024 px)
- Plan du document : panneau latéral construit depuis les styles Titre 1-3, clic pour naviguer, masquable
- Édition avancée des tableaux : barre contextuelle (ajouter/supprimer lignes et colonnes, supprimer le tableau)
- Sauvegarde automatique toutes les 4 secondes, proposition de restauration au lancement
- Fenêtre de caractères spéciaux (56 symboles : guillemets français, monnaie, math, accents)
- Aide des raccourcis clavier (menu Aide)
- Zoom au clavier (Cmd + / - / 0) synchronisé avec la barre d'état
- Temps de lecture estimé dans la barre d'état
- Titres colorés, citations sur fond, styles de page retravaillés

Prochaine étape : v0.3 — interface à la Apple, interligne, page de garde, en-têtes de tableau, collage sans mise en forme.

## v0.3 — 14 octobre 2026 — Interface à la Apple

Fait :
- Refonte visuelle façon Pages : barre d'outils sobre sur fond gris Apple (#f6f6f8), contrôles segmentés pour l'alignement et les listes, accent bleu système, boutons arrondis, typographie SF
- Suppression de la barre de titre bleue : le nom du document s'affiche dans la barre de titre native macOS (avec marqueur de modification)
- Recherche en carte flottante arrondie avec ombre, champs à focus bleu
- Barre d'état épurée style Apple : compteurs centrés en gris, messages de confirmation (enregistrement, remplacements, mode collage)
- Interligne réglable : compact, normal, large, très large
- Page de garde : titre, sous-titre et date centrés (menu Format)
- En-têtes de tableau : bascule première ligne td/th avec fond et gras
- Collage sans mise en forme (Cmd+Alt+Maj+V) : le prochain collage insère le texte seul
- Panneau Plan retouché (survol bleu, gras pour Titre 1)

Prochaine étape : v0.4 — interface à onglets à la Apple, export .docx natif, DMG en release automatique.

## v0.4 — 14 octobre 2026 — Onglets, .docx natif, releases automatiques

Fait :
- Interface à onglets façon Word, charte Apple : Accueil, Insertion, Mise en page, Affichage ; segments à pastille blanche active, boutons arrondis, accent bleu système, actions fichiers regroupées à droite de la barre d'onglets
- Fini le fouilli : chaque onglet n'affiche que ses contrôles ; plan masqué par défaut
- Export **.docx natif** : conteneur ZIP (stockage) et Office Open XML générés à la main en JavaScript (CRC32, styles, numérotation, tableaux, liens externes) — lisible par Word, Pages et LibreOffice
- Ouverture des .docx via NSAttributedString
- Formats recentrés sur le document : .docx, .doc, .html, PDF ; suppression du texte brut
- DMG d'installation construit par build.sh (hdiutil), version pilotée par le fichier VERSION
- Workflow GitHub Actions : à chaque version, l'app est construite sur macOS et le DMG est publié en release automatiquement
- README complet et animé (démo SVG SMIL du fonctionnement)

Prochaine étape : v0.5 — images dans l'export .docx, préférences.
