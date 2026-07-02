extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx

# Unique ID to ensure the redirect only happens once
const GUIDE_ID := "after_states_redirect"

func _ready() -> void:
	
	# Setup fade transition system
	FadeManager.setup(fade_sfx)

	# Check quest completion before showing hometown
	await _check_after_states_quest()

	# Normal hometown logic
	%QuestPanel.show_latest_quest()

	var spawn_name := SaveManager.last_spawn
	if spawn_name == "":
		spawn_name = SpawnManager.get_spawn()

	var spawn_marker: Marker2D = null
	if spawn_name != "":
		spawn_marker = %SpawnPoints.get_node_or_null(spawn_name)

	if spawn_marker:
		%Player.global_position = spawn_marker.global_position
	else:
		%Player.global_position = %SpawnPoints/default.global_position

	# Reset spawn to avoid double-use
	SpawnManager.set_spawn("")

func _check_after_states_quest() -> void:
	var quest_id := "after_states_of_matter"

	# Make sure QuestManager exists
	if not has_node("/root/QuestManager"):
		push_warning("QuestManager not found — skipping quest check.")
		return

	#  Only redirect if quest is completed and not already shown before
	if QuestManager.is_quest_completed(quest_id) and not GuideManager.has_seen(GUIDE_ID):
		print("🎯 Quest completed! Redirecting to Reward scene (first time only).")
		GuideManager.mark_seen(GUIDE_ID)  # Mark as shown to prevent repeat
		await FadeManager.fade_and_change("res://games/achievements/reward/Reward.tscn")
