extends TextureButton

@export var texture_on: Texture2D
@export var texture_off: Texture2D

var _is_on := true

func _ready() -> void:
	# Start background music (optional)
	MusicManager.play_music_by_id("musiclvl1")
	pressed.connect(_on_toggled)
	update_icon()

func _on_toggled() -> void:
	_is_on = !_is_on
	update_icon()

	if _is_on:
		_unmute_all()
	else:
		_mute_all()

func _mute_all() -> void:
	# Fade out or stop music
	MusicManager.stop_music(0.5)

	# Mute the player's footsteps
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.set_footsteps_muted(true)

func _unmute_all() -> void:
	# Resume music
	MusicManager.resume_music_or_last()

	# Unmute the player's footsteps
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.set_footsteps_muted(false)

func update_icon() -> void:
	texture_normal = texture_on if _is_on else texture_off
