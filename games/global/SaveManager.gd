extends Node

## SaveManager owns the one persisted gameplay document.
##
## `user://quest.json` is legacy data and is intentionally left untouched. New
## saves use `user://save.json` with an explicit schema version so migrations
## are deterministic and can be tested without relying on autoload order.

const SAVE_PATH := "user://save.json"
const TEMP_SAVE_PATH := "user://save.json.tmp"
const SAVE_SCHEMA_VERSION: int = 2
const SAVE_COALESCE_MS: int = 250
const SAFE_SCENE_PATH := "res://games/main.tscn"
const NEW_GAME_SCENE_PATH := "res://games/chapter_one/visual_one.tscn"
const MAX_DENSITY_LEVEL: int = 3
const MAX_STATES_LEVEL: int = 3

var current_scene_path: String = ""
var last_spawn: String = ""
var has_started_game: bool = false
var quest_data: Dictionary = {}
var shown_feedback: Array[String] = []
var last_save_data: Dictionary = {}

var _save_dirty: bool = false
var _save_timer: SceneTreeTimer
var _test_mode: bool = false


func _ready() -> void:
	_test_mode = "--route-test" in OS.get_cmdline_user_args()
	print("SaveManager save path: ", ProjectSettings.globalize_path(SAVE_PATH))
	var data: Dictionary = load_game()
	if not data.is_empty():
		restore_game(data)
	else:
		print("SaveManager: no previous save found; starting fresh.")


## Queue a coalesced save for routine progress updates.
func save_game() -> void:
	if _test_mode:
		_perform_save()
		return
	_save_dirty = true
	if _save_timer and _save_timer.time_left > 0.0:
		return
	_save_timer = get_tree().create_timer(float(SAVE_COALESCE_MS) / 1000.0)
	_save_timer.timeout.connect(_flush_deferred_save, CONNECT_ONE_SHOT)


func _flush_deferred_save() -> void:
	_save_timer = null
	if not _save_dirty:
		return
	_save_dirty = false
	_perform_save()


## Flush a pending write synchronously. An optional destination is used by
## transitions so a menu scene cannot overwrite the intended next scene.
func save_now(scene_path: String = "") -> bool:
	_save_dirty = false
	_save_timer = null
	var destination := ""
	if not scene_path.is_empty():
		destination = _validated_scene_path(scene_path, SAFE_SCENE_PATH)
		current_scene_path = destination
		_perform_save(destination)
	else:
		_perform_save()
	return _test_mode or FileAccess.file_exists(SAVE_PATH)


func flush_pending_save() -> void:
	if _save_dirty:
		_save_dirty = false
		_save_timer = null
		_perform_save()


