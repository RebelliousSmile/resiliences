extends Node2D
## FIN-1 — Enracinement
##
## Conditions : confiance_confluence ≥8 · confiance_gerland ≥6
##              · offre_reponse="refuse" · fil4 développé (ami ou amour)
##
## TODO : contenu narratif, musique de fin, crédits.

const TIMELINE_PATH : String = "res://dialogic/fins/fin_enracinement.dtl"


func _ready() -> void:
	_demarrer_fin()


func _demarrer_fin() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null or not ResourceLoader.exists(TIMELINE_PATH):
		push_warning("FinManager — Enracinement : timeline manquante %s" % TIMELINE_PATH)
		return
	if dialogic.has_method("start"):
		dialogic.start(TIMELINE_PATH)


func _get_dialogic() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Dialogic")
