extends Node

## Contract test for the reusable mobile-control scene. The test exercises the
## same CanvasLayer script used by the density levels, rather than duplicating
## its positioning math in the runner.

const TOUCH_SCENE := "res://games/chapter_one/hometown/building_two/Level2-1/TouchControls/Mobilecontrol.tscn"

var _width := 1280
var _height := 720
var _frames_to_wait := 3
var _frames := 0
var _controls: Node
var _failures: Array[String] = []
var _finishing := false


func _ready() -> void:
	_parse_arguments()
	if _width <= 0 or _height <= 0:
		_fail("window dimensions must be positive")
		return
	var root_window := get_tree().root
	if root_window != null:
		root_window.size = Vector2i(_width, _height)
	var packed := load(TOUCH_SCENE) as PackedScene
	if packed == null:
		_fail("shared touch scene failed to load")
		return
	_controls = packed.instantiate()
	if _controls == null:
		_fail("shared touch scene failed to instantiate")
		return
	add_child(_controls)


func _process(_delta: float) -> void:
	if _controls == null or _finishing:
		return
	_frames += 1
	if _frames < _frames_to_wait:
		return
	_finishing = true
	_validate()
	if _failures.is_empty():
		print("RESPONSIVE_TOUCH_RESULT PASS size=%dx%d" % [_width, _height])
		_controls.queue_free()
		await get_tree().process_frame
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("RESPONSIVE_TOUCH_FAIL " + failure)
		get_tree().quit(1)


func _validate() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		_failures.append("ResponsiveLayout autoload is unavailable")
		return
	var safe_rect: Rect2 = service.safe_rect
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		_failures.append("safe rectangle is empty: %s" % safe_rect)

	var buttons: Dictionary = {}
	var expected_actions := {
		"Left": "left",
		"Right": "right",
		"Jump": "jump",
		"Pick": "pickup",
		"Drop": "drop",
	}
	for button_name in expected_actions:
		var button := _controls.find_child(button_name, true, false) as TouchScreenButton
		if button == null:
			_failures.append("missing touch button: %s" % button_name)
			continue
		if button.texture_normal == null:
			_failures.append("touch button has no normal texture: %s" % button_name)
			continue
		if button.action != expected_actions[button_name]:
			_failures.append("touch action changed for %s: %s" % [button_name, button.action])
		var size := button.texture_normal.get_size() * button.scale.abs()
		if minf(size.x, size.y) < 72.0:
			_failures.append("touch button is below 72px: %s (%s)" % [button_name, size])
		var rect := Rect2(button.global_position, size)
		if not safe_rect.encloses(rect):
			_failures.append("touch button leaves safe rectangle: %s (%s safe=%s)" % [button_name, rect, safe_rect])
		buttons[button_name] = rect

	for movement_name in ["Left", "Right"]:
		for action_name in ["Jump", "Pick", "Drop"]:
			if buttons.has(movement_name) and buttons.has(action_name) and (buttons[movement_name] as Rect2).intersects(buttons[action_name] as Rect2):
				_failures.append("movement/action touch controls overlap: %s/%s" % [movement_name, action_name])

	if _width <= _height:
		var guard := get_node_or_null("/root/ResponsiveLayout/ResponsiveOrientationGuard/RotateDeviceOverlay")
		if guard == null or not guard.visible:
			_failures.append("portrait guard is not visible")


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--width="):
			_width = maxi(1, int(argument.trim_prefix("--width=")))
		elif argument.begins_with("--height="):
			_height = maxi(1, int(argument.trim_prefix("--height=")))
		elif argument.begins_with("--frames="):
			_frames_to_wait = maxi(1, int(argument.trim_prefix("--frames=")))


func _fail(message: String) -> void:
	_failures.append(message)
	_finishing = true
	for failure in _failures:
		print("RESPONSIVE_TOUCH_FAIL " + failure)
	get_tree().quit(1)
