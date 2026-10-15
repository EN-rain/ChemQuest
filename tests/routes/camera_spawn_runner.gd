extends Node

## Runtime regression for the original Hometown playability failure. Each run
## uses the real Hometown scene, camera limits, collision shape, and one named
## spawn at the requested viewport size.

const HOMETOWN_PATH := "res://games/chapter_one/hometown/hometown.tscn"
const SPAWNS := ["default", "from_building_one", "from_building_two", "from_hometown"]

var _width := 1280
var _height := 720
var _spawn := "default"
var _failures: Array[String] = []


func _ready() -> void:
	_parse_arguments()
	get_tree().root.size = Vector2i(_width, _height)
	var packed := load(HOMETOWN_PATH) as PackedScene
	if packed == null:
		_fail("Hometown scene failed to load")
		return
	SpawnManager.spawn_point = SpawnManager.normalize_spawn_name(_spawn)
	SaveManager.last_spawn = SpawnManager.spawn_point
	var scene := packed.instantiate()
	if scene == null:
		_fail("Hometown scene failed to instantiate")
		return
	add_child(scene)
	for _frame in range(8):
		await get_tree().process_frame
	_validate(scene)
	scene.queue_free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("CAMERA_SPAWN PASS spawn=%s size=%dx%d" % [_spawn, _width, _height])
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("CAMERA_SPAWN_FAIL " + failure)
		get_tree().quit(1)


func _validate(scene: Node) -> void:
	var player := scene.get_node_or_null("Player") as CharacterBody2D
	var camera := scene.get_node_or_null("Player/Camera2D") as Camera2D
	if player == null or camera == null:
		_fail("Hometown player or camera is missing")
		return
	var markers := scene.get_node_or_null("World/SpawnPoints")
	var marker := markers.get_node_or_null(_spawn) if markers != null else null
	if marker == null:
		_fail("declared spawn marker is missing: " + _spawn)
		return
	var distance := player.global_position.distance_to(marker.global_position)
	if distance > 2.0:
		_fail("player did not resolve spawn %s (distance %.2f)" % [_spawn, distance])

	camera.enabled = true
	camera.force_update_scroll()
	var zoom := camera.zoom
	if zoom.x <= 0.0 or zoom.y <= 0.0:
		_fail("camera has invalid zoom: %s" % zoom)
		return
	# With viewport stretch the camera consumes the virtual design viewport; the
	# root window is the physical presentation size. Use the virtual rect here
	# so the assertion matches the camera's actual world-to-screen transform.
	var visible_size := get_viewport().get_visible_rect().size / zoom
	var visible_rect := Rect2(camera.get_screen_center_position() - visible_size * 0.5, visible_size)
	var half_size := Vector2(16.0, 20.0)
	var collision := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D:
		half_size = (collision.shape as RectangleShape2D).size * 0.5
	var player_rect := Rect2(player.global_position - half_size, half_size * 2.0)
	if not visible_rect.encloses(player_rect):
		_fail("player is outside camera view at %s: player=%s view=%s" % [_spawn, player_rect, visible_rect])


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--width="):
			_width = maxi(1, int(argument.trim_prefix("--width=")))
		elif argument.begins_with("--height="):
			_height = maxi(1, int(argument.trim_prefix("--height=")))
		elif argument.begins_with("--spawn="):
			_spawn = SpawnManager.normalize_spawn_name(argument.trim_prefix("--spawn="))


func _fail(message: String) -> void:
	_failures.append(message)
