extends Node

var precision_accuracy_score: int = 0
var best_scores := {}

func set_last_scene(path: String) -> void:
	ProjectSettings.set_setting("application/last_scene", path)

func reset_precision_accuracy_score() -> void:
	precision_accuracy_score = 0

func update_best_score(game_id: String, score: int) -> int:
	var best := best_scores.get(game_id, -9999) as int
	if score > best:
		best_scores[game_id] = score
	return score - best

func unlock_level(level_name: String) -> void:
	print("Unlocked ", level_name)
	# You can store unlocks in a dictionary or save file if needed
