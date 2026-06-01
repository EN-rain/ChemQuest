extends Control

@onready var score_label: Label = %ScoreLabel
@onready var continue_button: Button = $Continue

var current_score: int = 0
var max_score: int = 10

func _ready() -> void:
	visible = false

func show_with_score(new_score: int, new_max: int) -> void:
	current_score = new_score
	max_score = new_max
	score_label.text = "%d/%d" % [current_score, max_score]
	visible = true

func _on_continue_pressed() -> void:
	Scoring.update_best_score("game5", current_score)
	if current_score >= 8:
		Scoring.unlock_level("game6")

	# ✅ Complete the Accuracy vs Precision quest dynamically
	var acc_id := "accuracy_vs_precision"
	if QuestManager.has_quest(acc_id) and not QuestManager.is_quest_completed(acc_id):
		QuestManager.complete_quest(acc_id)

	# ✅ Add the "after" quest directly from quest.json data
	var after_id := "after_accuracy_vs_precision"
	if not QuestManager.has_quest(after_id):
		# Pull quest data from QuestManager.active_quests (loaded from quest.json)
		if QuestManager.active_quests.has(after_id):
			QuestManager.add_quest(QuestManager.active_quests[after_id])
		else:
			push_warning("⚠ Quest id '%s' not found in quest.json" % after_id)

	Scoring.reset_precision_accuracy_score()
	get_tree().change_scene_to_file("res://games/chapter_one/hometown/building_one/building_one.tscn")
