extends Node2D
## FIN-4 — La Rupture
##
## Conditions : violence_choix_acte3 = "radical" · offre_reponse = "refuse"
##              · confiance_confluence ≤3 (fil 1 complet, refus total)
##
## TODO : contenu narratif, musique de fin, crédits.

const TIMELINE_PATH : String = "res://dialogic/fins/fin_rupture.dtl"


func _ready() -> void:
	_demarrer_fin()


func _demarrer_fin() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null or not ResourceLoader.exists(TIMELINE_PATH):
		push_warning("FinManager — La Rupture : timeline manquante %s" % TIMELINE_PATH)
		return
	if dialogic.has_method("start"):
		dialogic.start(TIMELINE_PATH)


func _get_dialogic() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Dialogic")
