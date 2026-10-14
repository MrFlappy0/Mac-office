# Spécification d'interface — Paper v0.8

Référence technique de la refonte UI/UX : disposition, jetons graphiques,
machine à états d'enregistrement et contrat entre le ruban et le document.

## 1. Disposition (layout trois étages)

```
┌────────────────────────────────────────────────────────────┐
│ Top bar : titre éditable + statut | Tell Me | accès rapide │
├────────────────────────────────────────────────────────────┤
│ Ruban : Fichier Accueil Insertion Mise en page Révision     │
│         Accueil -> [Presse-papiers|Police|Paragraphe|       │
│                        Styles rapides|Édition]              │
├──────────┬─────────────────────────────────────────────────┤
│ Plan     │ ┌──règle graduée (cm)──────────────────────┐     │
│ (titre 1 │ │  page A4, ombre douce, sauts de page     │     │
│  à 3)    │ │  poignées de marge et de retrait         │     │
├──────────┴─────────────────────────────────────────────────┤
│ Statut : Page x/y · mots · langue | Mode Page/Web · zoom   │
└────────────────────────────────────────────────────────────┘
```

## 2. Jetons graphiques (CSS custom properties)

| Token | Valeur | Usage |
|---|---|---|
| `--accent` | `#185abd` | accent type Word, états actifs, liens |
| `--accent-soft` | `rgba(24,90,189,.12)` | fond des boutons actifs, focus |
| `--bg` | `#f3f3f6` | plan de travail neutre |
| `--surface` / `--chrome` | `#ffffff` / `#fafafc` | page / barres |
| `--border` / `--border-strong` | `#e5e7eb` / `#d1d5db` | bordures neutres |
| `--text` / `--text-2` / `--text-3` | `#1d1d1f` / `#6b7280` / `#9ca3af` | hiérarchie du texte |
| `--danger` / `--ok` | `#dc2626` / `#16a34a` | erreur / enregistré |
| `--radius-s/m/l` | `5/7/11px` | rayons de bordure |
| `--ctrl-h` | `28px` | hauteur des contrôles |
| `--space-1..4` | `4/8/12/16px` | espacements |
| `--font-ui` | `-apple-system, SF Text, Inter, Segoe UI` | typographie d'interface (11-13px) |
| `--shadow-page` | ombre diffuse triple | feuille A4 |

## 3. Machine à états d'enregistrement

États : `clean`, `dirty`, `saving`, `error`.

```
        saisie / mise en forme
   clean ────────────────────────► dirty
     ▲                              │
     │ afterSave() (panneau OK)     │ Cmd+S / bouton
     │                              ▼
     ├────────────────────────── saving
     │                              │
     │ saveCancelled()             │ saveError()
     └──────── dirty/clean ◄───────┤
                                    ▼
                                  error ──(Réessayer → Cmd+S)──► saving
```

Règles :
- `Cmd+S` intercepté globalement (`keydown`, `preventDefault`). Déclenche
  `requestSave()` si `dirty` ou `error` ; sans effet en `clean` (bouton Enregistrer désactivé).
- Pendant `saving`, le bouton Enregistrer est désactivé (anti double requête), le statut affiche un point pulsant « Enregistrement… ».
- Document jamais nommé : le panneau natif d'enregistrement propose le choix du format (défaut Word .docx) et son emplacement.
- `beforeunload` : alerte native si l'état n'est pas `clean`.
- Autosauvegarde locale : `debounce` de 2 s après la dernière frappe (localStorage), indicateur visuel immédiat au passage `clean → dirty`.
- `error` : pastille rouge + bouton « Réessayer » qui relance `requestSave()`.

## 4. Contrat d'interface ruban ↔ document

- **Lecture (document → ruban)** : sur `selectionchange` et après chaque commande,
  `syncRibbon()` lit l'état réel du caret — `document.queryCommandState` pour
  gras/italique/souligné/barré/listes/alignements, `getComputedStyle` du nœud
  actif pour police et taille, `queryCommandEnabled` pour Annuler/Rétablir,
  présence d'une sélection pour Couper/Copier. Les boutons reflètent
  instantanément l'état (`.active`), les contrôles inapplicables sont `disabled`.
- **Écriture (ruban → document)** : chaque bouton appelle une commande
  centralisée `cmd(name, value)` (contentEditable / `document.execCommand`)
  après `restoreSelection()` pour ne pas perdre le curseur, puis `refresh()`
  propage les effets (compteurs, plan, sauts de page, statut).
- **Tell Me** : registre plat `COMMANDS = [{label, cat, fn}]` — toute commande du
  ruban y est enregistrée une fois ; la barre centrale filtre, navigue au clavier
  (↑ ↓ Entrée) et exécute.
- **Popovers** : nuanciers (palette standard, 7 couleurs récentes, « Autres
  couleurs » via sélecteur natif), fermeture au clic extérieur et par Échap.
- **Règles** : graduations en cm (37,8 px/cm) ; poignées glissables pour
  marges gauche/droite (application immédiate sur le padding de la page) et
  retrait de première ligne (paragraphe actif).
- **Zoom** : `body.style.zoom` (50–200 %) — slider, boutons ± et pourcentage
  cliquable ; le ruban, les règles et la page se mettent à l'échelle ensemble.
- **Sauts de page** : lignes pointillées superposées tous les 935 px de contenu
  (hauteur utile A4, marges 94 px), avec étiquette « Page N » ; masquées en
  mode Web et à l'export PDF.
