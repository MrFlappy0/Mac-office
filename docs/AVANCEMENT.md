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
