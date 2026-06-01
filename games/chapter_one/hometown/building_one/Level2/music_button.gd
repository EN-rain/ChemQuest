extends TextureButton

@export var texture_on: Texture2D
@export var texture_off: Texture2D

var _is_on := true

func _ready() -> void:
	MusicManager.play_music_by_id("game2")
	pressed.connect(_on_toggled)
	update_icon()

func _on_toggled() -> void:
	_is_on = !_is_on
	update_icon()

	if _is_on:
		_enable_all_sounds()
	else:
		_disable_all_sounds()

func update_icon() -> void:
	texture_normal = texture_on if _is_on else texture_off

# -----------------------------------------------------
# 🔇 SOUND CONTROL HELPERS
# -----------------------------------------------------

func _disable_all_sounds() -> void:
	print("🔇 Muting all sounds...")
	MusicManager.stop_music(0.5)  # Fade out music
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)

func _enable_all_sounds() -> void:
	print("🔊 Unmuting all sounds...")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	MusicManager.resume_music_or_last()
