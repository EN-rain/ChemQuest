extends Node

## Developer tools are opt-in for the current app session only. Their changes
## to game progression are intentional and persist via the normal SaveManager.
const MAIN_SCENE := "res://games/main.tscn"
const HOMETOWN_SCENE := "res://games/chapter_one/hometown/hometown.tscn"
const BUILDING_ONE_SCENE := "res://games/chapter_one/hometown/building_one/building_one.tscn"
const BUILDING_TWO_SCENE := "res://games/chapter_one/hometown/building_two/building_two.tscn"
const BACKUP_PATH := "user://devmode_progress_backup.json"
const GUIDE_BACKUP_PATH := "user://devmode_guides_backup.cfg"

## Ordered by when the player can first attempt each puzzle.
const PUZZLES := [
	"Book I - Elements",
	"Book II - Compounds",
	"Desk Quiz",
	"Book III - Mixtures",
	"Separation Methods",
	"Accuracy vs Precision",
	"Density - Level 1",
	"Density - Level 2",
	"Density - Level 3",
	"States of Matter - Level 1",
	"States of Matter - Level 2",
	"States of Matter - Level 3",
]

## To UNLOCK a stage, all quests associated with earlier stages must already
## be completed. Never complete the puzzle being unlocked (or the final reward).
const QUEST_COMPLETION_THRESHOLDS := {
	"find_wiz": 1,
	"read_books": 1,
	"finish_book1": 2,
	"after_book1": 2,
	"finish_book2": 3,
	"after_book2": 3,
	"desk_quiz": 4,
	"after_desk_quiz": 4,
	"finish_book3": 5,
	"after_book3": 5,
	"separation_methods": 6,
	"separation_methods_after": 6,
	"accuracy_vs_precision": 7,
	"after_accuracy_vs_precision": 7,
	"find_christofe": 7,
	"density_measurement": 10,
	"after_density_measurement": 10,
}

var enabled := false

const PASS_RATES_SAVE_PATH := "user://devmode_pass_rates.json"

const DEFAULT_PASS_CONFIGS := {
	"book1": {"name": "Book I - Elements", "max": 15, "default": 12, "type": "score"},
	"book2": {"name": "Book II - Compounds", "max": 15, "default": 12, "type": "score"},
	"desk_quiz": {"name": "Desk Quiz", "max": 15, "default": 12, "type": "score"},
	"book3": {"name": "Book III - Mixtures", "max": 15, "default": 12, "type": "score"},
	"separation_methods": {"name": "Separation Methods", "max": 15, "default": 12, "type": "score"},
	"accuracy_vs_precision": {"name": "Accuracy vs Precision", "max": 5, "default": 4, "type": "score"},
	"density_1": {"name": "Density - Level 1", "max": 1, "default": 1, "type": "goal"},
	"density_2": {"name": "Density - Level 2", "max": 1, "default": 1, "type": "goal"},
	"density_3": {"name": "Density - Level 3", "max": 1, "default": 1, "type": "goal"},
	"states_1": {"name": "States of Matter - Level 1", "max": 1, "default": 1, "type": "goal"},
	"states_2": {"name": "States of Matter - Level 2", "max": 1, "default": 1, "type": "goal"},
	"states_3": {"name": "States of Matter - Level 3", "max": 1, "default": 1, "type": "goal"},
}

const PUZZLE_INDEX_TO_KEY := {
	0: "book1",
	1: "book2",
	2: "desk_quiz",
	3: "book3",
	4: "separation_methods",
	5: "accuracy_vs_precision",
	6: "density_1",
	7: "density_2",
	8: "density_3",
	9: "states_1",
	10: "states_2",
	11: "states_3",
}

const DEFAULT_QUIZ_COUNTS := {
	"book1": 15,
	"book2": 15,
	"desk_quiz": 15,
	"book3": 15,
	"separation_methods": 15,
	"accuracy_vs_precision": 5,
}

var pass_rates: Dictionary = {}
var quiz_counts: Dictionary = {}


func _ready() -> void:
	_load_pass_rates()


