extends Node

const SCENES := [
	"res://games/chapter_one/hometown/building_one/building_one.tscn",
	"res://games/chapter_one/hometown/building_two/building_two.tscn",
]

var failures: Array[String] = []


func _ready() -> void:
	var tree: SceneTree = get_tree()
	get_window().size = Vector2i(1280, 720)
	await tree.process_frame
	for scene_path in SCENES:
		await _test_scene(scene_path)
	if failures.is_empty():
		print("NPC_DIALOGUE_RESULT PASS: both NPC scenes handle physical Skip and natural completion, including controls restoration")
		tree.quit(0)
	else:
		for problem in failures:
			print("NPC_DIALOGUE_FAIL ", problem)
		tree.quit(2)


func _test_scene(scene_path: String) -> void:
	# Use the real authored dialogue UI but leave the gameplay scene off-tree,
	# so this test cannot modify the player's checkpoint or trigger NPC quests.
	var source: Node = load(scene_path).instantiate()
	var original_canvas: CanvasLayer = source.get_node("CanvasLayer")
	var mini_canvas := CanvasLayer.new()
	var controls: Array[Control] = []
	for name in ["Buttons", "Control", "DialogueBox"]:
		var widget: Control = original_canvas.get_node(name)
		original_canvas.remove_child(widget)
		widget.owner = null
		mini_canvas.add_child(widget)
		controls.append(widget)
	add_child(mini_canvas)
	await get_tree().process_frame
	var move_controls := controls[0]
	var interact_controls := controls[1]
	var dialogue := controls[2]
	var skip: Button = dialogue.get_node("SkipButton")
	var done_count := [0]
	dialogue.dialogue_finished.connect(func() -> void: done_count[0] += 1)
	dialogue.set("typing_speed", 0.003)
	dialogue.set("auto_delay", 0.015)
	dialogue.set("end_delay", 0.02)
	move_controls.show()
	interact_controls.show()
	dialogue.start_dialogue(["A long first line to cancel", "Another long line"], "Test")
	_check(scene_path, "dialogue is visible", dialogue.visible)
	_check(scene_path, "both control groups are hidden", not move_controls.visible and not interact_controls.visible)
	_check(scene_path, "Skip is visible", skip.visible)
	_check(scene_path, "Skip is inside dialogue bounds", dialogue.get_global_rect().has_point(skip.get_global_rect().get_center()))
	# Real pointer press/release catches off-panel hitboxes or overlays.
	var click: Vector2 = skip.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = click
	motion.global_position = click
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	_check(scene_path, "Skip receives mouse input", get_viewport().gui_get_hovered_control() == skip)
	var down := InputEventMouseButton.new()
	down.position = click
	down.global_position = click
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	var up := InputEventMouseButton.new()
	up.position = click
	up.global_position = click
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	await get_tree().process_frame
	_check(scene_path, "Skip immediately hides dialogue and emits once", not dialogue.visible and done_count[0] == 1)
	_check(scene_path, "Skip restores movement and interact controls", move_controls.visible and interact_controls.visible)
	await get_tree().create_timer(0.2).timeout
	_check(scene_path, "cancelled typing timers do not emit duplicate completion", done_count[0] == 1)

	dialogue.start_dialogue(["OK", "Fine"], "Test")
	_check(scene_path, "normal playback hides controls", not move_controls.visible and not interact_controls.visible)
	await get_tree().create_timer(0.35).timeout
	_check(scene_path, "natural completion closes dialogue once", not dialogue.visible and done_count[0] == 2)
	_check(scene_path, "natural completion restores both controls", move_controls.visible and interact_controls.visible)

	mini_canvas.queue_free()
	source.free()
	await get_tree().process_frame
	await get_tree().process_frame


func _check(scene_path: String, name: String, good: bool) -> void:
	if not good:
		failures.append("%s: %s" % [scene_path.get_file(), name])
