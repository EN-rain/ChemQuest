extends Control

signal screen_pressed

const GUIDE_ID := "hometown_controls_tutorial"
const TALK_SOUND_PATH := "res://games/global/music/talk.mp3"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"

# Legacy compatibility constants
const TUTORIAL_ANIMATION := "tutorial_anim"
const FIRST_STOP := 1.0
const SECOND_STOP := 2.0
const FIRST_TEXT := "Use these controls to move, and double tap any direction to run."
const SECOND_TEXT := "Follow this quest to progress"

var _current_step := 0
var _total_steps := 3
var _is_active := false
var _is_animating := false

# Dynamic spotlight rects
var _target_rect := Rect2()
var _current_target_rect := Rect2()
var _pulse_timer := 0.0

# UI Controls created dynamically
var _card: PanelContainer
var _header_label: Label
var _step_badge: Label
var _skip_button: Button
var _headline_label: Label
var _body_label: Label
var _dots_label: Label
var _prompt_label: Label
var _sfx_player: AudioStreamPlayer

var _steps_data := [
	{
		"badge": "STEP 1 OF 3",
		"headline": "Moving Your Character",
		"text": "• Touch Controls: Tap or drag the direction buttons to walk. Double-tap any direction to run!\n• Keyboard: Use W, A, S, D or Arrow Keys to move. Hold Shift or double-tap to sprint.",
		"target": "buttons"
	},
	{
		"badge": "STEP 2 OF 3",
		"headline": "Quest Tracker",
		"text": "• The Quest Banner at the top displays your active objective.\n• Your initial task is to locate the wizard inside Building One.",
		"target": "quest"
	},
	{
		"badge": "STEP 3 OF 3",
		"headline": "Guidance Arrow",
		"text": "• A blue navigation arrow orbits your character to guide your path.\n• Follow the arrow's direction to easily find Building One and begin your journey!",
		"target": "player"
	}
]


func _ready() -> void:
	visible = false

	# Hide legacy placeholder children if present
	var legacy_panel := get_node_or_null("Panel")
	if legacy_panel != null:
		var showcase := legacy_panel.get_node_or_null("ShowCase")
		if showcase != null:
			showcase.visible = false
		var lbl := legacy_panel.get_node_or_null("Label")
		if lbl != null:
			lbl.visible = false

	if has_node("/root/GuideManager") and GuideManager.has_seen(GUIDE_ID):
		return

	# Setup modern UI and activate
	_setup_audio()
	_setup_ui()
	_start_tutorial()


func _setup_audio() -> void:
	if ResourceLoader.exists(TALK_SOUND_PATH):
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.stream = load(TALK_SOUND_PATH)
		_sfx_player.bus = "Master"
		_sfx_player.volume_db = -6.0
		add_child(_sfx_player)


func _play_sfx(pitch: float = 1.0) -> void:
	if _sfx_player != null and _sfx_player.stream != null:
		_sfx_player.pitch_scale = pitch
		_sfx_player.play()


