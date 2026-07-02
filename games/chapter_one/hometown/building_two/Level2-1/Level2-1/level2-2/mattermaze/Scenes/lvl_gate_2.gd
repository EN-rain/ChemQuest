extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = $"../CanvasLayer/FadeRect"


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0)


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	print("Player reached the gate.")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(
		Callable(self, "_on_flag_animation_finished"),
		CONNECT_ONE_SHOT
	)


func _on_flag_animation_finished() -> void:
	if not fade_rect:
		_load_next_level()
		return

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.finished.connect(Callable(self, "_load_next_level"), CONNECT_ONE_SHOT)


func _load_next_level() -> void:
	var current_scene := get_tree().current_scene
	var current_name := current_scene.name
	var next_scene_path := ""
	var completed_level_number := 0

	if current_name == "level_1":
		completed_level_number = 1
		next_scene_path = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_2.tscn"
	elif current_name == "level_2":
		completed_level_number = 2
		next_scene_path = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_3.tscn"
	elif current_name == "level_3":
		completed_level_number = 3
		next_scene_path = "res://games/chapter_one/hometown/building_two/building_two.tscn"

	if next_scene_path == "":
		print("No valid next level for:", current_name)
		return

	if QuestManager and completed_level_number > 0:
		QuestManager.advance_states_level(completed_level_number)

	print("Loading next scene:", next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)
