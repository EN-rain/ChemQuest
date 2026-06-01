extends Panel

@onready var dense_button: Button = $DenseButton
@onready var states_button: Button = $StatesButton
@onready var dense_panel: Panel = $DensePanel
@onready var states_panel: Panel = $StatesPanel

func _ready() -> void:
	MusicManager.play_music_by_id("arcade")
	$DenseButton/AnimatedSprite2D.play("default")
	$StatesButton/AnimatedSprite2D.play("default")
	_hide_all_panels()
	_update_button_states()

	# Connect buttons
	dense_button.pressed.connect(_on_dense_button_pressed)
	states_button.pressed.connect(_on_states_button_pressed)

	# Update dynamically when quests change
	if not QuestManager.quest_updated.is_connected(_update_button_states):
		QuestManager.quest_updated.connect(_update_button_states)

# --- Button logic ---
func _on_dense_button_pressed() -> void:
	_hide_all_panels()
	dense_panel.show()

func _on_states_button_pressed() -> void:
	if states_button.disabled:
		print("🔒 States lesson locked — finish the Density quest first.")
		return
	_hide_all_panels()
	states_panel.show()

# --- Panel + Button updates ---
func _hide_all_panels() -> void:
	dense_panel.hide()
	states_panel.hide()

func _update_button_states(_quest: Quest = null) -> void:
	var density_completed := QuestManager.is_quest_completed("after_density_measurement")
	_unlock_button(dense_button)
	if density_completed:
		_unlock_button(states_button)
	else:
		_lock_button(states_button)

func _lock_button(btn: Button) -> void:
	btn.disabled = true
	btn.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _unlock_button(btn: Button) -> void:
	btn.disabled = false
	btn.modulate = Color(1, 1, 1, 1)

# --- Back button ---
func _on_back_button_pressed() -> void:
	%GamePanel.hide()
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = true
	
	MusicManager.play_music_by_id("house")
	var game := get_node_or_null("../../World/Furnitures/Game")
	if game != null and game.has_method("refresh_interaction_prompt"):
		game.refresh_interaction_prompt()
