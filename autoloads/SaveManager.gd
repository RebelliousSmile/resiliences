extends Node
## SaveManager — 3 slots JSON, indépendant de Maaack
##
## Persiste l'intégralité de l'état du jeu :
##   GameStateManager + RelationManager + LumenManager + MenaceManager
##   + InventaireManager + acte/node courant.

const SAVE_DIR    : String = "user://saves"
const SLOT_PREFIX : String = "slot_"
const SLOT_EXT    : String = ".json"
const NB_SLOTS    : int    = 3
const SAVE_VERSION: int    = 1

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save(slot: int) -> void:
	if not _slot_valide(slot):
		save_completed.emit(slot, false)
		return
	var payload := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameStateManager.to_dict(),
		"relations":  RelationManager.to_dict(),
		"lumen":      LumenManager.to_dict(),
		"menace":     MenaceManager.to_dict(),
		"inventaire": InventaireManager.to_dict(),
	}
	var path := _path_for_slot(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: écriture impossible %s" % path)
		save_completed.emit(slot, false)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit(slot, true)


func load_save(slot: int) -> bool:
	if not _slot_valide(slot):
		load_completed.emit(slot, false)
		return false
	var path := _path_for_slot(slot)
	if not FileAccess.file_exists(path):
		load_completed.emit(slot, false)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_completed.emit(slot, false)
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: JSON invalide %s" % path)
		load_completed.emit(slot, false)
		return false

	# Reset avant d'appliquer pour repartir d'une base propre.
	GameStateManager.reset()
	RelationManager.reset()

	GameStateManager.from_dict(parsed.get("game_state", {}))
	RelationManager.from_dict(parsed.get("relations", {}))
	LumenManager.from_dict(parsed.get("lumen", {}))
	MenaceManager.from_dict(parsed.get("menace", {}))
	InventaireManager.from_dict(parsed.get("inventaire", {}))

	load_completed.emit(slot, true)
	return true


func delete_save(slot: int) -> void:
	if not _slot_valide(slot):
		return
	var path := _path_for_slot(slot)
	if not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		dir.remove(path.get_file())


func has_save(slot: int) -> bool:
	if not _slot_valide(slot):
		return false
	return FileAccess.file_exists(_path_for_slot(slot))


## Résumé léger pour le menu de chargement, sans appliquer la sauvegarde.
## Retourne { acte, node, timestamp } ou {} si le slot est vide / corrompu.
func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_path_for_slot(slot), FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var gs : Dictionary = parsed.get("game_state", {})
	return {
		"acte": gs.get("acte_courant", ""),
		"node": gs.get("node_courant", ""),
		"timestamp": parsed.get("timestamp", 0),
	}


## --- Interne ---

func _slot_valide(slot: int) -> bool:
	if slot < 1 or slot > NB_SLOTS:
		push_error("SaveManager: slot %d hors bornes (1..%d)" % [slot, NB_SLOTS])
		return false
	return true


func _path_for_slot(slot: int) -> String:
	return "%s/%s%d%s" % [SAVE_DIR, SLOT_PREFIX, slot, SLOT_EXT]
