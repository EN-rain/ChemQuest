extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var interact_button: TouchScreenButton = %interact
@onready var quest_indicator: Label = $Sprite2D/QuestIndicator

const ACTIVE_QUEST_ID := "desk_quiz"

var player_in_range: bool = false
var indicator_tween: Tween
var indicator_base_y: float = 0.0

func _ready() -> void:
	FadeManager.setup(fade_sfx)
	interact_button.hide()
	if quest_indicator:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_indicator_state()

	QuestManager.quest_added.connect(_update_interactable)
	QuestManager.quest_completed.connect(_update_interactable)
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

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		refresh_interaction_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
		interact_button.hide()

func _update_interactable(_quest: Quest = null) -> void:
	if not player_in_range:
		return

	#  Desk unlocks only after "after_book2" is completed
	if QuestManager.is_quest_completed("after_book2"):
		InteractionManager.current_interactable = self
		interact_button.show()
	else:
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			interact_button.hide()

func refresh_interaction_prompt() -> void:
	player_in_range = false
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			player_in_range = true
			break

	if not player_in_range:
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			interact_button.hide()
		return

	_update_interactable()

func interact() -> void:
	#  Double-check before interaction
	if not QuestManager.is_quest_completed("after_book2"):
		print("❌ The desk is locked until after Book 2.")
		return

	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("desk_spawn")
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/Level2/Level2.tscn")
