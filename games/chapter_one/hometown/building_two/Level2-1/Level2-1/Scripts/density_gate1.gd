extends Area2D
@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"

@export var density_threshold :float = 5.0 
@onready var animated_sprite :=$AnimatedSprite2D
func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body is RigidBody2D and body.has_method("get_density"):
		var density = body.get_density()
		print("📏 Object density:", density)

		if density > density_threshold:
			print("🚫 Density too high!")
			wrong.play()
			modulate = Color.RED
			return

		elif density < density_threshold:
			print("🚫 Density too low!")
			wrong.play()
			modulate = Color.RED
			return

		# ✅ Correct density reached
		elif density == density_threshold:
			print("✅ Density acceptable!")
			modulate = Color.GREEN
			correct.play()
			animated_sprite.play("Correct")
			await animated_sprite.animation_finished

			# ✅ Advance quest progress
			QuestManager.advance_density_level(1)

			# ✅ Refresh the LevelDensePanel UI (if it exists in the scene)
			var dense_panel = get_tree().get_first_node_in_group("LevelDensePanel")
			if dense_panel:
				dense_panel.update_levels_visibility()

			# ✅ Load the next level automatically
			var next_level_index = QuestManager.density_progress + 1
			if next_level_index <= 3:
				var next_path = "res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_" + str(next_level_index) + ".tscn"

				print("➡ Loading next level:", next_path)
				get_tree().change_scene_to_file(next_path)
			else:
				print("🎉 All density levels completed!")
				animated_sprite.play("new_animation")
				animated_sprite.sprite_frames.set_animation_loop("new_animation", true)

func _on_correct_animation_finished():
	if animated_sprite.animation == "Correct":
			animated_sprite.play("new_animation")
			
			animated_sprite.sprite_frames.set_animation_loop("new_animation",true)
			
			
			
			
			
