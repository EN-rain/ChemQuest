extends Node

var _failures: Array[String] = []
var _pass_count: int = 0

func _src(rel: String) -> String:
	return FileAccess.get_file_as_string("res://" + rel)

func _expect(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("  PASS  " + label)
	else:
		_failures.append(label)
		print("  FAIL  " + label)

func _ready() -> void:
	print("")
	print("=== Area2D Interact Button Contract ===")
	_check_map_gd()
	_check_desk_gd()
	_check_seperation_gd()
	_check_shooting_gd()
	_check_scene_signal_connections()
	_check_interaction_manager()
	_check_ui_gd()
	_check_cross_area_clobber_guard()
	print("")
	print("--- Results: %d passed, %d failed ---" % [_pass_count, _failures.size()])
	if _failures.is_empty():
		print("AREA2D_INTERACT_CONTRACT PASS")
		get_tree().quit(0)
	else:
		for f in _failures:
			print("AREA2D_INTERACT_FAIL " + f)
		get_tree().quit(1)

func _check_map_gd() -> void:
	print("")
	print("[map.gd / LevelOne]")
	var src := _src("games/chapter_one/hometown/building_one/map.gd")
	_expect("[A] map.gd has _deferred_check_overlap()", src.contains("_deferred_check_overlap"))
	_expect("[A] map.gd calls call_deferred for overlap check", src.contains("call_deferred"))
	_expect("[A] map.gd uses get_overlapping_bodies()", src.contains("get_overlapping_bodies()"))
	_expect("[B] map.gd _on_quest_changed calls refresh_interaction_prompt()", _fn_body_contains(src, "_on_quest_changed", "refresh_interaction_prompt"))
	_expect("[C] map.gd _on_body_exited guards with current_interactable == self", src.contains("current_interactable == self"))
	_expect("[C] map.gd no unchecked hide in _on_body_exited", not _unchecked_hide(src, "_on_body_exited"))
	_expect("[sanity] map.gd checks find_wiz quest", src.contains("find_wiz"))

func _check_desk_gd() -> void:
	print("")
	print("[desk.gd / LevelTwo]")
	var src := _src("games/chapter_one/hometown/building_one/desk.gd")
	_expect("[A] desk.gd has _deferred_check_overlap()", src.contains("_deferred_check_overlap"))
	_expect("[A] desk.gd calls call_deferred for overlap check", src.contains("call_deferred"))
	_expect("[A] desk.gd uses get_overlapping_bodies()", src.contains("get_overlapping_bodies()"))
	_expect("[B] desk.gd _on_quest_changed calls refresh_interaction_prompt()", _fn_body_contains(src, "_on_quest_changed", "refresh_interaction_prompt"))
	_expect("[C] desk.gd _on_body_exited guards with current_interactable == self", src.contains("current_interactable == self"))
	_expect("[sanity] desk.gd checks after_book2 quest", src.contains("after_book2"))

func _check_seperation_gd() -> void:
	print("")
	print("[seperation.gd / LevelThree]")
	var src := _src("games/chapter_one/hometown/building_one/seperation.gd")
	_expect("[A] seperation.gd has _deferred_check_overlap()", src.contains("_deferred_check_overlap"))
	_expect("[A] seperation.gd calls call_deferred for overlap check", src.contains("call_deferred"))
	_expect("[A] seperation.gd uses get_overlapping_bodies()", src.contains("get_overlapping_bodies()"))
	_expect("[B] seperation.gd _on_quest_changed calls refresh_interaction_prompt()", _fn_body_contains(src, "_on_quest_changed", "refresh_interaction_prompt"))
	_expect("[C] seperation.gd _on_body_exited guards with current_interactable == self", src.contains("current_interactable == self"))
	_expect("[D] seperation.gd connects body_entered in _ready()", src.contains("body_entered.connect"))
	_expect("[D] seperation.gd connects body_exited in _ready()", src.contains("body_exited.connect"))
	_expect("[sanity] seperation.gd checks after_book3 required quest", src.contains("after_book3"))

func _check_shooting_gd() -> void:
	print("")
	print("[shooting.gd / LevelFour]")
	var src := _src("games/chapter_one/hometown/building_one/shooting.gd")
	_expect("[A] shooting.gd has _deferred_check_overlap()", src.contains("_deferred_check_overlap"))
	_expect("[A] shooting.gd calls call_deferred for overlap check", src.contains("call_deferred"))
	_expect("[A] shooting.gd uses get_overlapping_bodies()", src.contains("get_overlapping_bodies()"))
	_expect("[B] shooting.gd _on_quest_changed calls refresh_interaction_prompt()", _fn_body_contains(src, "_on_quest_changed", "refresh_interaction_prompt"))
	_expect("[C] shooting.gd _on_body_exited guards with current_interactable == self", src.contains("current_interactable == self"))
	_expect("[D] shooting.gd connects body_entered in _ready()", src.contains("body_entered.connect"))
	_expect("[D] shooting.gd connects body_exited in _ready()", src.contains("body_exited.connect"))
	_expect("[sanity] shooting.gd checks separation_methods_after quest", src.contains("separation_methods_after"))

func _check_scene_signal_connections() -> void:
	print("")
	print("[Scene signal connections]")
	var scene := _src("games/chapter_one/hometown/building_one/building_one.tscn")
	_expect("[D] Scene wires LevelOne body_entered", scene.contains("body_entered") and scene.contains("LevelOne"))
	_expect("[D] Scene wires LevelOne body_exited", scene.contains("body_exited") and scene.contains("LevelOne"))
	_expect("[D] Scene wires LevelTwo body_entered", scene.contains("body_entered") and scene.contains("LevelTwo"))
	_expect("[D] Scene wires LevelTwo body_exited", scene.contains("body_exited") and scene.contains("LevelTwo"))
	_expect("[D] Scene has map_spawn marker", scene.contains("map_spawn"))
	_expect("[D] Scene has desk_spawn marker", scene.contains("desk_spawn"))
	_expect("[D] Scene has separation_spawn marker", scene.contains("separation_spawn"))
	_expect("[D] Scene has shooting_spawn marker", scene.contains("shooting_spawn"))

func _check_interaction_manager() -> void:
	print("")
	print("[InteractionManager]")
	var src := _src("games/global/InteractionManager.gd")
	_expect("[E] InteractionManager has current_interactable var", src.contains("var current_interactable"))
	_expect("[E] InteractionManager initialises to null", src.contains("= null"))
	_expect("[E] InteractionManager does NOT auto-hide anything", not src.contains("hide()"))

func _check_ui_gd() -> void:
	print("")
	print("[ui.gd]")
	var src := _src("games/chapter_one/hometown/building_one/ui.gd")
	_expect("[F] ui.gd hides interact in _ready()", src.contains("interact.hide()"))
	_expect("[F] ui.gd connects interact.pressed in _ready()", src.contains("interact.pressed.connect"))
	_expect("[F] ui.gd delegates to current_interactable.interact()", src.contains("current_interactable.interact()"))

func _check_cross_area_clobber_guard() -> void:
	print("")
	print("[Cross-area clobber guard]")
	var scripts := [
		"games/chapter_one/hometown/building_one/map.gd",
		"games/chapter_one/hometown/building_one/desk.gd",
		"games/chapter_one/hometown/building_one/seperation.gd",
		"games/chapter_one/hometown/building_one/shooting.gd",
	]
	for script_path in scripts:
		var nm: String = script_path.get_file()
		var src := _src(script_path)
		_expect("[G] " + nm + " no unchecked hide in _on_body_exited", not _unchecked_hide(src, "_on_body_exited"))

func _fn_body_contains(src: String, func_name: String, needle: String) -> bool:
	var lines := src.split("\n")
	var in_fn := false
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("func " + func_name):
			in_fn = true
			continue
		if in_fn:
			if stripped.begins_with("func ") and not stripped.begins_with("func " + func_name):
				break
			if needle in line:
				return true
	return false

func _unchecked_hide(src: String, func_name: String) -> bool:
	var lines := src.split("\n")
	var in_fn := false
	var guard_seen := false
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("func " + func_name):
			in_fn = true
			guard_seen = false
			continue
		if in_fn:
			if stripped.begins_with("func ") and not stripped.begins_with("func " + func_name):
				break
			if "current_interactable == self" in line:
				guard_seen = true
			if ("interact" in line and "hide()" in line) and not guard_seen:
				return true
	return false