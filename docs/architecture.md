# Architecture technique — RÉSILIENCES

> Doc d'implémentation pour les contributeurs. Spec narrative ailleurs.
> Voir le [README](../README.md) pour le démarrage rapide.

---

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                       Dialogic 2 (.dtl)                          │
│  - timelines, choix, conditions, événements `signal`             │
└──────────────────────────────┬──────────────────────────────────┘
                               │ signal_event(argument)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DialogicBridge (autoload)                  │
│  parse "commande:arg1:arg2:..." → appelle le bon manager         │
└──────────────────────────────┬──────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
┌──────────────┐      ┌───────────────┐       ┌───────────────┐
│ État central │      │ Mécaniques    │       │ UI overlays   │
│              │      │               │       │               │
│ GameState    │      │ MenaceManager │       │ LumenDisplay  │
│ LumenManager │      │ AssembleeVote │       │ MenaceDisplay │
│ RelationMgr  │      │ ConflitMgr    │       │ Observation   │
│ Inventaire   │      │ CraftManager  │       │ Assemblée     │
│              │      │               │       │ Conflit       │
│              │      │               │       │ Inventaire    │
└──────┬───────┘      └───────────────┘       └───────────────┘
       │
       ▼
┌──────────────┐
│ SaveManager  │ → 3 slots JSON dans user://saves/
└──────────────┘
```

---

## Ordre de chargement (autoloads)

L'ordre dans `project.godot` est important — les managers d'état avant
ceux qui en dépendent :

1. `GameStateManager` — état pur, aucune dépendance
2. `LumenManager` — dépend de `GameStateManager` (flags fragments)
3. `RelationManager` — état pur
4. `MenaceManager` — état pur
5. `InventaireManager` — état pur, charge `data/items.json`
6. `CraftManager` — dépend de `InventaireManager` + `GameStateManager`
7. `ConflitManager` — dépend de `GameStateManager`
8. `AssembleeVoteManager` — dépend de `RelationManager` + `GameStateManager`
9. `SaveManager` — dépend de tous les managers d'état
10. `DialogicBridge` — dépend de tout, branche `Dialogic.signal_event`

---

## GameStateManager

Stockage pur. Pas de logique métier — seulement des variables membre
exposées via `set_flag(name, value)` / `get_flag(name)`.

### Variables canoniques

| Catégorie | Nom | Type | Valeurs |
|-----------|-----|------|---------|
| Progression | `confiance_confluence` | `int` | 0 → 10 |
| Progression | `confiance_gerland` | `int` | 0 → 10 |
| Progression | `relation_lise` | `int` | 0 → 10 |
| LUMEN | `lumen_fragment_1..5` | `bool` | `false` au départ |
| LUMEN | `lumen_question_type` | `String` | `""`, `"soin"`, `"analyse"`, `"données"` |
| LUMEN | `lumen_revelation_recue` | `bool` | — |
| Fil 2 | `assemblee_intervention` | `bool` | — |
| Fil 2 | `assemblee_issue` | `String` | `""`, `"accord"`, `"report"`, `"blocage"` |
| Fil 3 | `violence_choix_acte3` | `String` | `"desescalade"`, `"passivite"`, `"direct"`, `"radical"` |
| Fil 3 | `gerland_generateur_choix` | `String` | — |
| Fil 4 | `fil4_pnj_tension` | `String` | id du PNJ |
| Fil 4 | `fil4_intervention_max` | `bool` | — |
| Fil 4 | `fil4_resolution` | `String` | `"ami"`, `"amour"`, `"neutre"` |
| Fil 4 | `fil4_max_choix_personnel` | `bool` | — |
| Rive | `rive_aide_silhouette2` | `bool` | — |
| Rive | `rive_silhouette1_relation` | `String` | `"distante"`, `"neutre"`, `"ouverte"` |
| Rive | `rive_silhouette2_relation` | `String` | idem |
| Solaize | `solaize_premiere_contact` | `bool` | — |
| Solaize | `lumen_solaize_reaction` | `String` | — |
| Solaize | `offre_reponse` | `String` | `"accepte"`, `"refuse"`, `"negocie"` |
| Solaize | `fin_debloquee` | `String` | `"enracinement"`, `"route"`, `"offre"`, `"rupture"` |
| Progression | `acte_courant` | `String` | `"acte1"` au départ |
| Progression | `node_courant` | `String` | `"s1_01"` au départ |

### Signaux

- `flag_changed(flag_name, old_value, new_value)`

### API

- `reset()` — remet tout aux valeurs par défaut
- `set_flag(name, value)` — refuse les noms inconnus (warning)
- `get_flag(name)` — idem
- `to_dict()` / `from_dict(data)` — pour SaveManager

---

## LumenManager

État du compagnon LUMEN + fragments du Protocole Continuité.

### Enum `LumenEtat`

| Valeur | Description |
|--------|-------------|
| `SILENCIEUX` | batterie vide — nuit, souterrains Solaize. `can_speak() == false` |
| `PARTIEL` | charge en cours — réponses courtes. `is_reliable() == false` |
| `ACTIF` | soleil — fonctionnel |
| `DEREGLE` | Couloir profond — réponses erratiques. `is_reliable() == false` |
| `FRAGMENT` | fragment Protocole Continuité déclenché — état transitoire |

### Signaux

- `etat_changed(ancien, nouveau)`
- `fragment_decouvert(numero)`

### API

- `set_etat(LumenEtat)` — change l'état + sync Dialogic
- `parse_etat(nom_string) → LumenEtat` — pour parser "ACTIF" etc.
- `add_fragment(1..5)` — pose le flag + incrémente le compteur
- `can_speak() → bool`
- `is_reliable() → bool`

### Synchronisation Dialogic

À chaque changement, `LumenManager` met à jour les variables Dialogic :
- `lumen_etat` (string : `"actif"` / `"silencieux"` / ...)
- `lumen_fragments_trouves` (int)

Utilisables dans les conditions `.dtl` :
```
[if {lumen_etat} == "actif"]
    LUMEN: Je perçois quelque chose.
