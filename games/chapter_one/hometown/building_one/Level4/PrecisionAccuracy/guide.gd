extends Control

signal tutorial_finished

const GUIDE_ID := "precision_guide"
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
		"headline": "Rotating Bullseye",
		"text": "• Rotating target rings spin in the center of the arena.\n• The closer your shot lands to the bullseye center, the higher your accuracy score!",
		"target": "target"
	},
	{
		"badge": "STEP 2 OF 4",
		"headline": "Moving Crosshair",
		"text": "• Your targeting reticle sweeps back and forth across the firing zone.\n• Anticipate the crosshair movement to line up your shot!",
		"target": "crosshair"
	},
	{
		"badge": "STEP 3 OF 4",
		"headline": "Tap to Shoot",
		"text": "• Tap the SHOOT button to take your shot when aligned!\n• You have 5 shots to prove your mastery of precision and accuracy.",
		"target": "fire"
	},
	{
		"badge": "STEP 4 OF 4",
		"headline": "Precision vs Accuracy",
		"text": "• Review the guide on the right: Accuracy is how close shots land to the bullseye.\n• Precision is how tightly grouped your shots are together!",
		"target": "score"
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

	_set_gameplay_paused(true)

	if _card != null:
		_card.visible = true
	_show_step_index(0, true)


func _set_gameplay_paused(paused: bool) -> void:
	var pa := get_node_or_null("%PAManager") as Node2D
	if pa == null and get_tree() != null and get_tree().current_scene != null:
		pa = get_tree().current_scene.find_child("PAManager", true, false) as Node2D
	if pa != null:
		pa.set_physics_process(not paused)
	var btn := get_node_or_null("%FireButton") as Button
	if btn == null and get_tree() != null and get_tree().current_scene != null:
		btn = get_tree().current_scene.find_child("FireButton", true, false) as Button
	if btn != null:
		btn.disabled = paused


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
		"target":
			var t3 := get_node_or_null("%Target3") as Node2D
			if t3 == null and get_tree() != null and get_tree().current_scene != null:
				t3 = get_tree().current_scene.find_child("Target3", true, false) as Node2D
			var center: Vector2 = t3.global_position if t3 != null else Vector2(vp_size.x * 0.5 + 20.0, vp_size.y * 0.5 - 96.0)
			var r := Rect2(center - Vector2(100.0, 100.0), Vector2(200.0, 200.0)).grow(12.0)
			return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)

		"crosshair":
			var bound := get_node_or_null("%FireZoneBoundary") as Control
			if bound == null and get_tree() != null and get_tree().current_scene != null:
				bound = get_tree().current_scene.find_child("FireZoneBoundary", true, false) as Control
			if bound != null:
				var r := bound.get_global_rect().grow(22.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_c := Rect2(Vector2(vp_size.x * 0.5 - 60.0, vp_size.y * 0.5 - 115.0), Vector2(195.0, 85.0)).grow(16.0)
			return Vector4(fallback_c.position.x, fallback_c.position.y, fallback_c.size.x, fallback_c.size.y)

		"fire":
			var fire_btn := get_node_or_null("%FireButton") as Control
			if fire_btn == null and get_tree() != null and get_tree().current_scene != null:
				fire_btn = get_tree().current_scene.find_child("FireButton", true, false) as Control
			if fire_btn != null:
				var spr := fire_btn.get_node_or_null("Sprite2D") as Control
				if spr != null:
					var r := spr.get_global_rect().grow(12.0)
					return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_f := Rect2(Vector2((vp_size.x - 300.0) * 0.5, vp_size.y - 122.0), Vector2(300.0, 105.0)).grow(12.0)
			return Vector4(fallback_f.position.x, fallback_f.position.y, fallback_f.size.x, fallback_f.size.y)

		"score":
			var legend: Control = null
			if get_tree() != null and get_tree().current_scene != null:
				legend = get_tree().current_scene.find_child("Legend", true, false) as Control
			if legend != null:
				var r := legend.get_global_rect().grow(10.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_s := Rect2(Vector2(vp_size.x - 235.0, vp_size.y * 0.5 - 220.0), Vector2(225.0, 420.0)).grow(10.0)
			return Vector4(fallback_s.position.x, fallback_s.position.y, fallback_s.size.x, fallback_s.size.y)

	return Vector4(0, 0, 0, 0)


func _calculate_card_position(target_type: String, vp_size: Vector2) -> Vector2:
	var card_sz := _card.size if _card != null else Vector2(480, 200)
	if card_sz.x <= 0 or card_sz.y <= 0:
		card_sz = Vector2(480, 200)

	match target_type:
		"target":
			# Target is upper-center bullseye, position card in lower center
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(420.0, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"crosshair":
			# Target is crosshair zone (y ~ 240..340), position card in upper center
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(80.0, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"fire":
			# Target is bottom-center SHOOT button, position card in upper center
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(140.0, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"score":
			# Target is right Legend panel, position card cleanly on the left
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
	_set_gameplay_paused(false)

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
	_set_gameplay_paused(false)

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
