extends Node

## Focused persistence contract checks for the Phase 2 save/reset boundary.

const LEGACY_FIXTURE := "res://tests/fixtures/legacy_save.json"
const CORRUPT_FIXTURE := "res://tests/fixtures/corrupt_save.json"
const SAVE_PATH := "user://save.json"
const QUEST_PATH := "user://quest.json"
const LESSON_PATH := "user://lesson_data.json"
const LEVEL3_PATH := "user://item_history.json"
const GUIDE_PATH := "user://guides.cfg"

var _original_save_exists := false
var _original_save_bytes := PackedByteArray()
var _original_quest_exists := false
var _original_quest_bytes := PackedByteArray()
var _original_lesson_exists := false
var _original_lesson_bytes := PackedByteArray()
var _original_level3_exists := false
var _original_level3_bytes := PackedByteArray()
var _original_guides_exists := false
var _original_guides_bytes := PackedByteArray()
var _unexpected_failures: Array[String] = []


func _ready() -> void:
	_snapshot_user_file(SAVE_PATH, "save")
	_snapshot_user_file(QUEST_PATH, "quest")
	_snapshot_user_file(LESSON_PATH, "lesson")
	_snapshot_user_file(LEVEL3_PATH, "level3")
	_snapshot_user_file(GUIDE_PATH, "guide")
	_run_fixture_contracts()
	_run_save_round_trip_contract()
	_run_new_game_reset_contract()
	_run_continue_checkpoint_contract()
	if "--devmode-test" in OS.get_cmdline_user_args():
		_run_dev_mode_contract()
	_restore_user_files()

	for failure in _unexpected_failures:
		print("CONTRACT_UNEXPECTED_FAIL " + failure)
	if _unexpected_failures.is_empty():
		print("CONTRACT_RESULT PASS")
		get_tree().quit(0)
	else:
		print("CONTRACT_RESULT FAIL unexpected=%d" % _unexpected_failures.size())
		get_tree().quit(2)


func _run_fixture_contracts() -> void:
	if not SaveManager.has_method("normalize_save_data"):
		_expect("SaveManager exposes normalize_save_data contract", false)
		return
	var legacy: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_FIXTURE))
	_expect("legacy fixture parses", typeof(legacy) == TYPE_DICTIONARY)
	if typeof(legacy) == TYPE_DICTIONARY:
		_expect("legacy fixture omits completed identity arrays", not legacy.has("density_completed_levels") and not legacy.has("completed_states_levels"))
		var migrated: Dictionary = SaveManager.normalize_save_data(legacy)
		_expect("legacy scene path is retained", migrated.get("scene_path", "") == "res://games/chapter_one/hometown/hometown.tscn")
		_expect("legacy data receives schema version", migrated.get("schema_version", 0) == SaveManager.SAVE_SCHEMA_VERSION)
		_expect("legacy missing density identities default to empty", migrated.get("density_completed_levels", []).is_empty())
		_expect("legacy missing states identities default to empty", migrated.get("states_completed_levels", []).is_empty())
	var legacy_scene_only: Dictionary = SaveManager.normalize_save_data({
		"last_scene": "res://games/chapter_one/hometown/building_two/building_two.tscn"
	})
	_expect("legacy last_scene migrates to scene_path", legacy_scene_only.get("scene_path", "") == "res://games/chapter_one/hometown/building_two/building_two.tscn")

	var invalid_path: Dictionary = SaveManager.normalize_save_data({"scene_path": "res://does_not_exist.tscn"})
	_expect("invalid scene path uses safe fallback", invalid_path.get("scene_path", "") == SaveManager.SAFE_SCENE_PATH)

	var corrupt: Variant = JSON.parse_string(FileAccess.get_file_as_string(CORRUPT_FIXTURE))
	_expect("corrupt fixture is rejected", corrupt == null)


