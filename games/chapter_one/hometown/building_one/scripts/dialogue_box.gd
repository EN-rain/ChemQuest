extends Panel

@onready var dialogue_label: Label = $TextLabel
@onready var name_label: Label = $Label
@onready var portrait_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var talk_sound: AudioStreamPlayer = $TalkSound
@onready var skip_button: Button = $SkipButton

var current_dialogue: Array = []
var current_index: int = 0
var speaker_name: String = "Wiz"
var typing_speed := 0.03      # seconds between letters
var auto_delay := 1.2         # wait after line completes
var end_delay := 1.0          # wait after last line before hiding
var _line_token: int = 0

signal dialogue_finished

func _ready() -> void:
	visible = false
	if skip_button:
		skip_button.hide()
		skip_button.pressed.connect(_on_skip_pressed)
	if portrait_anim and portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")


func start_dialogue(lines: Array, speaker: String = "Wiz", portrait: AnimatedSprite2D = null) -> void:
	if lines.is_empty():
		push_warning("⚠ Dialogue lines are empty.")
		return

	speaker_name = speaker
	name_label.text = speaker_name

	# Set portrait
	if portrait:
		portrait_anim.sprite_frames = portrait.sprite_frames
		if portrait.sprite_frames.has_animation("idle"):
			portrait_anim.play("idle")

	current_dialogue = lines
	current_index = 0
	visible = true
	if skip_button:
		skip_button.show()
	_show_line(current_dialogue[current_index])


func _show_line(line_text: String) -> void:
	_line_token += 1
	var token := _line_token
	dialogue_label.text = ""
	name_label.text = speaker_name

	# Play talking animation while typing
	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("talk"):
		portrait_anim.play("talk")

	for i in range(line_text.length()):
		if token != _line_token:
			return
		dialogue_label.text += line_text[i]

		# 🗣️ Play a short blip every few characters
		if i % 2 == 0 and talk_sound:
			talk_sound.stop()  # restart if still playing
			talk_sound.pitch_scale = randf_range(0.9, 1.1)  # variety
			talk_sound.play()

		await get_tree().create_timer(typing_speed).timeout
		if token != _line_token:
			return

	# ✅ Stop the talking sound after the line finishes
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	# Switch back to idle when line finishes
	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")

	await get_tree().create_timer(auto_delay).timeout
	if token != _line_token:
		return
	next_line()



func next_line() -> void:
	if current_dialogue.is_empty():
		return

	current_index += 1

	if current_index >= current_dialogue.size():
		await get_tree().create_timer(end_delay).timeout
		end_dialogue()
	else:
		_show_line(current_dialogue[current_index])


func end_dialogue() -> void:
	_line_token += 1
	visible = false
	if skip_button:
		skip_button.hide()
	
	#  Stop any remaining talking sound
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	# Return to idle animation
	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")

	emit_signal("dialogue_finished")


func _on_skip_pressed() -> void:
	if current_dialogue.is_empty():
		return

	current_index = current_dialogue.size() - 1
	_line_token += 1
	var token := _line_token
	dialogue_label.text = current_dialogue[current_index]
	name_label.text = speaker_name

	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")

	_finish_skipped_dialogue(token)


func _finish_skipped_dialogue(token: int) -> void:
	await get_tree().create_timer(auto_delay).timeout
	if token != _line_token:
		return
	next_line()
