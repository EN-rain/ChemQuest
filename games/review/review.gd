extends Control

## Review Screen
## Displays 8 puzzle cards representing all Chapter One puzzles.
## Only puzzles completed during gameplay are unlocked.
## Clicking an unlocked card launches that puzzle in Review mode.
## Clicking the Back button returns the player to their exact game state and position.

const FONT_LILITA := "res://assets/LilitaOne-Regular.ttf"
const FONT_ROBOTO := "res://assets/Roboto-BoldCondensed.ttf"
const BACK_ICON_PATH := "res://assets/back.png"

@onready var back_button: Button = %BackButton
@onready var cards_grid: GridContainer = %CardsGrid
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel

var _toast_tween: Tween = null
var _font_lilita: Font = null
var _font_roboto: Font = null


func _ready() -> void:
	if ResourceLoader.exists(FONT_LILITA):
		_font_lilita = load(FONT_LILITA)
	if ResourceLoader.exists(FONT_ROBOTO):
		_font_roboto = load(FONT_ROBOTO)

	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

	if toast_panel != null:
		toast_panel.visible = false
		toast_panel.modulate.a = 0.0

	_populate_cards()


func _on_back_pressed() -> void:
	if has_node("/root/MusicManager"):
		var mm = get_node("/root/MusicManager")
		if mm != null and mm.has_method("play_sfx"):
			mm.play_sfx("button")

	if has_node("/root/ReviewManager"):
		ReviewManager.exit_review_to_game()
	else:
		if has_node("/root/FadeManager"):
			FadeManager.fade_and_change("res://games/chapter_one/hometown/hometown.tscn")
		else:
			get_tree().change_scene_to_file("res://games/chapter_one/hometown/hometown.tscn")


func _populate_cards() -> void:
	if cards_grid == null:
		return

	# Clear existing children if any
	for child in cards_grid.get_children():
		child.queue_free()

	var definitions: Array = ReviewManager.PUZZLE_DEFINITIONS if has_node("/root/ReviewManager") else []

	for def in definitions:
		var is_unlocked: bool = false
		if has_node("/root/ReviewManager"):
			is_unlocked = ReviewManager.is_puzzle_unlocked(def.id)

		var card := _create_card(def, is_unlocked)
		cards_grid.add_child(card)


