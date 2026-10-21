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


func _get_saved_control_scheme() -> String:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return String(config.get_value("controls", "type", "arrows"))
	return "arrows"


func _apply_control_scheme(scheme: String) -> void:
	var is_arrows := (scheme == "arrows")
	var buttons := get_node_or_null("CanvasLayer/Buttons") as Control
	if buttons != null:
		buttons.visible = is_arrows
	var joystick := get_node_or_null("CanvasLayer/VirtualJoystick") as Control
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
