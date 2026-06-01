extends Node

const SAVE_PATH := "user://lesson_data.json"
const MAX_RUNS: int = 3

var lesson_data: Dictionary = {
	"element_spawn_history": {},
	"compound_spawn_history": {},
	"run_count": 0,
	"run_count_two": 0
}

func _ready() -> void:
	_load_data()

# --- Load and save data ---
func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text: String = file.get_as_text()
		file.close()

		if text.strip_edges() != "":
			var parsed: Variant = JSON.parse_string(text)
			if typeof(parsed) == TYPE_DICTIONARY:
				lesson_data = parsed as Dictionary

	# ✅ Ensure all required keys exist
	if not lesson_data.has("element_spawn_history"):
		lesson_data["element_spawn_history"] = {}
	if not lesson_data.has("compound_spawn_history"):
		lesson_data["compound_spawn_history"] = {}
	if not lesson_data.has("run_count"):
		lesson_data["run_count"] = 0
	if not lesson_data.has("run_count_two"):
		lesson_data["run_count_two"] = 0

func _save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(lesson_data, "\t"))
		file.close()

# ============================================================
# 🧩 LESSON 1 – Element tracking
# ============================================================
func mark_element_used(symbol: String) -> void:
	if not lesson_data.has("element_spawn_history"):
		lesson_data["element_spawn_history"] = {}
	lesson_data["element_spawn_history"][symbol] = true
	_save_data()

func can_spawn(symbol: String) -> bool:
	if not lesson_data.has("element_spawn_history"):
		return true
	return not lesson_data["element_spawn_history"].get(symbol, false)

func increment_run_and_check_reset() -> void:
	if not lesson_data.has("run_count"):
		lesson_data["run_count"] = 0

	lesson_data["run_count"] += 1

	if lesson_data["run_count"] >= MAX_RUNS:
		lesson_data["element_spawn_history"].clear()
		lesson_data["run_count"] = 0

	_save_data()

# ============================================================
# 🧪 LESSON 2 – Record compound as soon as it spawns
# ============================================================
func record_compound_spawned(formula: String) -> void:
	if not lesson_data.has("compound_spawn_history"):
		lesson_data["compound_spawn_history"] = {}
	
	if not lesson_data["compound_spawn_history"].has(formula):
		lesson_data["compound_spawn_history"][formula] = true
		print("📘 Recorded spawned compound:", formula)
	
	_save_data()


func can_spawn_compound(compound_name: String) -> bool:
	if not lesson_data.has("compound_spawn_history"):
		return true
	return not lesson_data["compound_spawn_history"].get(compound_name, false)

func increment_run_two_and_check_reset() -> void:
	if not lesson_data.has("run_count_two"):
		lesson_data["run_count_two"] = 0

	lesson_data["run_count_two"] += 1

	if lesson_data["run_count_two"] >= MAX_RUNS:
		lesson_data["compound_spawn_history"].clear()
		lesson_data["run_count_two"] = 0

	_save_data()
