extends Control

signal tutorial_finished

const GUIDE_ID := "seperation_guide"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"
const ROBOTO_FONT_PATH := "res://assets/Roboto-BoldCondensed.ttf"

var _current_step := 0
var _total_steps := 4
var _is_active := false
var _is_animating := false
var _pulse_timer := 0.0
var _input_cooldown := 0.0

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

var _steps_data := [
	{
		"badge": "STEP 1 OF 4",
		"headline": "Mixtures to Separate",
		"text": "• Mixtures (e.g. Wheat Husk, Iron Nuts & Bolts, Muddy Water) appear on the left tray.\n• Drag any mixture card into the center dish to begin separating it!",
		"target": "tray"
	},
	{
		"badge": "STEP 2 OF 4",
		"headline": "Active Separation Dish",
		"text": "• Dropping a mixture here activates it for separation.\n• Observe its components to determine what physical properties differ!",
		"target": "dish"
	},
	{
		"badge": "STEP 3 OF 4",
		"headline": "Separation Tools",
		"text": "• Tap the matching separation tool: Filtration, Magnetism, Evaporation, Decantation, or Sieving!\n• Each tool separates mixtures based on physical properties.",
		"target": "tools"
	},
	{
		"badge": "STEP 4 OF 4",
		"headline": "Guide, Timer & Score",
		"text": "• Use this Reference Guide on the right to review what each tool separates!\n• Solve each mixture before the countdown timer hits 0. Track rounds and score to pass!",
		"target": "legend"
	}
]


func _ready() -> void:
	var legacy_next := get_node_or_null("NextButton")
	if legacy_next != null:
		legacy_next.visible = false

	_setup_spotlight_overlay()
	_setup_ui()

	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if _has_seen_guide():
		visible = false
		_is_active = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	call_deferred("_start_tutorial")


func _has_seen_guide() -> bool:
	if has_node("/root/GuideManager"):
		var mgr := get_node("/root/GuideManager")
		if mgr.has_method("has_seen"):
			return mgr.has_seen(GUIDE_ID)
	return false


func _mark_guide_seen() -> void:
	if has_node("/root/GuideManager"):
		var mgr := get_node("/root/GuideManager")
		if mgr.has_method("mark_seen"):
			mgr.mark_seen(GUIDE_ID)


func _setup_spotlight_overlay() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 target_rect;
uniform float corner_radius = 18.0;
uniform float feather = 6.0;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.72);
uniform vec4 glow_color : source_color = vec4(0.92, 0.96, 1.0, 0.95);
uniform float border_width = 2.2;
uniform float glow_spread = 12.0;

