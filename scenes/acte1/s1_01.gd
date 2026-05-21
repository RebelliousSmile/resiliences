extends Node2D
## S1-01 — Bord du Couloir (aube)
##
## Scène de test d'intégration : valide que tous les autoloads et HUD
## sont fonctionnels. Lance la timeline dialogic/s1_01.dtl au _ready.
##
## Gestion des happenings :
##   - Les happenings en attente (déclenchés avant chargement de scène)
##     sont rejoués immédiatement avant le démarrage de la timeline.
##   - Les happenings déclenchés pendant la scène sont mis en file par
##     MenaceManager et joués au prochain appel de _jouer_happenings_en_attente().

const TIMELINE_PATH   : String = "res://dialogic/s1_01.dtl"
const HAPPENINGS_DIR  : String = "res://dialogic/happenings/"


func _ready() -> void:
	MenaceManager.happening_triggered.connect(_on_happening_triggered)
	_jouer_happenings_en_attente()
	_demarrer_timeline()


## Joue immédiatement les happenings accumulés avant l'entrée dans la scène.
func _jouer_happenings_en_attente() -> void:
	var pending := MenaceManager.consume_pending_happenings()
	for happening_id in pending:
		_lancer_happening(happening_id)


## Reçoit les happenings déclenchés en cours de scène.
## Si Dialogic est déjà actif, on ne lance rien maintenant : MenaceManager
## a déjà mis le happening en file — il sera consommé à la prochaine scène.
func _on_happening_triggered(happening_id: String) -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	# Propriété `current_timeline` disponible dans Dialogic 2.
	var timeline_active : bool = false
	if "current_timeline" in dialogic:
		timeline_active = dialogic.current_timeline != null
	if not timeline_active:
		_lancer_happening(happening_id)


func _lancer_happening(happening_id: String) -> void:
	var path : String = HAPPENINGS_DIR + happening_id + ".dtl"
	if not ResourceLoader.exists(path):
		push_warning("S1-01 : happening introuvable %s" % path)
		return
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	if dialogic.has_method("start"):
		dialogic.start(path)


func _demarrer_timeline() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		push_warning("S1-01 : Dialogic absent, la timeline ne sera pas démarrée.")
		return
	if not ResourceLoader.exists(TIMELINE_PATH):
		push_warning("S1-01 : timeline introuvable %s" % TIMELINE_PATH)
		return
	if dialogic.has_method("start"):
		dialogic.start(TIMELINE_PATH)


func _get_dialogic() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Dialogic")
