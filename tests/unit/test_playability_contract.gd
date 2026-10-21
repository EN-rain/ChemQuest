extends Node

## Regression contracts for the first playability recovery slice.

var _failures: Array[String] = []


func _ready() -> void:
	_check_hometown_camera_contract()
	_check_fade_manager_contract()
	_check_lesson_three_progression_contract()
	_check_spawn_contract()
	_check_states_route_contract()
	_check_nav_arrow_contract()

	if _failures.is_empty():
		print("PLAYABILITY_CONTRACT PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("PLAYABILITY_FAIL " + failure)
		get_tree().quit(1)


func _check_hometown_camera_contract() -> void:
	var scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/hometown.tscn")
	_expect("Hometown camera covers authored world bounds", scene.contains("authored_bounds = Rect2(-2724, -2704, 5183, 5499)"))


func _check_fade_manager_contract() -> void:
	var source := FileAccess.get_file_as_string("res://games/global/FadeManager.gd")
	_expect("FadeManager owns a persistent CanvasLayer", source.contains("CanvasLayer.new()"))
	_expect("FadeManager exposes transition_started", source.contains("signal transition_started"))
	_expect("FadeManager exposes transition_finished", source.contains("signal transition_finished"))


func _check_lesson_three_progression_contract() -> void:
	var source := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_one/Level1/Lesson3/results_panel.gd")
	_expect("Lesson 3 completes finish_book3", source.contains('complete_quest("finish_book3")'))
	_expect("Lesson 3 unlocks after_book3", source.contains('get_quest_template("after_book3")'))
	_expect("Lesson 3 no longer completes after_book2", not source.contains('complete_quest("after_book2")'))


func _check_spawn_contract() -> void:
	var scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_one/building_one.tscn")
	var source := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_one/Level3/results_panel.gd")
	_expect("Building One has canonical separation spawn", scene.contains('[node name="separation_spawn"'))
	_expect("Separation result uses canonical spawn", source.contains('set_spawn("separation_spawn")'))


func _check_states_route_contract() -> void:
	var panel := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_two/states_panel.gd")
	var player_scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/player.tscn")
	var gate_scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/lvl_gate2.tscn")
	_expect("States panel enters tutorial scene", panel.contains("mattermaze/Scenes/main.tscn"))
	_expect("Canonical States player uses canonical script", not player_scene.contains("Level2-1/Level2-1/level2-2/mattermaze/Scripts/player.gd"))
	_expect("Canonical States gate uses canonical script", not gate_scene.contains("Level2-1/Level2-1/level2-2/mattermaze/Scenes/lvl_gate_2.gd"))



func _check_nav_arrow_contract() -> void:
	var nav_src := FileAccess.get_file_as_string("res://games/chapter_one/hometown/scripts/nav_arrow.gd")
	var b1_scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/building_one/building_one.tscn")
	var ht_scene := FileAccess.get_file_as_string("res://games/chapter_one/hometown/hometown.tscn")
	_expect("Building One scene has World/GoBack node", b1_scene.contains('[node name="GoBack" type="Area2D" parent="World"'))
	_expect("Hometown scene has World/Buldings/BuildingTwoEntry node", ht_scene.contains('[node name="BuildingTwoEntry" type="Area2D" parent="World/Buldings"'))
	_expect("NavArrow explicitly targets World/GoBack in Building One for find_christofe", nav_src.contains('quest_id == "find_christofe"') and nav_src.contains('new_target = go_back'))
	_expect("NavArrow explicitly targets BuildingTwoEntry in Hometown for find_christofe", nav_src.contains('new_target = b2_entry'))


func _expect(label: String, condition: bool) -> void:
	if not condition:
		_failures.append(label)
