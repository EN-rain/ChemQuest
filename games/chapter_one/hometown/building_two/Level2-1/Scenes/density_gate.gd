extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"
@onready var canvas_layer: CanvasLayer = $UI

var _finished := false

func _ready() -> void:
	add_to_group("DensityGate3")
	connect("body_entered", Callable(self, "_on_body_entered"))
	call_deferred("_initialize_item_challenge")

func _initialize_item_challenge() -> void:
	print("\n🕓 [DensityGate3] Waiting for items...")
	await get_tree().create_timer(0.2).timeout

	var items = get_tree().get_nodes_in_group("ItemGroup")
	print("🔍 Found %s items in ItemGroup." % items.size())
	for i in items:
		print("   • Item %s → M:%.1f | V:%.1f | ρ:%.2f" % [i.item_id, i.object_mass, i.volume, i.density])

	ChallengeManager.setup_item_challenge(items)

func _on_body_entered(body: Node) -> void:
	if _finished:
		return
	if not (body is RigidBody2D and body.has_method("get_density")):
		return

	var density: float = float(body.get_density())
	var goal: float = ChallengeManager.goal_value

	print("📏 Object Density: %.2f | Target: %.2f" % [density, goal])

	if abs(density - goal) < 0.01:
		print("✅ Correct item detected!")
		modulate = Color.GREEN
		correct.play()
		animated_sprite.play("Correct")
		await animated_sprite.animation_finished

		_finished = true

		# ✅ Record density progress for level_3 (only once)
		if QuestManager:
			var scene_name := get_tree().current_scene.name
			var level_num := int(scene_name.replace("level_", ""))
			QuestManager.advance_density_level(level_num)

		_finish_density_quest()
		await _show_congratulations()
	else:
		print("🚫 Wrong density → Expected: %.2f Got: %.2f" % [goal, density])
		modulate = Color.RED
		wrong.play()


func _finish_density_quest() -> void:
	if QuestManager.has_quest("density_measurement") and not QuestManager.is_quest_completed("density_measurement"):
		QuestManager.complete_quest("density_measurement")
		var next_quest = QuestManager.get_quest_template("after_density_measurement")
		if next_quest:
			QuestManager.add_quest(next_quest)
		if has_node("/root/SaveManager"):
			SaveManager.save_game()

	var quest_panel = get_tree().get_first_node_in_group("QuestPanel")
	if quest_panel:
		quest_panel.show_latest_quest()


func _show_congratulations() -> void:
	var label := Label.new()
	label.text = "Excellent Work!\nYou mastered Density Measurement!"
	label.add_theme_color_override("font_color", Color.WHITE)
	label.set("theme_override_font_sizes/font_size", 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -250
	label.offset_top = -50
	canvas_layer.add_child(label)

	await get_tree().create_timer(2.5).timeout
	await _play_feedback_and_return()


func _play_feedback_and_return() -> void:
	var feedback_lines = PlayerFeedbackManager.get_feedback("player_after_density")

	if not feedback_lines.is_empty():
		var dialogue_box = get_tree().get_first_node_in_group("DialogueBox")
		if dialogue_box:
			dialogue_box.start_dialogue(feedback_lines)
			await dialogue_box.dialogue_finished

	print("🎉 Density quest complete — returning to BuildingTwo.")
	SpawnManager.set_spawn("game_spawn")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")
