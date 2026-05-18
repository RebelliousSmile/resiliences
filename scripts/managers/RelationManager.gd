extends Node
## RelationManager
##
## Autoload : gère le score de relation pour chaque personnage du jeu.
## Le score va de -100 (hostilité) à +100 (intime).
## Émet `relation_changed` lorsque le palier de niveau change.

# Bornes du score numérique
const SCORE_MIN: int = -100
const SCORE_MAX: int = 100

# Paliers ordonnés du plus bas au plus haut.
# Le nom retourné par get_niveau() est celui du premier palier dont le seuil
# minimum est >= au score courant lu en sens décroissant.
const PALIERS: Array = [
	{"nom": "hostile",  "min": -100},
	{"nom": "froid",    "min": -40},
	{"nom": "neutre",   "min": -10},
	{"nom": "sympathie","min": 20},
	{"nom": "confiance","min": 45},
	{"nom": "amitie",   "min": 70},
	{"nom": "intime",   "min": 90},
]

# Émis quand le palier change pour un personnage.
# `ancien_niveau` et `nouveau_niveau` sont des chaînes (cf. PALIERS).
signal relation_changed(personnage: String, ancien_niveau: String, nouveau_niveau: String)

# Émis pour chaque modification de score, même si le palier ne change pas.
# Utile pour le HUD de feedback discret.
signal score_changed(personnage: String, ancien_score: int, nouveau_score: int, raison: String)

# Dictionnaire { personnage: int } des scores courants.
var _scores: Dictionary = {}

# Historique léger des modifications (pour debug / journal).
# Chaque entrée : { personnage, delta, raison, score_apres, timestamp }
var _historique: Array = []


func _ready() -> void:
	# On laisse le SaveManager pousser ses données par save_loaded() ;
	# rien à initialiser ici tant qu'aucune sauvegarde n'est chargée.
	pass


## Modifie le score d'un personnage et émet les signaux appropriés.
## `valeur` peut être positive ou négative.
## `raison` est libre et sert au journal / debug.
func modifier(personnage: String, valeur: int, raison: String = "") -> void:
	var ancien_score: int = _scores.get(personnage, 0)
	var ancien_niveau: String = _niveau_pour_score(ancien_score)

	var nouveau_score: int = clamp(ancien_score + valeur, SCORE_MIN, SCORE_MAX)
	_scores[personnage] = nouveau_score

	var nouveau_niveau: String = _niveau_pour_score(nouveau_score)

	_historique.append({
		"personnage": personnage,
		"delta": valeur,
		"raison": raison,
		"score_apres": nouveau_score,
		"timestamp": Time.get_unix_time_from_system(),
	})

	score_changed.emit(personnage, ancien_score, nouveau_score, raison)
	if ancien_niveau != nouveau_niveau:
		relation_changed.emit(personnage, ancien_niveau, nouveau_niveau)


## Renvoie le palier (chaîne) courant pour un personnage.
func get_niveau(personnage: String) -> String:
	return _niveau_pour_score(get_score(personnage))


## Renvoie le score brut [-100, 100] pour un personnage.
func get_score(personnage: String) -> int:
	return _scores.get(personnage, 0)


## Renvoie la liste de tous les personnages connus.
func get_personnages() -> Array:
	return _scores.keys()


## Renvoie l'historique complet des modifications.
func get_historique() -> Array:
	return _historique.duplicate(true)


## Réinitialise toutes les relations (nouvelle partie).
func reset() -> void:
	_scores.clear()
	_historique.clear()


## --- Persistance : appelée par le SaveManager ---

func to_save_dict() -> Dictionary:
	return {
		"scores": _scores.duplicate(true),
		"historique": _historique.duplicate(true),
	}


func from_save_dict(data: Dictionary) -> void:
	_scores = data.get("scores", {}).duplicate(true)
	_historique = data.get("historique", []).duplicate(true)


## --- Interne ---

func _niveau_pour_score(score: int) -> String:
	# Parcours décroissant : on prend le premier palier dont le seuil min est <= score.
	for i in range(PALIERS.size() - 1, -1, -1):
		var p: Dictionary = PALIERS[i]
		if score >= int(p["min"]):
			return String(p["nom"])
	return String(PALIERS[0]["nom"])