func _run_save_round_trip_contract() -> void:
	if not SaveManager.has_method("save_now"):
		_expect("SaveManager exposes save_now contract", false)
		return
	QuestManager.density_progress = 2
	QuestManager.density_completed_levels = [1, 2]
	QuestManager.states_progress = 2
	QuestManager.completed_levels = [1, 2]
	SaveManager.last_spawn = "default"
	SaveManager.shown_feedback = []
	SaveManager.quest_data = {"quests": []}
	SaveManager.save_now("res://intro.tscn")

	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_expect("save round trip writes JSON", typeof(saved) == TYPE_DICTIONARY)
	if typeof(saved) != TYPE_DICTIONARY:
		return
	_expect("save round trip records explicit destination", saved.get("scene_path", "") == "res://intro.tscn")
	_expect("save contains schema version", saved.get("schema_version", 0) == SaveManager.SAVE_SCHEMA_VERSION)
	_expect("save persists density completed identities", saved.has("density_completed_levels"))
	_expect("save persists states completed identities", saved.has("states_completed_levels"))
	if saved.has("density_completed_levels"):
		_expect("density completed identities round-trip", SaveManager.normalize_level_ids(saved["density_completed_levels"], 3) == [1, 2])
	if saved.has("states_completed_levels"):
		_expect("states completed identities round-trip", SaveManager.normalize_level_ids(saved["states_completed_levels"], 3) == [1, 2])
	_expect("duplicate level IDs are normalized", SaveManager.normalize_level_ids([1, 1, 0, 2, 99], 3) == [1, 2])

	QuestManager.density_completed_levels = [1]
	QuestManager.density_progress = 1
	QuestManager.advance_density_level(1)
	_expect("replaying a density level adds no credit", QuestManager.density_progress == 1 and QuestManager.density_completed_levels == [1])
	QuestManager.completed_levels = [2]
	QuestManager.states_progress = 2
	QuestManager.advance_states_level(2)
	_expect("replaying a states level adds no credit", QuestManager.states_progress == 2 and QuestManager.completed_levels == [2])


func _run_new_game_reset_contract() -> void:
	if not SaveManager.has_method("reset_for_new_game"):
		_expect("SaveManager exposes reset_for_new_game contract", false)
		return
	GuideManager.mark_seen("lesson_1_guide")
	GuideManager.mark_seen("hometown_controls_tutorial")
	_expect("guides are recorded as seen before reset", GuideManager.has_seen("lesson_1_guide") and GuideManager.has_seen("hometown_controls_tutorial"))
	SaveManager.reset_for_new_game()
	_expect("new game makes guides appear again", not GuideManager.has_seen("lesson_1_guide") and not GuideManager.has_seen("hometown_controls_tutorial"))
	var guide_data := ConfigFile.new()
	_expect("new game clears on-disk guide flags", guide_data.load(GUIDE_PATH) == OK and not guide_data.get_value("guides", "lesson_1_guide", false))
	var quests: Array = QuestManager.get_active_quests()
	var all_reset := true
	for quest in quests:
		if quest.is_completed:
			all_reset = false
			break
	_expect("new game reset clears every quest completion", all_reset)
	_expect("new game reset clears density IDs", QuestManager.density_completed_levels.is_empty())
	_expect("new game reset clears states IDs", QuestManager.completed_levels.is_empty())
	_expect("new game reset clears feedback", PlayerFeedbackManager.get_shown_feedback().is_empty())
	_expect("new game reset sets spawn", SpawnManager.spawn_point == "default")
	_expect("new game reset saves cutscene destination", SaveManager.current_scene_path == SaveManager.NEW_GAME_SCENE_PATH)


