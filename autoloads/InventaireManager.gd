extends Node
## InventaireManager — items collectés par Max
##
## Les items sont chargés depuis data/items.json au démarrage.
## L'inventaire courant ne stocke que les quantités, pas les définitions.

const ITEMS_DEF_PATH : String = "res://data/items.json"

# { item_id: int } — quantités possédées
var items : Dictionary = {}

# Définitions des items : { item_id: { id, nom, description, categorie, ... } }
var _definitions : Dictionary = {}

signal inventory_changed(item_id: String, delta: int)


func _ready() -> void:
	_charger_definitions()


func _charger_definitions() -> void:
	if not FileAccess.file_exists(ITEMS_DEF_PATH):
		return
	var file := FileAccess.open(ITEMS_DEF_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("InventaireManager: items.json doit être un tableau")
		return
	for entry in parsed:
		if entry is Dictionary and entry.has("id"):
			_definitions[entry["id"]] = entry


func add_item(item_id: String, quantite: int = 1) -> void:
	if quantite <= 0:
		return
	var ancien : int = items.get(item_id, 0)
	items[item_id] = ancien + quantite
	inventory_changed.emit(item_id, quantite)


func remove_item(item_id: String, quantite: int = 1) -> void:
	if quantite <= 0 or not items.has(item_id):
		return
	var ancien : int = items[item_id]
	var nouvelle : int = max(0, ancien - quantite)
	if nouvelle == 0:
		items.erase(item_id)
	else:
		items[item_id] = nouvelle
	inventory_changed.emit(item_id, -quantite)


func has_item(item_id: String) -> bool:
	return items.has(item_id) and items[item_id] > 0


func get_quantity(item_id: String) -> int:
	return items.get(item_id, 0)


func get_definition(item_id: String) -> Dictionary:
	return _definitions.get(item_id, {})


## Renvoie les ids des recettes craftables actuellement, uniquement si
## LUMEN est ACTIF et que `lumen_hint` est vrai pour la recette.
## La vérification de faisabilité est déléguée à CraftManager.
func get_craftable_hints() -> Array:
	if not LumenManager.can_speak():
		return []
	if LumenManager.lumen_etat != LumenManager.LumenEtat.ACTIF:
		return []
	var out : Array = []
	for r in CraftManager.get_available_recipes():
		if r.get("lumen_hint", false):
			out.append(r["id"])
	return out


## Remet l'état à zéro (appelé par SaveManager avant chargement).
func reset() -> void:
	items.clear()


## Sérialisation pour SaveManager.
func to_dict() -> Dictionary:
	return items.duplicate(true)


func from_dict(data: Dictionary) -> void:
	items.clear()
	for k in data.keys():
		items[k] = int(data[k])
