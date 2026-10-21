extends Control

signal closed
signal control_scheme_changed(scheme: String)

const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"
const ROBOTO_FONT_PATH := "res://assets/Roboto-BoldCondensed.ttf"

@onready var backdrop: ColorRect = $Backdrop
@onready var card: PanelContainer = $CenterContainer/Card
@onready var close_button: Button = %CloseButton
@onready var arrows_btn: Button = %ArrowsBtn
@onready var joystick_btn: Button = %JoystickBtn
@onready var sound_slider: HSlider = %SoundSlider
@onready var sound_percent: Label = %SoundPercent
@onready var review_btn: Button = %ReviewBtn
@onready var main_menu_btn: Button = %MainMenuBtn
@onready var resume_btn: Button = %ResumeBtn

var _card_active: StyleBoxFlat
var _card_inactive: StyleBoxFlat
var _card_hover: StyleBoxFlat
var _active_scheme: String = "arrows"


func _ready() -> void:
	visible = false
	_init_card_styles()
	_build_control_previews()

	if close_button != null:
		close_button.pressed.connect(close)
	if resume_btn != null:
		resume_btn.pressed.connect(close)
	if arrows_btn != null:
		arrows_btn.pressed.connect(func(): _select_control_scheme("arrows"))
	if joystick_btn != null:
		joystick_btn.pressed.connect(func(): _select_control_scheme("joystick"))
	if sound_slider != null:
		sound_slider.value_changed.connect(_on_sound_slider_changed)
	if main_menu_btn != null:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if review_btn != null:
		review_btn.pressed.connect(_on_review_pressed)


func _init_card_styles() -> void:
	_card_active = StyleBoxFlat.new()
	_card_active.bg_color = Color(0.18, 0.18, 0.18, 0.95)
	_card_active.border_color = Color(1.0, 1.0, 1.0, 1.0)
	_card_active.set_border_width_all(2)
	_card_active.set_corner_radius_all(14)

	_card_inactive = StyleBoxFlat.new()
	_card_inactive.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	_card_inactive.border_color = Color(0.28, 0.28, 0.28, 0.5)
	_card_inactive.set_border_width_all(1)
	_card_inactive.set_corner_radius_all(14)

	_card_hover = StyleBoxFlat.new()
	_card_hover.bg_color = Color(0.22, 0.22, 0.22, 0.95)
	_card_hover.border_color = Color(0.6, 0.6, 0.6, 0.8)
	_card_hover.set_border_width_all(1)
	_card_hover.set_corner_radius_all(14)


func _build_control_previews() -> void:
	var font: Font = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else null
	var roboto_font: Font = load(ROBOTO_FONT_PATH) if ResourceLoader.exists(ROBOTO_FONT_PATH) else null

	# 1. Arrows Button (Image 2 design)
	if arrows_btn != null:
		for c in arrows_btn.get_children():
			c.queue_free()
		arrows_btn.custom_minimum_size = Vector2(230, 160)
		var vbox := VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 1.0
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 6)
		arrows_btn.add_child(vbox)

		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(_create_dpad_preview())
		vbox.add_child(center)

		var lbl := Label.new()
		lbl.text = "ARROWS (D-PAD)"
		if font != null:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		var sub := Label.new()
		sub.text = "4 directional buttons"
		if roboto_font != null:
			sub.add_theme_font_override("font", roboto_font)
		sub.add_theme_font_size_override("font_size", 13)
		sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sub)

	# 2. Joystick Button (Image 2 design)
	if joystick_btn != null:
		for c in joystick_btn.get_children():
			c.queue_free()
		joystick_btn.custom_minimum_size = Vector2(230, 160)
		var vbox := VBoxContainer.new()
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 1.0
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 6)
		joystick_btn.add_child(vbox)

		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(_create_joystick_preview())
		vbox.add_child(center)

		var lbl := Label.new()
		lbl.text = "VIRTUAL JOYSTICK"
		if font != null:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		var sub := Label.new()
		sub.text = "Fluid 360° analog stick"
		if roboto_font != null:
			sub.add_theme_font_override("font", roboto_font)
		sub.add_theme_font_size_override("font_size", 13)
		sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sub)


func _create_dpad_preview() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(72, 72)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex_up: Texture2D = load("res://assets/buttons/up.png") if ResourceLoader.exists("res://assets/buttons/up.png") else null
	var tex_down: Texture2D = load("res://assets/buttons/down.png") if ResourceLoader.exists("res://assets/buttons/down.png") else null
	var tex_left: Texture2D = load("res://assets/buttons/left.png") if ResourceLoader.exists("res://assets/buttons/left.png") else null
	var tex_right: Texture2D = load("res://assets/buttons/right.png") if ResourceLoader.exists("res://assets/buttons/right.png") else null

	var rect_up := TextureRect.new()
	rect_up.texture = tex_up
	rect_up.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect_up.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_up.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect_up.position = Vector2(24, 0)
	rect_up.size = Vector2(24, 24)
	rect_up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect_up)

	var rect_down := TextureRect.new()
	rect_down.texture = tex_down
	rect_down.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect_down.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_down.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect_down.position = Vector2(24, 48)
	rect_down.size = Vector2(24, 24)
	rect_down.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect_down)

	var rect_left := TextureRect.new()
	rect_left.texture = tex_left
	rect_left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect_left.position = Vector2(0, 24)
	rect_left.size = Vector2(24, 24)
	rect_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect_left)

	var rect_right := TextureRect.new()
	rect_right.texture = tex_right
	rect_right.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect_right.position = Vector2(48, 24)
	rect_right.size = Vector2(24, 24)
	rect_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect_right)

	return container


