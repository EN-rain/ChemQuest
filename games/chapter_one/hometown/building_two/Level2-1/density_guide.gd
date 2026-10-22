extends Control

signal tutorial_finished

const GUIDE_ID := "density_guide"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"
const ROBOTO_FONT_PATH := "res://assets/Roboto-BoldCondensed.ttf"
const QUESTION_ICON_PATH := "res://games/chapter_one/hometown/building_one/imgs/question.png"

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

# Optional persistent in-game guide button
var _hud_guide_btn: Button

var _steps_data := [
	{
		"badge": "STEP 1 OF 4",
		"headline": "Check the Goal",
		"text": "• Look at the GOAL banner at the top of your screen.\n• It displays the target Mass (kg), Volume (L), or Density required to unlock the gate!",
		"target": "goal"
	},
	{
		"badge": "STEP 2 OF 4",
		"headline": "Lift & Inspect Barrels",
		"text": "• Walk up to any barrel and tap the A (PICK) button or press E to lift it.\n• Jump across platforms with the barrel, or tap B (DROP) / press Q to set it down.",
		"target": "pick"
	},
	{
		"badge": "STEP 3 OF 4",
		"headline": "Measure & Calculate",
		"text": "• While holding a barrel, read its physical measurements in the DATA panel on the left.\n• Apply the formula to match the Goal:\n   Density = Mass / Volume\n   Mass = Density × Volume  |  Volume = Mass / Density",
		"target": "data"
	},
	{
		"badge": "STEP 4 OF 4",
		"headline": "Deliver to Exit Gate",
		"text": "• Carry the matching barrel to the Finish Gate on the far right to unlock the next level!\n• Tap HINT at the bottom or the ? button anytime to review these instructions.",
		"target": "gate"
	}
]


func _ready() -> void:
	_setup_spotlight_overlay()
	_setup_ui()
	call_deferred("_setup_persistent_triggers")

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
	_card.custom_minimum_size = Vector2(490, 205)

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
	_header_label.text = "DENSITY LAB"
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
	_skip_button.focus_mode = Control.FOCUS_NONE
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


func _setup_persistent_triggers() -> void:
	# 1. Wire GuideLabel (HINT banner at bottom) so tapping it reopens the guide
	var guide_lbl := get_node_or_null("../UiLabels/GuideLabel") as Control
	if guide_lbl == null and get_parent() != null:
		guide_lbl = get_parent().find_child("GuideLabel", true, false) as Control
	if guide_lbl != null and not guide_lbl.gui_input.is_connected(_on_hint_label_gui_input):
		guide_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		guide_lbl.gui_input.connect(_on_hint_label_gui_input)

	# 2. Add in-game GUIDE icon button on top right if not already present
	var ui_labels := get_node_or_null("../UiLabels") as Control
	if ui_labels == null and get_parent() != null:
		ui_labels = get_parent().find_child("UiLabels", true, false) as Control
	if ui_labels != null and ui_labels.find_child("DensityGuideButton", false, false) == null:
		_hud_guide_btn = Button.new()
		_hud_guide_btn.name = "DensityGuideButton"
		_hud_guide_btn.focus_mode = Control.FOCUS_NONE
		_hud_guide_btn.flat = true
		_hud_guide_btn.anchors_preset = Control.PRESET_TOP_RIGHT
		_hud_guide_btn.anchor_left = 1.0
		_hud_guide_btn.anchor_right = 1.0
		_hud_guide_btn.offset_left = -215.0
		_hud_guide_btn.offset_top = 16.0
		_hud_guide_btn.offset_right = -155.0
		_hud_guide_btn.offset_bottom = 76.0

		if ResourceLoader.exists(QUESTION_ICON_PATH):
			var icon_rect := TextureRect.new()
			icon_rect.texture = load(QUESTION_ICON_PATH)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(48, 48)
			icon_rect.anchors_preset = Control.PRESET_FULL_RECT
			icon_rect.anchor_right = 1.0
			icon_rect.anchor_bottom = 1.0
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_hud_guide_btn.add_child(icon_rect)
		else:
			_hud_guide_btn.text = "?"
			_hud_guide_btn.add_theme_font_size_override("font_size", 28)

		_hud_guide_btn.pressed.connect(show_guide)
		ui_labels.add_child.call_deferred(_hud_guide_btn)


func _on_hint_label_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		show_guide()


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/MusicManager"):
		var mgr := get_node("/root/MusicManager")
		if mgr != null and mgr.has_method("play_sfx"):
			mgr.play_sfx(sfx_name)


func show_guide() -> void:
	_play_sfx("button")
	modulate.a = 1.0
	_start_tutorial()


