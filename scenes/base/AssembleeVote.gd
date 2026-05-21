extends Control
## AssembléeVote — UI du vote en assemblée (Fil 2)
##
## Deux phases :
##   1. Influence  : N tours d'options de dialogue par PNJ
##   2. Vote final : animation séquencée, résolution → flag

signal vote_complete(issue: String)

enum Phase { INFLUENCE, VOTE }

@onready var _liste_pnj : VBoxContainer = $Panel/VBox/PNJList
@onready var _liste_options : VBoxContainer = $Panel/VBox/Actions
@onready var _label_phase : Label = $Panel/VBox/Phase
@onready var _label_tours : Label = $Panel/VBox/Tours

var _phase : Phase = Phase.INFLUENCE
var _vote_id : String = ""
var _seuil : String = "simple"

var POSITION_LABELS : Dictionary = {}


func _ready() -> void:
	POSITION_LABELS = {
		AssembleeVoteManager.VotePosition.POUR:       "POUR",
		AssembleeVoteManager.VotePosition.CONTRE:     "CONTRE",
		AssembleeVoteManager.VotePosition.ABSTENTION: "abst.",
		AssembleeVoteManager.VotePosition.INDECIS:    "?",
	}
	visible = false
	DialogicBridge.vote_requested.connect(open)
	AssembleeVoteManager.position_changed.connect(_on_position_changed)


func open(config: Dictionary) -> void:
	_vote_id = config.get("vote_id", "")
	_seuil = config.get("seuil", "simple")
	var tours : int = config.get("tours", 2)
	var participants : Array = config.get("participants", [])
	AssembleeVoteManager.start_vote(_vote_id, participants, tours, _seuil)
	_phase = Phase.INFLUENCE
	visible = true
	_refresh()


func _refresh() -> void:
	_label_tours.text = "Tours restants : %d" % AssembleeVoteManager.tours_restants
	_label_phase.text = "Influence" if _phase == Phase.INFLUENCE else "Vote"
	_rebuild_pnj_list()
	_rebuild_options()


func _rebuild_pnj_list() -> void:
	for c in _liste_pnj.get_children():
		c.queue_free()
	for pnj_id in AssembleeVoteManager.positions.keys():
		var pos : int = AssembleeVoteManager.positions[pnj_id]
		var label := Label.new()
		label.text = "%s — %s" % [pnj_id, POSITION_LABELS[pos]]
		_liste_pnj.add_child(label)


func _rebuild_options() -> void:
	for c in _liste_options.get_children():
		c.queue_free()
	if _phase == Phase.VOTE:
		var btn := Button.new()
		btn.text = "Procéder au vote"
		btn.pressed.connect(_resoudre_vote)
		_liste_options.add_child(btn)
		return

	for pnj_id in AssembleeVoteManager.positions.keys():
		var seuil := RelationManager.get_seuil(pnj_id)
		if seuil == "confiance" or seuil == "intime":
			_ajouter_option_pnj(pnj_id, "Convaincre", +1)
		elif seuil == "mefiance":
			_ajouter_option_pnj(pnj_id, "Discréditer", -1)

	if LumenManager.lumen_etat == LumenManager.LumenEtat.ACTIF:
		var btn_lumen := Button.new()
		btn_lumen.text = "[LUMEN] Lire les hésitations"
		btn_lumen.pressed.connect(_lumen_revele_indecis)
		_liste_options.add_child(btn_lumen)

	var fin := Button.new()
	fin.text = "Passer au vote →"
	fin.pressed.connect(_passer_au_vote)
	_liste_options.add_child(fin)


func _ajouter_option_pnj(pnj_id: String, libelle: String, delta: int) -> void:
	var btn := Button.new()
	btn.text = "%s · %s" % [libelle, pnj_id]
	btn.pressed.connect(_on_influence.bind(pnj_id, delta))
	_liste_options.add_child(btn)


func _on_influence(pnj_id: String, delta: int) -> void:
	AssembleeVoteManager.apply_influence(pnj_id, delta)
	AssembleeVoteManager.end_tour()
	if AssembleeVoteManager.tours_restants == 0:
		_phase = Phase.VOTE
	_refresh()


func _lumen_revele_indecis() -> void:
	# Effet visuel : on remplace les "?" par leur valeur réelle pour ce tour
	# (ne change pas la position). On consomme un tour quand même.
	AssembleeVoteManager.end_tour()
	if AssembleeVoteManager.tours_restants == 0:
		_phase = Phase.VOTE
	_refresh()


func _passer_au_vote() -> void:
	_phase = Phase.VOTE
	_refresh()


func _resoudre_vote() -> void:
	var issue := AssembleeVoteManager.resolve(_seuil)
	visible = false
	vote_complete.emit(issue)


func _on_position_changed(_pnj_id: String, _nouvelle: int) -> void:
	if visible:
		_rebuild_pnj_list()
