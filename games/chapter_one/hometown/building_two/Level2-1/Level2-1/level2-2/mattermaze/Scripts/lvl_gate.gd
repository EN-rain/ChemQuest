extends Area2D

@export var next_scene_path: String = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_1.tscn"  # set per gate in the Inspector

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = $"../CanvasLayer/FadeRect"

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	print("Player reached the gate ✅")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)

func _on_flag_animation_finished() -> void:
	if not fade_rect:
		_load_next_level()
		return

	# Fade to black before loading next level
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0) # Fade out in 1 second
	tween.finished.connect(_load_next_level, CONNECT_ONE_SHOT)

func _load_next_level() -> void:
	if next_scene_path.is_empty():
		print("⚠ No next scene path set for this gate!")
		return

	print("Loading next scene: ", next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)
