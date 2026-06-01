extends Area2D

@onready var map_panel: Panel = %MapPanel
@onready var indicator: Sprite2D = $Sprite2D
@onready var quest_indicator: Label = $Sprite2D/QuestIndicator

const ACTIVE_QUEST_IDS := ["read_books", "finish_book1", "finish_book2", "finish_book3"]

var indicator_tween: Tween
var indicator_base_y: float = 0.0
var player_in_range: bool = false

func _ready() -> void:
	if quest_indicator:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_indicator_state()
	if not map_panel.visibility_changed.is_connected(_on_map_panel_visibility_changed):
		map_panel.visibility_changed.connect(_on_map_panel_visibility_changed)
	if not QuestManager.quest_added.is_connected(_on_quest_changed):
		QuestManager.quest_added.connect(_on_quest_changed)
	if not QuestManager.quest_completed.is_connected(_on_quest_changed):
		QuestManager.quest_completed.connect(_on_quest_changed)

func _on_quest_changed(_quest: Quest) -> void:
	_update_indicator_state()

func _update_indicator_state() -> void:
	if _has_active_target_quest():
		start_indicator_pulse()
	else:
		stop_indicator_pulse()

func _has_active_target_quest() -> bool:
	var latest_quest := QuestManager.get_latest_incomplete_quest()
	if latest_quest == null:
		return false
	return latest_quest.id in ACTIVE_QUEST_IDS

func start_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()

	if quest_indicator:
		quest_indicator.visible = true
		quest_indicator.position.y = indicator_base_y
		indicator_tween = create_tween().set_loops()
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y - 12.0, 0.45)
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y, 0.45)

func stop_indicator_pulse() -> void:
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
		%interact.hide()

func refresh_interaction_prompt() -> void:
	if player_in_range and QuestManager.is_quest_completed("find_wiz"):
		InteractionManager.current_interactable = self
		if not map_panel.visible:
			%interact.show()
	else:
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			%interact.hide()

func interact() -> void:
	if QuestManager.has_quest("read_books") and not QuestManager.is_quest_completed("read_books"):
		QuestManager.complete_quest("read_books")
		var next_quest = QuestManager.get_quest_template("finish_book1")
		if next_quest:
			QuestManager.add_quest(next_quest)
		%QuestPanel.show_latest_quest()
		_update_indicator_state()

	map_panel.visible = true
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
	%interact.hide()

func _on_map_panel_visibility_changed() -> void:
	if map_panel.visible:
		%interact.hide()
		return

	refresh_interaction_prompt()
