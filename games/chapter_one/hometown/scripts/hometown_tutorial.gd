extends Control

signal screen_pressed

const GUIDE_ID := "hometown_controls_tutorial"
const TALK_SOUND_PATH := "res://games/global/music/talk.mp3"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"

# Legacy compatibility constants
const TUTORIAL_ANIMATION := "tutorial_anim"
const FIRST_STOP := 1.0
const SECOND_STOP := 2.0

var _current_step := 0
var _total_steps := 2
var _is_active := false
var _is_animating := false
var _pulse_timer := 0.0

# Spotlight Shader Overlay
var _spotlight_overlay: ColorRect
var _spotlight_material: ShaderMaterial
var _current_spot_rect := Vector4.ZERO

# UI Controls created dynamically
var _card: PanelContainer
var _header_label: Label
var _step_badge: Label
var _skip_button: Button
var _headline_label: Label
var _body_label: Label
var _prompt_label: Label
var _sfx_player: AudioStreamPlayer

var _steps_data := [
	{
		"badge": "STEP 1 OF 2",
		"headline": "Moving Your Character",
		"text": "• Tap or hold the direction buttons to move.\n• Double-tap any direction to run!",
		"target": "buttons"
	},
	{
		"badge": "STEP 2 OF 2",
		"headline": "Quest Tracker",
		"text": "• The Quest Banner at the top displays your active objective.\n• Follow the quest instructions to progress through the story!",
		"target": "quest"
	}
]


func _ready() -> void:
	visible = false

	# Hide legacy polygon/label if present
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

	# Setup modern spotlight shader and monochrome card UI
	_setup_audio()
	_setup_spotlight_overlay()
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


func _setup_spotlight_overlay() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 target_rect;
uniform float corner_radius = 16.0;
uniform float feather = 8.0;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.65);