[end]
```

---

## RelationManager

16 PNJ, échelle −100 → +100.

### PNJ canoniques

`loan`, `erwan`, `tanguy`, `ora`, `felix`, `souri`, `lise`, `armand`,
`yasmine`, `bap`, `irene`, `sofiane`, `marta`, `noemie`,
`nathan_berge`, `zel`.

### Seuils

| Valeur | Seuil |
|--------|-------|
| `< −30` | `mefiance` |
| `−30 à 30` | `neutre` |
| `30 à 60` | `sympathie` |
| `60 à 85` | `confiance` |
| `> 85` | `intime` |

### API

- `modify(pnj_id, delta)` — clampé entre −100/+100
- `get_value(pnj_id) → int`
- `get_seuil(pnj_id) → String`
- `reset()`

---

## MenaceManager

4 zones (0 → 10) avec **paliers à happenings**.

### Paliers (extrait)

| Zone | Seuil | Happening | Réversible |
|------|-------|-----------|------------|
| `confluence` | 3 | `h_confluence_tension_interne` | ✓ |
| `confluence` | 6 | `h_confluence_acces_restreint` | ✗ |
| `confluence` | 9 | `h_confluence_ultimatum_solaize` | ✗ |
| `gerland` | 3 | `h_gerland_blocage_composants` | ✓ |
| `gerland` | 6 | `h_gerland_panne_generateur` | ✗ |
| `gerland` | 9 | `h_gerland_evacuation` | ✗ |
| `vallee` | 4 | `h_vallee_contamination_etendue` | ✗ |
| `vallee` | 8 | `h_vallee_inaccessible` | ✗ |
| `solaize` | 3 | `h_solaize_surveillance_renforcee` | ✓ |
| `solaize` | 6 | `h_solaize_pression_ressources` | ✗ |
| `solaize` | 9 | `h_solaize_intervention_directe` | ✗ |

### Signaux

- `menace_changed(zone, ancienne, nouvelle)`
- `happening_triggered(happening_id)`

### API

- `add_menace(zone, valeur)` — vérifie les paliers franchis et émet
  `happening_triggered` ; pousse le happening dans la file
- `get_background_variant(zone) → "" | "tension" | "critique"` —
  utilisé par les scènes pour choisir le bon background
- `consume_pending_happenings() → Array[String]` — récupère et vide la
  file (à appeler à la prochaine transition)

### Règle d'affichage

**Jamais de chiffre, jamais de barre.** `MenaceDisplay.tscn` :

| Palier | Icône |
|--------|-------|
| 0–2 | invisible |
| 3–5 | visible, neutre |
| 6–8 | pulse lente |
| 9 | pulse rapide |

---

## AssembleeVoteManager

Votes en assemblée pour le Fil 2. Max ne vote pas — il/elle influence
les PNJ présents.

### Enum `VotePosition`

`POUR`, `CONTRE`, `ABSTENTION`, `INDECIS`

### Règle d'influence

| Relation Max ↔ PNJ | Option dispo | Effet sur INDÉCIS |
|--------------------|--------------|-------------------|
| ≥ `confiance` (60) | Convaincre | INDÉCIS → POUR |
| < `mefiance` (−30) | Discréditer | INDÉCIS → CONTRE |
| LUMEN actif | « Lire les hésitations » | révèle la position sans la changer |

### Signaux

- `vote_started(vote_id)`
- `position_changed(pnj_id, nouvelle_position)`
- `vote_resolved(vote_id, issue)`

### API

- `start_vote(vote_id, participants, tours, seuil)`
  - `participants` = `[{ pnj_id, position }, ...]`
  - `seuil` ∈ `"simple"`, `"qualifiee"` (2/3), `"unanimite"`
- `apply_influence(pnj_id, delta)`
- `end_tour()`
- `resolve(seuil) → "accord" | "report" | "blocage"` (pose
  `GameStateManager.assemblee_issue`)

---

## ConflitManager

Conflits par jauges (Fil 3 et négociations).
**Pas d'option neutre.** Chaque option déplace au moins une jauge.
**Pas d'affichage numérique** — icônes `↑↓` uniquement sur les options.

### Config

```gdscript
{
  "id": "c_generateur",
  "type": "negociation",
  "rounds": 3,
  "jauges": [
    {
      "id": "tension",
      "label": "Tension",
      "init": 5, "min": 0, "max": 10,
      "seuil_victoire": 0, "seuil_defaite": 10
    }
  ],
  "options": [
    {
      "label": "Proposer un compromis",
      "effets": { "tension": -2 },
      "condition": ""
    }
  ],
  "option_lumen": {
    "label": "Analyser la position adverse",
    "effets": { "tension": -1 }
  },
  "flag_resultat": "gerland_generateur_choix"
}
```

### Signaux

- `conflit_started(conflit_id)`
- `jauge_changed(conflit_id, jauge_id, ancienne, nouvelle)`
- `seuil_atteint(conflit_id, jauge_id, "victoire" | "defaite")`
- `conflit_resolu(conflit_id, issue)`

### API

- `start_conflit(config)`
- `apply_option(effets)` — `effets = { jauge_id: delta, ... }`
- `check_seuils()` — appelé automatiquement par `apply_option`
- `end_round()` — résout en `"temps_ecoule"` si rounds = 0

---

## InventaireManager + CraftManager

### Items

Définis dans `data/items.json` :

```json
{
  "id": "cable_aerospatial",
  "nom": "Câble aérospatial",
  "description": "Conducteur tressé, isolation gris-bleu.",
  "categorie": "composant",
  "craftable": false,
  "dialogic_tag": "item_cable"
}
```

Catégories : `composant`, `outil`, `document`, `ressource`.

### Recettes

`data/recettes.json` :

```json
{
  "id": "antenne_lumen",
  "ingredients": ["cable_aerospatial", "panneau_solaire_fragment"],
  "resultat": "antenne_lumen_bricolee",
  "condition": "",
  "lumen_hint": true
}
```

`condition` est un nom de flag de `GameStateManager` à vérifier
(`true`). `lumen_hint: true` → la recette est suggérée par LUMEN dans
`InventairePanel` si `LumenManager.lumen_etat == ACTIF`.

### API InventaireManager

- `add_item(id, quantite=1)`
- `remove_item(id, quantite=1)`
- `has_item(id) → bool`
- `get_quantity(id) → int`
- `get_definition(id) → Dictionary`
- `get_craftable_hints() → Array[String]` (ids des recettes craftables
  avec `lumen_hint`, si LUMEN actif)

### API CraftManager

- `can_craft(recette_id) → bool`
- `craft(recette_id)` — émet `item_crafted(recette_id, resultat_id)`
- `get_available_recipes() → Array`

---

## SaveManager

**Indépendant de Maaack.** 3 slots JSON dans `user://saves/slot_N.json`.

