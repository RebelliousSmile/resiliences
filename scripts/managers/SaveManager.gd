extends Node
## SaveManager
##
## Autoload : sérialise / désérialise l'état du jeu en JSON.
## 3 slots disponibles ; chaque slot contient relations + flags + lieu + chapitre.

const SAVE_DIR: String = "user://saves"
const SAVE_PREFIX: String = "slot_"
const SAVE_EXT: String = ".json"
const NB_SLOTS: int = 3
const SAVE_VERSION: int = 1

# Émis après une sauvegarde réussie ou échouée.
signal save_completed(slot: int, success: bool)

# Émis après un chargement réussi ou échoué.
signal load_completed(slot: int, success: bool)


func _ready() -> void:
	_ensure_save_dir()


## Sauvegarde dans le slot donné (0..NB_SLOTS-1).
## Retourne true si la sauvegarde a réussi.
func sauvegarder(slot: int) -> bool:
	if slot < 0 or slot >= NB_SLOTS:
		push_error("SaveManager: slot invalide %s" % slot)
		save_completed.emit(slot, false)
		return false

	var payload: Dictionary = _collecter_etat()
	var path: String = _path_pour_slot(slot)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: impossible d'ouvrir %s en écriture" % path)
		save_completed.emit(slot, false)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit(slot, true)
	return true


## Charge un slot. Retourne true si succès.
func charger(slot: int) -> bool:
	if slot < 0 or slot >= NB_SLOTS:
		push_error("SaveManager: slot invalide %s" % slot)
		load_completed.emit(slot, false)
		return false

	var path: String = _path_pour_slot(slot)
	if not FileAccess.file_exists(path):
		load_completed.emit(slot, false)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: impossible d'ouvrir %s en lecture" % path)
		load_completed.emit(slot, false)
		return false

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: JSON invalide dans %s" % path)
		load_completed.emit(slot, false)
		return false

	_appliquer_etat(parsed)
	load_completed.emit(slot, true)
	return true


## Retourne true si le slot existe sur disque.
func slot_existe(slot: int) -> bool:
	return FileAccess.file_exists(_path_pour_slot(slot))


## Renvoie un résumé léger du slot, sans tout charger.
## { existe, timestamp, chapitre, lieu } — utile pour l'écran de chargement.
func info_slot(slot: int) -> Dictionary:
	var path: String = _path_pour_slot(slot)
	if not FileAccess.file_exists(path):
		return {"existe": false}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"existe": false}
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"existe": false}

	return {
		"existe": true,
		"timestamp": parsed.get("timestamp", 0),
		"chapitre": parsed.get("game_state", {}).get("chapitre", ""),
		"lieu": parsed.get("location", {}).get("lieu_actuel", ""),
	}


## Supprime un slot.
func effacer_slot(slot: int) -> bool:
	var path: String = _path_pour_slot(slot)
	if not FileAccess.file_exists(path):
		return false
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return false
	return dir.remove(path.get_file()) == OK


## --- Interne ---

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _path_pour_slot(slot: int) -> String:
	return "%s/%s%d%s" % [SAVE_DIR, SAVE_PREFIX, slot, SAVE_EXT]


func _collecter_etat() -> Dictionary:
	# On interroge chaque manager via son contrat to_save_dict().
	# Les autoloads sont accédés par nom de chemin /root/<Name>.
	var rel := _get_autoload("RelationManager")
	var gs := _get_autoload("GameStateManager")
	var loc := _get_autoload("LocationManager")

	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"relations": rel.to_save_dict() if rel else {},
		"game_state": gs.to_save_dict() if gs else {},
		"location": loc.to_save_dict() if loc else {},
	}


func _appliquer_etat(data: Dictionary) -> void:
	var rel := _get_autoload("RelationManager")
	var gs := _get_autoload("GameStateManager")
	var loc := _get_autoload("LocationManager")

	if rel:
		rel.from_save_dict(data.get("relations", {}))
	if gs:
		gs.from_save_dict(data.get("game_state", {}))
	if loc:
		loc.from_save_dict(data.get("location", {}))


func _get_autoload(nom: String) -> Node:
	var root := get_tree().root if get_tree() else null
	if root == null:
		return null
	return root.get_node_or_null(nom)