func _setup_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH)

	# Main Tutorial Card Container
	_card = PanelContainer.new()
	_card.name = "TutorialCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.custom_minimum_size = Vector2(480, 220)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.11, 0.18, 0.95)
	card_style.border_color = Color(0.28, 0.78, 1.0, 0.85)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(14)
	card_style.shadow_color = Color(0, 0, 0, 0.55)
	card_style.shadow_size = 10
	card_style.content_margin_left = 22
	card_style.content_margin_right = 22
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	_card.add_theme_stylebox_override("panel", card_style)
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_card.add_child(vbox)

	# Header Row (Title, Step Badge, Skip Button)
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	_header_label = Label.new()
	_header_label.text = "🧭 EXPLORATION GUIDE"
	if font != null:
		_header_label.add_theme_font_override("font", font)
	_header_label.add_theme_font_size_override("font_size", 19)
	_header_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	header_hbox.add_child(_header_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	_step_badge = Label.new()
	_step_badge.text = "STEP 1 OF 3"
	if font != null:
		_step_badge.add_theme_font_override("font", font)
	_step_badge.add_theme_font_size_override("font_size", 14)
	_step_badge.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.75))
	header_hbox.add_child(_step_badge)

	var badge_spacer := Control.new()
	badge_spacer.custom_minimum_size = Vector2(12, 0)
	header_hbox.add_child(badge_spacer)

	_skip_button = Button.new()
	_skip_button.text = "SKIP ❯❯"
	_skip_button.flat = true
	if font != null:
		_skip_button.add_theme_font_override("font", font)
	_skip_button.add_theme_font_size_override("font_size", 13)
	_skip_button.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.7))
	_skip_button.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.6))
	_skip_button.pressed.connect(_on_skip_pressed)
	header_hbox.add_child(_skip_button)

	# Separator line
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.28, 0.78, 1.0, 0.25)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Headline
	_headline_label = Label.new()
	if font != null:
		_headline_label.add_theme_font_override("font", font)
	_headline_label.add_theme_font_size_override("font_size", 21)
	_headline_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.52))
	vbox.add_child(_headline_label)

	# Body text
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 15)
	_body_label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_label)

	# Footer Row
	var footer_hbox := HBoxContainer.new()
	vbox.add_child(footer_hbox)

	_dots_label = Label.new()
	_dots_label.text = "● ○ ○"
	_dots_label.add_theme_font_size_override("font_size", 16)
	_dots_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	footer_hbox.add_child(_dots_label)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.add_child(footer_spacer)

	_prompt_label = Label.new()
	_prompt_label.text = "▶ Tap anywhere or press Space to continue"
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 0.85))
	footer_hbox.add_child(_prompt_label)


func _start_tutorial() -> void:
	visible = true
	_is_active = true
	_current_step = 0
	if has_node("/root/GuideManager"):
		GuideManager.mark_seen(GUIDE_ID)
	_show_step_index(0, true)


func _process(delta: float) -> void:
	if not visible or not _is_active:
		return
	_pulse_timer += delta * 4.0
	queue_redraw()

	if _prompt_label != null:
		var alpha := 0.55 + 0.45 * sin(_pulse_timer)
		_prompt_label.modulate.a = alpha


func _draw() -> void:
	if not visible or not _is_active:
		return

	var vp_size := get_viewport_rect().size
	var overlay_color := Color(0.03, 0.05, 0.10, 0.72)

	if _current_target_rect.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, vp_size), overlay_color)
		return

	var t := _current_target_rect.grow(10.0)
	var x0 := 0.0
	var y0 := 0.0
	var x1 := clampf(t.position.x, 0.0, vp_size.x)
	var y1 := clampf(t.position.y, 0.0, vp_size.y)
	var x2 := clampf(t.end.x, 0.0, vp_size.x)
	var y2 := clampf(t.end.y, 0.0, vp_size.y)
	var x3 := vp_size.x
	var y3 := vp_size.y

	# Top band
	if y1 > y0:
		draw_rect(Rect2(x0, y0, x3 - x0, y1 - y0), overlay_color)
	# Bottom band
	if y3 > y2:
		draw_rect(Rect2(x0, y2, x3 - x0, y3 - y2), overlay_color)
	# Left block between y1 and y2
	if x1 > x0 and y2 > y1:
		draw_rect(Rect2(x0, y1, x1 - x0, y2 - y1), overlay_color)
	# Right block between y1 and y2
	if x3 > x2 and y2 > y1:
		draw_rect(Rect2(x2, y1, x3 - x2, y2 - y1), overlay_color)

	# Glowing highlight box around the active feature
	var pulse := 0.75 + 0.25 * sin(_pulse_timer)
	var border_color := Color(0.28, 0.78, 1.0, 0.95 * pulse)
	draw_rect(t, border_color, false, 3.0)
	draw_rect(t.grow(3.0), Color(0.28, 0.78, 1.0, 0.3 * pulse), false, 2.0)