### API

- `save(slot: int)` — slots 1..3
- `load_save(slot) → bool`
- `delete_save(slot)`
- `has_save(slot) → bool`
- `get_save_info(slot) → { acte, node, timestamp }`

### Format

```json
{
  "version": 1,
  "timestamp": 1716300000,
  "game_state": { ... },
  "relations":  { "loan": 12, ... },
  "lumen":      { "lumen_etat": 2, "lumen_fragments_trouves": 1 },
  "menace":     { ... },
  "inventaire": { "cable_aerospatial": 1 }
}
```

---

## DialogicBridge — commandes signal_event

Toutes les actions des `.dtl` passent par un événement `Signal` avec un
argument `"commande:arg1:arg2:..."`. Le bridge parse et dispatche.

### Commandes supportées

| Commande | Format | Effet |
|----------|--------|-------|
| `relation` | `relation:<pnj_id>:<delta>` | `RelationManager.modify` |
| `flag` | `flag:<nom>:<valeur>` | `GameStateManager.set_flag` |
| `menace_add` | `menace_add:<zone>:<valeur>` | `MenaceManager.add_menace` |
| `lumen_set_etat` | `lumen_set_etat:<ETAT>` | `LumenManager.set_etat` |
| `lumen_fragment` | `lumen_fragment:<1..5>` | `LumenManager.add_fragment` |
| `item_add` | `item_add:<id>[:qte]` | `InventaireManager.add_item` |
| `item_remove` | `item_remove:<id>[:qte]` | `InventaireManager.remove_item` |
| `show_observations` | `show_observations:<scene_id>` | Émet `observation_requested` avec les données de `data/scenarios/observations/<scene_id>.json` |
| `start_vote` | `start_vote:<vote_id>:<seuil>:<tours>` | Émet `vote_requested` avec `data/scenarios/votes/<vote_id>.json` |
| `start_conflit` | `start_conflit:<conflit_id>` | Émet `conflit_requested` avec `data/scenarios/conflits/<conflit_id>.json` |

