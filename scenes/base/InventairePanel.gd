extends Control
## InventairePanel — panneau latéral de l'inventaire
##
## Ouverture via la touche `ouvrir_inventaire` (cf. project.godot).
## Se ferme automatiquement à l'ouverture d'un dialogue Dialogic.
## Si LUMEN est actif et propose un hint de craft → suggestion affichée.

@onready var _liste : VBoxContainer = $Panel/VBox/Items
@onready var _hint : Label = $Panel/VBox/Hint
@onready var _craft_btn : Button = $Panel/VBox/Craft

var _selection : Array = []   # ids sélectionnés pour craft (max 2)


func _ready() -> void:
	visible = false
	InventaireManager.inventory_changed.connect(_on_inventory_changed)
	LumenManager.etat_changed.connect(_on_lumen_etat_changed)
	_craft_btn.pressed.connect(_on_craft_pressed)
	_brancher_dialogic()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ouvrir_inventaire"):
		toggle()


func toggle() -> void:
	visible = not visible
	if visible:
		_rebuild()


func close() -> void:
	visible = false


func _rebuild() -> void:
	for c in _liste.get_children():
		c.queue_free()
	_selection.clear()
	_craft_btn.disabled = true

	# Regroupement par catégorie.
	var par_categorie : Dictionary = {}
	for item_id in InventaireManager.items.keys():
		var def := InventaireManager.get_definition(item_id)
		var cat : String = def.get("categorie", "divers")
		if not par_categorie.has(cat):
			par_categorie[cat] = []
		par_categorie[cat].append(item_id)

	for cat in par_categorie.keys():
		var header := Label.new()
		header.text = "— %s —" % cat
		_liste.add_child(header)
		for item_id in par_categorie[cat]:
			_ajouter_ligne(item_id)

	# Hint LUMEN si pertinent.
	var hints : Array = InventaireManager.get_craftable_hints()
	if hints.size() > 0:
		_hint.text = "[LUMEN] tu peux assembler : %s" % ", ".join(hints)
		_hint.visible = true
	else:
		_hint.visible = false


func _ajouter_ligne(item_id: String) -> void:
	var def := InventaireManager.get_definition(item_id)
	var nom : String = def.get("nom", item_id)
	var qte : int = InventaireManager.get_quantity(item_id)
	var btn := Button.new()
	btn.name = "Item_" + item_id
	btn.text = "%s ×%d" % [nom, qte]
	btn.toggle_mode = true
	btn.toggled.connect(_on_item_toggle.bind(item_id))
	_liste.add_child(btn)


func _on_item_toggle(pressed: bool, item_id: String) -> void:
	if pressed:
		_selection.append(item_id)
		if _selection.size() > 2:
			var oldest : String = _selection.pop_front()
			var oldest_btn := _liste.get_node_or_null("Item_" + oldest) as Button
			if oldest_btn:
				oldest_btn.set_pressed_no_signal(false)
	else:
		_selection.erase(item_id)
	_craft_btn.disabled = _trouver_recette_pour_selection().is_empty()


func _trouver_recette_pour_selection() -> String:
	for r in CraftManager.get_available_recipes():
		var ings : Array = r.get("ingredients", [])
		if ings.size() != _selection.size():
			continue
		var ok := true
		for i in ings:
			if not _selection.has(i):
				ok = false
				break
		if ok:
			return r["id"]
	return ""


func _on_craft_pressed() -> void:
	var recette := _trouver_recette_pour_selection()
	if recette.is_empty():
		return
	CraftManager.craft(recette)
	_rebuild()


func _on_inventory_changed(_item_id: String, _delta: int) -> void:
	if visible:
		_rebuild()


func _on_lumen_etat_changed(_a: int, _n: int) -> void:
	if visible:
		_rebuild()


## Le panneau se ferme automatiquement à l'entrée d'une timeline.
func _brancher_dialogic() -> void:
	call_deferred("_essayer_brancher_dialogic")


func _essayer_brancher_dialogic() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var dialogic := tree.root.get_node_or_null("Dialogic")
	if dialogic and dialogic.has_signal("timeline_started"):
		if not dialogic.timeline_started.is_connected(close):
			dialogic.timeline_started.connect(close)
