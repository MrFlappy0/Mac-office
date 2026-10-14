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

Prochaine étape : v0.5 — refonte 100 % Swift natif, extension choisie à l'enregistrement, menu Réglages.

## v0.5 — 14 octobre 2026 — Refonte complète en Swift natif

Fait :
- Application entièrement réécrite en Swift/AppKit : plus de WebView ni d'HTML ; NSTextView riche et NSDocument, comme les applications système (consommation et réactivité améliorées)
- Structure de projet standard du marché : Swift Package Manager, cible PaperCore (formats, export .docx, styles, ZIP) + cible Paper (application) + cible docxprobe (vérification CI)
- L'extension est choisie uniquement au moment de l'enregistrement (panneau natif) : suppression de tous les boutons de format de l'interface, par défaut Word (.docx) ; .doc, .rtf, .html et .txt proposés
- Menu Réglages (Cmd+,) : police et taille par défaut, marges, correcteur orthographique, plan du document
- Plan de navigation natif (NSTableView), barre d'état mots/caractères/temps de lecture, panneau de symboles
- Recherche native NSTextFinder (barre incrémentale), panneau Fontes et Couleurs système
- Correction du build DMG sur GitHub : l'icône est générée une fois et committée (Resources/Paper.icns) — la génération via AppKit NSImage échoue sur les runners sans serveur d'affichage ; build basé sur SwiftPM, vérification du .docx en CI (unzip + docxprobe)
- Le générateur .docx a été porté en Swift et validé : ZIP intègre (unzip -t), listes et titres relus par textutil

Prochaine étape : v0.6 — correctif d'ouverture, zoom, export PDF direct, documents récents.

## v0.6 — 14 octobre 2026 — Correctif d'ouverture et fonctions quotidiennes

Corrigé :
- **Ouverture impossible au lancement** (« Aucun document n'a pu être créé ») : en Swift pur, le nom runtime de la classe est `Paper.PaperDocument`, donc `NSClassFromString("PaperDocument")` échouait et NSDocumentController ne trouvait pas la classe du document. Correction par `@objc(PaperDocument)` + déclaration `NSDocumentClass` dans l'Info.plist + `windowNibName` à nil (fenêtres 100 % programmatiques)
- Bug du ruban : le délégué était remis à nil juste après avoir été défini
- Séparateurs de ruban dépréciés remplacés par des espaces standard
- Recherche : Cmd+F standard, ajout de « Remplacer… » (interface NSTextFinder complète)

Ajouté :
- Zoom : menu Affichage (Cmd+ / Cmd- / Cmd+0) et geste de pincement natif (NSScrollView, 50 % à 300 %)
- **Export PDF direct** (Cmd+E) : pagination TextKit manuelle page A4 avec marges, sans passer par le panneau d'impression
- **Documents récents** : menu Fichier → Ouvrir récent, alimenté à l'ouverture et à l'enregistrement (8 entrées max)
- Format d'impression (runPageLayout:) dans le menu Fichier
- Diagnostic de lancement (NSLog) : nombre de documents ouverts

Prochaine étape : v0.7 — retour à l'interface à onglets, correctifs d'ouverture.

## v0.7 — 14 octobre 2026 — Retour de l'interface à onglets, correctifs

Décision : l'interface native programmatique de la v0.5/v0.6 était trop spartiate (pas d'onglets, mise en forme sommaire). La v0.7 rétablit l'éditeur à onglets de la v0.4 — visuellement abouti (onglets Accueil, Insertion, Mise en page, Affichage ; charte Apple ; page A4) — dans la coquille native corrigée.

Fait :
- Onglets façon Word rétablis : Accueil (styles, polices, tailles, gras/italique/souligné/barré, exposant/indice, couleurs, recherche), Insertion (lien, image, tableau, symboles, date, page de garde, ligne), Mise en page (alignements, listes, retraits, interligne, effacer), Affichage (plan, zoom, raccourcis)
- Correctifs d'ouverture : l'éditeur se charge depuis le bundle avec repli Resources/ en développement ; message de chargement vérifié au lancement (diagnostic NSLog)
- Un seul bouton Enregistrer : le format (Word .docx par défaut, Word 97 .doc, HTML, PDF) se choisit dans le panneau natif d'enregistrement
- Menu Réglages (Cmd+,) : police et taille par défaut, marges, correcteur orthographique — appliqués en direct
- Documents récents dans le menu Fichier
- Suppression de la cible docxprobe (le générateur .docx vit désormais dans l'éditeur, comme en v0.4)

Prochaine étape : v0.8 — refonte ergonomique complète (parité Word 365).

## v0.8 — 14 octobre 2026 — Refonte ergonomique complète

Fait :
- Layout trois étages : barre de titre (titre éditable au clic avec indicateur d'état de sauvegarde, recherche de commandes Tell Me centrée, barre d'accès rapide), ruban, barre d'état
- Ruban structuré : Fichier, Accueil, Insertion, Mise en page, Révision, Affichage ; onglet Accueil en groupes libellés (Presse-papiers, Police, Paragraphe, Styles rapides, Édition) ; icônes SVG cohérentes (28 px)
- Police : A−/A+ (pas d'incrément), casse cyclique, indice/exposant typographiques, nuanciers avec couleurs récentes et « Autres couleurs », gomme de format
- Presse-papiers : pinceau de reproduction de mise en forme (one-shot)
- Paragraphe : marques de format ¶, interligne, presets de marges, orientation paysage, couleur de page
- Zone de travail : règles graduées en cm avec poignées de marge et de retrait glissables, ombre de page réaliste, sauts de page visuels avec étiquettes
- Barre d'état : Page x sur y (estimée), compteur de mots avec statistiques détaillées, langue du correcteur, Mode Page/Web, slider de zoom 50-200 %
- Machine à états d'enregistrement stricte (clean/dirty/saving/error) : Cmd+S intercepté, bouton Enregistrer désactivé si à jour, autosauvegarde locale 2 s, beforeunload, bouton Réessayer en cas d'erreur
- Synchronisation bidirectionnelle du ruban (états actifs/désactivés selon le caret)
- Design tokens CSS complets (accent #185abd, bordures #E5E7EB/#D1D5DB, rayons, espacements, ombres) — spécification dans docs/INTERFACE.md

Prochaine étape : v0.9 — en-têtes et pieds de page, numérotation des pages, thème sombre.
