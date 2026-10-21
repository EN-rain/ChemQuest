extends Node2D

static var active_control_type: String = "arrows"

@onready var fade_sfx: ColorRect = %FadeSfx

# Controls radio selection
@onready var arrow_btn: Button = %ArrowBtn
@onready var joystick_btn: Button = %JoystickBtn
@onready var arrow_radio_dot: Control = %ArrowRadioDot
@onready var joystick_radio_dot: Control = %JoystickRadioDot
@onready var arrow_radio_ring: Panel = %ArrowRadioRing
@onready var joystick_radio_ring: Panel = %JoystickRadioRing

# Sound controls
@onready var sound_slider: HSlider = %SoundSlider
@onready var sound_percent: Label = %SoundPercent

# Radio ring styles
var _ring_active: StyleBoxFlat
var _ring_inactive: StyleBoxFlat


func _ready() -> void:
	if fade_sfx != null:
		FadeManager.setup(fade_sfx)

	_init_radio_styles()
	_load_settings()


func _init_radio_styles() -> void:
	_ring_active = StyleBoxFlat.new()
	_ring_active.bg_color = Color(0.18, 0.18, 0.18, 1.0)
	_ring_active.border_color = Color(1.0, 1.0, 1.0, 1.0)
	_ring_active.set_border_width_all(2)
	_ring_active.set_corner_radius_all(12)

	_ring_inactive = StyleBoxFlat.new()
	_ring_inactive.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	_ring_inactive.border_color = Color(0.45, 0.45, 0.45, 1.0)
	_ring_inactive.set_border_width_all(2)
	_ring_inactive.set_corner_radius_all(12)


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
	_set_control_scheme(ctrl_type, false)


func _on_sound_slider_value_changed(value: float) -> void:
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
		_save_setting("audio", "sound_volume", value)


func _on_arrow_btn_pressed() -> void:
	MusicManager.play_sfx("button")
	_set_control_scheme("arrows", true)


func _on_joystick_btn_pressed() -> void:
	MusicManager.play_sfx("button")
	_set_control_scheme("joystick", true)


func _set_control_scheme(scheme: String, save: bool = true) -> void:
	active_control_type = scheme
	var is_arrows := (scheme == "arrows")

	if arrow_radio_dot != null:
		arrow_radio_dot.visible = is_arrows
	if joystick_radio_dot != null:
		joystick_radio_dot.visible = not is_arrows

	if _ring_active != null and _ring_inactive != null:
		if arrow_radio_ring != null:
			arrow_radio_ring.add_theme_stylebox_override("panel", _ring_active if is_arrows else _ring_inactive)
		if joystick_radio_ring != null:
			joystick_radio_ring.add_theme_stylebox_override("panel", _ring_inactive if is_arrows else _ring_active)

	if save:
		_save_setting("controls", "type", scheme)
		_save_setting("controls", "chosen", true)


func _save_setting(section: String, key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value(section, key, value)
	config.save("user://settings.cfg")


static func get_control_type() -> String:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return String(config.get_value("controls", "type", "arrows"))
	return active_control_type


func _on_back_button_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/main.tscn")


func _on_achievements_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/achievements/achievements.tscn")


func _on_about_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/about.tscn")
