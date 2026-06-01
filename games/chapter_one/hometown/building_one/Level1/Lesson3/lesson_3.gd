extends Node2D

var mixtures = []
var mixture_scene = preload("res://games/chapter_one/hometown/building_one/Level1/Lesson3/mixtures.tscn")
var current_mixtures = []
var used_ids: Array = []

@onready var spawner_panel = %SpawnerPanel

var history_file_path := "user://data_history.json"
var history_data := {
	"spawn_history": {},
	"run_count": 0
}


func _ready():
	MusicManager.play_music_by_id("game1")
	randomize()
	load_mixtures()
	load_history()
	spawn_mixtures(3, true)


# --- Load mixtures from JSON file ---
func load_mixtures():
	var file = FileAccess.open("res://games/chapter_one/hometown/building_one/Level1/Lesson3/mixtures.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_ARRAY:
			mixtures = data
		else:
			push_error("Invalid mixtures data format.")
	else:
		push_error("Could not load mixtures.json")


# --- Load or initialize the Level 2 history file ---
func load_history() -> void:
	if not FileAccess.file_exists(history_file_path):
		save_history()
	else:
		var file = FileAccess.open(history_file_path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				history_data = parsed
			else:
				print("History file invalid, resetting...")
				save_history()


# --- Save history to Level 2 file ---
func save_history() -> void:
	var file = FileAccess.open(history_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(history_data, "\t"))
	file.close()


# --- Reset history after 3 completed runs ---
func reset_history() -> void:
	print("🔄 Resetting spawn history (3 runs reached)")
	history_data["spawn_history"] = {}
	history_data["run_count"] = 0
	save_history()


# --- Record correctly sorted mixture IDs ---
func record_correct_mixture(mixture_data: Dictionary) -> void:
	var id = str(mixture_data.get("id", ""))
	history_data["spawn_history"][id] = true
	save_history()


# --- Remove correct mixture if undone ---
func remove_correct_mixture(mixture_data: Dictionary) -> void:
	var id = str(mixture_data.get("id", ""))
	if id in history_data["spawn_history"]:
		history_data["spawn_history"].erase(id)
	save_history()


# --- Increment run count after all 15 are sorted ---
func increment_run_count() -> void:
	history_data["run_count"] += 1
	print("🏁 Run complete — current run count:", history_data["run_count"])
	if history_data["run_count"] >= 3:
		reset_history()
	else:
		save_history()


# --- Spawn mixtures (skip already correct ones) ---
func spawn_mixtures(count: int, reset: bool = false):
	const MAX_MIXTURES := 15

	# Determine total number of available mixtures dynamically
	var max_data := 0
	if not mixtures.is_empty():
		for m in mixtures:
			if typeof(m) == TYPE_DICTIONARY and m.has("id"):
				max_data = max(max_data, int(m["id"]))
	else:
		push_error("⚠️ No mixtures loaded.")
		return

	# Prevent overfilling
	if current_mixtures.size() >= MAX_MIXTURES:
		print("⚠️ Spawn limit reached (" + str(MAX_MIXTURES) + ") — skipping spawn.")
		return

	# Reset current spawn pool if requested
	if reset:
		for m in current_mixtures:
			if is_instance_valid(m):
				m.queue_free()
		current_mixtures.clear()
		used_ids.clear()

	# Clean invalid references
	current_mixtures = current_mixtures.filter(func(m): return is_instance_valid(m))

	var remaining_slots := MAX_MIXTURES - current_mixtures.size()
	count = min(count, remaining_slots)

	# Build list of available mixtures not yet used this session or marked complete
	var available: Array = []
	for m in mixtures:
		if typeof(m) == TYPE_DICTIONARY:
			var id = str(m.get("id", ""))
			if not used_ids.has(id) and (not history_data["spawn_history"].has(id) or history_data["spawn_history"][id] == false):
				available.append(m)

	# If there are no unused mixtures left, reset everything
	if available.is_empty():
		print("✅ All " + str(max_data) + " mixtures have been used. Resetting data_history.json...")
		reset_history()
		return

	# Randomly select mixtures to spawn
	available.shuffle()
	var selected = available.slice(0, count)
	var rect = spawner_panel.get_rect()

	for data in selected:
		var mixture = mixture_scene.instantiate()
		mixture.set_data(data)

		var pos_x = randi_range(0, rect.size.x)
		var pos_y = randi_range(0, rect.size.y)
		mixture.position = Vector2(pos_x, pos_y)
		mixture.original_position = mixture.position

		spawner_panel.add_child(mixture)
		current_mixtures.append(mixture)

		# Mark as temporarily used in this session
		used_ids.append(str(data.get("id", "")))


# --- Called from Boxes.gd when undoing ---
func return_mixture_to_pool(mixture_data: Dictionary) -> void:
	var id = str(mixture_data.get("id", ""))
	if id in history_data["spawn_history"]:
		history_data["spawn_history"][id] = false
	save_history()


# --- Lock all mixtures when finalizing ---
func lock_all_mixtures() -> void:
	for m in current_mixtures:
		if m is Mixture:
			m.stop_dragging()
			m.input_pickable = false
			m.monitoring = false
			m.monitorable = false


# --- UI back button handler ---
func _on_back_button_pressed() -> void:
	%BackPanel.visible = true
