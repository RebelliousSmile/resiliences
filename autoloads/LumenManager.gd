extends Node
## LumenManager — état du compagnon LUMEN et fragments du Protocole Continuité
##
## L'état LUMEN détermine la disponibilité du système (peut-il parler,
## est-il fiable, etc.). Synchronisé avec une variable Dialogic homonyme
## pour les conditions dans les .dtl.

enum LumenEtat {
	SILENCIEUX,   # batterie vide · nuit · souterrains Solaize
	PARTIEL,      # charge en cours · réponses courtes
	ACTIF,        # soleil · fonctionnel
	DEREGLE,      # Couloir profond · réponses erratiques
	FRAGMENT,     # fragment Protocole Continuité déclenché
}

var lumen_etat : LumenEtat = LumenEtat.SILENCIEUX
var lumen_fragments_trouves : int = 0   # 0 → 5

signal etat_changed(ancien: LumenEtat, nouveau: LumenEtat)
signal fragment_decouvert(numero: int)

const ETAT_NAMES : Dictionary = {
	LumenEtat.SILENCIEUX: "silencieux",
	LumenEtat.PARTIEL:    "partiel",
	LumenEtat.ACTIF:      "actif",
	LumenEtat.DEREGLE:    "deregle",
	LumenEtat.FRAGMENT:   "fragment",
}


func _ready() -> void:
	call_deferred("_sync_to_dialogic")


func set_etat(nouvel_etat: LumenEtat) -> void:
	if nouvel_etat == lumen_etat:
		return
	var ancien := lumen_etat
	lumen_etat = nouvel_etat
	etat_changed.emit(ancien, nouvel_etat)
	_sync_to_dialogic()


## Convertit une chaîne ("ACTIF" / "actif" / "Actif") vers la valeur d'enum.
func parse_etat(nom: String) -> LumenEtat:
	var key := nom.strip_edges().to_upper()
	for v in LumenEtat.values():
		if LumenEtat.keys()[v] == key:
			return v
	push_warning("LumenManager: état inconnu '%s'" % nom)
	return lumen_etat


func add_fragment(numero: int) -> void:
	if numero < 1 or numero > 5:
		push_warning("LumenManager: numéro de fragment invalide %d" % numero)
		return
	var flag_name := "lumen_fragment_%d" % numero
	if GameStateManager.get_flag(flag_name) == true:
		return
	GameStateManager.set_flag(flag_name, true)
	lumen_fragments_trouves = clampi(lumen_fragments_trouves + 1, 0, 5)
	fragment_decouvert.emit(numero)


## LUMEN peut-il s'exprimer ? Faux quand SILENCIEUX.
func can_speak() -> bool:
	return lumen_etat != LumenEtat.SILENCIEUX


## LUMEN est-il fiable ? Faux quand DÉRÉGLÉ ou PARTIEL.
func is_reliable() -> bool:
	return lumen_etat != LumenEtat.DEREGLE and lumen_etat != LumenEtat.PARTIEL


## Remet l'état à zéro (appelé par SaveManager avant chargement).
func reset() -> void:
	lumen_etat = LumenEtat.SILENCIEUX
	lumen_fragments_trouves = 0
	_sync_to_dialogic()


## Sérialisation pour SaveManager.
func to_dict() -> Dictionary:
	return {
		"lumen_etat": int(lumen_etat),
		"lumen_fragments_trouves": lumen_fragments_trouves,
	}


func from_dict(data: Dictionary) -> void:
	lumen_etat = data.get("lumen_etat", LumenEtat.SILENCIEUX)
	lumen_fragments_trouves = data.get("lumen_fragments_trouves", 0)
	_sync_to_dialogic()


## --- Intégration Dialogic ---

func _sync_to_dialogic() -> void:
	var dialogic := _get_dialogic()
	if dialogic == null:
		return
	if "VAR" in dialogic:
		var vars_subsys = dialogic.VAR
		if vars_subsys and vars_subsys.has_method("set_variable"):
			vars_subsys.set_variable("lumen_etat", ETAT_NAMES[lumen_etat])
			vars_subsys.set_variable("lumen_fragments_trouves", lumen_fragments_trouves)


func _get_dialogic() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var n := tree.root.get_node_or_null("Dialogic")
		if n:
			return n
	return null
