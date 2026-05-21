extends Node
## ConflitManager — conflits par jauges (Fil 3 et négociations)
##
## Pas d'option neutre dans les conflits : chaque option déplace au moins
## une jauge. Pas d'affichage numérique au joueur — uniquement des icônes
## ↑↓ sur les options pour prévisualiser l'effet.

var conflit_actif : bool = false
var conflit_id_courant : String = ""
var jauges : Dictionary = {}   # { jauge_id: int }
var rounds_restants : int = 0
var config_courante : Dictionary = {}

signal conflit_started(conflit_id: String)
signal jauge_changed(conflit_id: String, jauge_id: String, ancienne: int, nouvelle: int)
signal seuil_atteint(conflit_id: String, jauge_id: String, type: String)   # "victoire" | "defaite"
signal conflit_resolu(conflit_id: String, issue: String)


## Lance un conflit. Format de `config` :
## {
##   "id": "c_generateur",
##   "type": "negociation",
##   "rounds": 3,
##   "jauges": [
##     { "id": "tension", "label": "Tension",
##       "init": 5, "min": 0, "max": 10,
##       "seuil_victoire": 0, "seuil_defaite": 10 },
##     ...
##   ],
##   "flag_resultat": "gerland_generateur_choix"   # optionnel
## }
func start_conflit(config: Dictionary) -> void:
	config_courante = config.duplicate(true)
	conflit_id_courant = config.get("id", "")
	rounds_restants = config.get("rounds", 3)
	jauges.clear()
	for j in config.get("jauges", []):
		var id : String = j["id"]
		jauges[id] = int(j.get("init", 0))
	conflit_actif = true
	conflit_started.emit(conflit_id_courant)


## Applique l'effet d'une option. `effets` = { jauge_id: delta, ... }
## Vérifie les seuils après application.
func apply_option(effets: Dictionary) -> void:
	if not conflit_actif:
		return
	for jauge_id in effets.keys():
		if not jauges.has(jauge_id):
			continue
		var ancienne : int = jauges[jauge_id]
		var bornes := _bornes_pour(jauge_id)
		var nouvelle : int = clampi(ancienne + int(effets[jauge_id]), bornes.x, bornes.y)
		jauges[jauge_id] = nouvelle
		if nouvelle != ancienne:
			jauge_changed.emit(conflit_id_courant, jauge_id, ancienne, nouvelle)
	check_seuils()


func check_seuils() -> void:
	if not conflit_actif:
		return
	for j in config_courante.get("jauges", []):
		var id : String = j["id"]
		var v : int = jauges.get(id, 0)
		if j.has("seuil_victoire") and v <= int(j["seuil_victoire"]):
			seuil_atteint.emit(conflit_id_courant, id, "victoire")
			_resoudre("victoire_" + id)
			return
		if j.has("seuil_defaite") and v >= int(j["seuil_defaite"]):
			seuil_atteint.emit(conflit_id_courant, id, "defaite")
			_resoudre("defaite_" + id)
			return


func end_round() -> void:
	if not conflit_actif:
		return
	rounds_restants = max(0, rounds_restants - 1)
	if rounds_restants == 0:
		_resoudre("temps_ecoule")


## --- Interne ---

func _bornes_pour(jauge_id: String) -> Vector2i:
	for j in config_courante.get("jauges", []):
		if j.get("id", "") == jauge_id:
			return Vector2i(int(j.get("min", 0)), int(j.get("max", 10)))
	return Vector2i(0, 10)


func _resoudre(issue: String) -> void:
	conflit_actif = false
	var flag_name : String = config_courante.get("flag_resultat", "")
	if not flag_name.is_empty():
		GameStateManager.set_flag(flag_name, issue)
	conflit_resolu.emit(conflit_id_courant, issue)
