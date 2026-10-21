extends Node2D

static var active_control_type: String = "arrows"

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var controls_modal: Control = %ControlsModal

# Sound controls
@onready var sound_slider: HSlider = %SoundSlider
@onready var sound_percent: Label = %SoundPercent

# Controls modal elements
@onready var controls_sub: Label = %ControlsSub
@onready var normal_arrows_btn: Button = %NormalArrowsBtn
@onready var joystick_btn: Button = %JoystickBtn
@onready var normal_arrows_badge: Label = %NormalArrowsBadge
@onready var joystick_badge: Label = %JoystickBadge


func _ready() -> void:
	if fade_sfx != null:
		FadeManager.setup(fade_sfx)
	if controls_modal != null:
		controls_modal.visible = false

	_load_settings()


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


func _on_normal_arrows_pressed() -> void:
	MusicManager.play_sfx("button")
	_set_control_scheme("arrows", true)


func _on_joystick_pressed() -> void:
	MusicManager.play_sfx("button")
	_set_control_scheme("joystick", true)


func _set_control_scheme(scheme: String, save: bool = true) -> void:
	active_control_type = scheme
	var is_arrows := (scheme == "arrows")

	if normal_arrows_badge != null:
		normal_arrows_badge.text = "[ SELECTED ]" if is_arrows else "[ SELECT ]"
		normal_arrows_badge.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_arrows else Color(0.5, 0.5, 0.5, 0.7)
	if joystick_badge != null:
		joystick_badge.text = "[ SELECTED ]" if not is_arrows else "[ SELECT ]"
		joystick_badge.modulate = Color(1.0, 1.0, 1.0, 1.0) if not is_arrows else Color(0.5, 0.5, 0.5, 0.7)

	if controls_sub != null:
		controls_sub.text = "Current: Normal Arrows" if is_arrows else "Current: Joystick"

	if save:
		_save_setting("controls", "type", scheme)


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


func _on_controls_pressed() -> void:
	MusicManager.play_sfx("button")
	if controls_modal != null:
		controls_modal.visible = true


func _on_close_controls_pressed() -> void:
	MusicManager.play_sfx("button")
	if controls_modal != null:
		controls_modal.visible = false


func _on_achievements_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/achievements/achievements.tscn")


func _on_about_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/about.tscn")
