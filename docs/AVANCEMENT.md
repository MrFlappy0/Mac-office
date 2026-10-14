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

Prochaine étape : v0.3 — en-têtes et pieds de page, numérotation des pages à l'impression.
