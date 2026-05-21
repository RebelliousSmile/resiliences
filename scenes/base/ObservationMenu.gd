extends Control
## ObservationMenu — liste d'observations cliquables
##
## Reçoit une liste d'observations (typiquement via le signal
## DialogicBridge.observation_requested) :
##   { id, label, condition, texte, lumen_reaction? }
##
## Une observation lue devient inactive (une lecture = un usage).

signal observation_done(id: String)

@onready var _vbox : VBoxContainer = $Panel/VBox

var _observations : Array = []
var _vues : Dictionary = {}   # { id: true }


func _ready() -> void:
	visible = false
	DialogicBridge.observation_requested.connect(open)


func open(observations: Array) -> void:
	_observations = observations
	_vues.clear()
	_rebuild()
	visible = true


func close() -> void:
	visible = false


func _rebuild() -> void:
	for c in _vbox.get_children():
		c.queue_free()
	for obs in _observations:
		if not _condition_remplie(obs.get("condition", "")):
			continue
		var btn := Button.new()
		btn.text = str(obs.get("label", obs.get("id", "?")))
		var obs_id : String = obs.get("id", "")
		if _vues.has(obs_id):
			btn.disabled = true
		btn.pressed.connect(_on_observation_clicked.bind(obs))
		_vbox.add_child(btn)

	# Bouton "fin d'observations"
	var fermer := Button.new()
	fermer.text = "Reprendre"
	fermer.pressed.connect(close)
	_vbox.add_child(fermer)


func _on_observation_clicked(obs: Dictionary) -> void:
	var id : String = obs.get("id", "")
	_vues[id] = true
	# Injection texte : si un Dialogic est actif on lui passe une variable,
	# sinon on émet juste le signal pour la scène hôte.
	_injecter_texte(str(obs.get("texte", "")), obs)
	observation_done.emit(id)
	_rebuild()


func _injecter_texte(texte: String, obs: Dictionary) -> void:
	# Le texte d'observation est exposé via une variable Dialogic
	# `observation_courante` que les .dtl peuvent afficher.
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	if "VAR" in dialogic:
		var vars_subsys = dialogic.VAR
		if vars_subsys and vars_subsys.has_method("set_variable"):
			vars_subsys.set_variable("observation_courante", texte)
			# Réaction de LUMEN si actif et lumen_reaction défini.
			var reac : String = obs.get("lumen_reaction", "")
			if not reac.is_empty() and LumenManager.can_speak():
				vars_subsys.set_variable("lumen_observation_reaction", reac)
			else:
				vars_subsys.set_variable("lumen_observation_reaction", "")


func _condition_remplie(cond: String) -> bool:
	# Délègue à DialogicBridge pour partager la logique d'évaluation.
	return DialogicBridge.evaluer_condition(cond)


func _parse_value(brut: String):
	var low := brut.to_lower()
	if low == "true":  return true
	if low == "false": return false
	if brut.is_valid_int():
		return int(brut)
	return brut


func _get_dialogic() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_node_or_null("Dialogic")
	return null
