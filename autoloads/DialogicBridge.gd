extends Node
## DialogicBridge — pont entre Dialogic 2 et les managers de RÉSILIENCES
##
## Usage depuis une timeline Dialogic : ajouter un événement Signal avec
## comme argument une chaîne "commande:arg1:arg2:...".
##
## Commandes supportées :
##   relation:<pnj_id>:<delta>                       → RelationManager.modify
##   flag:<flag_name>:<valeur>                        → GameStateManager.set_flag
##   menace_add:<zone>:<valeur>[:raison]              → MenaceManager.add_menace
##   lumen_set_etat:<ETAT>                            → LumenManager.set_etat
##   lumen_fragment:<numero>                          → LumenManager.add_fragment
##   item_add:<item_id>[:quantite]                    → InventaireManager.add_item
##   item_remove:<item_id>[:quantite]                 → InventaireManager.remove_item
##   show_observations:<scene_id>                     → ouvre ObservationMenu
##   start_vote:<vote_id>:<seuil>:<tours>             → ouvre AssembléeVote
##   start_conflit:<conflit_id>                       → ouvre ConflitJauges
##
## Les payloads riches (liste d'observations, participants, jauges…) sont
## chargés depuis data/scenarios/<scene_id>.json — voir _charger_scenario().

signal observation_requested(observations: Array)
signal vote_requested(config: Dictionary)
signal conflit_requested(config: Dictionary)


func _ready() -> void:
	call_deferred("_brancher_signal_event")


func _brancher_signal_event() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	if dialogic.has_signal("signal_event") and not dialogic.signal_event.is_connected(_on_dialogic_signal):
		dialogic.signal_event.connect(_on_dialogic_signal)


## Point d'entrée principal — usage interne ou depuis une scène hôte.
func dispatch(argument) -> void:
	_on_dialogic_signal(argument)


func _on_dialogic_signal(argument) -> void:
	var texte : String = str(argument).strip_edges()
	if texte.is_empty():
		return
	var parts : PackedStringArray = texte.split(":", false)
	if parts.size() == 0:
		return
	var cmd : String = parts[0].to_lower()
	match cmd:
		"relation":
			if parts.size() >= 3:
				RelationManager.modify(parts[1], int(parts[2]))
		"flag":
			if parts.size() >= 3:
				GameStateManager.set_flag(parts[1], _parse_value(parts[2]))
		"menace_add":
			if parts.size() >= 3:
				MenaceManager.add_menace(parts[1], int(parts[2]))
		"lumen_set_etat":
			if parts.size() >= 2:
				LumenManager.set_etat(LumenManager.parse_etat(parts[1]))
		"lumen_fragment":
			if parts.size() >= 2:
				LumenManager.add_fragment(int(parts[1]))
		"item_add":
			if parts.size() >= 2:
				var qte : int = 1 if parts.size() < 3 else int(parts[2])
				InventaireManager.add_item(parts[1], qte)
		"item_remove":
			if parts.size() >= 2:
				var qte : int = 1 if parts.size() < 3 else int(parts[2])
				InventaireManager.remove_item(parts[1], qte)
		"show_observations":
			if parts.size() >= 2:
				_demander_observations(parts[1])
		"start_vote":
			if parts.size() >= 4:
				_demander_vote(parts[1], parts[2], int(parts[3]))
		"start_conflit":
			if parts.size() >= 2:
				_demander_conflit(parts[1])
		_:
			push_warning("DialogicBridge: commande inconnue '%s' (texte=%s)" % [cmd, texte])


## --- Chargement de scénarios riches (observations, votes, conflits) ---

func _demander_observations(scene_id: String) -> void:
	var data := _charger_scenario("observations/" + scene_id)
	if data.is_empty():
		return
	observation_requested.emit(data.get("observations", []))


func _demander_vote(vote_id: String, seuil: String, tours: int) -> void:
	var data := _charger_scenario("votes/" + vote_id)
	if data.is_empty():
		# Configuration minimale : vote sans participants prédéfinis.
		vote_requested.emit({
			"vote_id": vote_id,
			"seuil": seuil,
			"tours": tours,
			"participants": [],
		})
		return
	data["vote_id"] = vote_id
	data["seuil"] = seuil
	data["tours"] = tours
	# Applique les modificateurs_contextuels avant émission.
	_appliquer_modificateurs(data)
	vote_requested.emit(data)


