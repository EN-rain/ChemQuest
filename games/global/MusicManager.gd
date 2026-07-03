extends Node

@export var default_bus: String = "Music"

# Dictionary of all your registered music tracks
var music_library: Dictionary = {
	"main": preload("res://games/global/music/mainbg.mp3"),
	"prologue": preload("res://games/global/music/prologue.mp3"),
	"game1": preload("res://games/global/music/game1.mp3"),
	"game2": preload("res://games/global/music/game2.mp3"),
	"house": preload("res://games/global/music/coffee.mp3"),
	"arcade": preload("res://games/global/music/Arcade.mp3"),
	"button": preload("res://games/global/music/button.wav"),
	"correct": preload("res://games/global/music/corr.wav"),
	"wrong": preload("res://games/global/music/wrong.wav"),
	"shoot": preload("res://games/global/music/gun_shoot.wav"),
	"showresults": preload("res://games/global/music/showresults.ogg"),
	"musiclvl1": preload("res://games/global/music/hometown.mp3"),
	"musiclvl2": preload("res://games/global/music/hometown.mp3"),
	"musiclvl3": preload("res://games/global/music/hometown.mp3"),
	"musiclvl4": preload("res://games/global/music/hometown.mp3"),
	"states": preload("res://games/global/music/arcade_acadia.mp3")
}

var current_music: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var current_id: String = ""

func _ready() -> void:
	current_music = AudioStreamPlayer.new()
	current_music.bus = default_bus
	current_music.name = "CurrentMusic"
	add_child(current_music)

	# 🎧 Add a separate player for sound effects
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else default_bus
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)


# -----------------------
# 🔹 Play a track by ID
# -----------------------
func play_music_by_id(id: String, fade_in: float = 0.5) -> void:
	print("🎵 Request to play:", id)

	if not music_library.has(id):
		push_warning("Music ID '%s' not found in music_library!" % id)
		return

	# ✅ Don't restart the same track
	if current_id == id and current_music.playing:
		print("🎶 Already playing '%s', skipping restart." % id)
		return

	var stream = music_library[id]
	print("✅ Found stream:", stream)

	# ✅ Only stop old music if it's a different track
	if current_music.playing and current_id != id:
		stop_music_immediately()

	current_id = id
	_play_music(stream, fade_in)


# -----------------------
# 🔹 Internal play helper
# -----------------------
func _play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if current_music.playing:
		stop_music_immediately()

	# Fix (M7): Duplicate the stream before mutating its loop flag.
	# `preload()` returns a shared resource that any other consumer of
	# the same path would also see. Mutating `stream.loop` on a preloaded
	# resource leaks the loop setting across the entire project.
	# `duplicate()` gives us a unique instance to safely configure.
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3 or stream is AudioStreamWAV:
		stream = stream.duplicate() as AudioStream

	current_music.stream = stream
	current_music.volume_db = -40  # start quietly

	# ✅ Ensure a valid bus (fall back to Master if "Music" doesn’t exist)
	var bus_index := AudioServer.get_bus_index(default_bus)
	if bus_index == -1:
		current_music.bus = "Master"
	else:
		current_music.bus = default_bus

	# ✅ Enable looping on our private copy
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	current_music.play()

	# ✅ Smooth fade-in
	if fade_in > 0.0:
		var tween := create_tween()
		tween.tween_property(current_music, "volume_db", 0.0, fade_in)
	else:
		current_music.volume_db = 0.0

	print("🎧 Now playing:", stream, "on bus:", current_music.bus)


# -----------------------
# 🔹 Fade-out stop (not immediate)
# -----------------------
func stop_music(fade_out: float = 0.5) -> void:
	if not current_music.playing:
		return

	var tween := create_tween()
	tween.tween_property(current_music, "volume_db", -80.0, fade_out)
	tween.tween_callback(Callable(current_music, "stop"))
	# NOTE: We DO NOT clear current_id here!
	# That way, the last song can be resumed later.


# -----------------------
# 🔹 Immediate stop (⚡ instant)
# -----------------------
func stop_music_immediately() -> void:
	if current_music.playing:
		current_music.stop()
		current_music.stream = null
	current_music.volume_db = 0.0
	current_id = ""  # This one clears it fully (hard stop)


# -----------------------
# 🔹 Pause / Resume
# -----------------------
func pause_music() -> void:
	if current_music:
		current_music.stream_paused = true

func resume_music() -> void:
	if current_music:
		current_music.stream_paused = false


# -----------------------
# 🔹 Resume last played track or continue paused one
# -----------------------
func resume_music_or_last(fade_in: float = 0.5) -> void:
	if current_music.stream_paused:
		current_music.stream_paused = false
	elif not current_music.playing and current_id != "":
		play_music_by_id(current_id, fade_in)
	else:
		push_warning("No music to resume or last track unknown.")


# -----------------------
# 🔹 Dynamically add new music at runtime
# -----------------------
func add_music(id: String, path: String) -> void:
	if music_library.has(id):
		push_warning("Music ID '%s' already exists! Overwriting..." % id)
	music_library[id] = load(path)


# -----------------------
# 🔹 Play sound effects (buttons, clicks, etc.)
# -----------------------
func play_sfx(id: String) -> void:
	if not music_library.has(id):
		push_warning("SFX '%s' not found!" % id)
		return
	var stream = music_library[id]
	sfx_player.stream = stream
	sfx_player.play()
