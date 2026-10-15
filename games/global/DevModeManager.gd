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


func get_puzzle_names() -> Array:
	return PUZZLES.duplicate()


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
