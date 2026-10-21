extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx

# Unique ID to ensure the redirect only happens once
const GUIDE_ID := "after_states_redirect"

func _ready() -> void:
	
	# Setup fade transition system
	FadeManager.setup(fade_sfx)

	# Check quest completion before showing hometown. The reward redirect changes
	# scenes, so stop this scene's initialization as soon as it succeeds rather
	# than touching controls that may already have been freed.
	if await _check_after_states_quest():
		return

	# Normal hometown logic
	%QuestPanel.show_latest_quest()
	if has_node("/root/GuideManager") and not GuideManager.has_seen("hometown_tutorial"):
		%QuestPanel.visible = false

	var spawn_name := SpawnManager.get_spawn()
	if spawn_name == "":
		spawn_name = SaveManager.last_spawn
	spawn_name = SpawnManager.normalize_spawn_name(spawn_name)

	var spawn_marker: Marker2D = null
	if spawn_name != "":
		spawn_marker = %SpawnPoints.get_node_or_null(spawn_name)

	var resolved_spawn := "default"
	if spawn_marker:
		resolved_spawn = spawn_name
		%Player.global_position = spawn_marker.global_position
	else:
		%Player.global_position = %SpawnPoints/default.global_position

	SpawnManager.clear_pending()
	SaveManager.save_checkpoint(scene_file_path, resolved_spawn)
	_apply_control_scheme(_get_saved_control_scheme())

	var ingamesettings_btn := get_node_or_null("CanvasLayer/ingamesettings") as BaseButton
	var ingame_settings_panel := get_node_or_null("CanvasLayer/InGameSettings") as Control
	if ingamesettings_btn != null and ingame_settings_panel != null:
		ingamesettings_btn.pressed.connect(func():
			if MusicManager.has_method("play_sfx"):
				MusicManager.play_sfx("button")
			ingame_settings_panel.open()
		)


func _has_chosen_controls() -> bool:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return bool(config.get_value("controls", "chosen", false))
	return false


func _get_saved_control_scheme() -> String:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return String(config.get_value("controls", "type", "arrows"))
	return "arrows"


func _apply_control_scheme(scheme: String) -> void:
	var buttons := get_node_or_null("CanvasLayer/Buttons") as Control
	var joystick := get_node_or_null("CanvasLayer/VirtualJoystick") as Control

	if not _has_chosen_controls():
		if buttons != null:
			buttons.visible = false
		if joystick != null:
			joystick.visible = false
		return

	var is_arrows := (scheme == "arrows")
	if buttons != null:
		buttons.visible = is_arrows
	if joystick != null:
		joystick.visible = not is_arrows


func _check_after_states_quest() -> bool:
	var quest_id := "after_states_of_matter"

	# Make sure QuestManager exists
	if not has_node("/root/QuestManager"):
		push_warning("QuestManager not found — skipping quest check.")
		return false

	#  Only redirect if quest is completed and not already shown before
	if QuestManager.is_quest_completed(quest_id) and not GuideManager.has_seen(GUIDE_ID):
		print("🎯 Quest completed! Redirecting to Reward scene (first time only).")
		GuideManager.mark_seen(GUIDE_ID)  # Mark as shown to prevent repeat
		return await FadeManager.fade_and_change("res://games/achievements/reward/Reward.tscn")
	return false