func get_puzzle_names() -> Array:
	return PUZZLES.duplicate()


func get_quiz_count(puzzle_key: String, default_value: int = -1) -> int:
	if not enabled:
		if default_value >= 0:
			return default_value
		if DEFAULT_QUIZ_COUNTS.has(puzzle_key):
			return int(DEFAULT_QUIZ_COUNTS[puzzle_key])
		return 15
	if quiz_counts.has(puzzle_key):
		return int(quiz_counts[puzzle_key])
	if default_value >= 0:
		return default_value
	if DEFAULT_QUIZ_COUNTS.has(puzzle_key):
		return int(DEFAULT_QUIZ_COUNTS[puzzle_key])
	return 15


func set_quiz_count(puzzle_key: String, value: int) -> bool:
	if not enabled:
		return false
	if not DEFAULT_QUIZ_COUNTS.has(puzzle_key):
		return false
	var clamped_val: int = clampi(value, 1, 50)
	quiz_counts[puzzle_key] = clamped_val
	# Also clamp pass rate if it exceeds the new quiz count
	if pass_rates.has(puzzle_key) and pass_rates[puzzle_key] > clamped_val:
		pass_rates[puzzle_key] = clamped_val
	_save_pass_rates()
	return true


func set_quiz_count_by_index(index: int, value: int) -> bool:
	if PUZZLE_INDEX_TO_KEY.has(index):
		return set_quiz_count(PUZZLE_INDEX_TO_KEY[index], value)
	return false


func get_quiz_count_by_index(index: int) -> int:
	if PUZZLE_INDEX_TO_KEY.has(index):
		return get_quiz_count(PUZZLE_INDEX_TO_KEY[index])
	return 15


func get_pass_rate(puzzle_key: String, default_value: int = -1) -> int:
	if not enabled:
		if default_value >= 0:
			return default_value
		if DEFAULT_PASS_CONFIGS.has(puzzle_key):
			return int(DEFAULT_PASS_CONFIGS[puzzle_key]["default"])
		return 12
	if pass_rates.has(puzzle_key):
		return int(pass_rates[puzzle_key])
	if default_value >= 0:
		return default_value
	if DEFAULT_PASS_CONFIGS.has(puzzle_key):
		return int(DEFAULT_PASS_CONFIGS[puzzle_key]["default"])
	return 12


func set_pass_rate(puzzle_key: String, value: int) -> bool:
	if not enabled:
		return false
	if not DEFAULT_PASS_CONFIGS.has(puzzle_key):
		return false
	var max_val: int = get_quiz_count(puzzle_key, int(DEFAULT_PASS_CONFIGS[puzzle_key]["max"]))
	var clamped_val: int = clampi(value, 0, max_val)
	pass_rates[puzzle_key] = clamped_val
	_save_pass_rates()
	return true


func set_pass_rate_by_index(index: int, value: int) -> bool:
	if PUZZLE_INDEX_TO_KEY.has(index):
		return set_pass_rate(PUZZLE_INDEX_TO_KEY[index], value)
	return false


func get_pass_rate_by_index(index: int) -> int:
	if PUZZLE_INDEX_TO_KEY.has(index):
		var key: String = PUZZLE_INDEX_TO_KEY[index]
		return get_pass_rate(key)
	return 12


func get_puzzle_config_by_index(index: int) -> Dictionary:
	if PUZZLE_INDEX_TO_KEY.has(index):
		var key: String = PUZZLE_INDEX_TO_KEY[index]
		if DEFAULT_PASS_CONFIGS.has(key):
			var cfg: Dictionary = DEFAULT_PASS_CONFIGS[key].duplicate()
			var current_count: int = get_quiz_count(key, int(cfg.get("max", 15)))
			cfg["current_count"] = current_count
			cfg["max"] = current_count
			cfg["current_pass"] = get_pass_rate(key)
			return cfg
	return {}