func _perform_save(scene_path_override: String = "") -> void:
	if not scene_path_override.is_empty():
		current_scene_path = _validated_scene_path(scene_path_override, SAFE_SCENE_PATH)
	elif get_tree().current_scene:
		# Menus, glossary, and reward screens must not replace the last
		# playable scene with a non-playable Continue destination.
		var active_scene := get_tree().current_scene.scene_file_path
		if is_gameplay_scene(active_scene):
			current_scene_path = active_scene

	if current_scene_path.is_empty():
		current_scene_path = SAFE_SCENE_PATH
	current_scene_path = _validated_scene_path(current_scene_path, SAFE_SCENE_PATH)

	var quests: Array = []
	if has_node("/root/QuestManager"):
		for quest in QuestManager.active_quests.values():
			quests.append({
				"id": quest.id,
				"title": quest.title,
				"description": quest.description,
				"is_completed": quest.is_completed
			})
		quest_data["quests"] = quests

	if has_node("/root/SpawnManager"):
		# `spawn_point` is a one-shot transition value. Hubs clear it after
		# consuming the marker, so an empty value must not erase the persistent
		# resume spawn saved by the previous hub/lesson boundary.
		var pending_spawn := SpawnManager.normalize_spawn_name(SpawnManager.spawn_point)
		if not pending_spawn.is_empty():
			last_spawn = pending_spawn
	if has_node("/root/PlayerFeedbackManager"):
		shown_feedback = PlayerFeedbackManager.get_shown_feedback().duplicate()

	var density_ids: Array[int] = []
	var states_ids: Array[int] = []
	if has_node("/root/QuestManager"):
		density_ids = normalize_level_ids(QuestManager.density_completed_levels, MAX_DENSITY_LEVEL)
		if QuestManager.has_method("get_states_completed_levels"):
			states_ids = normalize_level_ids(QuestManager.get_states_completed_levels(), MAX_STATES_LEVEL)
		else:
			states_ids = normalize_level_ids(QuestManager.completed_levels, MAX_STATES_LEVEL)

	var save_data: Dictionary = {
		"schema_version": SAVE_SCHEMA_VERSION,
		"has_started_game": has_started_game,
		"scene_path": current_scene_path,
		"last_spawn": last_spawn,
		"quests": quest_data.get("quests", []),
		"shown_feedback": shown_feedback,
		"density_progress": int(QuestManager.density_progress) if has_node("/root/QuestManager") else 0,
		"density_completed_levels": density_ids,
		"states_progress": int(QuestManager.states_progress) if has_node("/root/QuestManager") else 0,
		"states_completed_levels": states_ids
	}
	last_save_data = save_data.duplicate(true)
	if _test_mode:
		print("SaveManager: route-test snapshot captured")
		return
	if _write_save_atomically(JSON.stringify(save_data, "\t")):
		print("SaveManager: game saved -> ", SAVE_PATH)


func _write_save_atomically(contents: String) -> bool:
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: failed to open temporary save for writing.")
		return false
	file.store_string(contents)
	file.flush()
	file.close()

	var temp_absolute := ProjectSettings.globalize_path(TEMP_SAVE_PATH)
	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var backup_absolute := save_absolute + ".bak"
	if FileAccess.file_exists(backup_absolute):
		DirAccess.remove_absolute(backup_absolute)

	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			push_error("SaveManager: failed to stage previous save (error %d)." % backup_error)
			return false

	var rename_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if rename_error != OK:
		if FileAccess.file_exists(backup_absolute):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		push_error("SaveManager: failed to commit save (error %d)." % rename_error)
		return false

	if FileAccess.file_exists(backup_absolute):
		DirAccess.remove_absolute(backup_absolute)
	return true


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: failed to open save file.")
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: invalid save JSON; using safe defaults.")
		return {}
	return normalize_save_data(parsed)


## Normalize both legacy documents and the current schema at the boundary.
func normalize_save_data(raw_data: Dictionary) -> Dictionary:
	var data: Dictionary = raw_data.duplicate(true)
	data["schema_version"] = SAVE_SCHEMA_VERSION
	# Older quest saves called this field `last_scene`; prefer the current
	# schema when present and migrate the legacy name when it is the only value.
	var raw_scene := str(data.get("scene_path", ""))
	if raw_scene.is_empty():
		raw_scene = str(data.get("last_scene", ""))
	data["scene_path"] = _validated_scene_path(raw_scene, SAFE_SCENE_PATH)
	# Older saves have no explicit started flag. A playable checkpoint is
	# sufficient evidence that the player reached gameplay previously.
	data["has_started_game"] = _to_bool(data.get("has_started_game", is_gameplay_scene(data["scene_path"])))
	data["last_spawn"] = _normalize_spawn_name(str(data.get("last_spawn", "")))
	data["quests"] = _normalize_quests(data.get("quests", []))
	data["shown_feedback"] = _normalize_string_array(data.get("shown_feedback", []))
	data["density_progress"] = clampi(int(data.get("density_progress", 0)), 0, MAX_DENSITY_LEVEL)
	data["density_completed_levels"] = normalize_level_ids(data.get("density_completed_levels", []), MAX_DENSITY_LEVEL)
	var legacy_states: Variant = data.get("states_completed_levels", data.get("completed_states_levels", []))
	data["states_completed_levels"] = normalize_level_ids(legacy_states, MAX_STATES_LEVEL)
	data["states_progress"] = clampi(int(data.get("states_progress", 0)), 0, MAX_STATES_LEVEL)
	return data


