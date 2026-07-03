extends Node2D

@onready var quest_manager: Node = get_node("/root/QuestManager")
@onready var vbox := $CanvasLayer/MarginContainer/Control/ScrollContainer/VBoxContainer
@onready var fade_sfx: ColorRect = %FadeSfx
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


func _ready() -> void:
	MusicManager.current_music.volume_db = -10  
	FadeManager.setup(fade_sfx)
	
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
		# ensure QuestManager exists and provides the method
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

	# Debug
	var order: Array[String] = []
	for q in data:
		order.append(String(q["id"]))
	print("Sorted order:", order)

	# Fetch Label1..9 under VBoxContainer
	var labels: Array[Label] = []
	for i in range(1, 10):
		var name := "Label%d" % i
		if vbox and vbox.has_node(name):
			labels.append(vbox.get_node(name) as Label)
		else:
			print("⚠️ Label not found:", name)

	# Apply data to labels
	for i in range(labels.size()):
		var label: Label = labels[i]
		if i < data.size():
			var quest: Dictionary = data[i]
			var completed_flag: bool = bool(quest["completed"])
			if completed_flag:
				label.text = String(quest["text"]) + " – Unlocked"
				label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
			else:
				# Fix (M26): show the actual achievement title when locked,
				# not "Unknown". Players need to see what they haven't unlocked yet.
				label.text = String(quest["text"]) + " – Locked"
				label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			print("Updated:", label.name, "->", label.text)
		else:
			label.text = ""

	print("--- Achievements Update Complete ---")


func _on_back_button_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
