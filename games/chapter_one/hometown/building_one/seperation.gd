extends Area2D

const REQUIRED_QUEST := "after_book3"
const ACTIVE_QUEST_ID := "separation_methods"

@onready var quest_indicator: Label = $Sprite2D/QuestIndicator

var indicator_tween: Tween
var indicator_base_y: float = 0.0
var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if quest_indicator:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_indicator_state()
	QuestManager.quest_added.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)

func _on_quest_changed(_quest: Quest) -> void:
	_update_indicator_state()

func _update_indicator_state() -> void:
	var latest_quest := QuestManager.get_latest_incomplete_quest()
	if latest_quest != null and latest_quest.id == ACTIVE_QUEST_ID:
		_start_indicator_pulse()
	else:
		_stop_indicator_pulse()

func _start_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()
	if quest_indicator:
		quest_indicator.visible = true
		quest_indicator.position.y = indicator_base_y
		indicator_tween = create_tween().set_loops()
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y - 12.0, 0.45)
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y, 0.45)

func _stop_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()
	if quest_indicator:
		quest_indicator.visible = false
		quest_indicator.position.y = indicator_base_y

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		refresh_interaction_prompt()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			%interact.hide()

func refresh_interaction_prompt() -> void:
	if player_in_range and QuestManager.is_quest_completed(REQUIRED_QUEST):
		InteractionManager.current_interactable = self
		%interact.show()
	else:
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			%interact.hide()

func interact() -> void:
	if not QuestManager.is_quest_completed(REQUIRED_QUEST):
		print("❌ Accuracy & Precision is locked until Separation is completed!")
		return

	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("seperation_spawn")
		print("👉 Spawn set to shooting_spawn from shooting.gd")

	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/Level3/level_3.tscn")
