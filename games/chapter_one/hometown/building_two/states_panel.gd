extends Panel

@onready var level_1: Button = $VBoxContainer/Level1
@onready var level_2: Button = $VBoxContainer/Level2
@onready var level_3: Button = $VBoxContainer/Level3
@onready var states_panel: Panel = %StatesPanel

func _ready() -> void:
	$ColorRect/AnimatedSprite2D.play("default")
	_update_states_levels()

	if not QuestManager.quest_updated.is_connected(_update_states_levels):
		QuestManager.quest_updated.connect(_update_states_levels)


# ---------------------------------------------------------
# 🔹 Update button unlock/visual states
# ---------------------------------------------------------
func _update_states_levels() -> void:
	var progress := QuestManager.states_progress

	_lock_button(level_1)
	_lock_button(level_2)
	_lock_button(level_3)

	match progress:
		0:
			_unlock_button(level_1)
		1:
			_unlock_button(level_1)
			_unlock_button(level_2)
		2:
			_unlock_button(level_1)
			_unlock_button(level_2)
			_unlock_button(level_3)
		_:
			_unlock_button(level_1)
			_unlock_button(level_2)
			_unlock_button(level_3)


# ---------------------------------------------------------
# 🔹 Button visuals
# ---------------------------------------------------------
func _lock_button(btn: Button) -> void:
	btn.disabled = true
	btn.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _unlock_button(btn: Button) -> void:
	btn.disabled = false
	btn.modulate = Color(1, 1, 1, 1)


# ---------------------------------------------------------
# 🔹 Level transitions
# ---------------------------------------------------------
func _on_level_1_pressed() -> void:
	MusicManager.stop_music()
	await FadeManager.fade_and_change(
		"res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/Scenes/level_1.tscn"
	)
	QuestManager.advance_states_level(1)  # ✅ pass level number
	_update_states_levels()

func _on_level_2_pressed() -> void:
	MusicManager.stop_music()
	await FadeManager.fade_and_change(
		"res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/Scenes/level_2.tscn"
	)
	QuestManager.advance_states_level(2)  # ✅ pass level number
	_update_states_levels()

func _on_level_3_pressed() -> void:
	MusicManager.stop_music()
	await FadeManager.fade_and_change(
		"res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/Scenes/level_3.tscn"
	)
	QuestManager.advance_states_level(3)  # ✅ pass level number
	_update_states_levels()


# ---------------------------------------------------------
# 🔹 Back button behavior
# ---------------------------------------------------------
func _on_back_button_pressed() -> void:
	states_panel.hide()
