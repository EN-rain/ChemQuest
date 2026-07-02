extends Panel

@onready var level_1_button: Button = $VBoxContainer/Level1
@onready var level_2_button: Button = $VBoxContainer/Level2
@onready var level_3_button: Button = $VBoxContainer/Level3
@onready var fade_sfx: ColorRect = %FadeSfx
@onready var dense_panel: Panel = %DensePanel

func _ready() -> void:
	$ColorRect/AnimatedSprite2D.play("default")
	FadeManager.setup(fade_sfx)
	_update_density_levels()

	if not QuestManager.quest_updated.is_connected(_update_density_levels):
		QuestManager.quest_updated.connect(_update_density_levels)


# ---------------------------------------------------------
# 🔹 Update button unlock/visual states
# ---------------------------------------------------------
func _update_density_levels() -> void:
	var progress := QuestManager.density_progress

	# Reset all buttons first
	_lock_button(level_1_button)
	_lock_button(level_2_button)
	_lock_button(level_3_button)

	# ✅ Unlock based on progress
	match progress:
		0:
			_unlock_button(level_1_button)
		1:
			_unlock_button(level_1_button)
			_unlock_button(level_2_button)
		2:
			_unlock_button(level_1_button)
			_unlock_button(level_2_button)
			_unlock_button(level_3_button)
		_:
			_unlock_button(level_1_button)
			_unlock_button(level_2_button)
			_unlock_button(level_3_button)


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
		"res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level 1/level_1.tscn"
	)
	_update_density_levels()

func _on_level_2_pressed() -> void:
	MusicManager.stop_music()
	await FadeManager.fade_and_change(
		"res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_2.tscn"
	)
	_update_density_levels()

func _on_level_3_pressed() -> void:
	MusicManager.stop_music()
	await FadeManager.fade_and_change(
		"res://games/chapter_one/hometown/building_two/Level2-1/Scenes/level_3.tscn"
	)
	_update_density_levels()


# ---------------------------------------------------------
# 🔹 Back button behavior
# ---------------------------------------------------------
func _on_back_button_pressed() -> void:
	dense_panel.hide()
