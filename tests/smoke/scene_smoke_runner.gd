extends Node

## Minimal dependency-free scene smoke runner.
##
## Usage:
##   godot --headless --path . --scene res://tests/smoke/scene_smoke_runner.tscn -- \
##     --scene=res://intro.tscn --frames=3 --timeout_ms=5000

var _target_path := ""
var _frames_to_wait := 3
var _timeout_ms := 5000
var _frame_count := 0
var _started_at_ms := 0
var _target_instance: Node
var _finishing := false


func _ready() -> void:
	_parse_user_arguments()
	_started_at_ms = Time.get_ticks_msec()
	if _target_path.is_empty():
		_fail("missing required --scene=res://... argument")
		return
	if not ResourceLoader.exists(_target_path, "PackedScene"):
		_fail("scene resource does not exist: " + _target_path)
		return

	var packed_scene := load(_target_path) as PackedScene
	if packed_scene == null:
		_fail("scene failed to load (parse error or invalid resource): " + _target_path)
		return
	_target_instance = packed_scene.instantiate()
	if _target_instance == null:
		_fail("scene failed to instantiate: " + _target_path)
		return
	add_child(_target_instance)
	print("SMOKE_START scene=%s frames=%d timeout_ms=%d" % [_target_path, _frames_to_wait, _timeout_ms])


func _process(_delta: float) -> void:
	if _target_instance == null or _finishing:
		return
	_frame_count += 1
	if Time.get_ticks_msec() - _started_at_ms >= _timeout_ms:
		_fail("timeout while starting scene: " + _target_path)
		return
	if _frame_count >= _frames_to_wait:
		_finishing = true
		print("SMOKE_PASS scene=%s frames=%d" % [_target_path, _frame_count])
		_target_instance.queue_free()
		await get_tree().process_frame
		get_tree().quit(0)


func _parse_user_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			_target_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--frames="):
			_frames_to_wait = maxi(1, int(argument.trim_prefix("--frames=")))
		elif argument.begins_with("--timeout_ms="):
			_timeout_ms = maxi(100, int(argument.trim_prefix("--timeout_ms=")))


func _fail(message: String) -> void:
	print("SMOKE_FAIL " + message)
	get_tree().quit(1)
