extends Node2D
## FIN-2 — La Route
##
## Conditions : confiance_confluence 4-7 · pas d'attachement dominant
##              · lumen_fragment_5 = true
##
## TODO : contenu narratif, musique de fin, crédits.

const TIMELINE_PATH : String = "res://dialogic/fins/fin_la_route.dtl"


func _ready() -> void:
	_demarrer_fin()


func _demarrer_fin() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null or not ResourceLoader.exists(TIMELINE_PATH):
		push_warning("FinManager — La Route : timeline manquante %s" % TIMELINE_PATH)
		return
	if dialogic.has_method("start"):
		dialogic.start(TIMELINE_PATH)


func _get_dialogic() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Dialogic")
