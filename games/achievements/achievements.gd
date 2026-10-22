extends Node2D

@onready var quest_manager: Node = get_node_or_null("/root/QuestManager")
@onready var cards_grid: GridContainer = %CardsGrid
@onready var fade_sfx: ColorRect = %FadeSfx
@onready var progress_label: Label = get_node_or_null("%ProgressLabel")

const FONT_LILITA  := "res://assets/LilitaOne-Regular.ttf"
const FONT_ROBOTO  := "res://assets/Roboto-BoldCondensed.ttf"

var _font_lilita: Font = null
var _font_roboto: Font = null

# Each quest ID maps to a readable custom achievement name
const ACHIEVEMENT_TEXT := {
	"finish_book1":       "Mastered Book I\nThe Nature of Elements",
	"finish_book2":       "Mastered Book II\nThe Art of Creation",
	"finish_book3":       "Mastered Book III\nThe Mystery of Mixtures",
	"density_measurement":"Lesson V\nThe Weight of Matter",
	"states_of_matter":   "Lesson VI\nThe Dance of Matter",
	"accuracy_vs_precision":"Lesson IV\nThe Measure of Truth",
	"separation_methods": "The Table\nof Separation"
}


func _ready() -> void:
	if MusicManager.current_music != null:
		MusicManager.current_music.volume_db = -10
	FadeManager.setup(fade_sfx)

	if ResourceLoader.exists(FONT_LILITA):
		_font_lilita = load(FONT_LILITA)
	if ResourceLoader.exists(FONT_ROBOTO):
		_font_roboto = load(FONT_ROBOTO)

	if not quest_manager:
		push_error("QuestManager not found at /root/QuestManager")
	else:
		if quest_manager.has_signal("quest_added"):
			quest_manager.quest_added.connect(_on_quest_updated)
		if quest_manager.has_signal("quest_completed"):
			quest_manager.quest_completed.connect(_on_quest_updated)
		if quest_manager.has_signal("quest_updated"):
			quest_manager.quest_updated.connect(_on_quest_updated)

	update_achievements()


func _on_quest_updated(_quest = null) -> void:
	update_achievements()


func update_achievements() -> void:
	if cards_grid == null:
		return

	# Clear previous cards
	for child in cards_grid.get_children():
		child.queue_free()

	# Gather + sort data (unlocked first)
	var data: Array[Dictionary] = []
	for id in ACHIEVEMENT_TEXT.keys():
		var completed := false
		if quest_manager and quest_manager.has_method("is_quest_completed"):
			completed = quest_manager.is_quest_completed(id)
		data.append({"id": id, "text": ACHIEVEMENT_TEXT[id], "completed": completed})

	data.sort_custom(func(a, b):
		return int(b["completed"]) - int(a["completed"])
	)

	var completed_count := 0
	for q in data:
		if bool(q["completed"]):
			completed_count += 1

	if progress_label != null:
		progress_label.text = "PROGRESS: %d / %d UNLOCKED" % [completed_count, data.size()]

	# Build a card for each achievement
	for q in data:
		var card := _make_card(q["text"], bool(q["completed"]))
		cards_grid.add_child(card)


func _make_card(display_text: String, is_unlocked: bool) -> PanelContainer:
	# --- Outer card ---
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 120)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.set_corner_radius_all(14)
	card_style.set_border_width_all(0)
	card_style.content_margin_left   = 18
	card_style.content_margin_right  = 18
	card_style.content_margin_top    = 14
	card_style.content_margin_bottom = 14
	if is_unlocked:
		card_style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	else:
		card_style.bg_color = Color(0.07, 0.07, 0.07, 1.0)
	card.add_theme_stylebox_override("panel", card_style)

	# --- Inner VBox ---
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# --- Status badge (UNLOCKED / LOCKED) ---
	var badge := Label.new()
	if is_unlocked:
		badge.text = "✓  UNLOCKED"
		badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		badge.text = "LOCKED"
		badge.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 1.0))
	if _font_roboto != null:
		badge.add_theme_font_override("font", _font_roboto)
	badge.add_theme_font_size_override("font_size", 12)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(badge)

	# --- Achievement name ---
	var name_lbl := Label.new()
	name_lbl.text = display_text
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_lilita != null:
		name_lbl.add_theme_font_override("font", _font_lilita)
	name_lbl.add_theme_font_size_override("font_size", 15)
	if is_unlocked:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	name_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	return card


func _on_back_button_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
