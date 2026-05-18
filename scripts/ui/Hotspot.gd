extends Area2D
## Hotspot
##
## Zone cliquable dans un lieu. Au clic, peut :
## - démarrer une timeline Dialogic
## - changer de lieu
## - poser un flag narratif
## - émettre un signal libre pour scripts ad hoc
##
## Tout est optionnel — on configure depuis l'inspecteur.

# Identifiant logique du hotspot (libre).
@export var id: String = ""

# Libellé affiché au survol (peut être vide).
@export var libelle: String = ""

# Timeline Dialogic à démarrer (chemin .dtl). Vide = aucune.
@export_file("*.dtl") var timeline: String = ""

# Lieu cible (id logique) si le clic doit déclencher un changement de lieu.
@export var lieu_cible: String = ""

# Scène cible (.tscn) associée au lieu cible.
@export_file("*.tscn") var scene_cible: String = ""

# Flag à poser au clic (clé). Vide = aucun.
@export var flag_a_poser: String = ""

# Valeur du flag (par défaut true).
@export var valeur_flag: Variant = true

# Émis au clic ; permet d'attacher des comportements custom depuis la scène.
signal clique(hotspot_id: String)
# Émis au survol.
signal survol(hotspot_id: String, entered: bool)


func _ready() -> void:
	input_pickable = true
	# Connexion native d'Area2D pour le clic / survol.
	input_event.connect(_on_input_event)
	mouse_entered.connect(func(): survol.emit(id, true))
	mouse_exited.connect(func(): survol.emit(id, false))


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_declencher()


func _declencher() -> void:
	clique.emit(id)

	# 1. Flag éventuel.
	if not flag_a_poser.is_empty() and GameStateManager:
		GameStateManager.set_flag(flag_a_poser, valeur_flag)

	# 2. Démarrage d'une timeline Dialogic si renseignée.
	if not timeline.is_empty():
		var dialogic := _get_dialogic()
		if dialogic and dialogic.has_method("start"):
			dialogic.start(timeline)
			return
		else:
			push_warning("Hotspot '%s' : Dialogic absent, timeline ignorée." % id)
			return

	# 3. Changement de lieu si renseigné (et pas de timeline).
	if not lieu_cible.is_empty() and not scene_cible.is_empty() and LocationManager:
		LocationManager.aller_a(lieu_cible, scene_cible)


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