float rounded_box_sdf(vec2 center_pos, vec2 half_size, float radius) {
    vec2 d = abs(center_pos) - half_size + vec2(radius);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

void fragment() {
    if (target_rect.z <= 1.0 || target_rect.w <= 1.0) {
        COLOR = dim_color;
    } else {
        vec2 center = target_rect.xy + target_rect.zw * 0.5;
        vec2 half_size = target_rect.zw * 0.5;
        float dist = rounded_box_sdf(FRAGCOORD.xy - center, half_size, corner_radius);

        float dim_alpha = smoothstep(-feather, feather, dist);
        float pulse = 0.78 + 0.22 * sin(TIME * 4.2);
        float core = 1.0 - smoothstep(0.0, border_width, abs(dist));

        float outer_glow = 0.0;
        if (dist > 0.0) {
            outer_glow = exp(-dist / glow_spread) * pulse * 0.85;
        }
        float inner_glow = 0.0;
        if (dist <= 0.0) {
            inner_glow = exp(dist / (glow_spread * 0.6)) * pulse * 0.35;
        }

        float halo = clamp(core * pulse + outer_glow + inner_glow, 0.0, 1.0);
        vec3 col = mix(dim_color.rgb, glow_color.rgb, halo);
        float alpha = clamp(dim_color.a * dim_alpha + halo * glow_color.a, 0.0, 1.0);
        COLOR = vec4(col, alpha);
    }
}
"""
	_spotlight_material = ShaderMaterial.new()
	_spotlight_material.shader = shader
	_spotlight_material.set_shader_parameter("corner_radius", 18.0)
	_spotlight_material.set_shader_parameter("feather", 6.0)
	_spotlight_material.set_shader_parameter("dim_color", Color(0.0, 0.0, 0.0, 0.72))
	_spotlight_material.set_shader_parameter("glow_color", Color(0.92, 0.96, 1.0, 0.95))
	_spotlight_material.set_shader_parameter("border_width", 2.2)
	_spotlight_material.set_shader_parameter("glow_spread", 12.0)

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
	var roboto_font: Font = null
	if ResourceLoader.exists(ROBOTO_FONT_PATH):
		roboto_font = load(ROBOTO_FONT_PATH)

	_card = PanelContainer.new()
	_card.name = "TutorialCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.custom_minimum_size = Vector2(480, 200)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	card_style.set_border_width_all(0)
	card_style.set_corner_radius_all(14)
	card_style.shadow_size = 0
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	_card.add_theme_stylebox_override("panel", card_style)
	_card.visible = false
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_card.add_child(vbox)

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
	_step_badge.text = "STEP 1 OF 4"
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

	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(1.0, 1.0, 1.0, 0.15)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	_headline_label = Label.new()
	if font != null:
		_headline_label.add_theme_font_override("font", font)
	_headline_label.add_theme_font_size_override("font_size", 21)
	_headline_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(_headline_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if roboto_font != null:
		_body_label.add_theme_font_override("font", roboto_font)
	_body_label.add_theme_font_size_override("font_size", 15)
	_body_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_label)

	var footer_hbox := HBoxContainer.new()
	vbox.add_child(footer_hbox)

	_prompt_label = Label.new()
	_prompt_label.text = "▶ Tap anywhere to continue"
	if font != null:
		_prompt_label.add_theme_font_override("font", font)
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_hbox.add_child(_prompt_label)


func _start_tutorial() -> void:
	visible = true
	_is_active = true
	_current_step = 0
	_input_cooldown = 0.35
	mouse_filter = Control.MOUSE_FILTER_STOP

	_pause_game_timer()

	if _card != null:
		_card.visible = true
	_show_step_index(0, true)


func _pause_game_timer() -> void:
	var timer_child := get_node_or_null("%Timer") as Timer
	if timer_child == null:
		var gt := get_node_or_null("%GameTimer")
		if gt != null and gt.has_node("Timer"):
			timer_child = gt.get_node("Timer") as Timer
	if timer_child != null:
		timer_child.set_paused(true)


func _resume_game_timer() -> void:
	var timer_child := get_node_or_null("%Timer") as Timer
	if timer_child == null:
		var gt := get_node_or_null("%GameTimer")
		if gt != null and gt.has_node("Timer"):
			timer_child = gt.get_node("Timer") as Timer
	if timer_child != null:
		if timer_child.is_stopped():
			timer_child.start()
		else:
			timer_child.set_paused(false)


func _process(delta: float) -> void:
	if not visible or not _is_active:
		return
	if _input_cooldown > 0.0:
		_input_cooldown = maxf(0.0, _input_cooldown - delta)
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
	_input_cooldown = 0.35

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
		tween.tween_method(func(v: Vector4):
			_current_spot_rect = v
			if _spotlight_material != null:
				_spotlight_material.set_shader_parameter("target_rect", v)
		, _current_spot_rect, target_box, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_property(_card, "position", card_target_pos, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_card, "modulate:a", 1.0, 0.2)
		tween.chain().tween_callback(func(): _is_animating = false)


func _on_viewport_size_changed() -> void:
	if not visible or not _is_active or _current_step >= _steps_data.size():
		return
	var vp_size := get_viewport_rect().size
	var data: Dictionary = _steps_data[_current_step]
	var target_box := _calculate_target_box(data["target"], vp_size)
	var card_pos := _calculate_card_position(data["target"], vp_size)
	_current_spot_rect = target_box
	if _spotlight_material != null:
		_spotlight_material.set_shader_parameter("target_rect", target_box)
	if _card != null:
		_card.position = card_pos


func _calculate_target_box(target_type: String, vp_size: Vector2) -> Vector4:
	match target_type:
		"tray", "spawner":
			var sp_panel := get_node_or_null("%SpawnPanel") as Control
			if sp_panel != null:
				var bgml := sp_panel.get_parent() as Control
				if bgml != null:
					var r := bgml.get_global_rect().grow(8.0)
					return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
				var r := sp_panel.get_global_rect().grow(14.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_tray := Rect2(Vector2(14.0, (vp_size.y - 425.0) * 0.5), Vector2(285.0, 425.0)).grow(8.0)
			return Vector4(fallback_tray.position.x, fallback_tray.position.y, fallback_tray.size.x, fallback_tray.size.y)

		"dish", "holder":
			var center := Vector2(vp_size.x * 0.5, vp_size.y * 0.5)
			var r := Rect2(Vector2(center.x - 162.0, center.y - 255.0), Vector2(324.0, 338.0)).grow(10.0)
			return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)

		"tools":
			var hbox := get_node_or_null("%Buttons/HBoxContainer") as Control
			if hbox != null:
				var r := hbox.get_global_rect()
				r.size.y += 34.0
				r = r.grow(10.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_t := Rect2(Vector2((vp_size.x - 760.0) * 0.5, vp_size.y - 198.0), Vector2(760.0, 158.0)).grow(10.0)
			return Vector4(fallback_t.position.x, fallback_t.position.y, fallback_t.size.x, fallback_t.size.y)

		"legend", "timer":
			var legend := get_node_or_null("%Legend") as Control
			if legend == null and get_tree() != null and get_tree().current_scene != null:
				legend = get_tree().current_scene.find_child("Legend", true, false) as Control
			if legend != null:
				var r := legend.get_global_rect().grow(10.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_l := Rect2(Vector2(vp_size.x - 290.0, vp_size.y * 0.5 - 245.0), Vector2(265.0, 365.0)).grow(10.0)
			return Vector4(fallback_l.position.x, fallback_l.position.y, fallback_l.size.x, fallback_l.size.y)

	return Vector4(0, 0, 0, 0)


func _calculate_card_position(target_type: String, vp_size: Vector2) -> Vector2:
	var card_sz := _card.size if _card != null else Vector2(480, 200)
	if card_sz.x <= 0 or card_sz.y <= 0:
		card_sz = Vector2(480, 200)

	match target_type:
		"tray", "spawner":
			# Target is left panel (x: 14..300), position card cleanly to the right
			var x := clampf(330.0, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf((vp_size.y - card_sz.y) * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"dish", "holder":
			# Target is center dish (x: 470..810, y: 95..440), position card in center bottom
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(475.0, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"tools":
			# Target is bottom row (y: 520..680), position card in top center
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(120.0, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"legend", "timer":
			# Target is right Legend panel (x: 985..1265), position card cleanly on the left
			var x := clampf(vp_size.x * 0.22, 20.0, vp_size.x - card_sz.x - 30.0)
			var y := clampf((vp_size.y - card_sz.y) * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

	return (vp_size - card_sz) * 0.5


func _next_step() -> void:
	if _is_animating:
		return
	if MusicManager != null and MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
	if _current_step + 1 < _total_steps:
		_show_step_index(_current_step + 1)
	else:
		_finish_tutorial()


func _finish_tutorial() -> void:
	if not _is_active:
		return
	_is_active = false
	_mark_guide_seen()
	_resume_game_timer()

	tutorial_finished.emit()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _on_skip_pressed() -> void:
	if not _is_active:
		return
	if MusicManager != null and MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
	_is_active = false
	_mark_guide_seen()
	_resume_game_timer()

	tutorial_finished.emit()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible or not _is_active:
		return
	if _input_cooldown > 0.0:
		return

	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		if _skip_button != null and _skip_button.get_global_rect().has_point(event.position):
			return
		_next_step()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_next_step()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()


func _on_guide_button_pressed() -> void:
	if MusicManager != null and MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
	modulate.a = 1.0
	_start_tutorial()


func _on_next_button_pressed() -> void:
	_next_step()
