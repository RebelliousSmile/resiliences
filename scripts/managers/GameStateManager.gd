extends Node
## GameStateManager
##
## Autoload : conserve l'état narratif global (flags, décisions, chapitre).
## Sert de source de vérité pour les conditions de branchement Dialogic.

# Émis à chaque modification de flag.
signal flag_changed(key: String, old_value, new_value)

# Émis quand une décision importante est enregistrée.
signal decision_recorded(decision_id: String, choix: String)

# Émis quand le chapitre change.
signal chapitre_changed(ancien: String, nouveau: String)

# État global du monde : flags narratifs arbitraires.
var _flags: Dictionary = {}

# Historique des décisions importantes (ordre chronologique).
# Chaque entrée : { id, choix, contexte, timestamp }
var _decisions: Array = []

# Chapitre courant (ex: "ch01_arrivee").
var _chapitre: String = "prologue"


func _ready() -> void:
	# Branchement automatique sur Dialogic si l'addon est présent au runtime.
	# On utilise call_deferred pour laisser le temps aux autres autoloads de se charger.
	call_deferred("_brancher_dialogic")


## Pose ou met à jour un flag arbitraire.
func set_flag(key: String, value) -> void:
	var old_value = _flags.get(key, null)
	_flags[key] = value
	if old_value != value:
		flag_changed.emit(key, old_value, value)
		_sync_to_dialogic(key, value)


## Récupère un flag, avec valeur par défaut si absent.
func get_flag(key: String, default = null):
	return _flags.get(key, default)


## Renvoie true si le flag existe (quelle que soit sa valeur).
func has_flag(key: String) -> bool:
	return _flags.has(key)


## Supprime un flag.
func erase_flag(key: String) -> void:
	if _flags.has(key):
		var old = _flags[key]
		_flags.erase(key)
		flag_changed.emit(key, old, null)


## Enregistre une décision importante (consultable ensuite via get_decisions()).
func record_decision(decision_id: String, choix: String, contexte: String = "") -> void:
	_decisions.append({
		"id": decision_id,
		"choix": choix,
		"contexte": contexte,
		"timestamp": Time.get_unix_time_from_system(),
		"chapitre": _chapitre,
	})
	# Le choix est aussi exposé comme flag pour les conditions Dialogic.
	set_flag("decision_" + decision_id, choix)
	decision_recorded.emit(decision_id, choix)


## Renvoie l'historique complet des décisions.
func get_decisions() -> Array:
	return _decisions.duplicate(true)


## Renvoie le choix effectué pour une décision donnée, ou "" si absent.
func get_decision(decision_id: String) -> String:
	for d in _decisions:
		if d["id"] == decision_id:
			return d["choix"]
	return ""


## Change de chapitre.
func set_chapitre(nouveau: String) -> void:
	var ancien := _chapitre
	if ancien == nouveau:
		return
	_chapitre = nouveau
	chapitre_changed.emit(ancien, nouveau)


func get_chapitre() -> String:
	return _chapitre


## Réinitialise tout (nouvelle partie).
func reset() -> void:
	_flags.clear()
	_decisions.clear()
	_chapitre = "prologue"


## --- Persistance ---

func to_save_dict() -> Dictionary:
	return {
		"flags": _flags.duplicate(true),
		"decisions": _decisions.duplicate(true),
		"chapitre": _chapitre,
	}


func from_save_dict(data: Dictionary) -> void:
	_flags = data.get("flags", {}).duplicate(true)
	_decisions = data.get("decisions", []).duplicate(true)
	_chapitre = data.get("chapitre", "prologue")


## --- Intégration Dialogic ---

## Si Dialogic 2 est chargé, on miroite chaque flag dans
## les variables Dialogic pour pouvoir les tester depuis les timelines.
func _sync_to_dialogic(key: String, value) -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	# Dialogic 2 expose un sous-système VAR avec set_variable / get_variable.
	if "VAR" in dialogic:
		var vars_subsys = dialogic.VAR
		if vars_subsys and vars_subsys.has_method("set_variable"):
			vars_subsys.set_variable(key, value)


func _brancher_dialogic() -> void:
	if _get_dialogic() == null:
		return
	# Au chargement, on pousse tous les flags existants vers Dialogic.
	for k in _flags.keys():
		_sync_to_dialogic(k, _flags[k])


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
