extends Node

const FEEDBACK_PATH := "res://games/global/player_feedback.json"

var feedback_data: Dictionary = {}
var shown_feedback: Array[String] = []  # 💬 Tracks which feedback keys were shown


# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	load_feedback()


# ============================================================
# 📂 LOAD FEEDBACK DATA
# ============================================================
func load_feedback() -> void:
	if not FileAccess.file_exists(FEEDBACK_PATH):
		push_error("❌ Missing feedback file at: " + FEEDBACK_PATH)
		return

	var file := FileAccess.open(FEEDBACK_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed is Dictionary:
		feedback_data = parsed
		print("✅ Player feedback loaded:", feedback_data.size(), "entries.")
	else:
		push_error("⚠️ Invalid feedback JSON format.")


# ============================================================
# 💬 GET FEEDBACK LINES (Non-repeating)
# ============================================================
func get_feedback(id: String) -> Array:
	# 🧱 Prevent repeating the same feedback multiple times (even across sessions)
	if id in shown_feedback:
		print("ℹ️ Feedback already shown:", id)
		return []

	var lines: Array = feedback_data.get(id, [])
	if not lines.is_empty():
		shown_feedback.append(id)  # Mark as shown
		print("💬 Showing feedback:", id)
		_auto_save_feedback()       # 🔄 Save progress immediately
	return lines


# ============================================================
# 💾 SAVE/LOAD SHOWN FEEDBACK (Used by SaveManager)
# ============================================================
func get_shown_feedback() -> Array[String]:
	return shown_feedback


func set_shown_feedback(data: Array) -> void:
	shown_feedback.clear()
	for item in data:
		if typeof(item) == TYPE_STRING:
			shown_feedback.append(item)
	print("💬 Restored shown feedback keys:", shown_feedback)


# ============================================================
# 🧠 AUTO-SAVE (Optional but Recommended)
# ============================================================
func _auto_save_feedback() -> void:
	# If SaveManager exists, persist the update
	if has_node("/root/SaveManager"):
		SaveManager.shown_feedback = shown_feedback
		SaveManager.save_game()
