extends TextureButton

@export var texture_on: Texture2D
@export var texture_off: Texture2D

var _is_on := true

func _ready() -> void:
	# Start a default track (optional)
	MusicManager.play_music_by_id("game1")
	pressed.connect(_on_toggled)
	update_icon()

func _on_toggled() -> void:
	_is_on = !_is_on
	update_icon()

	if _is_on:
		MusicManager.resume_music_or_last()
	else:
		MusicManager.stop_music(0.5)  # fade out nicely

func update_icon() -> void:
	texture_normal = texture_on if _is_on else texture_off
