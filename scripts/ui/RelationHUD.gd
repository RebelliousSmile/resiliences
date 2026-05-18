extends Control
## RelationHUD
##
## HUD discret affichant les niveaux de relation des personnages présents
## dans le lieu courant. Se met à jour automatiquement via les signaux
## de RelationManager.
##
## À utiliser comme racine d'une petite scène (cf. RelationHUD.tscn) ou
## comme noeud enfant ajouté à la main dans un lieu.

# Liste des personnages à afficher (à renseigner dans l'inspecteur).
@export var personnages_presents: PackedStringArray = []

# Petit feedback flash quand la valeur change (en secondes).
const FLASH_DURATION: float = 0.6

# Conteneur où on instancie les lignes "nom : niveau".
# Non-typé pour pouvoir rester null si la scène associée n'a pas
# la structure attendue (cas du HUD instancié par code).
@onready var _vbox: Node = get_node_or_null("Panel/VBox")

# Dictionnaire personnage -> Label pour mise à jour rapide.
var _labels: Dictionary = {}


func _ready() -> void:
	# Si le noeud n'a pas de structure attendue (utilisation par code),
	# on la construit à la volée.
	if _vbox == null:
		_construire_layout()

	# Connexion aux signaux du RelationManager (autoload).
	if RelationManager:
		RelationManager.score_changed.connect(_on_score_changed)
		RelationManager.relation_changed.connect(_on_relation_changed)

	_rebuild()


## Permet à un lieu de déclarer dynamiquement les personnages présents.
func set_personnages(liste: PackedStringArray) -> void:
	personnages_presents = liste
	_rebuild()


func _rebuild() -> void:
	# Vide la liste actuelle.
	for child in _vbox.get_children():
		child.queue_free()
	_labels.clear()

	for nom in personnages_presents:
		var label := Label.new()
		label.name = "Rel_" + nom
		label.text = _format_ligne(nom)
		label.add_theme_font_size_override("font_size", 14)
		_vbox.add_child(label)
		_labels[nom] = label


func _format_ligne(personnage: String) -> String:
	var niveau: String = RelationManager.get_niveau(personnage) if RelationManager else "?"
	var score: int = RelationManager.get_score(personnage) if RelationManager else 0
	return "%s — %s (%d)" % [personnage, niveau, score]


func _on_score_changed(personnage: String, _ancien: int, _nouveau: int, _raison: String) -> void:
	if not _labels.has(personnage):
		return
	var label: Label = _labels[personnage]
	label.text = _format_ligne(personnage)
	_flash(label)


func _on_relation_changed(personnage: String, _ancien: String, _nouveau: String) -> void:
	# Déjà couvert par _on_score_changed pour le texte ; ici on peut
	# ajouter un effet plus marqué pour le passage de palier.
	if not _labels.has(personnage):
		return
	_flash(_labels[personnage], Color.YELLOW)


func _flash(node: Control, couleur: Color = Color.WHITE) -> void:
	node.modulate = couleur
	var tween := create_tween()
	tween.tween_property(node, "modulate", Color.WHITE, FLASH_DURATION)


func _construire_layout() -> void:
	# Layout minimal de secours quand le HUD est instancié sans .tscn associé.
	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.offset_left = 16
	panel.offset_top = 16
	panel.offset_right = 280
	panel.offset_bottom = 140
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	panel.add_child(vbox)
	_vbox = vbox
