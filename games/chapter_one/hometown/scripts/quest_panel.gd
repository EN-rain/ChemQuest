extends Control

@onready var detail_label: Label = $Label

func _ready() -> void:
	QuestManager.quest_added.connect(_on_quest_added)
	QuestManager.quest_completed.connect(_on_quest_completed)
	show_latest_quest()

# ---------------------------------------------------------
#  Update the quest text in UI
# ---------------------------------------------------------
func update_quest_display(quest: Quest) -> void:
	if quest == null:
		detail_label.text = "No active quest."
		visible = false
		return

	detail_label.text = quest.title + "\n" + quest.description
	visible = true

# ---------------------------------------------------------
#  Find the latest quest that is NOT completed
# ---------------------------------------------------------
func show_latest_quest() -> void:
	if QuestManager.active_quests.size() == 0:
		update_quest_display(null)
		return

	var quests: Array = QuestManager.get_active_quests()
	for quest in quests:
		if not quest.is_completed:
			update_quest_display(quest)
			return

	update_quest_display(null)

# ---------------------------------------------------------
#  React to quest updates
# ---------------------------------------------------------
func _on_quest_completed(_quest: Quest) -> void:
	show_latest_quest()

func _on_quest_added(_quest: Quest) -> void:
	show_latest_quest()
