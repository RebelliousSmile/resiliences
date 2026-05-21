extends Control
## ConflitJauges — UI des conflits par jauges
##
## Pas de chiffre : les jauges sont représentées par des ProgressBar
## stylisées, et les options affichent uniquement des icônes ↑↓ pour
## prévisualiser l'effet.

signal conflit_termine(issue: String)

@onready var _jauges_box : VBoxContainer = $Panel/VBox/Jauges
@onready var _options_box : VBoxContainer = $Panel/VBox/Options
@onready var _label_rounds : Label = $Panel/VBox/Rounds

var _config : Dictionary = {}
# { jauge_id: ProgressBar }
var _bars : Dictionary = {}


func _ready() -> void:
	visible = false
	DialogicBridge.conflit_requested.connect(open)
	ConflitManager.jauge_changed.connect(_on_jauge_changed)
	ConflitManager.conflit_resolu.connect(_on_resolu)


func open(config: Dictionary) -> void:
	_config = config
	ConflitManager.start_conflit(config)
	_construire_jauges()
	_construire_options()
	_refresh_rounds()
	visible = true


func _construire_jauges() -> void:
	for c in _jauges_box.get_children():
		c.queue_free()
	_bars.clear()
	for j in _config.get("jauges", []):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = str(j.get("label", j.get("id", "")))
		label.custom_minimum_size.x = 140
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.min_value = int(j.get("min", 0))
		bar.max_value = int(j.get("max", 10))
		bar.value = ConflitManager.jauges.get(j["id"], 0)
		bar.custom_minimum_size = Vector2(280, 24)
		row.add_child(bar)
		_jauges_box.add_child(row)
		_bars[j["id"]] = bar


func _construire_options() -> void:
	for c in _options_box.get_children():
		c.queue_free()
	var options : Array = _config.get("options", [])
	for opt in options:
		var visible_opt : bool = _condition_remplie(opt.get("condition", ""))
		if not visible_opt:
			continue
		var btn := Button.new()
		btn.text = "%s   %s" % [str(opt.get("label", "?")), _previsualiser(opt.get("effets", {}))]
		btn.pressed.connect(_on_option.bind(opt))
		_options_box.add_child(btn)

	if LumenManager.lumen_etat == LumenManager.LumenEtat.ACTIF and _config.has("option_lumen"):
		var opt_l : Dictionary = _config["option_lumen"]
		var btn := Button.new()
		btn.text = "[LUMEN] %s   %s" % [str(opt_l.get("label", "Analyser")), _previsualiser(opt_l.get("effets", {}))]
		btn.pressed.connect(_on_option.bind(opt_l))
		_options_box.add_child(btn)


func _previsualiser(effets: Dictionary) -> String:
	# Icônes uniquement, jamais de valeurs.
	var parts : Array = []
	for jauge_id in effets.keys():
		var d : int = int(effets[jauge_id])
		if d == 0:
			continue
		parts.append("%s %s" % [jauge_id, "↑" if d > 0 else "↓"])
	return "  ".join(parts)


func _on_option(opt: Dictionary) -> void:
	ConflitManager.apply_option(opt.get("effets", {}))
	if ConflitManager.conflit_actif:
		ConflitManager.end_round()
		_refresh_rounds()
		_construire_options()


func _refresh_rounds() -> void:
	_label_rounds.text = "Rounds restants : %d" % ConflitManager.rounds_restants


func _on_jauge_changed(_conflit_id: String, jauge_id: String, _ancienne: int, nouvelle: int) -> void:
	if _bars.has(jauge_id):
		var bar : ProgressBar = _bars[jauge_id]
		var tween := create_tween()
		tween.tween_property(bar, "value", nouvelle, 0.3)


func _on_resolu(_conflit_id: String, issue: String) -> void:
	visible = false
	conflit_termine.emit(issue)


func _condition_remplie(cond: String) -> bool:
	if cond.is_empty():
		return true
	return GameStateManager.get_flag(cond) == true
