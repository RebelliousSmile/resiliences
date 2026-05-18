# Narrative Game Template (Godot 4)

Base de projet pour un jeu narratif type *Life is Strange* :
dialogues branchés, relations entre personnages, conséquences différées,
exploration de lieux.

Stack :

- **Godot 4 .NET** (dernière stable)
- **Dialogic 2** — dialogues, personnages, timelines
- **Maaack's Game Template** — menus, save UI, options
- **GDScript** pour tous les systèmes custom

---

## 5 étapes pour avoir quelque chose qui tourne

### 1. Installer Godot 4 .NET

Télécharger la version stable .NET depuis <https://godotengine.org/download>
(onglet « .NET / C# »). Lancer une fois l'éditeur pour qu'il génère le cache.

> Le projet est en GDScript uniquement, mais .NET est requis si vous
> prévoyez d'ajouter des plugins en C# plus tard. Vous pouvez utiliser
> la version standard si vous n'en avez pas besoin.

### 2. Cloner ce repo dans un dossier vide

```bash
git clone <ce-repo> mon-jeu
cd mon-jeu
```

Ouvrir le dossier dans Godot (`Import` → sélectionner `project.godot`).
L'éditeur va se plaindre des autoloads dont les scripts existent
(c'est attendu) et de Dialogic absent (à installer à l'étape suivante).

### 3. Installer Maaack's Game Template

Dans Godot : `AssetLib` (onglet en haut) → chercher « Maaack's Game Template »
→ `Download` → `Install`. Cocher au moins :

- `addons/maaacks_game_template/`
- Les scènes de menu (`main_menu`, `pause`, `options`, `save_slots`)

Ne pas écraser `project.godot` lors de l'install. Le template fournit
les écrans principaux : on les branchera plus tard sur nos managers via les
signaux exposés (`SaveManager.save_completed`, etc.).

### 4. Installer Dialogic 2

Toujours dans `AssetLib` → chercher « Dialogic » → version 2.x → `Install`.
Activer ensuite l'addon : `Project → Project Settings → Plugins` → cocher
**Dialogic**.

Au redémarrage, l'onglet « Dialogic » apparaît dans la barre d'outils.

> `DialogicBridge` (notre autoload) détecte Dialogic au runtime. Sans
> Dialogic actif, les signaux dans les timelines sont simplement
> ignorés et les méthodes publiques restent appelables depuis le code.

### 5. Lancer la scène de test

Scène principale : `res://scenes/locations/Location_Template.tscn`.
`F5` ou bouton lecture. Vous devriez voir :

- Un fond noir (aucune texture n'est livrée — déposez votre image
  dans `Background` du TextureRect)
- Un HUD discret en haut à gauche affichant Léa et Aurore en `neutre (0)`
- Trois hotspots cliquables (porte, personnage, photo)

Tester :

- Cliquer sur la photo → flag `a_vu_photo=true` + Aurore -5
- Cliquer sur le personnage → démarre `dialogues/exemple_lea.dtl`
  (à importer une fois dans Dialogic)
- `F5` (touche jeu) → quicksave dans le slot 0
- `F9` → quickload du slot 0

---

## Architecture

```
scripts/managers/
├── RelationManager.gd     # scores [-100, +100] + paliers + signaux
├── GameStateManager.gd    # flags narratifs + historique de décisions
├── LocationManager.gd     # transitions de lieux avec fondu
└── SaveManager.gd         # JSON 3 slots
scripts/dialogic/
└── DialogicBridge.gd      # pont timelines → managers (cf. plus bas)
scripts/ui/
├── RelationHUD.gd         # HUD discret des relations
└── Hotspot.gd             # Area2D cliquable configurable
scenes/
├── locations/Location_Template.tscn   # scène prototype
└── ui/RelationHUD.tscn                # HUD réutilisable
dialogues/
└── exemple_lea.dtl        # timeline d'exemple
```

Autoloads enregistrés dans `project.godot`, dans l'ordre :

1. `RelationManager`
2. `GameStateManager`
3. `LocationManager`
4. `SaveManager` (dépend des trois ci-dessus)
5. `DialogicBridge` (dépend de Dialogic + des managers)

---

## Intégration Dialogic → RelationManager

Le pont accepte deux usages.

### A) Via l'événement `Signal` de Dialogic (recommandé)

Dans une timeline, ajouter un événement « Signal » et lui passer une chaîne
au format `commande:arg1:arg2:...` :

| Commande   | Format                                | Effet |
|------------|---------------------------------------|-------|
| `relation` | `relation:<perso>:<delta>[:raison]`   | `RelationManager.modifier()` |
| `flag`     | `flag:<cle>:<valeur>`                 | `GameStateManager.set_flag()` |
| `decision` | `decision:<id>:<choix>`               | `GameStateManager.record_decision()` |
| `goto`     | `goto:<lieu>:<scene_path>`            | `LocationManager.aller_a()` |

Exemple (extrait de `dialogues/exemple_lea.dtl`) :

```
- Lui sourire en retour
    [signal arg="relation:Lea:+5:salut_chaleureux"]
    Lea: Ça me fait plaisir de te voir.
```

`DialogicBridge` parse l'argument et appelle le bon manager.
Les flags posés via `GameStateManager.set_flag()` sont automatiquement
miroir-és dans les variables Dialogic, donc utilisables dans les
conditions `[if {ma_cle} == true]` des timelines.

### B) Directement depuis un script

```gdscript
DialogicBridge.modifier_relation("Lea", 10, "a_aide_avec_le_cours")
DialogicBridge.poser_flag("rencontre_aurore", true)
DialogicBridge.enregistrer_decision("fin_chap1", "partir_avec_lea")
```

---

## Test isolé de chaque manager

Chaque script est autonome. Pour les tester sans lancer le jeu complet,
créer une scène vide, attacher le manager comme autoload temporaire,
et appeler ses méthodes depuis la console de débogage ou un script :

```gdscript
# Test RelationManager
RelationManager.modifier("Lea", 30, "test")
print(RelationManager.get_niveau("Lea"))   # → "sympathie"
print(RelationManager.get_score("Lea"))    # → 30

# Test SaveManager
SaveManager.sauvegarder(0)
SaveManager.charger(0)
print(SaveManager.info_slot(0))
```

---

## Inputs configurés

- `clic_principal` — clic gauche
- `echap` — touche Échap (pause)
- `sauvegarde_rapide` — `F5`
- `chargement_rapide` — `F9`

À étendre via `Project → Project Settings → Input Map`.

---

## Ce qui reste à faire (idées de prochaine étape)

- Brancher l'écran de sauvegarde de Maaack sur `SaveManager.info_slot()`
- Ajouter un journal in-game listant `GameStateManager.get_decisions()`
- Variantes visuelles de personnages selon le niveau de relation
- Système d'objectifs / chapitres branché sur `chapitre_changed`
