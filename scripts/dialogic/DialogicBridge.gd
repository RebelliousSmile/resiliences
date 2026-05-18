extends Node
## DialogicBridge
##
## Pont entre Dialogic 2 et nos managers (RelationManager, GameStateManager).
##
## DEUX FAÇONS DE L'UTILISER depuis une timeline Dialogic :
##
## A) Via l'événement "Signal" de Dialogic (le plus simple, recommandé) :
##    - Ajouter un événement Signal dans la timeline avec comme argument :
##        relation:Lea:+10:bonne_decision
##      ou:
##        flag:rencontre_aurore:true
##      ou:
##        decision:fin_chap1:partir
##    - Dialogic émet alors `Dialogic.signal_event` avec ce paramètre,
##      qu'on parse ici et qu'on dispatch vers le bon manager.
##
## B) En appelant directement les méthodes publiques de ce script
##    depuis un script de scène, un autre custom event, etc.
##
## Ce noeud est instancié automatiquement par un autoload, voir
## project.godot (autoload `DialogicBridge`).

# Préfixes des commandes supportées dans l'argument du signal Dialogic.
const CMD_RELATION: String = "relation"
const CMD_FLAG: String = "flag"
const CMD_DECISION: String = "decision"
const CMD_GOTO: String = "goto"


func _ready() -> void:
	# Branchement différé pour s'assurer que Dialogic est chargé.
	call_deferred("_brancher_signal_event")


func _brancher_signal_event() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		# Dialogic absent : on log et on continue (les méthodes publiques
		# restent appelables).
		push_warning("DialogicBridge: Dialogic non détecté, intégration timeline désactivée.")
		return
	# Dialogic 2 émet `signal_event(argument)` sur l'événement Signal.
	if dialogic.has_signal("signal_event") and not dialogic.signal_event.is_connected(_on_dialogic_signal):
		dialogic.signal_event.connect(_on_dialogic_signal)


## Récupère l'autoload Dialogic 2 s'il est présent, peu importe la façon
## dont il est enregistré (Engine singleton ou simple autoload /root/Dialogic).
func _get_dialogic() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var n := tree.root.get_node_or_null("Dialogic")
		if n:
			return n
	if Engine.has_singleton("Dialogic"):
		var s = Engine.get_singleton("Dialogic")
		if s is Node:
			return s
	return null


## Reçoit l'argument d'un événement Signal de Dialogic et le dispatche.
## Format : "commande:arg1:arg2:..."
func _on_dialogic_signal(argument) -> void:
	var texte: String = str(argument).strip_edges()
	if texte.is_empty():
		return

	var parts: PackedStringArray = texte.split(":", false)
	if parts.size() == 0:
		return

	var cmd: String = parts[0].to_lower()
	match cmd:
		CMD_RELATION:
			# relation:<personnage>:<delta>:<raison?>
			if parts.size() < 3:
				push_warning("DialogicBridge: relation mal formée: %s" % texte)
				return
			var perso: String = parts[1]
			var delta: int = int(parts[2])
			var raison: String = parts[3] if parts.size() > 3 else ""
			modifier_relation(perso, delta, raison)

		CMD_FLAG:
			# flag:<cle>:<valeur>
			if parts.size() < 3:
				push_warning("DialogicBridge: flag mal formé: %s" % texte)
				return
			poser_flag(parts[1], _parse_valeur(parts[2]))

		CMD_DECISION:
			# decision:<id>:<choix>
			if parts.size() < 3:
				push_warning("DialogicBridge: decision mal formée: %s" % texte)
				return
			enregistrer_decision(parts[1], parts[2])

		CMD_GOTO:
			# goto:<lieu>:<scene_path>
			if parts.size() < 3:
				push_warning("DialogicBridge: goto mal formé: %s" % texte)
				return
			aller_a(parts[1], parts[2])

		_:
			push_warning("DialogicBridge: commande inconnue '%s' (texte=%s)" % [cmd, texte])


## --- API publique (utilisable depuis tout script ou custom event) ---

func modifier_relation(personnage: String, delta: int, raison: String = "") -> void:
	if RelationManager:
		RelationManager.modifier(personnage, delta, raison)


func poser_flag(key: String, value) -> void:
	if GameStateManager:
		GameStateManager.set_flag(key, value)


func enregistrer_decision(decision_id: String, choix: String) -> void:
	if GameStateManager:
		GameStateManager.record_decision(decision_id, choix)


func aller_a(lieu: String, scene_path: String) -> void:
	if LocationManager:
		LocationManager.aller_a(lieu, scene_path)


## --- Interne ---

func _parse_valeur(brut: String) -> Variant:
	# Convertit la chaîne brute en bool, int ou string selon le contenu.
	var t := brut.strip_edges().to_lower()
	if t == "true":
		return true
	if t == "false":
		return false
	if t.is_valid_int():
		return int(t)
	if t.is_valid_float():
		return float(t)
	return brut
