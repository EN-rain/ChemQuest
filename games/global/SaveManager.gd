extends Node


# Use user:// for writable location in exports (res:// is read-only)
const SAVE_PATH := "user://save.json"

# ============================================================
# 🌍 GAME STATE VARIABLES
# ============================================================
var current_scene_path: String = ""
var last_spawn: String = ""
var quest_data: Dictionary = {}
var shown_feedback: Array[String] = []  # 💬 stores feedback keys already shown


# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	print("🧩 Actual save path:", ProjectSettings.globalize_path(SAVE_PATH))
# if FileAccess.file_exists(SAVE_PATH):
#     print("🧹 Deleting old user save:", ProjectSettings.globalize_path(SAVE_PATH))
#     DirAccess.remove_absolute(SAVE_PATH)

	print("💾 SaveManager autoload ready.")
	var data := load_game()
	if data.size() > 0:
		restore_game(data)
	else:
		print("🆕 No previous save found; starting fresh.")


# ============================================================
# 💾 SAVE GAME
# ============================================================
func save_game() -> void:
	print("💾 Saving game...")

	#  Capture current scene path automatically
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

	#  Sync latest spawn and quests
	if has_node("/root/SpawnManager"):
		last_spawn = SpawnManager.spawn_point

	if has_node("/root/QuestManager"):
		var quests: Array = []
		for quest in QuestManager.active_quests.values():
			quests.append({
				"id": quest.id,
				"title": quest.title,
				"description": quest.description,
				"is_completed": quest.is_completed
			})
		quest_data["quests"] = quests

	#  Sync feedback state
	if has_node("/root/PlayerFeedbackManager"):
		shown_feedback = PlayerFeedbackManager.get_shown_feedback()

	#  Combine data
	var save_data: Dictionary = {
		"scene_path": current_scene_path,
		"last_spawn": last_spawn,
		"quests": quest_data.get("quests", []),
		"shown_feedback": shown_feedback,
		"density_progress": QuestManager.density_progress, 
		"states_progress": QuestManager.states_progress  
	}

	#  Write file safely
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print(" Game saved successfully ->", SAVE_PATH)
	else:
		push_error("❌ Failed to open save file for writing.")


# ============================================================
# 📂 LOAD GAME
# ============================================================
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠️ No save file found. Starting new game.")
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("❌ Failed to open save file.")
		return {}

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("⚠️ Invalid save file format.")
		return {}

	print("📂 Save file loaded successfully!")
	return parsed


# ============================================================
# 🔄 RESTORE GAME STATE
# ============================================================
func restore_game(data: Dictionary) -> void:
	print("♻️ Restoring game from save data...")

	last_spawn = data.get("last_spawn", "")
	current_scene_path = data.get("scene_path", "")
	quest_data["quests"] = data.get("quests", [])

	#  Safe rebuild of typed Array[String]
	shown_feedback = []
	for item in data.get("shown_feedback", []):
		if typeof(item) == TYPE_STRING:
			shown_feedback.append(item)

	#  Restore quest data
#  Restore quest data
	if has_node("/root/QuestManager"):
		QuestManager.load_from_save_data(quest_data["quests"])
		QuestManager.density_progress = int(data.get("density_progress", 0))
		QuestManager.states_progress = int(data.get("states_progress", 0))  #  new line


	#  Restore spawn point
	if has_node("/root/SpawnManager"):
		SpawnManager.spawn_point = last_spawn

	#  Restore feedback data
	if has_node("/root/PlayerFeedbackManager"):
		PlayerFeedbackManager.set_shown_feedback(shown_feedback)

	print("📍 Restored spawn:", last_spawn)
	print("🎯 Restored scene:", current_scene_path)
	print("💬 Restored feedback keys:", shown_feedback)


# ============================================================
# ▶️ CONTINUE GAME
# ============================================================
func continue_game() -> void:
	if current_scene_path == "":
		print("⚠️ No saved scene path, starting from default scene.")
		return

	print("▶️ Continuing game from:", current_scene_path, "Spawn:", last_spawn)
	get_tree().change_scene_to_file(current_scene_path)


# ============================================================
# 📍 SAVE SPAWN POINT
# ============================================================
func save_spawn(spawn_name: String) -> void:
	if spawn_name == "":
		push_warning("⚠️ Tried to save an empty spawn name.")
		return

	last_spawn = spawn_name
	print("📍 Saving spawn point:", spawn_name)
	save_game()


# ============================================================
# 🎬 CHANGE SCENE AND SAVE (used by go_back.gd)
# ============================================================
func change_scene_with_save(scene_path: String, spawn_name: String = "") -> void:
	current_scene_path = scene_path
	if spawn_name != "":
		last_spawn = spawn_name
	save_game()
