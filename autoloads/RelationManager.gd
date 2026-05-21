extends Node
## RelationManager — relations PNJ pour RÉSILIENCES
##
## Échelle −100 → +100.
## Seuils :
##   Méfiance  (< −30)
##   Neutre    (−30 à 30)
##   Sympathie (30 à 60)
##   Confiance (60 à 85)
##   Intime    (> 85)

const SCORE_MIN : int = -100
const SCORE_MAX : int = 100

const SEUIL_MEFIANCE  : int = -30
const SEUIL_SYMPATHIE : int = 30
const SEUIL_CONFIANCE : int = 60
const SEUIL_INTIME    : int = 85

# PNJ canoniques de RÉSILIENCES. Les valeurs initiales sont à 0 (Neutre).
var relations : Dictionary = {
	"loan": 0,
	"erwan": 0,
	"tanguy": 0,
	"ora": 0,
	"felix": 0,
	"souri": 0,
	"lise": 0,
	"armand": 0,
	"yasmine": 0,
	"bap": 0,
	"irene": 0,
	"sofiane": 0,
	"marta": 0,
	"noemie": 0,
	"nathan_berge": 0,
	"zel": 0,
}

signal relation_changed(pnj_id: String, ancienne: int, nouvelle: int)


func modify(pnj_id: String, delta: int) -> void:
	if not relations.has(pnj_id):
		push_warning("RelationManager: PNJ inconnu '%s'" % pnj_id)
		return
	var ancienne : int = relations[pnj_id]
	var nouvelle : int = clampi(ancienne + delta, SCORE_MIN, SCORE_MAX)
	relations[pnj_id] = nouvelle
	relation_changed.emit(pnj_id, ancienne, nouvelle)


func get_value(pnj_id: String) -> int:
	return relations.get(pnj_id, 0)


## Renvoie le palier ("mefiance" | "neutre" | "sympathie" | "confiance" | "intime").
func get_seuil(pnj_id: String) -> String:
	var v : int = get_value(pnj_id)
	if v < SEUIL_MEFIANCE:
		return "mefiance"
	if v < SEUIL_SYMPATHIE:
		return "neutre"
	if v < SEUIL_CONFIANCE:
		return "sympathie"
	if v <= SEUIL_INTIME:
		return "confiance"
	return "intime"


## Réinitialise toutes les relations à zéro.
func reset() -> void:
	for k in relations.keys():
		relations[k] = 0


## Sérialisation pour SaveManager.
func to_dict() -> Dictionary:
	return relations.duplicate(true)


func from_dict(data: Dictionary) -> void:
	for k in relations.keys():
		if data.has(k):
			relations[k] = int(data[k])