func _run_continue_checkpoint_contract() -> void:
	const HOMETOWN := "res://games/chapter_one/hometown/hometown.tscn"
	SaveManager.reset_for_new_game()
	_expect("Continue disabled before first spawn", not SaveManager.has_continue_checkpoint())
	var menu_scene: Node = load("res://games/main.tscn").instantiate()
	add_child(menu_scene)
	var menu_continue: Button = menu_scene.get_node("CanvasLayer/VBoxContainer/Continue")
	_expect("Continue appears grey after progress reset", menu_continue.disabled and menu_continue.modulate.a <= 0.5 and menu_continue.modulate.r < 1.0)
	SaveManager.save_checkpoint(HOMETOWN, "default")
	_expect("first spawn enables Continue", SaveManager.has_continue_checkpoint())
	menu_scene.call("_refresh_continue_button")
	_expect("Continue is fully visible with a checkpoint", not menu_continue.disabled and menu_continue.modulate == Color.WHITE)
	var checkpoint: Dictionary = SaveManager.load_game()
	_expect("first spawn persists a valid checkpoint", checkpoint.get("has_started_game", false) and checkpoint.get("scene_path", "") == HOMETOWN and checkpoint.get("last_spawn", "") == "default")
	SaveManager.save_before_transition("res://games/main.tscn")
	SaveManager.save_before_transition("res://games/glossary/main.tscn")
	SaveManager.save_game()
	SaveManager.flush_pending_save()
	var after_menu: Dictionary = SaveManager.load_game()
	_expect("menu and glossary navigation preserve checkpoint", after_menu.get("scene_path", "") == HOMETOWN and after_menu.get("has_started_game", false))
	SaveManager.restore_game(after_menu)
	_expect("Continue can restore saved spawn and scene", SaveManager.has_continue_checkpoint() and SaveManager.last_spawn == "default" and SaveManager.current_scene_path == HOMETOWN)
	SaveManager.reset_for_new_game()
	_expect("New Game disables previous Continue checkpoint", not SaveManager.has_continue_checkpoint())
	menu_scene.call("_refresh_continue_button")
	_expect("Continue becomes grey again after another reset", menu_continue.disabled and menu_continue.modulate.a <= 0.5)
	menu_scene.queue_free()


