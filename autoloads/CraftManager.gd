extends Node
## CraftManager — recettes de bricolage
##
## Charge les recettes depuis data/recettes.json au démarrage.
## Une recette = { id, ingredients, resultat, condition?, lumen_hint? }
## L'inventaire est InventaireManager (autoload séparé).

const RECETTES_PATH : String = "res://data/recettes.json"

var _recettes : Array = []   # liste de Dictionary

signal item_crafted(recette_id: String, resultat_id: String)


func _ready() -> void:
	_charger_recettes()


func _charger_recettes() -> void:
	if not FileAccess.file_exists(RECETTES_PATH):
		return
	var file := FileAccess.open(RECETTES_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("CraftManager: recettes.json doit être un tableau")
		return
	_recettes = parsed


func can_craft(recette_id: String) -> bool:
	var r := _trouver_recette(recette_id)
	if r.is_empty():
		return false
	# Condition flag éventuelle.
	var cond : String = r.get("condition", "")
	if not cond.is_empty():
		if not GameStateManager.get_flag(cond):
			return false
	for ing in r.get("ingredients", []):
		if not InventaireManager.has_item(ing):
			return false
	return true


func craft(recette_id: String) -> void:
	if not can_craft(recette_id):
		return
	var r := _trouver_recette(recette_id)
	for ing in r.get("ingredients", []):
		InventaireManager.remove_item(ing, 1)
	var resultat : String = r.get("resultat", "")
	if not resultat.is_empty():
		InventaireManager.add_item(resultat, 1)
	item_crafted.emit(recette_id, resultat)


## Renvoie la liste complète des recettes actuellement craftables.
func get_available_recipes() -> Array:
	var out : Array = []
	for r in _recettes:
		if can_craft(r.get("id", "")):
			out.append(r)
	return out


func _trouver_recette(recette_id: String) -> Dictionary:
	for r in _recettes:
		if r.get("id", "") == recette_id:
			return r
	return {}
