extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_expect("Music bus exists", AudioServer.get_bus_index("Music") != -1)
	_expect("SFX bus exists", AudioServer.get_bus_index("SFX") != -1)
	var main_source := FileAccess.get_file_as_string("res://games/main.gd")
	_expect("menu buttons use SFX API", not main_source.contains("play_music_by_id(\"button\""))
	MusicManager.play_sfx("button")
	_expect("button SFX uses SFX bus", MusicManager.sfx_player.bus == "SFX")
	var stream := MusicManager.sfx_player.stream
	if stream is AudioStreamWAV:
		_expect("button SFX is non-looping", stream.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	else:
		_expect("button SFX loaded", stream != null)

	if _failures.is_empty():
		print("AUDIO_RESULT PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("AUDIO_FAIL " + failure)
		get_tree().quit(1)


func _expect(label: String, condition: bool) -> void:
	if not condition:
		_failures.append(label)
