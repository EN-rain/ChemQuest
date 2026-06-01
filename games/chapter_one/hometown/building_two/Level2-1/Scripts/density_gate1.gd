extends Area2D

@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("DensityGate")
	connect("body_entered", Callable(self, "_on_body_entered"))
	call_deferred("_initialize_challenge")


func _initialize_challenge() -> void:
	print("\n🕓 [DensityGate] Waiting for barrels...")
	await get_tree().create_timer(0.2).timeout

	var barrels = get_tree().get_nodes_in_group("BarrelGroup")
	print("🔍 Found %s barrels in BarrelGroup." % barrels.size())
	for b in barrels:
		print("   • Barrel %s → M:%.1f | V:%.1f | ρ:%.2f" % [b.barrel_id, b.object_mass, b.volume, b.density])

	ChallengeManager.setup_challenge(barrels)


func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody2D and body.has_method("get_density")):
		return

	var type = ChallengeManager.challenge_type
	var goal = ChallengeManager.goal_value
	var mass: float = body.object_mass
	var vol: float = body.volume
	var dens: float = body.get_density()

	var value := 0.0
	match type:
		"density": value = dens
		"mass": value = dens * vol
		"volume": value = mass / max(dens, 0.001)

	print("\n📏 [DensityGate] Barrel Entered:", body.name)
	print("   ▶ Type:", type, "| Computed:", value, "| Goal:", goal)

	if abs(value - goal) < 0.01:
		print("✅ CORRECT! Proceeding...")
		modulate = Color.GREEN
		correct.play()
		animated_sprite.play("Correct")
		await animated_sprite.animation_finished

		# ✅ QuestManager progression
		if QuestManager:
			var scene_name := get_tree().current_scene.name
			var level_num := int(scene_name.replace("level_", ""))
			QuestManager.advance_density_level(level_num)

		get_tree().change_scene_to_file("res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Scenes/level_2.tscn")
	else:
		print("❌ WRONG! Expected:", goal, "Got:", value)
		modulate = Color.RED
		wrong.play()
