extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var playing_label: Label = %Playing

func _ready() -> void:
	MusicManager.play_music_by_id("main")
	FadeManager.setup(fade_sfx)
	_start_blinking_playing_label()


# ---------------------------------------------------------
# Label blink animation
# ---------------------------------------------------------
func _start_blinking_playing_label() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(playing_label, "modulate:a", 0.2, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(playing_label, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_start_blinking_playing_label)


# ---------------------------------------------------------
# 🟢 CONTINUE BUTTON
# ---------------------------------------------------------
func _on_continue_pressed() -> void:
	MusicManager.play_music_by_id("button", 0)  # 🔊 play click sound

	if not FileAccess.file_exists("user://save.json"):
		print("⚠ No save file found. Starting new game instead.")
		await _on_new_game_pressed()
		return

	# Load and restore save data
	var data := SaveManager.load_game()
	if data.size() > 0:
		SaveManager.restore_game(data)

	var next_scene := SaveManager.current_scene_path
	var spawn_name := SaveManager.last_spawn if SaveManager.last_spawn != "" else "default"

	print("▶ Continue pressed -> scene:", next_scene, "spawn:", spawn_name)

	SpawnManager.set_spawn(spawn_name)
	await FadeManager.fade_and_change(next_scene)



# ---------------------------------------------------------
# 🆕 NEW GAME BUTTON
# ---------------------------------------------------------
func _on_new_game_pressed() -> void:
	MusicManager.play_music_by_id("button", 0)  # 🔊 play click sound
	print("🆕 Starting a new game...")

	# 1️⃣ Reset quests
	_reset_all_quests_to_false_except_first()
	_clear_save_data()

	# 2️⃣ Reload quest data into QuestManager
	QuestManager.active_quests.clear()
	QuestManager.load_default_quests()

	# 3️⃣ Add the first quest to start
	var first_quest: Quest = QuestManager.get_quest_template("find_wiz")
	if first_quest:
		first_quest.is_completed = false
		QuestManager.add_quest(first_quest)
		print("🌟 First quest loaded:", first_quest.title)
	else:
		push_error("⚠ Could not find 'find_wiz' quest!")

	# 4️⃣ Save default spawn and scene
	SaveManager.current_scene_path = "res://games/chapter_one/hometown/hometown.tscn"
	SaveManager.last_spawn = "default"
	SpawnManager.set_spawn("default")

	# 5️⃣ Transition to intro cutscene
	await FadeManager.fade_and_change("res://games/chapter_one/visual_one.tscn")


# ---------------------------------------------------------
# 🧹 Reset all quest progress
# ---------------------------------------------------------
func _reset_all_quests_to_false_except_first() -> void:
	var quest_path := "user://quest.json"
	var default_path := "res://games/global/quest.json"

	if not FileAccess.file_exists(quest_path) and FileAccess.file_exists(default_path):
		var default_file := FileAccess.open(default_path, FileAccess.READ)
		var text := default_file.get_as_text()
		default_file.close()

		var new_file := FileAccess.open(quest_path, FileAccess.WRITE)
		new_file.store_string(text)
		new_file.close()

	var quest_file := FileAccess.open(quest_path, FileAccess.READ)
	if not quest_file:
		print("⚠ Failed to open quest file.")
		return

	var data = JSON.parse_string(quest_file.get_as_text())
	quest_file.close()

	if typeof(data) == TYPE_DICTIONARY and data.has("quests"):
		for quest in data["quests"]:
			quest["is_completed"] = quest["id"] != "find_wiz"

		data["last_spawn"] = "default"
		data["last_scene"] = "res://games/chapter_one/hometown/hometown.tscn"

		var save_file := FileAccess.open(quest_path, FileAccess.WRITE)
		save_file.store_string(JSON.stringify(data, "\t"))
		save_file.close()

		print("🔄 Quests reset successfully (only 'find_wiz' active).")
	else:
		print("⚠ Invalid quest data format in quest.json.")


# ---------------------------------------------------------
# 🗑 Clear save.json and memory data
# ---------------------------------------------------------
func _clear_save_data() -> void:
	QuestManager.active_quests.clear()
	SaveManager.current_scene_path = ""
	SaveManager.last_spawn = ""

	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
		print("🗑 Save file deleted.")

	print("🔄 Game progress reset.")


# ---------------------------------------------------------
# 🧭 MENU BUTTONS
# ---------------------------------------------------------
func _on_chapter_1_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/chapter_one/visual_one.tscn")

func _on_about_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/about.tscn")

func _on_glossary_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/main.tscn")

func _on_exit_pressed() -> void:
	MusicManager.play_sfx("button")
	MusicManager.stop_music()
	get_tree().quit()
