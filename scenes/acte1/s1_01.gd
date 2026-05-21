extends Node2D
## S1-01 — Bord du Couloir (aube)
##
## Scène de test d'intégration : valide que tous les autoloads et HUD
## sont fonctionnels. Lance la timeline dialogic/s1_01.dtl au _ready.

const TIMELINE_PATH : String = "res://dialogic/s1_01.dtl"


func _ready() -> void:
	_demarrer_timeline()


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
