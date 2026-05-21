extends Node
## AssembléeVoteManager — votes en assemblée pour le Fil 2
##
## Max ne vote pas (traversant·e, pas membre). Il/elle influence les PNJ
## présents via le dialogue. Les options de dialogue sont conditionnées
## par la relation avec chaque PNJ :
##   - relation ≥ Confiance → option de soutien (déplace INDÉCIS vers POUR)
##   - relation < Méfiance  → option hostile  (risque de déplacement inverse)
## LUMEN actif → option spéciale : révèle la position d'un INDÉCIS sans
## la changer.

enum VotePosition { POUR, CONTRE, ABSTENTION, INDECIS }

var vote_actif : bool = false
var vote_id_courant : String = ""
var positions : Dictionary = {}   # { pnj_id: VotePosition }
var tours_restants : int = 0
var seuil_courant  : String = "simple"

signal vote_started(vote_id: String)
signal position_changed(pnj_id: String, nouvelle_position: VotePosition)
signal vote_resolved(vote_id: String, issue: String)


## Lance un vote.
## `participants` est une liste de dictionnaires :
##   [ { "pnj_id": "loan", "position": VotePosition.INDECIS }, ... ]
func start_vote(vote_id: String, participants: Array, tours: int, seuil: String = "simple") -> void:
	vote_id_courant = vote_id
	tours_restants = tours
	seuil_courant = seuil
	positions.clear()
	for p in participants:
		var pnj_id : String = p.get("pnj_id", "")
		var pos : int = p.get("position", VotePosition.INDECIS)
		if not pnj_id.is_empty():
			positions[pnj_id] = pos
	vote_actif = true
	vote_started.emit(vote_id)


## Tente de déplacer un PNJ. Règles :
##   - delta > 0 demande de déplacer vers POUR ; n'est efficace que si
##     la relation Max ↔ PNJ est >= Confiance (option disponible).
##   - delta < 0 tente de déplacer vers CONTRE ; n'est efficace que si
##     la relation est < Méfiance.
##   - sinon : aucun effet (mais le tour est consommé par le tour caller).
func apply_influence(pnj_id: String, delta: int) -> void:
	if not vote_actif or not positions.has(pnj_id):
		return
	var seuil := RelationManager.get_seuil(pnj_id)
	var pos_actuelle : int = positions[pnj_id]
	var nouvelle : int = pos_actuelle

	if delta > 0 and (seuil == "confiance" or seuil == "intime"):
		if pos_actuelle == VotePosition.INDECIS or pos_actuelle == VotePosition.ABSTENTION:
			nouvelle = VotePosition.POUR
		elif pos_actuelle == VotePosition.CONTRE:
			nouvelle = VotePosition.INDECIS
	elif delta < 0 and seuil == "mefiance":
		if pos_actuelle == VotePosition.INDECIS or pos_actuelle == VotePosition.ABSTENTION:
			nouvelle = VotePosition.CONTRE
		elif pos_actuelle == VotePosition.POUR:
			nouvelle = VotePosition.INDECIS

	if nouvelle != pos_actuelle:
		positions[pnj_id] = nouvelle
		position_changed.emit(pnj_id, nouvelle)


func end_tour() -> void:
	tours_restants = max(0, tours_restants - 1)


## Résout le vote selon le seuil demandé.
## Renvoie l'issue ("accord" | "report" | "blocage") et la pose dans
## GameStateManager.assemblee_issue.
func resolve(seuil: String = "") -> String:
	if seuil.is_empty():
		seuil = seuil_courant
	var pour : int = 0
	var contre : int = 0
	var abst : int = 0
	var indecis : int = 0
	for pos in positions.values():
		match pos:
			VotePosition.POUR:       pour += 1
			VotePosition.CONTRE:     contre += 1
			VotePosition.ABSTENTION: abst += 1
			VotePosition.INDECIS:    indecis += 1

	var total : int = positions.size()
	var issue : String = "blocage"

	match seuil:
		"simple":
			if pour > contre:
				issue = "accord"
			elif contre > pour:
				issue = "blocage"
			else:
				issue = "report"
		"qualifiee":
			# 2/3 des exprimés (POUR + CONTRE).
			var exprimes : int = pour + contre
			if exprimes > 0 and float(pour) / float(exprimes) >= 2.0 / 3.0:
				issue = "accord"
			elif exprimes > 0 and float(contre) / float(exprimes) >= 2.0 / 3.0:
				issue = "blocage"
			else:
				issue = "report"
		"unanimite":
			if contre == 0 and indecis == 0 and pour > 0:
				issue = "accord"
			elif pour == 0:
				issue = "blocage"
			else:
				issue = "report"

	vote_actif = false
	GameStateManager.set_flag("assemblee_issue", issue)
	vote_resolved.emit(vote_id_courant, issue)
	return issue
