extends Node

## Responsive scene contract runner.
##
## Usage:
##   godot --headless --path . --scene res://tests/smoke/responsive_layout_runner.tscn -- \
##     --scene=res://intro.tscn --width=854 --height=480 --frames=5

const MANIFEST_PATH := "res://tests/smoke/responsive_scenes.json"

var _target_path := ""
var _width := 1280
var _height := 720
var _frames_to_wait := 5
var _frame_count := 0
var _screenshot_path := ""
var _target_instance: Node
var _manifest_entry: Dictionary = {}
var _failures: Array[String] = []
var _finishing := false


func _ready() -> void:
	_parse_user_arguments()
	if _target_path.is_empty():
		_fail("missing required --scene=res://... argument")
		return
	if _width <= 0 or _height <= 0:
		_fail("width and height must be positive")
		return
	if not ResourceLoader.exists(_target_path, "PackedScene"):
		_fail("scene resource does not exist: " + _target_path)
		return
	_manifest_entry = _find_manifest_entry(_target_path)
	if _manifest_entry.is_empty():
		_fail("scene is missing from responsive_scenes.json: " + _target_path)
		return

	var root_window := get_tree().root
	if root_window != null:
		root_window.size = Vector2i(_width, _height)

	var packed_scene := load(_target_path) as PackedScene
	if packed_scene == null:
		_fail("scene failed to load (parse error or invalid resource): " + _target_path)
		return
	_target_instance = packed_scene.instantiate()
	if _target_instance == null:
		_fail("scene failed to instantiate: " + _target_path)
		return
	add_child(_target_instance)
	print("RESPONSIVE_START scene=%s requested=%dx%d window=%s viewport=%s visible=%s content_scale=%s" % [_target_path, _width, _height, get_tree().root.size, get_viewport().size, get_viewport().get_visible_rect().size, get_tree().root.content_scale_size])


func _process(_delta: float) -> void:
	if _target_instance == null or _finishing:
		return
	_frame_count += 1
	if _frame_count < _frames_to_wait:
		return
	_finishing = true
	_validate_layout()
	if _failures.is_empty() and not _screenshot_path.is_empty():
		_capture_screenshot()
	if _failures.is_empty():
		print("RESPONSIVE_PASS scene=%s size=%dx%d" % [_target_path, _width, _height])
		_target_instance.queue_free()
		await get_tree().process_frame
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("RESPONSIVE_FAIL " + failure)
		get_tree().quit(1)


func _validate_layout() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var safe_rect := viewport_rect
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		_failures.append("ResponsiveLayout autoload is unavailable")
	else:
		var actual_size: Vector2 = service.viewport_size
		if actual_size.x <= 0.0 or actual_size.y <= 0.0:
			_failures.append("ResponsiveLayout reported an invalid viewport size: %s" % actual_size)
		if _width <= _height:
			var guard := get_node_or_null("/root/ResponsiveLayout/ResponsiveOrientationGuard/RotateDeviceOverlay")
			if guard == null or not guard.visible:
				_failures.append("portrait guard is not visible for %dx%d" % [_width, _height])
		safe_rect = service.safe_rect

	var critical: Array = _manifest_entry.get("critical", [])
	for item_variant in critical:
		var item: Dictionary = item_variant if item_variant is Dictionary else {"path": String(item_variant)}
		var node_path := String(item.get("path", ""))
		var node := _target_instance.get_node_or_null(NodePath(node_path))
		if node == null:
			_failures.append("missing critical node: %s" % node_path)
			continue
		if node is Control:
			var must_fit := bool(item.get("must_fit", true))
			_validate_control(node as Control, node_path, safe_rect if must_fit else viewport_rect, must_fit)
		elif node is TouchScreenButton:
			var must_fit := bool(item.get("must_fit", true))
			_validate_touch_button(node as TouchScreenButton, node_path, safe_rect if must_fit else viewport_rect, must_fit)


func _validate_control(control: Control, node_path: String, viewport_rect: Rect2, must_fit: bool) -> void:
	if control.size.x <= 0.0 or control.size.y <= 0.0:
		_failures.append("critical Control has zero size: %s (%s)" % [node_path, control.size])
		return
	var rect := control.get_global_rect()
	if not rect.intersects(viewport_rect):
		_failures.append("critical Control is outside viewport: %s (%s)" % [node_path, rect])
		return
	if must_fit:
		var intersection := rect.intersection(viewport_rect)
		var area := rect.size.x * rect.size.y
		var visible_area := intersection.size.x * intersection.size.y
		if area > 0.0 and visible_area / area < 0.9:
			_failures.append("critical Control is clipped: %s (%s)" % [node_path, rect])


func _validate_touch_button(button: TouchScreenButton, node_path: String, viewport_rect: Rect2, must_fit: bool) -> void:
	if button.texture_normal == null:
		_failures.append("touch button has no normal texture: %s" % node_path)
		return
	var size := button.texture_normal.get_size() * button.scale.abs()
	var rect := Rect2(button.global_position, size)
	if size.x <= 0.0 or size.y <= 0.0:
		_failures.append("touch button has zero size: %s" % node_path)
	elif minf(size.x, size.y) < 72.0:
		_failures.append("touch button is below the 72px design target: %s (%s)" % [node_path, size])
	elif not rect.intersects(viewport_rect):
		_failures.append("touch button is outside viewport: %s (%s)" % [node_path, rect])
	elif must_fit and not viewport_rect.encloses(rect):
		_failures.append("touch button leaves safe rectangle: %s (%s safe=%s)" % [node_path, rect, viewport_rect])


func _find_manifest_entry(scene_path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		return {}
	for entry_variant in parsed.get("active", []):
		if entry_variant is Dictionary and entry_variant.get("path", "") == scene_path:
			return entry_variant
	return {}


func _parse_user_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			_target_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--width="):
			_width = maxi(1, int(argument.trim_prefix("--width=")))
		elif argument.begins_with("--height="):
			_height = maxi(1, int(argument.trim_prefix("--height=")))
		elif argument.begins_with("--frames="):
			_frames_to_wait = maxi(1, int(argument.trim_prefix("--frames=")))
		elif argument.begins_with("--screenshot="):
			_screenshot_path = argument.trim_prefix("--screenshot=")


func _capture_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("viewport screenshot is empty")
		return
	var output_path := _screenshot_path
	if output_path.begins_with("res://"):
		output_path = ProjectSettings.globalize_path(output_path)
	var parent_dir := output_path.get_base_dir()
	if not parent_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(parent_dir)
	var error := image.save_png(output_path)
	if error != OK:
		_failures.append("could not save viewport screenshot: %s (error=%s)" % [output_path, error])


func _fail(message: String) -> void:
	_failures.append(message)
	_finishing = true
	for failure in _failures:
		print("RESPONSIVE_FAIL " + failure)
	get_tree().quit(1)
