extends Node
## s1_01_init — initialisation des variables pour la toute première scène.
##
## C'est la seule scène autorisée à avoir un `_init.gd` (cf. règles de
## RÉSILIENCES). À la fin de l'init, toutes les variables sont à leur
## valeur par défaut.

func _ready() -> void:
	GameStateManager.reset()
	RelationManager.reset()
	GameStateManager.set_flag("acte_courant", "acte1")
	GameStateManager.set_flag("node_courant", "s1_01")
	# LUMEN démarre SILENCIEUX au début de S1-01 (batterie vide).
	LumenManager.set_etat(LumenManager.LumenEtat.SILENCIEUX)
