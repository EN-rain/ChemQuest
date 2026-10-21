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
	if spawn_name.is_empty():
		spawn_name = SaveManager.last_spawn
	spawn_name = SpawnManager.normalize_spawn_name(spawn_name)
	var spawn_marker: Marker2D = null

	print("🏠 BuildingOne ready, SpawnManager returned =", spawn_name)

	if spawn_name != "":
		spawn_marker = %SpawnPoints.get_node_or_null(spawn_name)
		if spawn_marker:
			print("✅ Found spawn marker:", spawn_name, "at", spawn_marker.global_position)
		else:
			print("⚠️ No spawn marker found for:", spawn_name)

	# Default fallback spawn point
	var default_marker: Marker2D = %SpawnPoints/default
	var default_spawn: Vector2 = default_marker.global_position
	var resolved_spawn_name := "default"

	# 🧍 Place player at correct spawn
	if spawn_marker:
		resolved_spawn_name = spawn_name
		%Player.global_position = spawn_marker.global_position
		print("🎯 Player spawned at", spawn_marker.global_position, "via", spawn_name)
	else:
		%Player.global_position = default_spawn
		print("⚠️ Default spawn used at", default_spawn)

	# 💬 Show player feedback if applicable
	_check_player_feedback()

	# 💾 Save current spawn for continuation
	SpawnManager.clear_pending()
	SaveManager.save_checkpoint(scene_file_path, resolved_spawn_name)
	SaveManager.save_game()

	# 🎮 Controls & Settings
	_apply_control_scheme(_get_saved_control_scheme())
	print("🏠 [BuildingOne] _ready() finished. Player pos=", %Player.global_position, " can_move=", %Player.can_move, " spawn=", resolved_spawn_name)
	var ingamesettings_btn := get_node_or_null("CanvasLayer/ingamesettings") as BaseButton
	var ingame_settings_panel := get_node_or_null("CanvasLayer/InGameSettings") as Control
	if ingamesettings_btn != null and ingame_settings_panel != null:
		ingamesettings_btn.pressed.connect(func():
			if MusicManager.has_method("play_sfx"):
				MusicManager.play_sfx("button")
			ingame_settings_panel.open()
		)


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


# ===============================
# 🎮 CONTROLS
# ===============================
func _get_saved_control_scheme() -> String:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return String(config.get_value("controls", "type", "arrows"))
	return "arrows"


func _apply_control_scheme(scheme: String) -> void:
	var buttons := get_node_or_null("CanvasLayer/Buttons") as Control
	var joystick := get_node_or_null("CanvasLayer/VirtualJoystick") as Control
	var is_arrows := (scheme == "arrows")
	if buttons != null:
		buttons.visible = is_arrows
	if joystick != null:
		joystick.visible = not is_arrows
	print("🎮 [BuildingOne] _apply_control_scheme: scheme=", scheme, " buttons.visible=", buttons.visible if buttons else "null", " joystick.visible=", joystick.visible if joystick else "null")
