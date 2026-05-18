extends Node
## LocationManager
##
## Autoload : pilote les changements de scène entre lieux avec un fondu plein écran.
## Conserve l'historique de navigation pour les retours en arrière.

# Durée du fade-out / fade-in (secondes).
const FADE_DURATION: float = 0.4

# Émis dès que la transition commence (utile pour bloquer les inputs).
signal location_change_started(nouveau_lieu: String)

# Émis quand le nouveau lieu est complètement chargé et visible.
signal location_changed(ancien_lieu: String, nouveau_lieu: String)

# Identifiant du lieu courant (clé arbitraire, ex: "appartement_lea").
var _lieu_actuel: String = ""

# Chemin de scène du lieu courant.
var _scene_actuelle: String = ""

# Pile { lieu, scene } des lieux précédents (pour retour en arrière).
var _historique: Array = []

# Verrou pour empêcher les transitions concurrentes.
var _transition_en_cours: bool = false

# CanvasLayer + ColorRect utilisés pour le fondu plein écran.
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	_creer_fade_overlay()


## Change de lieu avec une transition en fondu.
## `lieu` : identifiant logique (ex: "lycee_couloir").
## `scene_path` : chemin .tscn de la scène à charger.
func aller_a(lieu: String, scene_path: String) -> void:
	if _transition_en_cours:
		push_warning("LocationManager: transition déjà en cours, ignorée.")
		return
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("LocationManager: scène introuvable %s" % scene_path)
		return

	_transition_en_cours = true
	var ancien := _lieu_actuel
	location_change_started.emit(lieu)

	# Empile l'ancien lieu dans l'historique (si défini).
	if not _lieu_actuel.is_empty():
		_historique.append({"lieu": _lieu_actuel, "scene": _scene_actuelle})

	# Fade out → change de scène → fade in.
	await _fade(0.0, 1.0)
	get_tree().change_scene_to_file(scene_path)
	# On laisse un frame au moteur pour instancier la nouvelle scène.
	await get_tree().process_frame
	_lieu_actuel = lieu
	_scene_actuelle = scene_path
	await _fade(1.0, 0.0)

	_transition_en_cours = false
	location_changed.emit(ancien, lieu)


## Retour au lieu précédent. Renvoie false si l'historique est vide.
func retour() -> bool:
	if _historique.is_empty():
		return false
	var precedent: Dictionary = _historique.pop_back()
	# On ne ré-empile pas le lieu courant pour éviter les boucles.
	var sauvegarde := _lieu_actuel
	_lieu_actuel = ""
	await aller_a(precedent["lieu"], precedent["scene"])
	return true


func get_lieu_actuel() -> String:
	return _lieu_actuel


func get_scene_actuelle() -> String:
	return _scene_actuelle


func get_historique() -> Array:
	return _historique.duplicate(true)


## --- Persistance ---

func to_save_dict() -> Dictionary:
	return {
		"lieu_actuel": _lieu_actuel,
		"scene_actuelle": _scene_actuelle,
		"historique": _historique.duplicate(true),
	}


func from_save_dict(data: Dictionary) -> void:
	_lieu_actuel = data.get("lieu_actuel", "")
	_scene_actuelle = data.get("scene_actuelle", "")
	_historique = data.get("historique", []).duplicate(true)
	# Si une scène est connue, on y va sans transition (chargement de save).
	# Différé pour éviter de changer de scène pendant le parcours de l'arbre.
	if not _scene_actuelle.is_empty() and ResourceLoader.exists(_scene_actuelle):
		call_deferred("_charger_scene_sauvegardee", _scene_actuelle)


func _charger_scene_sauvegardee(path: String) -> void:
	get_tree().change_scene_to_file(path)


## --- Interne ---

func _creer_fade_overlay() -> void:
	# CanvasLayer au-dessus de tout pour ne pas être masqué par les scènes.
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_layer.add_child(_fade_rect)


func _fade(from_alpha: float, to_alpha: float) -> void:
	_fade_rect.color.a = from_alpha
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", to_alpha, FADE_DURATION)
	await tween.finished
