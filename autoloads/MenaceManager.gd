extends Node
## MenaceManager — niveaux de menace par zone (0 → 10)
##
## Aucun affichage numérique. Les happenings sont déclenchés au franchissement
## d'un palier. Les happenings réversibles peuvent être annulés si la menace
## redescend ; les irréversibles restent verrouillés.

var menace_confluence : int = 0
var menace_gerland    : int = 0
var menace_vallee     : int = 0
var menace_solaize    : int = 0   # transversal — affecte toutes les zones

signal menace_changed(zone: String, ancienne: int, nouvelle: int)
signal happening_triggered(happening_id: String)

const VALEUR_MIN : int = 0
const VALEUR_MAX : int = 10

const PALIERS : Dictionary = {
	"confluence": [
		{ "seuil": 3, "happening": "h_confluence_tension_interne",    "reversible": true  },
		{ "seuil": 6, "happening": "h_confluence_acces_restreint",    "reversible": false },
		{ "seuil": 9, "happening": "h_confluence_ultimatum_solaize",  "reversible": false },
	],
	"gerland": [
		{ "seuil": 3, "happening": "h_gerland_blocage_composants",    "reversible": true  },
		{ "seuil": 6, "happening": "h_gerland_panne_generateur",      "reversible": false },
		{ "seuil": 9, "happening": "h_gerland_evacuation",            "reversible": false },
	],
	"vallee": [
		{ "seuil": 4, "happening": "h_vallee_contamination_etendue",  "reversible": false },
		{ "seuil": 8, "happening": "h_vallee_inaccessible",           "reversible": false },
	],
	"solaize": [
		{ "seuil": 3, "happening": "h_solaize_surveillance_renforcee","reversible": true  },
		{ "seuil": 6, "happening": "h_solaize_pression_ressources",   "reversible": false },
		{ "seuil": 9, "happening": "h_solaize_intervention_directe",  "reversible": false },
	],
}

# Happenings déjà déclenchés (set utilisé comme bloqueur).
var _happenings_declenches : Dictionary = {}

# File d'attente des happenings à insérer à la prochaine transition de scène.
var _happenings_en_attente : Array = []


func add_menace(zone: String, valeur: int) -> void:
	if not PALIERS.has(zone):
		push_warning("MenaceManager: zone inconnue '%s'" % zone)
		return
	var ancienne : int = _get_zone_value(zone)
	var nouvelle : int = clampi(ancienne + valeur, VALEUR_MIN, VALEUR_MAX)
	_set_zone_value(zone, nouvelle)
	if ancienne == nouvelle:
		return
	menace_changed.emit(zone, ancienne, nouvelle)
	if nouvelle > ancienne:
		_check_paliers(zone, ancienne, nouvelle)


## Renvoie la variante de background à appliquer selon le palier :
## "" (calme) | "tension" (3-5) | "critique" (6+).
func get_background_variant(zone: String) -> String:
	var v : int = _get_zone_value(zone)
	if v >= 6:
		return "critique"
	if v >= 3:
		return "tension"
	return ""


## Récupère et vide la file d'attente — appelée par la couche scène à la
## prochaine transition.
func consume_pending_happenings() -> Array:
	var pending := _happenings_en_attente.duplicate()
	_happenings_en_attente.clear()
	return pending


## Remet l'état à zéro (appelé par SaveManager avant chargement).
func reset() -> void:
	menace_confluence = 0
	menace_gerland    = 0
	menace_vallee     = 0
	menace_solaize    = 0
	_happenings_declenches.clear()
	_happenings_en_attente.clear()


## Sérialisation pour SaveManager.
func to_dict() -> Dictionary:
	return {
		"menace_confluence": menace_confluence,
		"menace_gerland":    menace_gerland,
		"menace_vallee":     menace_vallee,
		"menace_solaize":    menace_solaize,
		"happenings_declenches": _happenings_declenches.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	menace_confluence = data.get("menace_confluence", 0)
	menace_gerland    = data.get("menace_gerland", 0)
	menace_vallee     = data.get("menace_vallee", 0)
	menace_solaize    = data.get("menace_solaize", 0)
	_happenings_declenches = data.get("happenings_declenches", {}).duplicate(true)


## --- Interne ---

func _get_zone_value(zone: String) -> int:
	match zone:
		"confluence": return menace_confluence
		"gerland":    return menace_gerland
		"vallee":     return menace_vallee
		"solaize":    return menace_solaize
	return 0


func _set_zone_value(zone: String, v: int) -> void:
	match zone:
		"confluence": menace_confluence = v
		"gerland":    menace_gerland = v
		"vallee":     menace_vallee = v
		"solaize":    menace_solaize = v


func _check_paliers(zone: String, ancienne: int, nouvelle: int) -> void:
	for palier in PALIERS[zone]:
		var seuil : int = palier["seuil"]
		if ancienne < seuil and nouvelle >= seuil:
			var happening_id : String = palier["happening"]
			if _happenings_declenches.has(happening_id):
				continue
			_happenings_declenches[happening_id] = true
			_happenings_en_attente.append(happening_id)
			happening_triggered.emit(happening_id)
