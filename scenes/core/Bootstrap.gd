extends Node
## Bootstrap
##
## Hook global pour la sauvegarde/chargement rapide via raccourci clavier.
## À attacher au noeud racine d'une scène persistante, ou à instancier
## comme autoload supplémentaire si vous voulez le rendre toujours dispo.
##
## Par défaut, ce script n'est PAS un autoload (cf. project.godot) ;
## ajoutez-le manuellement si besoin.

const SLOT_RAPIDE: int = 0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sauvegarde_rapide"):
		if SaveManager:
			SaveManager.sauvegarder(SLOT_RAPIDE)
	elif event.is_action_pressed("chargement_rapide"):
		if SaveManager:
			SaveManager.charger(SLOT_RAPIDE)
	elif event.is_action_pressed("echap"):
		# Hook pour menu pause / retour.
		get_tree().paused = not get_tree().paused