func normalize_level_ids(raw_value: Variant, max_level: int) -> Array[int]:
	var result: Array[int] = []
	if not raw_value is Array:
		return result
	for value in raw_value:
		var level := int(value)
		if level <= 0 or level > max_level or result.has(level):
			continue
		result.append(level)
	result.sort()
	return result


func _normalize_quests(raw_value: Variant) -> Array:
	var result: Array = []
	if not raw_value is Array:
		return result
	for entry in raw_value:
		if not entry is Dictionary:
			continue
		result.append({
			"id": str(entry.get("id", "")),
			"title": str(entry.get("title", "")),
			"description": str(entry.get("description", "")),
			"is_completed": _to_bool(entry.get("is_completed", false))
		})
	return result


func _normalize_string_array(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not raw_value is Array:
		return result
	for value in raw_value:
		if typeof(value) == TYPE_STRING and not result.has(value):
			result.append(value)
	return result


func _to_bool(value: Variant) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_STRING:
		return value.strip_edges().to_lower() == "true"
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return value != 0
	return false


func _normalize_spawn_name(value: String) -> String:
	if has_node("/root/SpawnManager") and SpawnManager.has_method("normalize_spawn_name"):
		return SpawnManager.normalize_spawn_name(value)
	if value == "seperation_spawn":
		return "separation_spawn"
	return value


func _validated_scene_path(path: String, fallback: String) -> String:
	if path.begins_with("res://") and ResourceLoader.exists(path, "PackedScene"):
		return path
	if not path.is_empty():
		push_warning("SaveManager: invalid scene path '%s'; using %s." % [path, fallback])
	return fallback


func is_gameplay_scene(scene_path: String) -> bool:
	return scene_path.begins_with("res://games/chapter_one/") and scene_path != NEW_GAME_SCENE_PATH


func has_continue_checkpoint() -> bool:
	return has_started_game and is_gameplay_scene(current_scene_path) and FileAccess.file_exists(SAVE_PATH)


## Scene navigation should only checkpoint destinations in gameplay. Going
## back to the menu (or visiting a glossary/reward screen) preserves the
## previously saved scene, including any progress made before navigating away.
func save_before_transition(destination: String) -> void:
	if has_node("/root/ReviewManager") and ReviewManager.is_in_review:
		return
	if is_gameplay_scene(destination):
		save_now(destination)
	elif get_tree().current_scene and is_gameplay_scene(get_tree().current_scene.scene_file_path):
		save_now(get_tree().current_scene.scene_file_path)
	else:
		flush_pending_save()


## Called after the player has actually spawned in a playable hub. A
## synchronous checkpoint means an immediate return to menu is safe.
func save_checkpoint(scene_path: String, spawn_name: String) -> void:
	if not is_gameplay_scene(scene_path) or not ResourceLoader.exists(scene_path, "PackedScene"):
		push_warning("SaveManager: refusing checkpoint in non-gameplay scene: " + scene_path)
		return
	if spawn_name.is_empty():
		push_warning("SaveManager: checkpoint requires a non-empty spawn name.")
		return
	last_spawn = _normalize_spawn_name(spawn_name)
	has_started_game = true
	save_now(scene_path)


func restore_game(data: Dictionary) -> void:
	var normalized := normalize_save_data(data)
	has_started_game = normalized["has_started_game"]
	last_spawn = _normalize_spawn_name(normalized["last_spawn"])
	current_scene_path = normalized["scene_path"]
	quest_data["quests"] = normalized["quests"]
	shown_feedback = normalized["shown_feedback"]

	if has_node("/root/QuestManager"):
		QuestManager.load_from_save_data(quest_data["quests"])
		QuestManager.density_progress = int(normalized["density_progress"])
		QuestManager.density_completed_levels = normalize_level_ids(normalized["density_completed_levels"], MAX_DENSITY_LEVEL)
		QuestManager.states_progress = int(normalized["states_progress"])
		QuestManager.completed_levels = normalize_level_ids(normalized["states_completed_levels"], MAX_STATES_LEVEL)
		if QuestManager.has_method("get_states_completed_levels"):
			QuestManager.cleared_states_levels = QuestManager.completed_levels.duplicate()
	if has_node("/root/SpawnManager"):
		SpawnManager.spawn_point = last_spawn
	if has_node("/root/PlayerFeedbackManager"):
		PlayerFeedbackManager.set_shown_feedback(shown_feedback)


func continue_game() -> void:
	var next_scene := _validated_scene_path(current_scene_path, SAFE_SCENE_PATH)
	current_scene_path = next_scene
	if has_node("/root/FadeManager"):
		await FadeManager.fade_and_change(next_scene)
	else:
		if get_tree().change_scene_to_file(next_scene) != OK:
			push_error("SaveManager: failed to continue into %s." % next_scene)


func save_spawn(spawn_name: String) -> void:
	if spawn_name.is_empty():
		push_warning("SaveManager: tried to save an empty spawn name.")
		return
	last_spawn = _normalize_spawn_name(spawn_name)
	save_game()


func change_scene_with_save(scene_path: String, spawn_name: String = "") -> void:
	if spawn_name != "":
		last_spawn = spawn_name
	save_now(scene_path)


## Reset a complete game session, including once-per-playthrough guides.
## A New Game or developer Reset Progress must show tutorials again.
func reset_for_new_game() -> void:
	_save_dirty = false
	_save_timer = null
	current_scene_path = NEW_GAME_SCENE_PATH
	last_spawn = "default"
	has_started_game = false
	quest_data.clear()
	shown_feedback.clear()

	if has_node("/root/QuestManager"):
		QuestManager.reset_for_new_game()
	if has_node("/root/SpawnManager"):
		SpawnManager.spawn_point = "default"
	if has_node("/root/PlayerFeedbackManager") and PlayerFeedbackManager.has_method("reset_progress"):
		PlayerFeedbackManager.reset_progress()
	if has_node("/root/GuideManager") and GuideManager.has_method("reset_all"):
		GuideManager.reset_all()
	if has_node("/root/ChallengeManager") and ChallengeManager.has_method("reset_state"):
		ChallengeManager.reset_state()
	if has_node("/root/Scoring"):
		Scoring.reset_precision_accuracy_score()
		if Scoring.has_method("reset_progress"):
			Scoring.reset_progress()
	if has_node("/root/LessonManager") and LessonManager.has_method("reset_progress"):
		LessonManager.reset_progress()
	if has_node("/root/Level3Manager") and Level3Manager.has_method("reset_progress"):
		Level3Manager.reset_progress()
	# Book III mixture history is stored outside LessonManager's file.
	# Clearing it ensures Reset Progress really starts every puzzle fresh.
	var mixture_history := FileAccess.open("user://data_history.json", FileAccess.WRITE)
	if mixture_history:
		mixture_history.store_string(JSON.stringify({"spawn_history": {}, "run_count": 0}, "\t"))
		mixture_history.close()
	else:
		push_warning("SaveManager: could not reset mixture spawn history.")

	# Reset control scheme election config so new game / reset asks the player again
	var settings_cfg := ConfigFile.new()
	if settings_cfg.load("user://settings.cfg") == OK:
		settings_cfg.set_value("controls", "chosen", false)
		settings_cfg.set_value("controls", "type", "arrows")
		settings_cfg.save("user://settings.cfg")

	save_now(NEW_GAME_SCENE_PATH)
