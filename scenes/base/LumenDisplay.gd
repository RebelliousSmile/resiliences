extends Control
## LumenDisplay — HUD permanent de l'état LUMEN
##
## Pas de valeur numérique. Apparence pilotée par LumenManager.lumen_etat.

@onready var _icone : TextureRect = $Wrapper/Icone
@onready var _libelle : Label = $Wrapper/Libelle
@onready var _pulse_player : AnimationPlayer = $AnimationPlayer

const COULEUR_ACTIF      : Color = Color("#f0c040")
const COULEUR_PARTIEL    : Color = Color("#a07a30")
const COULEUR_SILENCIEUX : Color = Color("#3a3a3a")
const COULEUR_DEREGLE    : Color = Color("#c04040")
const COULEUR_FRAGMENT   : Color = Color("#ffe080")


func _ready() -> void:
	LumenManager.etat_changed.connect(_on_etat_changed)
	LumenManager.fragment_decouvert.connect(_on_fragment_decouvert)
	_refresh(LumenManager.lumen_etat)


func _on_etat_changed(_ancien: int, nouveau: int) -> void:
	_refresh(nouveau)


func _on_fragment_decouvert(_numero: int) -> void:
	_pulse_player.play("pulse_fragment")


func _refresh(etat: int) -> void:
	match etat:
		LumenManager.LumenEtat.ACTIF:
			_icone.modulate = COULEUR_ACTIF
			_libelle.text = "LUMEN"
			_libelle.visible = true
			_pulse_player.stop()
		LumenManager.LumenEtat.PARTIEL:
			_icone.modulate = COULEUR_PARTIEL
			_libelle.text = "lumen…"
			_libelle.visible = true
			_pulse_player.play("pulse_partiel")
		LumenManager.LumenEtat.SILENCIEUX:
			_icone.modulate = COULEUR_SILENCIEUX
			_libelle.visible = false
			_pulse_player.stop()
		LumenManager.LumenEtat.DEREGLE:
			_icone.modulate = COULEUR_DEREGLE
			_libelle.text = "LU?M-EN"
			_libelle.visible = true
			_pulse_player.play("glitch_deregle")
		LumenManager.LumenEtat.FRAGMENT:
			_icone.modulate = COULEUR_FRAGMENT
			_libelle.text = "LUMEN"
			_libelle.visible = true
			_pulse_player.play("pulse_fragment")