### Exemple `.dtl`

```dtl
- Donner le câble à Loan
    [signal arg="item_remove:cable_aerospatial:1"]
    [signal arg="relation:loan:+5"]
    [signal arg="flag:lumen_revelation_recue:true"]
    Loan: Merci. Vraiment.

- Forcer le passage
    [signal arg="menace_add:confluence:2"]
    [signal arg="relation:irene:-10"]
    Narrateur: Tu pousses la grille du pied.
```

### Données enrichies (votes, conflits, observations)

Quand une commande déclenche une UI complexe, le bridge va chercher la
configuration dans `data/scenarios/<type>/<id>.json` puis émet le
signal correspondant. Les scènes d'overlay (`AssembleeVote.tscn`,
`ConflitJauges.tscn`, `ObservationMenu.tscn`) écoutent ces signaux et
ouvrent leur UI.

> Note : tant que Dialogic 2 n'est pas installé, ou que les vrais
> `DialogicEvent` resources ne sont pas créés, on passe par
> `signal_event` (Signal Dialogic standard). C'est interchangeable.

---

## Scène S1-01 (test d'intégration)

`scenes/acte1/s1_01.tscn` contient :

- **Background** (`CanvasLayer` layer −10) — TextureRect plein écran
- **HUD** (layer 10) — `LumenDisplay`, `MenaceDisplay`, `InventairePanel`
- **Overlays** (layer 20) — `ObservationMenu`, `AssembleeVote`, `ConflitJauges`
- **Init** — `s1_01_init.gd` (seul `_init.gd` du projet) qui appelle
  `GameStateManager.reset()` et `LumenManager.set_etat(SILENCIEUX)`

`s1_01.gd` démarre la timeline `dialogic/s1_01.dtl` au `_ready`.

---

## Conventions de code

- **snake_case** strict pour toutes les variables GDScript
- Pas de `_init.gd` sauf `s1_01_init.gd`
- Tous les chiffres internes ; jamais affichés au joueur (menace, jauges)
- Pas d'option neutre dans `ConflitJauges`
- 2 fichiers par node de scène : `.tscn` + `.gd` (jamais 3+)
- Toujours utiliser les noms canoniques de `GameStateManager._FLAG_NAMES`
- Sauvegarde : ne pas dépendre de Maaack

---

## Tests de validation par étape

| Étape | Test |
|-------|------|
| 1 Core | `GameStateManager.set_flag("lumen_fragment_1", true)` → `get_flag("lumen_fragment_1") == true` |
| 1 Core | `SaveManager.save(1)` puis `load_save(1)` → flags restaurés |
| 2 Mécas | `MenaceManager.add_menace("confluence", 3)` → `happening_triggered("h_confluence_tension_interne")` émis |
| 2 Mécas | `AssembleeVoteManager.start_vote(...)` → `resolve("simple")` renvoie une issue |
| 3 UI | `LumenManager.set_etat(LumenEtat.ACTIF)` → `LumenDisplay` se met à jour |
| 4 Events | `[signal arg="menace_add:gerland:2"]` dans une `.dtl` → `MenaceManager` mis à jour |
| 5 S1-01 | Scène complète jouable du début à la fin, tous les flags posés |

---

## À faire (hors scope de la phase courante)

- Compléter `dialogic/s1_01.dtl` à partir de
  `scene_1_1_bord_du_couloir.md` (à intégrer au dépôt)
- Créer `data/scenarios/{observations,votes,conflits}/*.json` pour les
  scènes du fil 2 et du fil 3
- Migrer les `signal_event` vers de vrais `DialogicEvent` resources
  une fois Dialogic 2 installé (purement cosmétique côté éditeur)
- Brancher l'écran de save de Maaack sur `SaveManager.get_save_info()`
- Ajouter les portraits PNG alpha et backgrounds 1920×1080 dans
  `assets/`
