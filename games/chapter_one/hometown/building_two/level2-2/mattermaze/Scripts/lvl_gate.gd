extends Area2D

@export var next_scene_path: String = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn"  # set per gate in the Inspector

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = $"../CanvasLayer/FadeRect"
var _gate_triggered := false
var _transition_started := false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent
	_check_autopass()

func _check_autopass() -> void:
	var dev_manager := get_node_or_null("/root/DevModeManager")
	if dev_manager and dev_manager.has_method("get_pass_rate"):
		var lvl := _current_level_number()
		var key := "states_%d" % lvl
		if int(dev_manager.call("get_pass_rate", key, 1)) == 0:
			call_deferred("_trigger_autopass")

func _trigger_autopass() -> void:
	if _gate_triggered or _transition_started:
		return
	_gate_triggered = true
	print("DevMode auto-pass triggered for States of Matter level")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)

func _current_level_number() -> int:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return 1
	var file_name := current_scene.scene_file_path.get_file().get_basename()
	var regex := RegEx.new()
	regex.compile(r"(\d+)$")
	var result := regex.search(file_name)
	return int(result.get_string(1)) if result != null else 1

func _on_body_entered(body: Node) -> void:
	if _gate_triggered or _transition_started or body.name != "Player":
		return
	_gate_triggered = true

	print("Player reached the gate ✅")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)

func _on_flag_animation_finished() -> void:
	_load_next_level()

func _load_next_level() -> void:
	if _transition_started:
		return
	if next_scene_path.is_empty():
		print("⚠ No next scene path set for this gate!")
		return

	print("Loading next scene: ", next_scene_path)
	_transition_started = true
	await FadeManager.fade_and_change(next_scene_path)
