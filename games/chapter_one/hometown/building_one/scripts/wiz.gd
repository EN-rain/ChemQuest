extends CharacterBody2D

@onready var area: Area2D = $Area2D
@onready var dialogue_box: Panel = %DialogueBox
@onready var interact_button: TouchScreenButton = %interact
@onready var quest_indicator: Label = $AnimatedSprite2D/QuestIndicator

const ACTIVE_QUEST_IDS := [
	"find_wiz",
	"after_book1",
	"after_book2",
	"after_desk_quiz",
	"after_book3",
	"separation_methods_after",
	"after_accuracy_vs_precision",
]

var indicator_tween: Tween
var indicator_base_y: float = 0.0

func _ready() -> void:
	$AnimatedSprite2D.play("default")
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
	if body.is_in_group("Player"):
		InteractionManager.current_interactable = self
		if not dialogue_box.visible:
			interact_button.show()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
		interact_button.hide()

func interact() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false

	interact_button.hide()

	var lines: Array = []

	if QuestManager.has_quest("find_wiz") and not QuestManager.is_quest_completed("find_wiz"):
		lines = DialogueManager.get_dialogue("wiz_intro")
	elif QuestManager.is_quest_completed("find_wiz") and not QuestManager.has_quest("read_books"):
		lines = DialogueManager.get_dialogue("wiz_books_intro")
	elif QuestManager.is_quest_completed("finish_book1") and not QuestManager.is_quest_completed("after_book1"):
		lines = DialogueManager.get_dialogue("wiz_return_after_book1")
	elif QuestManager.is_quest_completed("finish_book2") and not QuestManager.is_quest_completed("after_book2"):
		lines = DialogueManager.get_dialogue("wiz_return_after_book2")
	elif QuestManager.is_quest_completed("desk_quiz") and not QuestManager.is_quest_completed("after_desk_quiz"):
		lines = DialogueManager.get_dialogue("wiz_return_after_desk")
	elif QuestManager.is_quest_completed("finish_book3") and not QuestManager.is_quest_completed("after_book3"):
		lines = DialogueManager.get_dialogue("wiz_return_after_book3")
	elif QuestManager.is_quest_completed("separation_methods") and not QuestManager.is_quest_completed("separation_methods_after"):
		lines = DialogueManager.get_dialogue("wiz_return_after_separation")
	elif QuestManager.is_quest_completed("accuracy_vs_precision") and not QuestManager.is_quest_completed("after_accuracy_vs_precision"):
		lines = DialogueManager.get_dialogue("wiz_return_after_accuracy")
	else:
		lines = DialogueManager.get_dialogue("wiz_after")

	dialogue_box.start_dialogue(lines, "wiz")
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)


func _on_dialogue_finished() -> void:
	if QuestManager.has_quest("find_wiz") and not QuestManager.is_quest_completed("find_wiz"):
		QuestManager.complete_quest("find_wiz")
		var next_quest = QuestManager.get_quest_template("read_books")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("finish_book1") and not QuestManager.is_quest_completed("after_book1"):
		QuestManager.complete_quest("after_book1")
		var next_quest = QuestManager.get_quest_template("finish_book2")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("finish_book2") and not QuestManager.is_quest_completed("after_book2"):
		QuestManager.complete_quest("after_book2")
		var next_quest = QuestManager.get_quest_template("desk_quiz")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("desk_quiz") and not QuestManager.is_quest_completed("after_desk_quiz"):
		QuestManager.complete_quest("after_desk_quiz")
		var next_quest = QuestManager.get_quest_template("finish_book3")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("finish_book3") and not QuestManager.is_quest_completed("after_book3"):
		QuestManager.complete_quest("after_book3")
		var next_quest = QuestManager.get_quest_template("separation_methods")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("separation_methods") and not QuestManager.is_quest_completed("separation_methods_after"):
		QuestManager.complete_quest("separation_methods_after")
		var next_quest = QuestManager.get_quest_template("accuracy_vs_precision")
		if next_quest: QuestManager.add_quest(next_quest)
	elif QuestManager.is_quest_completed("accuracy_vs_precision") and not QuestManager.is_quest_completed("after_accuracy_vs_precision"):
		QuestManager.complete_quest("after_accuracy_vs_precision")
		var next_quest = QuestManager.get_quest_template("find_christofe")
		if next_quest: QuestManager.add_quest(next_quest)

	_update_indicator_state()

	var player = get_tree().get_first_node_in_group("Player")
	if player: player.can_move = true

	if area.get_overlapping_bodies().any(func(b): return b.is_in_group("Player")):
		interact_button.show()
