extends CharacterBody2D

@onready var area: Area2D = $Area2D
@onready var dialogue_box: Panel = %DialogueBox
@onready var interact_button: TouchScreenButton = %interact
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var quest_indicator: Label = $AnimatedSprite2D/QuestIndicator

const ACTIVE_QUEST_IDS := [
	"find_christofe",
	"after_density_measurement",
	"after_states_of_matter",
]

var indicator_tween: Tween
var indicator_base_y: float = 0.0

func _ready() -> void:
	anim.play("default")
	if quest_indicator:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_indicator_state()
	if not QuestManager.quest_added.is_connected(_on_quest_changed):
		QuestManager.quest_added.connect(_on_quest_changed)
	if not QuestManager.quest_completed.is_connected(_on_quest_changed):
		QuestManager.quest_completed.connect(_on_quest_changed)

func _on_quest_changed(_quest: Quest) -> void:
	_update_indicator_state()

func _update_indicator_state() -> void:
	if _has_active_target_quest():
		_start_indicator_pulse()
	else:
		_stop_indicator_pulse()

func _has_active_target_quest() -> bool:
	var latest_quest := QuestManager.get_latest_incomplete_quest()
	if latest_quest == null:
		return false
	return latest_quest.id in ACTIVE_QUEST_IDS

func _start_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()
	if not quest_indicator:
		return

	quest_indicator.visible = true
	quest_indicator.position.y = indicator_base_y
	indicator_tween = create_tween().set_loops()
	indicator_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y - 10.0, 0.7)
	indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y, 0.7)

func _stop_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()
	if quest_indicator:
		quest_indicator.visible = false
		quest_indicator.position.y = indicator_base_y

func _on_area_2d_body_entered(body: Node2D) -> void:
	anim.play("default")
	if body.is_in_group("Player"):
		InteractionManager.current_interactable = self

		# Only show interact button if the Accuracy vs Precision quest is completed
		if QuestManager.is_quest_completed("after_accuracy_vs_precision"):
			interact_button.show()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and InteractionManager.current_interactable == self:
		InteractionManager.current_interactable = null
		interact_button.hide()

func interact() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
	interact_button.hide()

	var lines: Array = []

	if QuestManager.has_quest("find_christofe") and not QuestManager.is_quest_completed("find_christofe"):
		lines = DialogueManager.get_dialogue("intro")
	elif QuestManager.has_quest("density_measurement") and not QuestManager.is_quest_completed("density_measurement"):
		lines = DialogueManager.get_dialogue("in_progress")
	elif QuestManager.is_quest_completed("density_measurement") and not QuestManager.has_quest("after_density_measurement"):
		lines = DialogueManager.get_dialogue("after_density")
	elif QuestManager.has_quest("states_of_matter") and not QuestManager.is_quest_completed("states_of_matter"):
		lines = DialogueManager.get_dialogue("in_progress_states")
	elif QuestManager.is_quest_completed("states_of_matter") and not QuestManager.has_quest("after_states_of_matter"):
		lines = DialogueManager.get_dialogue("after_states")
	elif QuestManager.is_quest_completed("after_states_of_matter"):
		lines = DialogueManager.get_dialogue("completed_states")
	else:
		lines = DialogueManager.get_dialogue("completed")

	dialogue_box.start_dialogue(lines)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	if QuestManager.has_quest("find_christofe") and not QuestManager.is_quest_completed("find_christofe"):
		QuestManager.complete_quest("find_christofe")
		var next_quest = QuestManager.get_quest_template("density_measurement")
		if next_quest:
			QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("density_measurement") and not QuestManager.has_quest("after_density_measurement"):
		var next_quest = QuestManager.get_quest_template("after_density_measurement")
		if next_quest:
			QuestManager.add_quest(next_quest)
	elif QuestManager.has_quest("after_density_measurement") and not QuestManager.is_quest_completed("after_density_measurement"):
		QuestManager.complete_quest("after_density_measurement")
		var next_quest = QuestManager.get_quest_template("states_of_matter")
		if next_quest:
			QuestManager.add_quest(next_quest)
		print("States of Matter lesson unlocked!")
	elif QuestManager.is_quest_completed("states_of_matter") and not QuestManager.has_quest("after_states_of_matter"):
		var next_quest = QuestManager.get_quest_template("after_states_of_matter")
		if next_quest:
			QuestManager.add_quest(next_quest)

	_update_indicator_state()

	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = true

	if QuestManager.is_quest_completed("after_accuracy_vs_precision") and area.get_overlapping_bodies().any(func(b): return b.is_in_group("Player")):
		interact_button.show()
