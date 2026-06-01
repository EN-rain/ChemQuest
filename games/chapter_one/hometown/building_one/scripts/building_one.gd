extends Node2D

@onready var feedback_panel: Panel = %FeedbackPanel

func _ready() -> void:
	# 🎵 Play background music
	MusicManager.play_music_by_id("house")

	# 📜 Show active quest
	%QuestPanel.show_latest_quest()

	# 💾 Save current scene info for resume system
	SaveManager.current_scene_path = "res://games/chapter_one/hometown/building_one/building_one.tscn"
	SaveManager.save_game()

	# 🧭 Handle spawn point
	var spawn_name := SpawnManager.get_spawn()
	var spawn_marker: Marker2D = null

	print("🏠 BuildingOne ready, SpawnManager returned =", spawn_name)

	if spawn_name != "":
		spawn_marker = %SpawnPoints.get_node_or_null(spawn_name)
		if spawn_marker:
			print("✅ Found spawn marker:", spawn_name, "at", spawn_marker.global_position)
		else:
			print("⚠️ No spawn marker found for:", spawn_name)

	# Default fallback spawn point
	var default_spawn: Vector2 = %SpawnPoints/from_building_one.global_position

	# 🧍 Place player at correct spawn
	if spawn_marker:
		%Player.global_position = spawn_marker.global_position
		print("🎯 Player spawned at", spawn_marker.global_position, "via", spawn_name)
	else:
		%Player.global_position = default_spawn
		print("⚠️ Default spawn used at", default_spawn)

	# 💬 Show player feedback if applicable
	_check_player_feedback()

	# 💾 Save current spawn for continuation
	if spawn_name != "":
		SaveManager.save_spawn(spawn_name)
	else:
		SaveManager.save_spawn("from_building_one")

	SaveManager.save_game()


# ===============================
# 🧠 FEEDBACK HANDLING
# ===============================
func _check_player_feedback() -> void:
	if not feedback_panel:
		print("⚠️ No FeedbackPanel found in scene.")
		return

	var feedback_key := _get_feedback_for_completed_quest()
	if feedback_key == "":
		print("ℹ️ No feedback triggered.")
		return

	var lines := PlayerFeedbackManager.get_feedback(feedback_key)
	if lines.is_empty():
		print("⚠️ No feedback text found for key:", feedback_key)
		return

	print("💬 Showing player feedback:", feedback_key)
	feedback_panel.show_feedback(lines)


func _get_feedback_for_completed_quest() -> String:
	# 🧩 Map quest completions to player feedback keys
	var mapping := {
		"finish_book1": "player_after_book1",
		"finish_book2": "player_after_book2",
		"desk_quiz": "player_after_desk",
		"finish_book3": "player_after_book3",
		"separation_methods": "player_after_separation",
		"accuracy_vs_precision": "player_after_accuracy",
	}

	for quest_id in mapping.keys():
		if QuestManager.has_quest(quest_id) and QuestManager.is_quest_completed(quest_id):
			print("✅ Feedback match found for quest:", quest_id)
			return mapping[quest_id]

	return ""