func _show_step_index(idx: int, immediate: bool = false) -> void:
	if idx < 0 or idx >= _steps_data.size():
		_finish_tutorial()
		return

	_current_step = idx
	_is_animating = true
	_play_sfx(1.0 + idx * 0.1)

	var data: Dictionary = _steps_data[idx]
	_step_badge.text = data["badge"]
	_headline_label.text = data["headline"]
	_body_label.text = data["text"]

	# Update step dots
	var dots := ""
	for i in range(_total_steps):
		dots += "● " if i == idx else "○ "
	_dots_label.text = dots.strip_edges()

	# Resolve target highlight rect and card position
	var vp_size := get_viewport_rect().size
	var target_rect := _calculate_target_rect(data["target"], vp_size)
	var card_target_pos := _calculate_card_position(data["target"], vp_size)

	if immediate:
		_target_rect = target_rect
		_current_target_rect = target_rect
		_card.position = card_target_pos
		_card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_card, "modulate:a", 1.0, 0.25)
		_is_animating = false
	else:
		_target_rect = target_rect
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "_current_target_rect", target_rect, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_card, "position", card_target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_card, "modulate:a", 1.0, 0.2)
		tween.chain().tween_callback(func(): _is_animating = false)


func _calculate_target_rect(target_type: String, vp_size: Vector2) -> Rect2:
	match target_type:
		"buttons":
			var buttons_node: Control = get_node_or_null("../Buttons") as Control
			if buttons_node != null:
				var min_pos := Vector2(100000, 100000)
				var max_pos := Vector2(-100000, -100000)
				for child in buttons_node.get_children():
					if child is TouchScreenButton and child.visible:
						var p: Vector2 = child.global_position
						var sz: Vector2 = Vector2(16, 16) * child.scale.abs()
						if child.texture_normal != null:
							sz = child.texture_normal.get_size() * child.scale.abs()
						min_pos.x = minf(min_pos.x, p.x)
						min_pos.y = minf(min_pos.y, p.y)
						max_pos.x = maxf(max_pos.x, p.x + sz.x)
						max_pos.y = maxf(max_pos.y, p.y + sz.y)
				if min_pos.x < max_pos.x and min_pos.y < max_pos.y:
					return Rect2(min_pos, max_pos - min_pos)
			return Rect2(Vector2(20, vp_size.y - 440), Vector2(340, 360))

		"quest":
			var quest_node: Control = get_node_or_null("../QuestPanel") as Control
			if quest_node != null:
				var r: Rect2 = quest_node.get_global_rect()
				if r.size.x > 0 and r.size.y > 0:
					return r
			return Rect2(Vector2(vp_size.x * 0.5 - 200, 20), Vector2(400, 90))

		"player":
			var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
			if player == null:
				player = get_node_or_null("../../World/Player") as Node2D
			if player != null:
				var p_screen: Vector2 = player.get_global_transform_with_canvas().origin
				return Rect2(p_screen - Vector2(75, 75), Vector2(150, 150))
			return Rect2(vp_size * 0.5 - Vector2(75, 75), Vector2(150, 150))

	return Rect2()


func _calculate_card_position(target_type: String, vp_size: Vector2) -> Vector2:
	var card_sz := _card.size if _card != null else Vector2(480, 220)
	if card_sz.x <= 0 or card_sz.y <= 0:
		card_sz = Vector2(480, 220)

	match target_type:
		"buttons":
			# Position card in center-right so bottom-left buttons are completely unobstructed
			var x := clampf(vp_size.x * 0.55 - card_sz.x * 0.5 + 40, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.55 - card_sz.y * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"quest":
			# Position card in center below top quest banner
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.35, 120.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"player":
			# Position card in lower area below the center player
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y - card_sz.y - 36.0, 20.0, vp_size.y - card_sz.y - 20.0)
			return Vector2(x, y)

	return (vp_size - card_sz) * 0.5


func _next_step() -> void:
	if _is_animating:
		return
	if _current_step + 1 < _total_steps:
		_show_step_index(_current_step + 1)
	else:
		_finish_tutorial()


func _finish_tutorial() -> void:
	if not _is_active:
		return
	_is_active = false
	_play_sfx(1.4)
	screen_pressed.emit()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _on_skip_pressed() -> void:
	_finish_tutorial()


func _input(event: InputEvent) -> void:
	if not visible or not _is_active:
		return

	# Advance on click or touch
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		# If user clicked the skip button specifically, let button handler handle it
		if _skip_button != null and _skip_button.get_global_rect().has_point(event.position):
			return
		_next_step()
		get_viewport().set_input_as_handled()
		return

	# Advance on Space or Enter; Skip on Escape
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_next_step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
