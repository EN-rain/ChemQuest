extends Node

## Deterministic, headless interaction checks for the recovery-critical routes.
## The runner uses real scenes and public gameplay methods, but never writes the
## developer profile (`--route-test` makes SaveManager retain an in-memory
## snapshot instead).

const BUILDING_ONE_PATH := "res://games/chapter_one/hometown/building_one/building_one.tscn"
const LESSON_THREE_PATH := "res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn"
const STATES_MAIN_PATH := "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/main.tscn"
const STATES_LEVEL_ONE_PATH := "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn"

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	if has_node("/root/FadeManager"):
		FadeManager.set_test_mode(true)
	await _run_checks()
	if _failures.is_empty():
		print("ROUTE_INTERACTION PASS checks=%d" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("ROUTE_INTERACTION_FAIL " + failure)
		get_tree().quit(1)


func _run_checks() -> void:
	_test_spawn_contract()
	_test_progression_contract()
	_test_fade_service()
	await _test_states_touch_controls()
	await _test_lesson_three_completion()
	_test_canonical_states_resources()


func _test_spawn_contract() -> void:
	SpawnManager.set_spawn("seperation_spawn")
	_check(SpawnManager.get_spawn() == "separation_spawn", "legacy separation spawn alias was not normalized")
	var resolved := SpawnManager.validate_for_scene(BUILDING_ONE_PATH)
	_check(resolved == "separation_spawn", "canonical separation spawn was rejected by Building One")
	SpawnManager.set_spawn("from_hometown")
	resolved = SpawnManager.validate_for_scene(BUILDING_ONE_PATH)
	_check(resolved == "default", "invalid Building One spawn did not fall back to default")
	_check(SaveManager.last_spawn == "default", "SaveManager.last_spawn was not synchronized after fallback")
	SpawnManager.clear_pending()


func _test_progression_contract() -> void:
	QuestManager.reset_for_new_game()
	QuestManager.density_completed_levels.clear()
	QuestManager.density_progress = 0
	QuestManager.advance_density_level(1)
	QuestManager.advance_density_level(1)
	_check(QuestManager.density_progress == 1, "density replay changed progress")
	_check(not QuestManager.is_quest_completed("density_measurement"), "density quest completed before level 3")
	QuestManager.advance_density_level(2)
	_check(QuestManager.density_progress == 2, "density level 2 was not recorded")
	QuestManager.advance_density_level(3)
	_check(QuestManager.density_progress == 3, "density level 3 was not recorded")
	_check(QuestManager.is_quest_completed("density_measurement"), "density quest did not complete at level 3")
	_check(int(SaveManager.last_save_data.get("density_progress", -1)) == 3, "density completion was not captured in the save snapshot")
	_check(SaveManager.last_save_data.get("density_completed_levels", []) == [1, 2, 3], "density level identities were not persisted")
	QuestManager.advance_density_level(3)
	_check(QuestManager.density_completed_levels.size() == 3, "density replay duplicated level identity")

	QuestManager.reset_for_new_game()
	QuestManager.completed_levels.clear()
	QuestManager.cleared_states_levels.clear()
	QuestManager.states_progress = 0
	QuestManager.advance_states_level(1)
	QuestManager.advance_states_level(1)
	_check(QuestManager.states_progress == 1, "states replay changed progress")
	QuestManager.advance_states_level(2)
	QuestManager.advance_states_level(3)
	_check(QuestManager.states_progress == 3, "states level 3 was not recorded")
	_check(QuestManager.is_quest_completed("states_of_matter"), "states quest did not complete at level 3")
	_check(int(SaveManager.last_save_data.get("states_progress", -1)) == 3, "states completion was not captured in the save snapshot")
	_check(SaveManager.last_save_data.get("states_completed_levels", []) == [1, 2, 3], "states level identities were not persisted")
	QuestManager.advance_states_level(2)
	_check(QuestManager.get_states_completed_levels().size() == 3, "states replay duplicated level identity")


func _test_fade_service() -> void:
	_check(is_instance_valid(FadeManager.fade_rect), "FadeManager does not own a persistent overlay")
	var invalid := await FadeManager.fade_and_change("res://tests/routes/missing_scene.tscn", 0.0)
	_check(not invalid, "FadeManager accepted an invalid scene path")
	_check(not FadeManager._transition_in_progress, "invalid transition left FadeManager locked")


func _test_states_touch_controls() -> void:
	var packed := load("res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/StateTouchControls.tscn") as PackedScene
	_check(packed != null, "States touch-control scene failed to load")
	if packed == null:
		return
	var controls := packed.instantiate()
	add_child(controls)
	await get_tree().process_frame
	var solid := controls.get_node_or_null("Control/Actions/Solid") as Button
	var liquid := controls.get_node_or_null("Control/Actions/Liquid") as Button
	var gas := controls.get_node_or_null("Control/Actions/Gas") as Button
	var left := controls.get_node_or_null("Control/Movement/left") as Button
	_check(solid != null and liquid != null and gas != null and left != null, "States touch buttons are missing")
	if solid != null:
		solid.emit_signal("button_down")
		_check(Input.is_action_pressed("Solid"), "Solid touch button did not press the input action")
		solid.emit_signal("button_up")
		_check(not Input.is_action_pressed("Solid"), "Solid touch button did not release the input action")
	if liquid != null:
		liquid.emit_signal("button_down")
		_check(Input.is_action_pressed("Liquid"), "Liquid touch button did not press the input action")
		liquid.emit_signal("button_up")
	if gas != null:
		gas.emit_signal("button_down")
		_check(Input.is_action_pressed("Gas"), "Gas touch button did not press the input action")
		gas.emit_signal("button_up")
	if left != null:
		_check(left.custom_minimum_size.x >= 72.0 and left.custom_minimum_size.y >= 72.0, "movement touch target is smaller than 72 design pixels")
	controls.queue_free()
	await get_tree().process_frame


func _test_lesson_three_completion() -> void:
	QuestManager.reset_for_new_game()
	var packed := load(LESSON_THREE_PATH) as PackedScene
	_check(packed != null, "Lesson 3 scene failed to load for completion test")
	if packed == null:
		return
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var results := scene.get_node_or_null("CanvasLayer/MarginContainer/Control/ResultsPanel")
	_check(results != null and results.has_method("show_results"), "Lesson 3 results panel is not callable")
	if results != null and results.has_method("show_results"):
		results.show_results(12, [])
		_check(QuestManager.is_quest_completed("finish_book3"), "Lesson 3 pass did not complete finish_book3")
		_check(not QuestManager.is_quest_completed("after_book3"), "Lesson 3 pass completed the follow-up quest prematurely")
		_check(QuestManager.has_quest("after_book3"), "Lesson 3 pass did not expose after_book3")
	scene.queue_free()
	await get_tree().process_frame


func _test_canonical_states_resources() -> void:
	var player_scene := load("res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/player.tscn") as PackedScene
	var gate_scene := load("res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/lvl_gate2.tscn") as PackedScene
	_check(player_scene != null and gate_scene != null, "canonical States player/gate resources failed to load")
	if player_scene != null:
		var player := player_scene.instantiate()
		var script_path := str(player.get_script().resource_path) if player.get_script() else ""
		_check("level2-2/mattermaze/Scripts/player.gd" in script_path and "Level2-1/Level2-1" not in script_path, "States player still uses a legacy duplicate script")
		player.free()
	if gate_scene != null:
		var gate := gate_scene.instantiate()
		var script_path := str(gate.get_script().resource_path) if gate.get_script() else ""
		_check("level2-2/mattermaze/Scenes/lvl_gate_2.gd" in script_path and "Level2-1/Level2-1" not in script_path, "States gate still uses a legacy duplicate script")
		gate.free()
	_check(ResourceLoader.exists(STATES_MAIN_PATH, "PackedScene"), "States tutorial scene is missing")
	_check(ResourceLoader.exists(STATES_LEVEL_ONE_PATH, "PackedScene"), "States level 1 scene is missing")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
