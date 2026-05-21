# data/scenarios/votes/

Fichiers JSON de configuration des votes en assemblée (Fil 2).

## Nommage

`<vote_id>.json` — le `vote_id` est celui passé à `start_vote:<vote_id>:<seuil>:<tours>` dans la timeline Dialogic.

## Schéma complet

```json
{
  "participants": [
    { "pnj_id": "loan",    "position": 3 },
    { "pnj_id": "yasmine", "position": 3 },
    { "pnj_id": "erwan",   "position": 1 }
  ],
  "modificateurs_contextuels": [
    {
      "pnj_id":            "yasmine",
      "condition":         "flag:noemie_observee=true",
      "position_initiale": 0
    },
    {
      "pnj_id":            "erwan",
      "condition":         "lumen:ACTIF",
      "position_initiale": 3
    }
  ]
}
```

## Valeurs position / VotePosition

| Valeur | Constante `AssembleeVoteManager.VotePosition` | Sens |
|--------|----------------------------------------------|------|
| `0`    | `POUR`                                        | Vote favorable |
| `1`    | `CONTRE`                                      | Vote défavorable |
| `2`    | `ABSTENTION`                                  | Abstention |
| `3`    | `INDECIS`                                     | Position indéterminée |

## modificateurs_contextuels

Appliqués par `DialogicBridge._appliquer_modificateurs()` **avant** l'émission du signal `vote_requested`. Si la condition est vraie, la `position_initiale` remplace la position définie dans `participants`. Si le PNJ n'est pas dans `participants`, il est ajouté.

Formats de condition supportés (voir `DialogicBridge.evaluer_condition()`) :
- `""` / `"toujours"` → toujours vrai
- `"lumen:ACTIF"` → LumenManager en état ACTIF
- `"flag:nom"` → flag booléen vrai
- `"flag:nom=valeur"` → flag égal à valeur
- `"variable:nom >= valeur"` → comparaison numérique

## Exemple minimal (sans modificateurs)

```json
{
  "participants": [
    { "pnj_id": "loan",    "position": 3 },
    { "pnj_id": "yasmine", "position": 3 }
  ]
}
```
