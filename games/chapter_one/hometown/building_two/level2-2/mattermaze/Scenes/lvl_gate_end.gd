extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = $CanvasLayer/ColorRect

var _finished := false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0)

func _on_body_entered(body: Node) -> void:
	if _finished or body.name != "Player":
		return

	print("Player reached the final gate ✅")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)

func _on_flag_animation_finished() -> void:
	if fade_rect:
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
		tween.finished.connect(_return_to_building_two, CONNECT_ONE_SHOT)
	else:
		_return_to_building_two()

func _return_to_building_two() -> void:
	if _finished:
		return
	_finished = true

	print("🎮 Level 3 complete – returning to Building Two.")

	# ✅ Record States Progress (only once per level)
	if QuestManager:
		var scene_name := get_tree().current_scene.name
		var level_num := int(scene_name.replace("level_", ""))
		QuestManager.advance_states_level(level_num)

	# ✅ Quest completion + feedback
	if QuestManager.has_quest("states_of_matter") and not QuestManager.is_quest_completed("states_of_matter"):
		QuestManager.complete_quest("states_of_matter")
		var next_quest = QuestManager.get_quest_template("after_states_of_matter")
		if next_quest:
			QuestManager.add_quest(next_quest)
		if has_node("/root/SaveManager"):
			SaveManager.save_game()

	# 🎤 Player feedback
	if PlayerFeedbackManager:
		var lines := PlayerFeedbackManager.get_feedback("player_after_states")
		if not lines.is_empty():
			var feedback_panel = get_tree().get_first_node_in_group("FeedbackPanel")
			if feedback_panel:
				feedback_panel.show_feedback(lines)

	# 🎵 Return music + teleport
	MusicManager.play_music_by_id("house")
	if SpawnManager:
		SpawnManager.set_spawn("game_spawn")

	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")