## Applique les modificateurs_contextuels du JSON de vote.
## Format attendu dans le JSON :
##   "modificateurs_contextuels": [
##     { "pnj_id": "yasmine", "condition": "flag:noemie_ok=true", "position_initiale": 1 }
##   ]
## position_initiale utilise les valeurs enum VotePosition (0=POUR,1=CONTRE,2=ABSTENTION,3=INDECIS).
func _appliquer_modificateurs(data: Dictionary) -> void:
	var mods : Array = data.get("modificateurs_contextuels", [])
	if mods.is_empty():
		return
	var participants : Array = data.get("participants", [])
	for mod in mods:
		if not mod is Dictionary:
			continue
		var cond : String = mod.get("condition", "")
		if not evaluer_condition(cond):
			continue
		var pnj_id : String = mod.get("pnj_id", "")
		var nouvelle_pos : int = int(mod.get("position_initiale", AssembleeVoteManager.VotePosition.INDECIS))
		# Cherche le participant correspondant et met à jour sa position.
		var trouve : bool = false
		for p in participants:
			if p is Dictionary and p.get("pnj_id", "") == pnj_id:
				p["position"] = nouvelle_pos
				trouve = true
				break
		if not trouve:
			# Ajoute le participant s'il n'est pas encore dans la liste.
			participants.append({ "pnj_id": pnj_id, "position": nouvelle_pos })
	data["participants"] = participants


func _demander_conflit(conflit_id: String) -> void:
	var data := _charger_scenario("conflits/" + conflit_id)
	if data.is_empty():
		return
	data["id"] = conflit_id
	conflit_requested.emit(data)


func _charger_scenario(relative: String) -> Dictionary:
	var path := "res://data/scenarios/" + relative + ".json"
	if not FileAccess.file_exists(path):
		push_warning("DialogicBridge: scénario introuvable %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## --- Évaluation de conditions (observations, votes, modificateurs) ---

## Évalue une condition.  Formats supportés :
##   ""  |  "toujours"               → toujours vrai
##   "lumen:<ETAT>"                  → LumenManager.lumen_etat == ETAT
##   "flag:<nom>"                    → GameStateManager.get_flag(nom) == true
##   "flag:<nom>=<valeur>"           → get_flag(nom) == valeur
##   "variable:<nom> <op> <valeur>"  → comparaison (>=, <=, !=, >, <, =)
##   "<nom>=<valeur>"  (compat)      → get_flag(nom) == valeur
##   "<nom>"           (compat)      → get_flag(nom) == true
func evaluer_condition(cond: String) -> bool:
	cond = cond.strip_edges()
	if cond.is_empty() or cond == "toujours":
		return true
	if cond.begins_with("lumen:"):
		var etat_nom := cond.substr(6).strip_edges().to_upper()
		var etat := LumenManager.parse_etat(etat_nom)
		return LumenManager.lumen_etat == etat
	if cond.begins_with("variable:"):
		return _evaluer_variable(cond.substr(9).strip_edges())
	if cond.begins_with("flag:"):
		cond = cond.substr(5).strip_edges()
	# Compat : "nom=valeur" ou "nom"
	if cond.contains("="):
		var parts := cond.split("=", false, 1)
		var flag := parts[0].strip_edges()
		var val  := _parse_value(parts[1].strip_edges())
		return GameStateManager.get_flag(flag) == val
	return GameStateManager.get_flag(cond) == true


func _evaluer_variable(expr: String) -> bool:
	for op in [">=", "<=", "!=", ">", "<", "="]:
		if expr.contains(op):
			var parts := expr.split(op, false, 1)
			if parts.size() < 2:
				continue
			var nom := parts[0].strip_edges()
			var val  := _parse_value(parts[1].strip_edges())
			var actuelle = GameStateManager.get_flag(nom)
			match op:
				">=": return actuelle >= val
				"<=": return actuelle <= val
				"!=": return actuelle != val
				">":  return actuelle > val
				"<":  return actuelle < val
				"=":  return actuelle == val
	push_warning("DialogicBridge: expression variable invalide '%s'" % expr)
	return false


## --- Helpers ---

func _parse_value(brut: String):
	var t := brut.strip_edges()
	var low := t.to_lower()
	if low == "true":  return true
	if low == "false": return false
	if t.is_valid_int():
		return int(t)
	if t.is_valid_float():
		return float(t)
	return brut


func _get_dialogic() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var n := tree.root.get_node_or_null("Dialogic")
		if n:
			return n
	if Engine.has_singleton("Dialogic"):
		var s = Engine.get_singleton("Dialogic")
		if s is Node:
			return s
	return null
