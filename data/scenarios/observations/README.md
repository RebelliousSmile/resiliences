# data/scenarios/observations/

Fichiers JSON de listes d'observations cliquables (menu d'observation de Max).

## Nommage

`<scene_id>.json` — le `scene_id` est celui passé à `show_observations:<scene_id>` dans la timeline Dialogic.

## Schéma

```json
{
  "observations": [
    {
      "id":             "obs_panneau_solaire",
      "label":          "Examiner le panneau",
      "condition":      "",
      "texte":          "Un panneau récupéré sur un toit d'usine, encore chaud.",
      "lumen_reaction": "Je détecte une signature thermique résiduelle."
    }
  ]
}
```

## Champs

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `id` | string | ✅ | Identifiant unique de l'observation (dans la scène) |
| `label` | string | ✅ | Texte affiché sur le bouton |
| `condition` | string | — | Condition d'affichage (vide = toujours visible) |
| `texte` | string | ✅ | Texte injecté dans `observation_courante` (variable Dialogic) |
| `lumen_reaction` | string | — | Réaction de LUMEN si `LumenManager.can_speak()` est vrai |

## Formats de condition (champ `condition`)

Voir `DialogicBridge.evaluer_condition()` pour la liste complète :
- `""` / `"toujours"` → toujours visible
- `"lumen:ACTIF"` → visible si LUMEN est en état ACTIF
- `"flag:nom"` → visible si le flag est vrai
- `"flag:nom=valeur"` → visible si le flag vaut la valeur
- `"variable:nom >= valeur"` → comparaison numérique

## Comportement

- Une observation déjà lue devient **désactivée** (bouton grisé) pour la session courante.
- `lumen_reaction` n'est injectée que si `LumenManager.can_speak()` retourne `true` ET que le champ est non vide.
- Le bouton "Reprendre" ferme le menu sans marquer les observations non lues.

## Exemple complet (`s1_01.json`)

```json
{
  "observations": [
    {
      "id":        "obs_couloir_lumiere",
      "label":     "La lumière au bout",
      "condition": "",
      "texte":     "Une lueur bleutée filtre sous la porte métallique.",
      "lumen_reaction": ""
    },
    {
      "id":             "obs_panneau_defaillant",
      "label":          "Panneau de contrôle",
      "condition":      "flag:panneau_inspecte=false",
      "texte":          "Le panneau clignote en rouge. Une surchauffe ?",
      "lumen_reaction": "Anomalie détectée sur le circuit 3-A."
    }
  ]
}
```
