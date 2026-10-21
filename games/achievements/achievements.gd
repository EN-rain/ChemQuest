extends Node2D

@onready var quest_manager: Node = get_node_or_null("/root/QuestManager")
@onready var vbox := $CanvasLayer/MarginContainer/Control/ScrollContainer/VBoxContainer
@onready var fade_sfx: ColorRect = %FadeSfx
@onready var progress_label: Label = get_node_or_null("%ProgressLabel")

# Each quest ID maps to a readable custom achievement name
const ACHIEVEMENT_TEXT := {
	"finish_book1": "Mastered Book I – The Nature of Elements",
	"finish_book2": "Mastered Book II – The Art of Creation",
	"finish_book3": "Mastered Book III – The Mystery of Mixtures",
	"density_measurement": "Lesson V – The Weight of Matter",
	"states_of_matter": "Lesson VI – The Dance of Matter",
	"accuracy_vs_precision": "Lesson IV – The Measure of Truth",
	"separation_methods": "The Table of Separation"
}

var _style_unlocked: StyleBoxFlat
var _style_locked: StyleBoxFlat


func _ready() -> void:
	if MusicManager.current_music != null:
		MusicManager.current_music.volume_db = -10  
	FadeManager.setup(fade_sfx)
	_init_styles()
	
	print("=== Achievements Panel Ready ===")
	if not quest_manager:
		push_error("⚠️ QuestManager not found at /root/QuestManager")
		return

	# Connect to quest signals just like QuestPanel.gd
	if quest_manager.has_signal("quest_added"):
		quest_manager.quest_added.connect(_on_quest_updated)
	if quest_manager.has_signal("quest_completed"):
		quest_manager.quest_completed.connect(_on_quest_updated)
	if quest_manager.has_signal("quest_updated"):
		quest_manager.quest_updated.connect(_on_quest_updated)

	# Initialize display
	update_achievements()


func _init_styles() -> void:
	_style_unlocked = StyleBoxFlat.new()
	_style_unlocked.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	_style_unlocked.border_color = Color(1.0, 1.0, 1.0, 0.95)
	_style_unlocked.set_border_width_all(2)
	_style_unlocked.set_corner_radius_all(12)
	_style_unlocked.content_margin_left = 22
	_style_unlocked.content_margin_right = 22
	_style_unlocked.content_margin_top = 14
	_style_unlocked.content_margin_bottom = 14

	_style_locked = StyleBoxFlat.new()
	_style_locked.bg_color = Color(0.04, 0.04, 0.04, 0.75)
	_style_locked.border_color = Color(0.2, 0.2, 0.2, 0.6)
	_style_locked.set_border_width_all(1)
	_style_locked.set_corner_radius_all(12)
	_style_locked.content_margin_left = 22
	_style_locked.content_margin_right = 22
	_style_locked.content_margin_top = 14
	_style_locked.content_margin_bottom = 14


# ---------------------------------------------------------
#  Update display when quests change
# ---------------------------------------------------------
func _on_quest_updated(_quest: Quest = null) -> void:
	update_achievements()


# ---------------------------------------------------------
#  Update Achievements display
# ---------------------------------------------------------
func update_achievements() -> void:
	print("\n--- Updating Achievements ---")

	# Gather all achievement data
	var data: Array[Dictionary] = []
	for id in ACHIEVEMENT_TEXT.keys():
		var completed: bool = false
		if quest_manager and quest_manager.has_method("is_quest_completed"):
			completed = quest_manager.is_quest_completed(id)
		data.append({
			"id": id,
			"text": ACHIEVEMENT_TEXT[id],
			"completed": completed
		})
		print("Quest:", id, "Completed:", completed)

	# Sort so unlocked appear first
	data.sort_custom(func(a, b):
		return int(b["completed"]) - int(a["completed"])
	)

	var completed_count := 0
	for q in data:
		if bool(q["completed"]):
			completed_count += 1

	if progress_label != null:
		progress_label.text = "PROGRESS: %d / %d UNLOCKED" % [completed_count, data.size()]

	# Fetch Label1..9 under VBoxContainer
	var labels: Array[Label] = []
	for i in range(1, 10):
		var name := "Label%d" % i
		if vbox and vbox.has_node(name):
			labels.append(vbox.get_node(name) as Label)

	# Apply data to labels in pure Black & White
	for i in range(labels.size()):
		var label: Label = labels[i]
		if i < data.size():
			var quest: Dictionary = data[i]
			var completed_flag: bool = bool(quest["completed"])
			label.visible = true
			if completed_flag:
				label.text = "[ ✓ UNLOCKED ]    " + String(quest["text"])
				if _style_unlocked != null:
					label.add_theme_stylebox_override("normal", _style_unlocked)
				label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				label.text = "[ 🔒 LOCKED ]      " + String(quest["text"])
				if _style_locked != null:
					label.add_theme_stylebox_override("normal", _style_locked)
				label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
			print("Updated:", label.name, "->", label.text)
		else:
			label.visible = false
			label.text = ""

	print("--- Achievements Update Complete ---")


func _on_back_button_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