func _create_joystick_preview() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(72, 72)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var joy_base := Panel.new()
	joy_base.custom_minimum_size = Vector2(64, 64)
	joy_base.position = Vector2(4, 4)
	joy_base.size = Vector2(64, 64)
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.12, 0.12, 0.12, 0.75)
	base_style.border_color = Color(1.0, 1.0, 1.0, 0.5)
	base_style.set_border_width_all(2)
	base_style.set_corner_radius_all(32)
	joy_base.add_theme_stylebox_override("panel", base_style)
	container.add_child(joy_base)

	var joy_knob := Panel.new()
	joy_knob.custom_minimum_size = Vector2(26, 26)
	joy_knob.position = Vector2(19, 19)
	joy_knob.size = Vector2(26, 26)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.92, 0.92, 0.92, 0.95)
	knob_style.set_corner_radius_all(13)
	joy_knob.add_theme_stylebox_override("panel", knob_style)
	joy_base.add_child(joy_knob)

	return container


func open() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_settings()

	if card != null:
		card.scale = Vector2(0.95, 0.95)
		card.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, 0.2)
		if backdrop != null:
			backdrop.modulate.a = 0.0
			tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)


func close() -> void:
	if not visible:
		return
	var tween := create_tween().set_parallel(true)
	if card != null:
		tween.tween_property(card, "scale", Vector2(0.95, 0.95), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(card, "modulate:a", 0.0, 0.18)
	if backdrop != null:
		tween.tween_property(backdrop, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(func():
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		closed.emit()
	)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://settings.cfg")
	var sound_vol: float = 80.0
	var ctrl_type: String = "arrows"
	if err == OK:
		sound_vol = float(config.get_value("audio", "sound_volume", 80.0))
		ctrl_type = String(config.get_value("controls", "type", "arrows"))
	else:
		var bus_idx := AudioServer.get_bus_index("Master")
		if bus_idx != -1:
			if AudioServer.is_bus_mute(bus_idx):
				sound_vol = 0.0
			else:
				var db := AudioServer.get_bus_volume_db(bus_idx)
				sound_vol = clampf(db_to_linear(db) * 100.0, 0.0, 100.0)

	if sound_slider != null:
		sound_slider.value = sound_vol
	_apply_sound_volume(sound_vol, false)
	_update_control_ui(ctrl_type)


func _select_control_scheme(scheme: String) -> void:
	if MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
	_active_scheme = scheme

	# Save persistent config
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("controls", "type", scheme)
	config.set_value("controls", "chosen", true)
	config.save("user://settings.cfg")

	_update_control_ui(scheme)
	control_scheme_changed.emit(scheme)

	# Apply immediately to Hometown if present
	var hometown := get_tree().current_scene
	if hometown != null and hometown.has_method("_apply_control_scheme"):
		hometown.call("_apply_control_scheme", scheme)
	else:
		# Fallback to direct HUD search
		var buttons := get_node_or_null("../Buttons") as Control
		if buttons != null:
			buttons.visible = (scheme == "arrows")
		var joystick := get_node_or_null("../VirtualJoystick") as Control
		if joystick != null:
			joystick.visible = (scheme != "arrows")


func _update_control_ui(scheme: String) -> void:
	_active_scheme = scheme
	var is_arrows := (scheme == "arrows")

	if arrows_btn != null and _card_active != null and _card_inactive != null:
		arrows_btn.add_theme_stylebox_override("normal", _card_active if is_arrows else _card_inactive)
		arrows_btn.add_theme_stylebox_override("hover", _card_hover)
		arrows_btn.add_theme_stylebox_override("pressed", _card_active if is_arrows else _card_inactive)
		arrows_btn.add_theme_stylebox_override("focus", _card_active if is_arrows else _card_inactive)

	if joystick_btn != null and _card_active != null and _card_inactive != null:
		joystick_btn.add_theme_stylebox_override("normal", _card_inactive if is_arrows else _card_active)
		joystick_btn.add_theme_stylebox_override("hover", _card_hover)
		joystick_btn.add_theme_stylebox_override("pressed", _card_inactive if is_arrows else _card_active)
		joystick_btn.add_theme_stylebox_override("focus", _card_inactive if is_arrows else _card_active)


func _on_sound_slider_changed(value: float) -> void:
	_apply_sound_volume(value, true)


func _apply_sound_volume(value: float, save: bool = true) -> void:
	if sound_percent != null:
		sound_percent.text = "%d%%" % int(value)

	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		if value <= 0.0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var linear_val := value / 100.0
			var db_val := linear_to_db(linear_val)
			AudioServer.set_bus_volume_db(bus_idx, db_val)

	if save:
		var config := ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("audio", "sound_volume", value)
		config.save("user://settings.cfg")


func _on_main_menu_pressed() -> void:
	if MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/main.tscn")


func _on_review_pressed() -> void:
	# "leave the review button for now"
	if MusicManager.has_method("play_sfx"):
		MusicManager.play_sfx("button")
