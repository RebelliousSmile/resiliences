extends Node
## FinManager — détermine et charge la fin du jeu
##
## Évalue les conditions de chaque fin dans l'ordre de priorité.
## La première condition remplie détermine la fin. Aucune fin = erreur de
## conception (toutes les fins ont des conditions de fallback).
##
## Conditions (d'après architecture.md) :
##   FIN-1 Enracinement : CC ≥8 · CG ≥6 · offre_reponse="refuse" · fil4 développé
##   FIN-2 La Route     : CC 4-7 · pas d'attachement dominant · fragment 5 trouvé
##   FIN-3 L'Offre      : CC <4  · relation_lise ≥7 · LUMEN intégré (ACTIF)
##   FIN-4 La Rupture   : violence radicale · refus total · fil 1 complet
##
## (CC = confiance_confluence · CG = confiance_gerland)

const SCENES : Dictionary = {
	"enracinement": "res://scenes/fins/fin_enracinement.tscn",
	"route":        "res://scenes/fins/fin_la_route.tscn",
	"offre":        "res://scenes/fins/fin_offre.tscn",
	"rupture":      "res://scenes/fins/fin_rupture.tscn",
}

signal fin_determinee(fin_id: String)


## Évalue les conditions et retourne l'identifiant de la fin applicable.
## Retourne "" si aucune condition n'est remplie (état de jeu incomplet).
func get_fin_id() -> String:
	var cc : int = GameStateManager.confiance_confluence
	var cg : int = GameStateManager.confiance_gerland
	var rl : int = GameStateManager.relation_lise
	var offre    : String = GameStateManager.offre_reponse
	var violence : String = GameStateManager.violence_choix_acte3
	var fil4_res : String = GameStateManager.fil4_resolution
	var fragment5 : bool  = GameStateManager.lumen_fragment_5
	var lumen_integre : bool = (LumenManager.lumen_etat == LumenManager.LumenEtat.ACTIF)

	# FIN-1 — Enracinement
	var fil4_developpe : bool = (fil4_res == "ami" or fil4_res == "amour")
	if cc >= 8 and cg >= 6 and offre == "refuse" and fil4_developpe:
		return "enracinement"

	# FIN-4 — La Rupture (évaluée avant FIN-2 car conditions extrêmes)
	if violence == "radical" and offre == "refuse" and cc <= 3:
		return "rupture"

	# FIN-3 — L'Offre
	if cc < 4 and rl >= 7 and lumen_integre:
		return "offre"

	# FIN-2 — La Route (fallback intermédiaire)
	if cc >= 4 and cc <= 7 and fragment5:
		return "route"

	# Fallback : fin la plus probable selon le dernier état connu.
	if GameStateManager.fin_debloquee != "":
		return GameStateManager.fin_debloquee

	return ""


## Charge la scène de fin correspondant à `fin_id`.
## Si `fin_id` est vide, utilise get_fin_id() pour le déterminer.
func aller_a_la_fin(fin_id: String = "") -> void:
	if fin_id.is_empty():
		fin_id = get_fin_id()
	if fin_id.is_empty():
		push_error("FinManager: impossible de déterminer la fin — état de jeu incomplet.")
		return
	if not SCENES.has(fin_id):
		push_error("FinManager: fin inconnue '%s'" % fin_id)
		return
	var path : String = SCENES[fin_id]
	if not ResourceLoader.exists(path):
		push_warning("FinManager: scène de fin introuvable %s" % path)
		return
	GameStateManager.set_flag("fin_debloquee", fin_id)
	fin_determinee.emit(fin_id)
	get_tree().change_scene_to_file(path)