func _on_guide_button_pressed() -> void:
	show_guide()


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
	var player: Node = null
	if get_tree() != null and get_tree().current_scene != null:
		player = get_tree().current_scene.find_child("player", true, false)
		if player == null:
			player = get_tree().current_scene.find_child("Player", true, false)
	if player != null and player is CharacterBody2D:
		player.set_physics_process(not paused)


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

	if _prompt_label != null:
		if idx == _total_steps - 1:
			_prompt_label.text = "▶ Tap anywhere to finish"
		else:
			_prompt_label.text = "▶ Tap anywhere to continue"

	var vp_size := get_viewport_rect().size
	var target_box := _calculate_target_box(data["target"], vp_size)
	var card_target_pos := _calculate_card_position(data["target"], vp_size, target_box)

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
	var card_pos := _calculate_card_position(data["target"], vp_size, target_box)
	_current_spot_rect = target_box
	if _spotlight_material != null:
		_spotlight_material.set_shader_parameter("target_rect", target_box)
	if _card != null:
		_card.position = card_pos


func _calculate_target_box(target_type: String, vp_size: Vector2) -> Vector4:
	match target_type:
		"goal":
			var goal: Control = null
			if get_tree() != null and get_tree().current_scene != null:
				goal = get_tree().current_scene.find_child("GoalLabel", true, false) as Control
			if goal != null:
				var r := goal.get_global_rect().grow(16.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_g := Rect2(Vector2(vp_size.x * 0.5 - 200.0, 10.0), Vector2(400.0, 70.0)).grow(12.0)
			return Vector4(fallback_g.position.x, fallback_g.position.y, fallback_g.size.x, fallback_g.size.y)

		"pick":
			var pick_btn: Node = null
			if get_tree() != null and get_tree().current_scene != null:
				pick_btn = get_tree().current_scene.find_child("Pick", true, false)
			if pick_btn != null and pick_btn is TouchScreenButton:
				var ts := pick_btn as TouchScreenButton
				var pos := ts.global_position
				var tex_sz := ts.texture_normal.get_size() if ts.texture_normal != null else Vector2(80.0, 80.0)
				var sz := tex_sz * ts.scale
				var r := Rect2(pos, sz).grow(14.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_p := Rect2(Vector2(vp_size.x - 220.0, vp_size.y - 180.0), Vector2(100.0, 100.0)).grow(14.0)
			return Vector4(fallback_p.position.x, fallback_p.position.y, fallback_p.size.x, fallback_p.size.y)

		"data":
			var panel2: Control = null
			if get_tree() != null and get_tree().current_scene != null:
				panel2 = get_tree().current_scene.find_child("Panel2", true, false) as Control
			if panel2 != null:
				var r := panel2.get_global_rect().grow(12.0)
				return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			var fallback_d := Rect2(Vector2(16.0, vp_size.y * 0.5 - 100.0), Vector2(230.0, 200.0)).grow(12.0)
			return Vector4(fallback_d.position.x, fallback_d.position.y, fallback_d.size.x, fallback_d.size.y)

		"gate":
			var gate: Node2D = null
			if get_tree() != null and get_tree().current_scene != null:
				gate = get_tree().current_scene.find_child("DensityGatetoNextLvL", true, false) as Node2D
			if gate != null and get_viewport() != null:
				var screen_pos := get_viewport().get_canvas_transform() * gate.global_position
				# Only spotlight the exit gate if it is actually within the visible screen
				if get_viewport_rect().grow(-50.0).has_point(screen_pos):
					var r := Rect2(screen_pos - Vector2(50.0, 90.0), Vector2(100.0, 180.0)).grow(16.0)
					return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
			# Exit gate is off-screen on the right; return ZERO for clean full dimming
			return Vector4.ZERO

	return Vector4(0, 0, 0, 0)


func _calculate_card_position(target_type: String, vp_size: Vector2, target_box: Vector4 = Vector4.ZERO) -> Vector2:
	var card_sz := _card.size if _card != null else Vector2(500, 215)
	if card_sz.x <= 0 or card_sz.y <= 0:
		card_sz = Vector2(500, 215)

	match target_type:
		"goal":
			# Target is top center; place card lower center
			var x := clampf((vp_size.x - card_sz.x) * 0.5, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.44, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"pick":
			# Target is bottom right mobile control; place card left center
			var x := clampf(vp_size.x * 0.08, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf((vp_size.y - card_sz.y) * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"data":
			# Target is DATA panel on left; place card in upper right so player in center remains visible
			var x := clampf(vp_size.x - card_sz.x - 36.0, 20.0, vp_size.x - card_sz.x - 20.0)
			var y := clampf(vp_size.y * 0.22, 30.0, vp_size.y - card_sz.y - 30.0)
			return Vector2(x, y)

		"gate":
			# If gate is on screen, card is left center; if off screen (target_box == ZERO), center the card
			if target_box.z > 1.0:
				var x := clampf(vp_size.x * 0.08, 20.0, vp_size.x - card_sz.x - 20.0)
				var y := clampf((vp_size.y - card_sz.y) * 0.5, 30.0, vp_size.y - card_sz.y - 30.0)
				return Vector2(x, y)
			return (vp_size - card_sz) * 0.5

	return (vp_size - card_sz) * 0.5


func _next_step() -> void:
	if _is_animating:
		return
	_play_sfx("button")
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
	_play_sfx("button")
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
