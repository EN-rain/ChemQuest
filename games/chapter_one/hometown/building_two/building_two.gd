extends Node2D

@onready var feedback_panel: Panel = %FeedbackPanel
@onready var player: Node2D = %Player
@onready var spawn_points: Node = %SpawnPoints
@onready var quest_panel: Control = %QuestPanel

func _ready() -> void:
	#  Store scene path for save system
	SaveManager.current_scene_path = "res://games/chapter_one/hometown/building_two/building_two.tscn"
	SaveManager.save_game()

	# 🎵 Play background music
	MusicManager.play_music_by_id("house")

	# 📜 Show most recent quest
	if quest_panel:
		quest_panel.show_latest_quest()

	# 🚪 Spawn setup
	_handle_player_spawn()

	# 💬 Feedback setup
	_check_player_feedback()


func _handle_player_spawn() -> void:
	var spawn_name := SpawnManager.get_spawn()
	var spawn_marker: Marker2D = null

	print("🏗️ BuildingTwo ready — SpawnManager returned:", spawn_name)

	if spawn_name != "":
		spawn_marker = spawn_points.get_node_or_null(spawn_name)
		if spawn_marker:
			print("✅ Found spawn marker:", spawn_name, "at", spawn_marker.global_position)
		else:
			print("⚠️ No spawn marker found for:", spawn_name)

	var default_spawn: Vector2 = spawn_points.get_node("default").global_position

	if spawn_marker:
		player.global_position = spawn_marker.global_position
		print("🎯 Player spawned at", spawn_marker.global_position, "via", spawn_name)
	else:
		player.global_position = default_spawn
		print("⚠️ Default spawn used at", default_spawn)


func _check_player_feedback() -> void:
	if not feedback_panel:
		push_warning("⚠️ No FeedbackPanel found in scene.")
		return

	var feedback_key := _get_feedback_for_completed_quest()
	if feedback_key == "":
		print("ℹ️ No feedback triggered.")
		return

	var lines := PlayerFeedbackManager.get_feedback(feedback_key)
	if lines.is_empty():
		push_warning("⚠️ No feedback text found for key: %s" % feedback_key)
		return

	print("💬 Showing player feedback:", feedback_key)
	feedback_panel.show_feedback(lines)


func _get_feedback_for_completed_quest() -> String:
	var mapping := {
		"density_measurement": "player_after_density",
		"states_of_matter": "player_after_states"
	}

	for quest_id in mapping.keys():
		if QuestManager.has_quest(quest_id) and QuestManager.is_quest_completed(quest_id):
			print(" Feedback match found for quest:", quest_id)
			return mapping[quest_id]

	return ""
