# data/scenarios/conflits/

Fichiers JSON de configuration des conflits par jauges (Fil 3, négociations).

## Nommage

`<conflit_id>.json` — le `conflit_id` est celui passé à `start_conflit:<conflit_id>` dans la timeline Dialogic.

## Schéma complet

```json
{
  "type":          "negociation",
  "rounds":        3,
  "flag_resultat": "gerland_generateur_choix",
  "jauges": [
    {
      "id":             "tension",
      "label":          "Tension",
      "init":           5,
      "min":            0,
      "max":            10,
      "seuil_victoire": 0,
      "seuil_defaite":  10
    }
  ],
  "options": [
    {
      "label":     "Proposer un compromis",
      "condition": "",
      "effets":    { "tension": -2 }
    },
    {
      "label":     "Maintenir la pression",
      "condition": "flag:negoc_demarre=true",
      "effets":    { "tension": 1 }
    }
  ]
}
```

## Champs racine

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `type` | string | — | Type narratif (`"negociation"`, `"confrontation"`, etc.) — informatif |
| `rounds` | int | ✅ | Nombre de rounds avant résolution automatique (`"temps_ecoule"`) |
| `flag_resultat` | string | — | Flag GameState posé avec l'issue (`victoire_<jauge>`, `defaite_<jauge>`, `temps_ecoule`) |
| `jauges` | array | ✅ | Liste des jauges de conflit |
| `options` | array | — | Options proposées au joueur (utilisées par l'UI de conflit) |

## Champs d'une jauge

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `id` | string | ✅ | Identifiant interne |
| `label` | string | — | Libellé affiché (icône + label dans l'UI) |
| `init` | int | — | Valeur initiale (défaut : 0) |
| `min` | int | — | Borne basse (défaut : 0) |
| `max` | int | — | Borne haute (défaut : 10) |
| `seuil_victoire` | int | — | Valeur ≤ à atteindre pour victoire (`victoire_<id>`) |
| `seuil_defaite` | int | — | Valeur ≥ atteinte pour défaite (`defaite_<id>`) |

## Champs d'une option

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `label` | string | ✅ | Texte du bouton |
| `condition` | string | — | Condition d'affichage (mêmes formats que observations) |
| `effets` | object | ✅ | `{ jauge_id: delta }` — delta signé appliqué à la jauge |

## Issues possibles (flag_resultat)

| Valeur | Déclencheur |
|--------|------------|
| `"victoire_<jauge_id>"` | jauge atteint `seuil_victoire` |
| `"defaite_<jauge_id>"` | jauge atteint `seuil_defaite` |
| `"temps_ecoule"` | `rounds` épuisés sans seuil atteint |

## Note : pas d'affichage numérique

Les valeurs numériques des jauges ne sont jamais montrées au joueur — uniquement des icônes ↑↓ sur les options pour prévisualiser l'effet.

## Exemple — négociation génératrice (`c_generateur.json`)

```json
{
  "type":          "negociation",
  "rounds":        4,
  "flag_resultat": "gerland_generateur_choix",
  "jauges": [
    {
      "id":             "tension",
      "label":          "Tension",
      "init":           5,
      "min":            0,
      "max":            10,
      "seuil_victoire": 1,
      "seuil_defaite":  9
    }
  ],
  "options": [
    {
      "label":     "Proposer un partage équitable",
      "condition": "",
      "effets":    { "tension": -2 }
    },
    {
      "label":     "Exiger l'accès immédiat",
      "condition": "",
      "effets":    { "tension": 3 }
    },
    {
      "label":     "Laisser LUMEN analyser",
      "condition": "lumen:ACTIF",
      "effets":    { "tension": -3 }
    }
  ]
}
```
