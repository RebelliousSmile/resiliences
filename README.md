# RÉSILIENCES

Visual novel narratif en **Godot 4 + Dialogic 2**. Backgrounds fixes
1920×1080, portraits PNG alpha, pas de navigation spatiale. Tout passe
par les `.dtl` (dialogues, choix, events) pilotés par des autoloads
GDScript.

> Doc technique complète : [`docs/architecture.md`](docs/architecture.md)

---

## Stack

- **Godot 4** (.NET non requis — GDScript pur)
- **Dialogic 2** — dialogues, personnages, timelines


---

## Démarrage rapide

### 1. Installer Godot 4

Télécharger Godot 4 stable depuis <https://godotengine.org/download>.
Lancer une fois l'éditeur pour générer le cache.

### 2. Ouvrir le projet

```bash
git clone <ce-repo> resiliences
cd resiliences
```

Ouvrir le dossier dans Godot (`Import` → sélectionner `project.godot`).
L'éditeur signalera Dialogic absent — c'est attendu, on l'installe à
l'étape 3.

### 3. Installer Dialogic 2

Dans Godot : `AssetLib` → chercher « Dialogic » → version 2.x →
`Install`. Puis `Project → Project Settings → Plugins` → cocher
**Dialogic**. Au redémarrage, l'onglet « Dialogic » apparaît.

> Sans Dialogic, `DialogicBridge` ignore silencieusement les signaux
> dans les timelines ; les autoloads restent appelables depuis du code.

### 4. Lancer la scène d'entrée

Scène principale : `res://scenes/acte1/s1_01.tscn` (configurée comme
`run/main_scene`). `F5` ou bouton lecture.

---

## Arborescence

```
autoloads/                 # tous les managers (singletons Godot)
  GameStateManager.gd      # flags canoniques RÉSILIENCES
  LumenManager.gd          # état LUMEN + fragments
  RelationManager.gd       # 16 PNJ, échelle -100/+100
  MenaceManager.gd         # 4 zones, paliers + happenings
  AssembleeVoteManager.gd  # votes 4 positions
  ConflitManager.gd        # conflits par jauges
  InventaireManager.gd     # items
  CraftManager.gd          # recettes
  SaveManager.gd           # 3 slots JSON, autonome
  DialogicBridge.gd        # dispatch signal_event → managers
scenes/
  base/                    # composants UI réutilisables
    LumenDisplay.{tscn,gd}
    MenaceDisplay.{tscn,gd}
    ObservationMenu.{tscn,gd}
    AssembleeVote.{tscn,gd}
    ConflitJauges.{tscn,gd}
    InventairePanel.{tscn,gd}
  acte1/                   # scènes de l'acte 1
    s1_01.{tscn,gd}        # Bord du Couloir (aube)
    s1_01_init.gd          # seul _init.gd autorisé
dialogic/                  # timelines Dialogic (.dtl)
  s1_01.dtl
data/
  items.json               # définitions d'items
  recettes.json            # recettes de craft
assets/
  backgrounds/  characters/  ui/  music/  sfx/
```

---

## Règles absolues (rappel)

- **snake_case** pour toutes les variables GDScript.
- **Pas de `_init.gd`** sauf pour `s1_01_init.gd`.
- **Pas de chiffres affichés** pour la menace — visuel uniquement.
- **Pas d'option neutre** dans `ConflitJauges` — chaque option déplace.
- **Deux fichiers par NODE de scène** : `.tscn` + `.gd`. Pas plus.
- Toujours utiliser les **noms de variables canoniques** définis dans
  `GameStateManager.gd`.

---

## Utilisation depuis une timeline Dialogic

Toutes les actions passent par un événement `Signal` Dialogic avec un
argument `"commande:arg1:arg2:..."`. Le détail des commandes est dans
[`docs/architecture.md`](docs/architecture.md#commandes-dialogicbridge).

Exemple :

```dtl
- Aider la silhouette
    [signal arg="flag:rive_aide_silhouette2:true"]
    [signal arg="relation:loan:5"]
    Narrateur: Tu t'agenouilles à côté d'elle.
```

---

## Tests de validation

| Étape       | Test                                                                                       |
|-------------|--------------------------------------------------------------------------------------------|
| 1 Core      | `GameStateManager.set_flag("lumen_fragment_1", true)` → `get_flag(...)` renvoie `true`     |
| 1 Core      | `SaveManager.save(1)` → `SaveManager.load_save(1)` → flags restaurés                       |
| 2 Mécas     | `MenaceManager.add_menace("confluence", 3)` → `happening_triggered` émis                   |
| 2 Mécas     | `AssembleeVoteManager.start_vote(...)` → `resolve("simple")` renvoie une issue             |
| 3 UI        | `LumenManager.set_etat(LumenEtat.ACTIF)` → `LumenDisplay` se met à jour                    |
| 4 Events    | `[signal arg="menace_add:gerland:2"]` dans un `.dtl` → `MenaceManager` mis à jour          |
| 5 S1-01     | Scène complète jouable de bout en bout, tous les flags posés                               |

---

## Inputs configurés

- `clic_principal` — clic gauche
- `echap` — touche Échap
- `ouvrir_inventaire` — touche `I`

Étendre via `Project → Project Settings → Input Map`.
