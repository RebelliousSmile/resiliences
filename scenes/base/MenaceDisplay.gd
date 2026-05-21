extends Control
## MenaceDisplay — HUD discret par zone de menace
##
## Une icône par zone. Pas de chiffre, pas de barre.
##   palier 0-2 → invisible
##   palier 3-5 → neutre
##   palier 6-8 → pulse lente
##   palier 9   → pulse rapide

const ZONES : PackedStringArray = ["confluence", "gerland", "vallee", "solaize"]

@onready var _hbox : HBoxContainer = $HBox

# { zone: TextureRect }
var _icones : Dictionary = {}
# { zone: AnimationPlayer }
var _animations : Dictionary = {}


func _ready() -> void:
	for zone in ZONES:
		_construire_icone(zone)
	MenaceManager.menace_changed.connect(_on_menace_changed)
	for zone in ZONES:
		_refresh(zone)


func _construire_icone(zone: String) -> void:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(40, 40)
	_hbox.add_child(wrapper)

	var icone := TextureRect.new()
	icone.name = "Icone"
	icone.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.tooltip_text = zone
	wrapper.add_child(icone)

	var player := AnimationPlayer.new()
	player.name = "Anim"
	wrapper.add_child(player)
	var lib := AnimationLibrary.new()

	var slow := Animation.new()
	slow.length = 2.0
	slow.loop_mode = Animation.LOOP_LINEAR
	var slow_track := slow.add_track(Animation.TYPE_VALUE)
	slow.track_set_path(slow_track, "Icone:modulate:a")
	slow.track_insert_key(slow_track, 0.0, 0.4)
	slow.track_insert_key(slow_track, 1.0, 1.0)
	slow.track_insert_key(slow_track, 2.0, 0.4)
	lib.add_animation("pulse_slow", slow)

	var fast := Animation.new()
	fast.length = 0.6
	fast.loop_mode = Animation.LOOP_LINEAR
	var fast_track := fast.add_track(Animation.TYPE_VALUE)
	fast.track_set_path(fast_track, "Icone:modulate:a")
	fast.track_insert_key(fast_track, 0.0, 0.3)
	fast.track_insert_key(fast_track, 0.3, 1.0)
	fast.track_insert_key(fast_track, 0.6, 0.3)
	lib.add_animation("pulse_fast", fast)

	player.add_animation_library("", lib)

	_icones[zone] = icone
	_animations[zone] = player


func _on_menace_changed(zone: String, _ancienne: int, _nouvelle: int) -> void:
	_refresh(zone)


func _refresh(zone: String) -> void:
	if not _icones.has(zone):
		return
	var icone : TextureRect = _icones[zone]
	var player : AnimationPlayer = _animations[zone]
	var v : int = _valeur_zone(zone)
	if v <= 2:
		icone.visible = false
		player.stop()
		return
	icone.visible = true
	if v <= 5:
		icone.modulate = Color(1, 1, 1, 1)
		player.stop()
	elif v <= 8:
		player.play("pulse_slow")
	else:
		player.play("pulse_fast")


func _valeur_zone(zone: String) -> int:
	match zone:
		"confluence": return MenaceManager.menace_confluence
		"gerland":    return MenaceManager.menace_gerland
		"vallee":     return MenaceManager.menace_vallee
		"solaize":    return MenaceManager.menace_solaize
	return 0
