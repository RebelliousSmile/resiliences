extends Node2D
## Location_Template
##
## Script de scène pour le prototype de lieu.
## - Affiche le libellé du hotspot survolé
## - Connecte les hotspots aux managers (déjà fait dans Hotspot.gd ;
##   ce script ne sert qu'au feedback UI et démos custom).

@onready var _libelle: Label = $UI/LibelleHotspot
@onready var _hud: Control = $UI/RelationHUD


func _ready() -> void:
	_libelle.text = ""
	# Connexion à tous les hotspots du lieu.
	for hs in $Hotspots.get_children():
		if hs is Area2D and hs.has_signal("survol"):
			hs.survol.connect(_on_hotspot_survol)
			hs.clique.connect(_on_hotspot_clique)

	# Si la sauvegarde a déjà des personnages connus, on les ajoute au HUD.
	if RelationManager and _hud:
		_hud.set_personnages(PackedStringArray(["Lea", "Aurore"]))


func _on_hotspot_survol(_id: String, entered: bool) -> void:
	if not entered:
		_libelle.text = ""
		return
	for hs in $Hotspots.get_children():
		if hs.id == _id:
			_libelle.text = hs.libelle
			return


func _on_hotspot_clique(id: String) -> void:
	# Hook libre pour ajouter des comportements custom par hotspot.
	# Exemple : un hotspot qui modifie une relation directement.
	if id == "examiner_photo" and RelationManager:
		RelationManager.modifier("Aurore", -5, "a_examine_photo_sans_demander")
