extends Node

const SAVE_PATH := "user://item_history.json"
const MAX_RUNS: int = 3

var level3_data: Dictionary = {
	"item_history": {},   # item_name: true/false (true = cleared)
	"run_count": 0
}


func _ready() -> void:
	_load_data()


# ============================================================
# 📂 LOAD / SAVE DATA
# ============================================================
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
				level3_data = parsed as Dictionary

	# ✅ Ensure essential keys always exist
	if not level3_data.has("item_history"):
		level3_data["item_history"] = {}
	if not level3_data.has("run_count"):
		level3_data["run_count"] = 0


func _save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level3_data, "\t"))
		file.close()


# ============================================================
# 🧩 ITEM TRACKING
# ============================================================
func mark_item_cleared(item_name: String) -> void:
	if item_name == "":
		return

	if not level3_data.has("item_history"):
		level3_data["item_history"] = {}

	level3_data["item_history"][item_name] = true
	_save_data()


func can_spawn_item(item_name: String) -> bool:
	if not level3_data.has("item_history"):
		return true
	return not level3_data["item_history"].get(item_name, false)


# ============================================================
# 🔁 RUN TRACKING
# ============================================================
func increment_run_and_check_reset() -> void:
	if not level3_data.has("run_count"):
		level3_data["run_count"] = 0

	level3_data["run_count"] += 1

	if level3_data["run_count"] >= MAX_RUNS:
		# ✅ Reset all cleared items after 3 runs
		level3_data["item_history"].clear()
		level3_data["run_count"] = 0

	_save_data()