func get_puzzle_config(puzzle_key: String) -> Dictionary:
	if DEFAULT_PASS_CONFIGS.has(puzzle_key):
		var cfg: Dictionary = DEFAULT_PASS_CONFIGS[puzzle_key].duplicate()
		var current_count: int = get_quiz_count(puzzle_key, int(cfg.get("max", 15)))
		cfg["current_count"] = current_count
		cfg["max"] = current_count
		cfg["current_pass"] = get_pass_rate(puzzle_key)
		return cfg
	return {}


func reset_all_pass_rates() -> void:
	pass_rates.clear()
	for key in DEFAULT_PASS_CONFIGS:
		pass_rates[key] = int(DEFAULT_PASS_CONFIGS[key]["default"])
	_save_pass_rates()


func reset_all_quiz_counts() -> void:
	quiz_counts.clear()
	for key in DEFAULT_QUIZ_COUNTS:
		quiz_counts[key] = int(DEFAULT_QUIZ_COUNTS[key])
	_save_pass_rates()


func apply_global_quiz_count(count: int) -> void:
	if not enabled:
		return
	var clamped: int = clampi(count, 1, 50)
	for key in DEFAULT_QUIZ_COUNTS:
		quiz_counts[key] = clamped
		if pass_rates.has(key) and pass_rates[key] > clamped:
			pass_rates[key] = clamped
	_save_pass_rates()


func apply_global_pass_percentage(percentage: float) -> void:
	if not enabled:
		return
	var pct: float = clampf(percentage, 0.0, 100.0) / 100.0
	for key in DEFAULT_PASS_CONFIGS:
		var cfg: Dictionary = DEFAULT_PASS_CONFIGS[key]
		if cfg["type"] == "score":
			var max_v: int = get_quiz_count(key, int(cfg["max"]))
			var req: int = clampi(int(round(max_v * pct)), 1 if pct > 0.0 else 0, max_v)
			pass_rates[key] = req
		elif cfg["type"] == "goal":
			pass_rates[key] = 0 if pct <= 0.0 else 1
	_save_pass_rates()


func _load_pass_rates() -> void:
	pass_rates.clear()
	for key in DEFAULT_PASS_CONFIGS:
		pass_rates[key] = int(DEFAULT_PASS_CONFIGS[key]["default"])
	quiz_counts.clear()
	for key in DEFAULT_QUIZ_COUNTS:
		quiz_counts[key] = int(DEFAULT_QUIZ_COUNTS[key])

	if FileAccess.file_exists(PASS_RATES_SAVE_PATH):
		var file := FileAccess.open(PASS_RATES_SAVE_PATH, FileAccess.READ)
		if file != null:
			var json = JSON.parse_string(file.get_as_text())
			if typeof(json) == TYPE_DICTIONARY:
				if json.has("pass_rates") and typeof(json["pass_rates"]) == TYPE_DICTIONARY:
					var pr: Dictionary = json["pass_rates"]
					for key in pr:
						if DEFAULT_PASS_CONFIGS.has(key):
							pass_rates[key] = int(pr[key])
				else:
					for key in json:
						if DEFAULT_PASS_CONFIGS.has(key):
							pass_rates[key] = int(json[key])
				if json.has("quiz_counts") and typeof(json["quiz_counts"]) == TYPE_DICTIONARY:
					var qc: Dictionary = json["quiz_counts"]
					for key in qc:
						if DEFAULT_QUIZ_COUNTS.has(key):
							quiz_counts[key] = clampi(int(qc[key]), 1, 50)
			file.close()


