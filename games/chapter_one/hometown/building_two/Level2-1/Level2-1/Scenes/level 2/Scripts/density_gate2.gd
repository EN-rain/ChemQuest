extends Area2D

@export var density_threshold: float = 13.7
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody2D and body.has_method("get_density")):
		return

	var density = body.get_density()
	print("📏 Object density:", density)

	if density > density_threshold:
		print("🚫 Density too high!")
		modulate = Color(1, 0, 0, 1) # Red
		return

	elif density < density_threshold:
		print("🚫 Density too low!")
		modulate = Color(1, 0, 0, 1) # Red
		return

	# ✅ Correct density
	print("✅ Density acceptable!")
	modulate = Color(0, 1, 0, 1) # Green

	animated_sprite.play("Correct")
	await animated_sprite.animation_finished

	# ✅ Progress the quest and unlock Level 3
	if Engine.has_singleton("QuestManager"):
		QuestManager.advance_density_level(2)

	# ✅ Refresh LevelDensePanel visibility
	var dense_panel = get_tree().get_first_node_in_group("LevelDensePanel")
	if dense_panel:
		dense_panel.update_levels_state()

	# ✅ Load the next level (Level 3)
	var current_scene_name = get_tree().current_scene.name
	var next_scene_path = "res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn" 

	print("➡ Loading next level:", next_scene_path)
	if ResourceLoader.exists(next_scene_path):
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("🎉 All density levels complete! No next level found.")

func _on_correct_animation_finished() -> void:
	if animated_sprite.animation == "Correct":
		animated_sprite.play("new_animation")
		animated_sprite.sprite_frames.set_animation_loop("new_animation", true)
