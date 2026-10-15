extends Area2D

@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var _finished := false

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
	if _finished:
		return
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
		_finished = true
		print("✅ CORRECT! Proceeding...")
		modulate = Color.GREEN
		correct.play()
		animated_sprite.play("Correct")
		await animated_sprite.animation_finished

		# ✅ QuestManager progression
		if QuestManager:
			var level_num := _current_level_number()
			QuestManager.advance_density_level(level_num)

		await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn")
	else:
		print("❌ WRONG! Expected:", goal, "Got:", value)
		modulate = Color.RED
		wrong.play()


func _current_level_number() -> int:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return 0
	var file_name := current_scene.scene_file_path.get_file().get_basename()
	var regex := RegEx.new()
	regex.compile(r"(\d+)$")
	var result := regex.search(file_name)
	return int(result.get_string(1)) if result != null else 0