func _run_dev_mode_contract() -> void:
	SaveManager.reset_for_new_game()
	DevModeManager.disable()
	_expect("dev edit denied while disabled", not DevModeManager.set_unlocked_count(4))
	_expect("dev mode starts disabled", not DevModeManager.enabled)
	var main_scene: Node = load("res://games/main.tscn").instantiate()
	add_child(main_scene)
	var dev_indicator := main_scene.get_node("CanvasLayer2/DevLabel") as Label
	_expect("main screen hides dev indicator", not dev_indicator.visible)
	for i in range(4):
		main_scene.call("_on_dev_button_pressed")
	_expect("four quick clicks do not enable Dev Mode", not DevModeManager.enabled)
	main_scene.set("_dev_first_click_ms", Time.get_ticks_msec() - 2100)
	main_scene.call("_on_dev_button_pressed")
	_expect("clicks after two seconds restart activation count", not DevModeManager.enabled and main_scene.get("_dev_click_count") == 1)
	for i in range(3):
		main_scene.call("_on_dev_button_pressed")
	_expect("after expiry four new clicks are not enough", not DevModeManager.enabled)
	main_scene.call("_on_dev_button_pressed")
	_expect("fifth click enables Dev Mode and label", DevModeManager.enabled and dev_indicator.visible)
	main_scene.queue_free()
	_expect("initial puzzle count is zero", DevModeManager.get_unlocked_count() == 0)
	_expect("developer unlock of fourth puzzle succeeds", DevModeManager.set_puzzle_unlocked(3, true))
	_expect("fourth puzzle unlock completes earlier three", DevModeManager.get_unlocked_count() == 4 and QuestManager.is_quest_completed("finish_book1") and QuestManager.is_quest_completed("finish_book2") and QuestManager.is_quest_completed("desk_quiz"))
	_expect("fourth puzzle remains unfinished", not QuestManager.is_quest_completed("finish_book3"))
	_expect("developer unlock of states level 2 succeeds", DevModeManager.set_puzzle_unlocked(10, true))
	_expect("density prerequisite levels are completed", QuestManager.density_completed_levels == [1, 2, 3] and QuestManager.is_quest_completed("after_density_measurement"))
	_expect("states level 1 complete, level 2 unlocked", DevModeManager.get_unlocked_count() == 11 and QuestManager.completed_levels == [1] and not QuestManager.is_quest_completed("states_of_matter"))
	var dev_saved: Dictionary = SaveManager.load_game()
	QuestManager.reset_for_new_game()
	SaveManager.restore_game(dev_saved)
	_expect("developer progress survives save/load", DevModeManager.get_unlocked_count() == 11 and QuestManager.density_completed_levels == [1, 2, 3] and QuestManager.completed_levels == [1])
	_expect("developer progression never skips final reward", not QuestManager.is_quest_completed("after_states_of_matter"))
	_expect("developer selection saved into Continue hub", SaveManager.has_continue_checkpoint() and SaveManager.current_scene_path == DevModeManager.BUILDING_TWO_SCENE)
	_expect("unchecking second puzzle succeeds", DevModeManager.set_puzzle_unlocked(1, false))
	_expect("unchecking second rolls back it and later stages", DevModeManager.get_unlocked_count() == 1 and not QuestManager.is_quest_completed("finish_book1") and not QuestManager.is_quest_completed("desk_quiz") and QuestManager.density_completed_levels.is_empty() and QuestManager.completed_levels.is_empty())
	var dev_scene: Node = load("res://games/devmode.tscn").instantiate()
	add_child(dev_scene)
	_expect("dev scene renders all 12 puzzle checkboxes", dev_scene.get_node("PuzzleScroll/PuzzleList").get_child_count() == DevModeManager.PUZZLES.size())
	dev_scene.queue_free()
	DevModeManager.disable()
	_expect("disabled dev mode rejects unlock-all", not DevModeManager.unlock_all())
	DevModeManager.enable()
	_expect("unlock all sets prerequisites but not final puzzle completion", DevModeManager.unlock_all() and DevModeManager.get_unlocked_count() == 12 and QuestManager.completed_levels == [1, 2] and not QuestManager.is_quest_completed("states_of_matter"))
	GuideManager.mark_seen("property_guide")
	_expect("dev reset clears progress and guides", DevModeManager.reset_progress() and not SaveManager.has_continue_checkpoint() and DevModeManager.get_unlocked_count() == 0 and not GuideManager.has_seen("property_guide"))
	DevModeManager.disable()


func _expect(label: String, condition: bool) -> void:
	if not condition:
		_unexpected_failures.append(label)


func _snapshot_user_file(path: String, kind: String) -> void:
	var exists := FileAccess.file_exists(path)
	var bytes := FileAccess.get_file_as_bytes(path) if exists else PackedByteArray()
	if kind == "save":
		_original_save_exists = exists
		_original_save_bytes = bytes
	elif kind == "quest":
		_original_quest_exists = exists
		_original_quest_bytes = bytes
	elif kind == "lesson":
		_original_lesson_exists = exists
		_original_lesson_bytes = bytes
	elif kind == "level3":
		_original_level3_exists = exists
		_original_level3_bytes = bytes
	elif kind == "guide":
		_original_guides_exists = exists
		_original_guides_bytes = bytes


func _restore_user_files() -> void:
	_restore_user_file(SAVE_PATH, _original_save_exists, _original_save_bytes)
	_restore_user_file(QUEST_PATH, _original_quest_exists, _original_quest_bytes)
	_restore_user_file(LESSON_PATH, _original_lesson_exists, _original_lesson_bytes)
	_restore_user_file(LEVEL3_PATH, _original_level3_exists, _original_level3_bytes)
	_restore_user_file(GUIDE_PATH, _original_guides_exists, _original_guides_bytes)


func _restore_user_file(path: String, existed: bool, bytes: PackedByteArray) -> void:
	if existed:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_buffer(bytes)
			file.close()
	else:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)
