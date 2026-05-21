extends Node
## GameStateManager — état central de RÉSILIENCES
##
## Stockage pur : aucune logique métier ici.
## Toutes les variables sont à leur valeur par défaut au démarrage.
## La scène S1-01 (via s1_01_init.gd) appelle reset() au lancement
## d'une nouvelle partie.

signal flag_changed(flag_name: String, old_value, new_value)

# --- Variables de progression (0 → 10) ---
var confiance_confluence : int = 0
var confiance_gerland    : int = 0
var relation_lise        : int = 0

# --- Flags LUMEN ---
var lumen_fragment_1 : bool = false
var lumen_fragment_2 : bool = false
var lumen_fragment_3 : bool = false
var lumen_fragment_4 : bool = false
var lumen_fragment_5 : bool = false
var lumen_question_type    : String = ""   # "soin" | "analyse" | "données"
var lumen_revelation_recue : bool = false

# --- Fil 2 — Organisation horizontale ---
var assemblee_intervention : bool = false
var assemblee_issue        : String = ""   # "accord" | "report" | "blocage"

# --- Fil 3 — Violence ---
var violence_choix_acte3       : String = ""   # "desescalade" | "passivite" | "direct" | "radical"
var gerland_generateur_choix   : String = ""

# --- Fil 4 — Attachement ---
var fil4_pnj_tension         : String = ""
var fil4_intervention_max    : bool = false
var fil4_resolution          : String = ""   # "ami" | "amour" | "neutre"
var fil4_max_choix_personnel : bool = false

# --- Rive (acte 1) ---
var rive_aide_silhouette2     : bool = false
var rive_silhouette1_relation : String = ""   # "distante" | "neutre" | "ouverte"
var rive_silhouette2_relation : String = ""

# --- Solaize ---
var solaize_premiere_contact : bool = false
var lumen_solaize_reaction   : String = ""
var offre_reponse            : String = ""   # "accepte" | "refuse" | "negocie"
var fin_debloquee            : String = ""   # "enracinement" | "route" | "offre" | "rupture"

# --- Progression de scène (pour la sauvegarde) ---
var acte_courant  : String = "acte1"
var node_courant  : String = "s1_01"

# Liste des noms canoniques des flags (toutes les @variable ci-dessus
# sont accessibles via set_flag / get_flag).
const _FLAG_NAMES : PackedStringArray = [
	"confiance_confluence", "confiance_gerland", "relation_lise",
	"lumen_fragment_1", "lumen_fragment_2", "lumen_fragment_3",
	"lumen_fragment_4", "lumen_fragment_5",
	"lumen_question_type", "lumen_revelation_recue",
	"assemblee_intervention", "assemblee_issue",
	"violence_choix_acte3", "gerland_generateur_choix",
	"fil4_pnj_tension", "fil4_intervention_max",
	"fil4_resolution", "fil4_max_choix_personnel",
	"rive_aide_silhouette2",
	"rive_silhouette1_relation", "rive_silhouette2_relation",
	"solaize_premiere_contact", "lumen_solaize_reaction",
	"offre_reponse", "fin_debloquee",
	"acte_courant", "node_courant",
]


## Remet toutes les variables à leur valeur de départ.
## Appelée par SaveManager au chargement, ou par s1_01_init.gd au début.
func reset() -> void:
	confiance_confluence = 0
	confiance_gerland = 0
	relation_lise = 0

	lumen_fragment_1 = false
	lumen_fragment_2 = false
	lumen_fragment_3 = false
	lumen_fragment_4 = false
	lumen_fragment_5 = false
	lumen_question_type = ""
	lumen_revelation_recue = false

	assemblee_intervention = false
	assemblee_issue = ""

	violence_choix_acte3 = ""
	gerland_generateur_choix = ""

	fil4_pnj_tension = ""
	fil4_intervention_max = false
	fil4_resolution = ""
	fil4_max_choix_personnel = false

	rive_aide_silhouette2 = false
	rive_silhouette1_relation = ""
	rive_silhouette2_relation = ""

	solaize_premiere_contact = false
	lumen_solaize_reaction = ""
	offre_reponse = ""
	fin_debloquee = ""

	acte_courant = "acte1"
	node_courant = "s1_01"


## Modifie un flag par son nom canonique.
## Émet `flag_changed` même si la valeur ne change pas — laisse les
## écouteurs filtrer si besoin.
func set_flag(flag_name: String, value) -> void:
	if not _FLAG_NAMES.has(flag_name):
		push_warning("GameStateManager: flag inconnu '%s'" % flag_name)
		return
	var old_value = get(flag_name)
	set(flag_name, value)
	flag_changed.emit(flag_name, old_value, value)


func get_flag(flag_name: String):
	if not _FLAG_NAMES.has(flag_name):
		push_warning("GameStateManager: flag inconnu '%s'" % flag_name)
		return null
	return get(flag_name)


## Sérialisation pour SaveManager.
func to_dict() -> Dictionary:
	var d : Dictionary = {}
	for name in _FLAG_NAMES:
		d[name] = get(name)
	return d


func from_dict(data: Dictionary) -> void:
	for name in _FLAG_NAMES:
		if data.has(name):
			set(name, data[name])
