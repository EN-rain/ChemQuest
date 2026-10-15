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
