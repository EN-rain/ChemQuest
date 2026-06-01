extends Area2D

@onready var correct: AudioStreamPlayer = $"../Correct"
@onready var wrong: AudioStreamPlayer = $"../Wrong"
@export var density_threshold: float = 8.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var canvas_layer: CanvasLayer = $UI  # Ensure your scene has a "UI" CanvasLayer

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody2D and body.has_method("get_density")):
		return

	var density = body.get_density()
	print("📏 Object density:", density)

	if density > density_threshold:
		print("🚫 Density too high!")
		wrong.play()
		modulate = Color(1, 0, 0, 1)
		return

	elif density < density_threshold:
		print("🚫 Density too low!")
		wrong.play()
		modulate = Color(1, 0, 0, 1)
		return

	# ✅ Correct density reached
	print("✅ Density acceptable!")
	modulate = Color(0, 1, 0, 1)
	correct.play()
	animated_sprite.play("Correct")
	await animated_sprite.animation_finished

	# ✅ Advance quest & show congratulations
	_finish_density_quest()
	_show_congratulations()

func _finish_density_quest() -> void:
	# ✅ Mark quest as completed and add follow-up quest
	if QuestManager.has_quest("density_measurement") and not QuestManager.is_quest_completed("density_measurement"):
		print("🏁 Completing quest: density_measurement")
		QuestManager.complete_quest("density_measurement")

		# Add "after_density_measurement" quest
		var next_quest = QuestManager.get_quest_template("after_density_measurement")
		if next_quest:
			QuestManager.add_quest(next_quest)

		# Optional: save immediately
		QuestManager.save_quests()

	# ✅ Update UI (if the quest panel exists)
	var quest_panel = get_tree().get_first_node_in_group("QuestPanel")
	if quest_panel:
		quest_panel.show_latest_quest()

func _show_congratulations() -> void:
	# ✅ Display a congratulatory message
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

	# ✅ Create fade-to-black overlay
	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = get_viewport_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fade_rect)

	# ✅ Fade out smoothly, then change scene
	var tween := get_tree().create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 3.0)
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete() -> void:
	print("🎉 Density quest complete — returning to BuildingTwo.")
	SpawnManager.set_spawn("from_building_two")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")