func _create_card(def: Dictionary, is_unlocked: bool) -> Control:
	var card_btn := Button.new()
	card_btn.custom_minimum_size = Vector2(245, 230)
	card_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	card_btn.focus_mode = Control.FOCUS_NONE

	# Base card styling
	var style_norm := StyleBoxFlat.new()
	style_norm.set_corner_radius_all(14)
	style_norm.content_margin_left = 10
	style_norm.content_margin_top = 10
	style_norm.content_margin_right = 10
	style_norm.content_margin_bottom = 10

	var style_hover := StyleBoxFlat.new()
	style_hover.set_corner_radius_all(14)
	style_hover.content_margin_left = 10
	style_hover.content_margin_top = 10
	style_hover.content_margin_right = 10
	style_hover.content_margin_bottom = 10

	if is_unlocked:
		style_norm.bg_color = Color(0.12, 0.14, 0.20, 0.95)
		style_norm.border_color = Color(0.25, 0.55, 0.85, 0.6)
		style_norm.set_border_width_all(2)

		style_hover.bg_color = Color(0.16, 0.20, 0.30, 0.98)
		style_hover.border_color = Color(0.35, 0.80, 1.0, 1.0)
		style_hover.set_border_width_all(2)
		style_hover.shadow_color = Color(0.1, 0.4, 0.7, 0.4)
		style_hover.shadow_size = 8
	else:
		style_norm.bg_color = Color(0.09, 0.09, 0.11, 0.9)
		style_norm.border_color = Color(0.22, 0.22, 0.26, 0.5)
		style_norm.set_border_width_all(1)

		style_hover.bg_color = Color(0.12, 0.12, 0.14, 0.95)
		style_hover.border_color = Color(0.35, 0.25, 0.28, 0.6)
		style_hover.set_border_width_all(1)

	card_btn.add_theme_stylebox_override("normal", style_norm)
	card_btn.add_theme_stylebox_override("hover", style_hover)
	card_btn.add_theme_stylebox_override("pressed", style_hover)
	card_btn.add_theme_stylebox_override("focus", style_hover)

	# Inner layout
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	card_btn.add_child(vbox)

	# 1. Preview Image container
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(225, 125)
	preview_panel.clip_contents = true
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var preview_style := StyleBoxFlat.new()
	preview_style.set_corner_radius_all(10)
	preview_style.bg_color = Color(0.05, 0.05, 0.07, 1.0)
	preview_panel.add_theme_stylebox_override("panel", preview_style)
	vbox.add_child(preview_panel)

	var preview_tex := TextureRect.new()
	preview_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var img_path: String = def.get("preview", "")
	if ResourceLoader.exists(img_path):
		preview_tex.texture = load(img_path)

	if not is_unlocked:
		preview_tex.modulate = Color(0.3, 0.3, 0.35, 0.6)

	preview_panel.add_child(preview_tex)

	# 2. Lock / Status Overlay
	if not is_unlocked:
		# Dark overlay
		var lock_overlay := ColorRect.new()
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_overlay.color = Color(0.05, 0.05, 0.08, 0.65)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_panel.add_child(lock_overlay)

		# Center lock icon badge
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_panel.add_child(center)

		var lock_pill := PanelContainer.new()
		var lock_pill_style := StyleBoxFlat.new()
		lock_pill_style.set_corner_radius_all(12)
		lock_pill_style.bg_color = Color(0.18, 0.08, 0.10, 0.9)
		lock_pill_style.border_color = Color(0.7, 0.25, 0.30, 0.8)
		lock_pill_style.set_border_width_all(1)
		lock_pill_style.content_margin_left = 12
		lock_pill_style.content_margin_right = 12
		lock_pill_style.content_margin_top = 4
		lock_pill_style.content_margin_bottom = 4
		lock_pill.add_theme_stylebox_override("panel", lock_pill_style)
		center.add_child(lock_pill)

		var lock_lbl := Label.new()
		lock_lbl.text = "LOCKED"
		if _font_roboto != null:
			lock_lbl.add_theme_font_override("font", _font_roboto)
		lock_lbl.add_theme_font_size_override("font_size", 13)
		lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.50))
		lock_pill.add_child(lock_lbl)
	else:
		# Small UNLOCKED badge in top-right
		var badge_margin := MarginContainer.new()
		badge_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge_margin.add_theme_constant_override("margin_top", 6)
		badge_margin.add_theme_constant_override("margin_right", 6)
		badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_panel.add_child(badge_margin)

		var badge_box := HBoxContainer.new()
		badge_box.alignment = BoxContainer.ALIGNMENT_END
		badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_margin.add_child(badge_box)

		var badge_pill := PanelContainer.new()
		var badge_style := StyleBoxFlat.new()
		badge_style.set_corner_radius_all(8)
		badge_style.bg_color = Color(0.08, 0.25, 0.15, 0.85)
		badge_style.border_color = Color(0.2, 0.8, 0.4, 0.7)
		badge_style.set_border_width_all(1)
		badge_style.content_margin_left = 8
		badge_style.content_margin_right = 8
		badge_style.content_margin_top = 2
		badge_style.content_margin_bottom = 2
		badge_pill.add_theme_stylebox_override("panel", badge_style)
		badge_box.add_child(badge_pill)

		var badge_lbl := Label.new()
		badge_lbl.text = "UNLOCKED"
		if _font_roboto != null:
			badge_lbl.add_theme_font_override("font", _font_roboto)
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		badge_pill.add_child(badge_lbl)

	# 3. Puzzle Name Below
	var name_lbl := Label.new()
	name_lbl.text = def.get("name", "Puzzle")
	if _font_lilita != null:
		name_lbl.add_theme_font_override("font", _font_lilita)
	name_lbl.add_theme_font_size_override("font_size", 16)
	if is_unlocked:
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	vbox.add_child(name_lbl)

	# 4. Category / Action Info
	var sub_lbl := Label.new()
	if is_unlocked:
		sub_lbl.text = def.get("category", "") + " • TAP TO PLAY ▶"
		sub_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	else:
		sub_lbl.text = "Story puzzle • Locked"
		sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
	if _font_roboto != null:
		sub_lbl.add_theme_font_override("font", _font_roboto)
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.clip_text = true
	vbox.add_child(sub_lbl)

	# 5. Connect interaction
	card_btn.pressed.connect(func(): _on_card_pressed(def, is_unlocked, card_btn))

	return card_btn


func _on_card_pressed(def: Dictionary, is_unlocked: bool, card_btn: Button) -> void:
	if is_unlocked:
		if has_node("/root/MusicManager"):
			var mm = get_node("/root/MusicManager")
			if mm != null and mm.has_method("play_sfx"):
				mm.play_sfx("button")

		# Micro-animation on click
		var tween := create_tween()
		tween.tween_property(card_btn, "scale", Vector2(0.96, 0.96), 0.08).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card_btn, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD)
		await tween.finished

		var scene_path: String = def.get("scene", "")
		if not scene_path.is_empty() and ResourceLoader.exists(scene_path, "PackedScene"):
			if has_node("/root/ReviewManager"):
				ReviewManager.launch_puzzle(scene_path)
			elif has_node("/root/FadeManager"):
				FadeManager.fade_and_change(scene_path)
			else:
				get_tree().change_scene_to_file(scene_path)
	else:
		# Locked feedback: shake card and show hint toast
		_shake_card(card_btn)
		var hint_text: String = def.get("hint", "Complete this puzzle in Chapter One to unlock review mode!")
		_show_toast("%s: %s" % [def.get("name", "Puzzle"), hint_text])


func _shake_card(node: Control) -> void:
	var original_pos := node.position
	var tween := create_tween()
	tween.tween_property(node, "position:x", original_pos.x - 6, 0.05)
	tween.tween_property(node, "position:x", original_pos.x + 6, 0.05)
	tween.tween_property(node, "position:x", original_pos.x - 4, 0.05)
	tween.tween_property(node, "position:x", original_pos.x + 4, 0.05)
	tween.tween_property(node, "position:x", original_pos.x, 0.05)


func _show_toast(message: String) -> void:
	if toast_panel == null or toast_label == null:
		return

	toast_label.text = message
	toast_panel.visible = true

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)
