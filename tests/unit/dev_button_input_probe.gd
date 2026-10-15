extends Node

func _ready() -> void:
	var tree: SceneTree = get_tree()
	print("INPUT_PROBE initial window=", get_window().size, " visible=", get_viewport().get_visible_rect().size)
	get_window().size = Vector2i(1280, 720)
	FadeManager.set_test_mode(true)
	var transitions: Array[String] = []
	FadeManager.transition_started.connect(func(path: String) -> void: transitions.append(path))
	await get_tree().process_frame
	print("INPUT_PROBE adjusted window=", get_window().size, " visible=", get_viewport().get_visible_rect().size)
	var menu: Node = load("res://games/main.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var dev: Button = menu.get_node("CanvasLayer2/DevButton")
	var manager := get_node_or_null("/root/DevModeManager")
	var failures: Array[String] = []
	print("INPUT_PROBE manager_present=", manager != null, " dev_rect=", dev.get_global_rect(), " visible=", dev.visible, " disabled=", dev.disabled, " mouse_filter=", dev.mouse_filter)
	var positions := [Vector2(100, 600), Vector2(100, 500), Vector2(100, 700), Vector2(60, 550), Vector2(100, 600), Vector2(100, 680)]
	for index in positions.size():
		var pos: Vector2 = positions[index]
		var motion := InputEventMouseMotion.new()
		motion.position = pos
		motion.global_position = pos
		get_viewport().push_input(motion, true)
		await get_tree().process_frame
		var hovered: Control = get_viewport().gui_get_hovered_control()
		var hovered_path := str(hovered.get_path()) if hovered != null else "none"
		if hovered != dev:
			failures.append("DevButton not receiving pointer at click %d" % [index + 1])
		var down := InputEventMouseButton.new()
		down.position = pos
		down.global_position = pos
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		get_viewport().push_input(down, true)
		var up := InputEventMouseButton.new()
		up.position = pos
		up.global_position = pos
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		get_viewport().push_input(up, true)
		await get_tree().process_frame
		print("INPUT_PROBE click=", index + 1, " hovered=", hovered_path, " dev_count=", menu.get("_dev_click_count") if is_instance_valid(menu) else "scene_changed", " enabled=", manager.get("enabled") if manager else "missing")
		if index == 3 and bool(manager.get("enabled")):
			failures.append("Dev Mode enabled too early")
		if index == 4 and (not bool(manager.get("enabled")) or not (menu.get_node("CanvasLayer2/DevLabel") as Label).visible):
			failures.append("Fifth click did not activate Dev Mode and label")
	if transitions != ["res://games/devmode.tscn"]:
		failures.append("Sixth click did not request devmode.tscn: %s" % [transitions])
	if failures.is_empty():
		print("INPUT_PROBE PASS: six physical-style clicks, activation, label, and devmode scene request")
		tree.quit(0)
	else:
		for failure in failures:
			print("INPUT_PROBE FAIL: ", failure)
		tree.quit(1)