float rounded_box_sdf(vec2 center_pos, vec2 half_size, float radius) {
    vec2 d = abs(center_pos) - half_size + vec2(radius);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

void fragment() {
    vec2 center = target_rect.xy + target_rect.zw * 0.5;
    vec2 half_size = target_rect.zw * 0.5;
    float dist = rounded_box_sdf(FRAGCOORD.xy - center, half_size, corner_radius);
    float alpha = smoothstep(-feather, feather, dist);
    COLOR = vec4(dim_color.rgb, dim_color.a * alpha);
}
"""
	_spotlight_material = ShaderMaterial.new()
	_spotlight_material.shader = shader
	_spotlight_material.set_shader_parameter("corner_radius", 18.0)
	_spotlight_material.set_shader_parameter("feather", 8.0)
	_spotlight_material.set_shader_parameter("dim_color", Color(0.0, 0.0, 0.0, 0.65))

	_spotlight_overlay = ColorRect.new()
	_spotlight_overlay.name = "SpotlightOverlay"
	_spotlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_spotlight_overlay.anchor_right = 1.0
	_spotlight_overlay.anchor_bottom = 1.0
	_spotlight_overlay.material = _spotlight_material
	add_child(_spotlight_overlay)


func _setup_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH)

	# Main Tutorial Card Container (Pure Black & White, No Borders)
	_card = PanelContainer.new()
	_card.name = "TutorialCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.custom_minimum_size = Vector2(480, 200)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	card_style.set_border_width_all(0)
	card_style.set_corner_radius_all(14)
	card_style.shadow_color = Color(0, 0, 0, 0.65)
	card_style.shadow_size = 12
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	_card.add_theme_stylebox_override("panel", card_style)
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_card.add_child(vbox)

	# Header Row (Title: "TUTORIAL", Step Badge, Skip Button)
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	_header_label = Label.new()
	_header_label.text = "TUTORIAL"
	if font != null:
		_header_label.add_theme_font_override("font", font)
	_header_label.add_theme_font_size_override("font_size", 19)
	_header_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	header_hbox.add_child(_header_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	_step_badge = Label.new()
	_step_badge.text = "STEP 1 OF 2"
	if font != null:
		_step_badge.add_theme_font_override("font", font)
	_step_badge.add_theme_font_size_override("font_size", 14)
	_step_badge.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
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
	_skip_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_skip_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	_skip_button.pressed.connect(_on_skip_pressed)
	header_hbox.add_child(_skip_button)

	# Separator line
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(1.0, 1.0, 1.0, 0.15)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Headline
	_headline_label = Label.new()
	if font != null:
		_headline_label.add_theme_font_override("font", font)
	_headline_label.add_theme_font_size_override("font_size", 21)
	_headline_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(_headline_label)

	# Body text
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 15)
	_body_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_label)

	# Footer Row (Mobile prompt)
	var footer_hbox := HBoxContainer.new()
	vbox.add_child(footer_hbox)

	_prompt_label = Label.new()
	_prompt_label.text = "▶ Tap anywhere to continue"
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	if _prompt_label != null:
		var alpha := 0.55 + 0.45 * sin(_pulse_timer)
		_prompt_label.modulate.a = alpha


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

	var vp_size := get_viewport_rect().size
	var target_box := _calculate_target_box(data["target"], vp_size)
	var card_target_pos := _calculate_card_position(data["target"], vp_size)

	if immediate:
		_current_spot_rect = target_box
		if _spotlight_material != null:
			_spotlight_material.set_shader_parameter("target_rect", target_box)
		_card.position = card_target_pos
		_card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_card, "modulate:a", 1.0, 0.25)
		_is_animating = false
	else:
		var tween := create_tween().set_parallel(true)
		# Smoothly glide the spotlight cutout to the new target
		tween.tween_method(func(v: Vector4):
			_current_spot_rect = v
			if _spotlight_material != null:
				_spotlight_material.set_shader_parameter("target_rect", v)
		, _current_spot_rect, target_box, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# Smoothly reposition the card
		tween.tween_property(_card, "position", card_target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_card, "modulate:a", 1.0, 0.2)
		tween.chain().tween_callback(func(): _is_animating = false)


func _calculate_target_box(target_type: String, vp_size: Vector2) -> Vector4:
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
					var r := Rect2(min_pos, max_pos - min_pos).grow(16.0)
					return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback := Rect2(Vector2(20, vp_size.y - 440), Vector2(340, 360)).grow(16.0)
			return Vector4(fallback.position.x, fallback.position.y, fallback.size.x, fallback.size.y)

		"quest":
			var quest_node: Control = get_node_or_null("../QuestPanel") as Control
			if quest_node != null:
				var r: Rect2 = quest_node.get_global_rect()
				if r.size.x > 0 and r.size.y > 0:
					r = r.grow(12.0)
					return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_q := Rect2(Vector2((vp_size.x - 420) * 0.5, 20), Vector2(420, 90)).grow(12.0)
			return Vector4(fallback_q.position.x, fallback_q.position.y, fallback_q.size.x, fallback_q.size.y)

	return Vector4(0, 0, 0, 0)


func _calculate_card_position(target_type: String, vp_size: Vector2) -> Vector2:
	var card_sz := _card.size if _card != null else Vector2(480, 200)
	if card_sz.x <= 0 or card_sz.y <= 0:
		card_sz = Vector2(480, 200)

	match target_type:
		"buttons":
			# Position card in center-right so bottom-left buttons and spotlight are clear
			var x := clampf(vp_size.x * 0.55 - card_sz.x * 0.5 + 40, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.55 - card_sz.y * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"quest":
			# Position card in center below top quest banner and spotlight
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.42 - card_sz.y * 0.5 + 30, 110.0, vp_size.y - card_sz.y - 30.0)
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
	if not _is_active:
		return
	_is_active = false
	screen_pressed.emit()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible or not _is_active:
		return

	# Advance on click or touch
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		if _skip_button != null and _skip_button.get_global_rect().has_point(event.position):
			return
		_next_step()
		get_viewport().set_input_as_handled()
		return

	# Advance on Space or Enter; Skip on Escape (for testing)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_next_step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
