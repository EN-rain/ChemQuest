extends Area2D

@onready var game_panel: Panel = %GamePanel
@onready var interact_button: TouchScreenButton = %interact
@onready var quest_indicator: Label = $Sprite2D/QuestIndicator

# Required quests
const REQUIRED_QUEST := "find_christofe"
const UNLOCK_STATES_QUEST := "after_density_measurement"
const ACTIVE_QUEST_IDS := ["density_measurement", "states_of_matter"]

var indicator_tween: Tween
var indicator_base_y: float = 0.0
var player_in_range: bool = false

func _ready() -> void:
	if quest_indicator:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_indicator_state()
	if not game_panel.visibility_changed.is_connected(_on_game_panel_visibility_changed):
		game_panel.visibility_changed.connect(_on_game_panel_visibility_changed)
	if not QuestManager.quest_added.is_connected(_on_quest_changed):
		QuestManager.quest_added.connect(_on_quest_changed)
	if not QuestManager.quest_completed.is_connected(_on_quest_changed):
		QuestManager.quest_completed.connect(_on_quest_changed)

func _on_quest_changed(_quest: Quest) -> void:
	_update_indicator_state()

func _update_indicator_state() -> void:
	var latest_quest := QuestManager.get_latest_incomplete_quest()
	if latest_quest != null and latest_quest.id in ACTIVE_QUEST_IDS:
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
		indicator_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
			interact_button.hide()

func interact() -> void:
	MusicManager.play_music_by_id("arcade")
	if not _can_interact():
		return

	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("game_spawn")

	game_panel.show()
	_update_indicator_state()

func refresh_interaction_prompt() -> void:
	if player_in_range and _can_interact():
		InteractionManager.current_interactable = self
		if not game_panel.visible:
			interact_button.show()
	else:
		if InteractionManager.current_interactable == self:
			InteractionManager.current_interactable = null
			interact_button.hide()

func _on_game_panel_visibility_changed() -> void:
	if game_panel.visible:
		interact_button.hide()
		return

	refresh_interaction_prompt()

# --- Helper function ---
func _can_interact() -> bool:
	# Show interact if Density quest is complete (after_density_measurement)
	# OR if find_christofe is complete (original condition)
	return (
		QuestManager.is_quest_completed(REQUIRED_QUEST)
		or QuestManager.is_quest_completed(UNLOCK_STATES_QUEST)
	)