func _save_pass_rates() -> void:
	if "--devmode-test" in OS.get_cmdline_user_args() or "--route-test" in OS.get_cmdline_user_args():
		return
	var file := FileAccess.open(PASS_RATES_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		var data := {
			"pass_rates": pass_rates,
			"quiz_counts": quiz_counts,
		}
		file.store_string(JSON.stringify(data, "  "))
		file.close()


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


## Inspect the real progress, not temporary UI toggles, so saved progress
## continues to be reflected correctly after restarting the game.
func get_unlocked_count() -> int:
	var count := 0
	var quest_steps := [
		"find_wiz", "after_book1", "after_book2", "after_desk_quiz",
		"after_book3", "separation_methods_after", "find_christofe",
	]
	for quest_id in quest_steps:
		if not QuestManager.is_quest_completed(quest_id):
			return count
		count += 1
	for level in range(1, 4):
		if not QuestManager.density_completed_levels.has(level):
			return count
		count += 1
	if not QuestManager.is_quest_completed("after_density_measurement"):
		return count
	for level in range(1, 3):
		if not QuestManager.get_states_completed_levels().has(level):
			return count
		count += 1
	return count


## Checking a later puzzle completes its prerequisites and unlocks that
## puzzle only. Unchecking a puzzle rolls back it and every later puzzle.
func set_puzzle_unlocked(index: int, checked: bool) -> bool:
	if not enabled or index < 0 or index >= PUZZLES.size():
		return false
	var target_count := index + 1 if checked else index
	return set_unlocked_count(target_count)


func unlock_all() -> bool:
	if not enabled:
		return false
	return set_unlocked_count(PUZZLES.size())


func set_unlocked_count(count: int) -> bool:
	if not enabled or count < 0 or count > PUZZLES.size():
		return false
	# An already unlocked target must not accidentally erase partially finished
	# in-level progress or a legitimately completed final quest.
	if count == get_unlocked_count():
		return true
	if not _backup_current_progress():
		return false

	# Restore all quest definitions so a previously completed stage can be
	# rolled back cleanly without leaving downstream quests completed.
	QuestManager.load_default_quests()
	for quest_id in QUEST_COMPLETION_THRESHOLDS:
		var quest: Quest = QuestManager.active_quests.get(quest_id)
		if quest != null:
			quest.is_completed = count >= int(QUEST_COMPLETION_THRESHOLDS[quest_id])

	QuestManager.density_completed_levels.clear()
	for level in range(1, clampi(count - 7, 0, 3) + 1):
		QuestManager.density_completed_levels.append(level)
	QuestManager.density_progress = QuestManager.density_completed_levels.size()
	QuestManager.completed_levels.clear()
	for level in range(1, clampi(count - 10, 0, 2) + 1):
		QuestManager.completed_levels.append(level)
	QuestManager.cleared_states_levels = QuestManager.completed_levels.duplicate()
	QuestManager.states_progress = QuestManager.completed_levels.size()
	QuestManager.quest_updated.emit()

	# Developer changes must have a playable Continue destination, even if
	# the user opened Developer Mode before ever starting a normal game.
	var destination := HOMETOWN_SCENE
	if count >= 7:
		destination = BUILDING_TWO_SCENE
	elif count >= 1:
		destination = BUILDING_ONE_SCENE
	SpawnManager.clear_pending()
	SaveManager.save_checkpoint(destination, "default")
	return true


func reset_progress() -> bool:
	if not enabled or not _backup_current_progress():
		return false
	SaveManager.reset_for_new_game()
	reset_all_pass_rates()
	reset_all_quiz_counts()
	return true


func _backup_current_progress() -> bool:
	# Always snapshot the latest saved state before a mutation, including
	# mutations performed after leaving and re-entering the dev scene.
	if "--devmode-test" in OS.get_cmdline_user_args() or "--route-test" in OS.get_cmdline_user_args():
		return true
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		if not _backup_file(SaveManager.SAVE_PATH, BACKUP_PATH):
			return false
	# Guides have their own persistent file, independent of save.json.
	# Preserve it too, because Reset Progress now clears guide history.
	if FileAccess.file_exists("user://guides.cfg"):
		if not _backup_file("user://guides.cfg", GUIDE_BACKUP_PATH):
			return false
	return true


func _backup_file(source_path: String, backup_path: String) -> bool:
	var file := FileAccess.open(backup_path, FileAccess.WRITE)
	if file == null:
		push_error("DevMode: cannot back up %s; change cancelled." % source_path)
		return false
	file.store_buffer(FileAccess.get_file_as_bytes(source_path))
	file.flush()
	file.close()
	return true
