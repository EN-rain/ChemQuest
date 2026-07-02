extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"

func _ready() -> void:
	add_to_group("DensityGate2")
	connect("body_entered", Callable(self, "_on_body_entered"))
	call_deferred("_initialize_bottle_challenge")


func _initialize_bottle_challenge() -> void:
	print("\n🕓 [DensityGate2] Waiting for bottles...")
	await get_tree().create_timer(0.2).timeout

	var bottles = get_tree().get_nodes_in_group("BottleGroup")
	print("🔍 Found %s bottles in BottleGroup." % bottles.size())
	for b in bottles:
		print("   • Bottle %s → M:%.1f | V:%.1f | ρ:%.2f" % [b.bottle_id, b.object_mass, b.volume, b.density])

	ChallengeManager.setup_bottle_challenge(bottles)


func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody2D and body.has_method("get_density")):
		return

	var density: float = body.get_density()
	var goal: float = ChallengeManager.goal_value

	print("📏 Object Density: %.2f | Target: %.2f" % [density, goal])

	if abs(density - goal) < 0.01:
		print("✅ Correct Bottle Detected!")
		modulate = Color.GREEN
		correct.play()
		animated_sprite.play("Correct")
		await animated_sprite.animation_finished

		# ✅ Add QuestManager safe progress
		if QuestManager:
			var scene_name := get_tree().current_scene.name
			var level_num := int(scene_name.replace("level_", ""))
			QuestManager.advance_density_level(level_num)

		# ✅ Save progress if SaveManager exists
		if has_node("/root/SaveManager"):
			SaveManager.save_game()

		# ✅ Optional panel update (if in scene)
		var dense_panel = get_tree().get_first_node_in_group("DensePanel")
		if dense_panel and dense_panel.has_method("update_levels_state"):
			dense_panel.update_levels_state()

		await _go_to_level3()
	else:
		print("🚫 Wrong Density → Expected: %.2f Got: %.2f" % [goal, density])
		modulate = Color.RED
		wrong.play()


func _go_to_level3() -> void:
	print("➡ Loading Level 3 directly after Level 2...")
	var next_scene_path = "res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn"

	if ResourceLoader.exists(next_scene_path):
		await get_tree().create_timer(0.5).timeout
		await FadeManager.fade_and_change(next_scene_path)
	else:
		print("❌ Level 3 scene not found at:", next_scene_path)
