extends Panel

@onready var map_panel: Panel = %MapPanel
@onready var interact_button: TouchScreenButton = %interact
@onready var fade_sfx: ColorRect = %FadeSfx
@onready var quest_indicator: CanvasItem = get_node_or_null("Frame/QuestIndicator")

@onready var button1: Button = %Button1
@onready var button2: Button = %Button2
@onready var button3: Button = %Button3
@onready var color2: ColorRect = %Button2/ColorRect
@onready var color3: ColorRect = %Button3/ColorRect

var indicator_tween: Tween
var indicator_base_y: float = 0.0

func _ready() -> void:
	FadeManager.setup(fade_sfx)
	if quest_indicator is Control:
		indicator_base_y = quest_indicator.position.y
		quest_indicator.visible = false
	_update_button_lock()
	_update_quest_indicator()

	QuestManager.quest_updated.connect(_update_button_lock)
	QuestManager.quest_updated.connect(_update_quest_indicator)
	QuestManager.quest_added.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)

func _update_button_lock() -> void:
	button1.disabled = false
	button2.disabled = not QuestManager.is_quest_completed("after_book1")
	button3.disabled = not QuestManager.is_quest_completed("after_desk_quiz")

	_update_button_visual(button2, color2)
	_update_button_visual(button3, color3)

func _update_button_visual(button: Button, color_overlay: ColorRect) -> void:
	var texture_rect := button.get_node_or_null("TextureRect")
	var locked_label := button.get_node_or_null("Label")

	if button.disabled:
		if texture_rect:
			texture_rect.modulate.a = 0.5
		if locked_label:
			locked_label.visible = true

		color_overlay.show()
		button.visible = true
	else:
		if texture_rect:
			texture_rect.modulate.a = 1.0
		if locked_label:
			locked_label.visible = false

		color_overlay.hide()
		button.visible = true

func _on_quest_changed(_quest: Quest) -> void:
	_update_quest_indicator()

func _update_quest_indicator() -> void:
	if not quest_indicator:
		return

	var should_show := QuestManager.has_quest("find_wiz") and not QuestManager.is_quest_completed("find_wiz")
	if should_show:
		_start_indicator_pulse()
	else:
		_stop_indicator_pulse()

func _start_indicator_pulse() -> void:
	if not quest_indicator:
		return
	if indicator_tween:
		indicator_tween.kill()

	quest_indicator.visible = true
	if quest_indicator is Control:
		quest_indicator.position.y = indicator_base_y

	indicator_tween = create_tween().set_loops()
	indicator_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if quest_indicator is Control:
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y - 10.0, 0.7)
		indicator_tween.tween_property(quest_indicator, "position:y", indicator_base_y, 0.7)

func _stop_indicator_pulse() -> void:
	if indicator_tween:
		indicator_tween.kill()
		indicator_tween = null
	if quest_indicator:
		quest_indicator.visible = false
		if quest_indicator is Control:
			quest_indicator.position.y = indicator_base_y

# --- Map buttons ---
func _on_button_1_pressed() -> void:
	MusicManager.stop_music()
	MusicManager.play_music_by_id("button")
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("map_spawn")
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/Level1/Lesson1/lesson_one.tscn")

func _on_button_2_pressed() -> void:
	MusicManager.play_music_by_id("button")
	if button2.disabled:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("map_spawn")
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/Level1/Lesson2/lesson_two.tscn")

func _on_button_3_pressed() -> void:
	MusicManager.play_music_by_id("button")
	if button3.disabled:
		return
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.can_move = false
		SpawnManager.set_spawn("map_spawn")
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn")

# --- Back button ---
func _on_back_pressed() -> void:
	map_panel.visible = false
	var player = get_tree().get_first_node_in_group("Player")
	player.can_move = true
	call_deferred("_refresh_level_interactions")
	_update_button_lock()
	_update_quest_indicator()

# --- Always refresh when panel visibility changes ---
func _on_visibility_changed() -> void:
	if visible:
		interact_button.hide()
		_update_button_lock()
	else:
		call_deferred("_refresh_level_interactions")
	_update_quest_indicator()

func _refresh_level_interactions() -> void:
	await get_tree().physics_frame
	for path in [
		"../../World/Furnitures/LevelOne",
		"../../World/Furnitures/LevelTwo",
		"../../World/Furnitures/LevelThree",
		"../../World/Furnitures/LevelFour",
	]:
		var level := get_node_or_null(path)
		if level != null and level.has_method("refresh_interaction_prompt"):
			level.refresh_interaction_prompt()
