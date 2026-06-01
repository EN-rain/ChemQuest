extends Panel

@onready var feedback_label: Label = $Label
@onready var talk_sound: AudioStreamPlayer = $TalkSound

var lines: Array = []
var index := 0
var typing_speed := 0.03
var auto_delay := 1.0
var typing := false


func _ready() -> void:
	visible = false


func show_feedback(texts: Array) -> void:
	if texts.is_empty():
		return

	lines = texts
	index = 0
	visible = true
	_show_line(lines[index])


func _show_line(line: String) -> void:
	feedback_label.text = ""
	typing = true

	# make sure no old sound keeps playing
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	# start typing loop
	for i in range(line.length()):
		feedback_label.text += line[i]

		# Play blip sound every few letters while typing
		if i % 2 == 0 and talk_sound:
			talk_sound.stop()
			talk_sound.pitch_scale = randf_range(0.9, 1.1)
			talk_sound.play()

		await get_tree().create_timer(typing_speed).timeout

	# ✅ stop sound right after typing ends
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	typing = false

	# wait a moment before showing next line
	await get_tree().create_timer(auto_delay).timeout
	_next_line()


func _next_line() -> void:
	index += 1
	if index >= lines.size():
		_hide_feedback()
	else:
		_show_line(lines[index])


func _hide_feedback() -> void:
	typing = false
	if talk_sound and talk_sound.playing:
		talk_sound.stop()
	visible = false
