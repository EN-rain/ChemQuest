extends Panel

@onready var dialogue_label: Label = $TextLabel
@onready var name_label: Label = $Label
@onready var portrait_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var talk_sound: AudioStreamPlayer = $TalkSound
@onready var skip_button: Button = $SkipButton

var current_dialogue: Array = []
var current_index: int = 0
var speaker_name: String = "Cristofe"
var typing_speed := 0.03      # seconds between letters
var auto_delay := 1.2         # wait after line completes
var end_delay := 1.0          # wait after last line before hiding
var _line_token: int = 0
var _dialogue_active := false
var _movement_controls: Control
var _interaction_controls: Control
var _movement_was_visible := false
var _interaction_was_visible := false

signal dialogue_finished

func _ready() -> void:
	visible = false
	if skip_button:
		skip_button.hide()
		skip_button.pressed.connect(_on_skip_pressed)
		var skip_text := skip_button.get_node_or_null("Label") as Control
		if skip_text:
			skip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if portrait_anim and portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")


func start_dialogue(lines: Array, speaker: String = "Cristofe", portrait: AnimatedSprite2D = null) -> void:
	if _dialogue_active:
		return
	_dialogue_active = true
	_hide_gameplay_controls()
	if lines.is_empty():
		push_warning("⚠ Dialogue lines are empty.")
		call_deferred("end_dialogue")
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

	# ✅ Start talk animation
	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("talk"):
		portrait_anim.play("talk")

	# ✅ Make sure sound only plays while typing
	for i in range(line_text.length()):
		if token != _line_token:
			return
		dialogue_label.text += line_text[i]

		# 🗣️ Play short blip only during typing
		if i % 2 == 0 and talk_sound:
			if not talk_sound.playing:
				talk_sound.pitch_scale = randf_range(0.9, 1.1)
				talk_sound.play()
			else:
				# small pitch variation to avoid overlap stutter
				talk_sound.pitch_scale = randf_range(0.95, 1.05)

		await get_tree().create_timer(typing_speed).timeout
		if token != _line_token:
			return

	# ✅ Immediately stop the sound after finishing typing
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	# ✅ Switch to idle animation once text finishes typing
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
		var token := _line_token
		await get_tree().create_timer(end_delay).timeout
		if token != _line_token or not _dialogue_active:
			return
		end_dialogue()
	else:
		_show_line(current_dialogue[current_index])


func end_dialogue() -> void:
	if not _dialogue_active:
		return
	_dialogue_active = false
	_line_token += 1
	current_dialogue.clear()
	visible = false
	if skip_button:
		skip_button.hide()
	
	# 🧘‍♂️ Stop any remaining talking sound
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	# Return to idle animation
	if portrait_anim.sprite_frames and portrait_anim.sprite_frames.has_animation("idle"):
		portrait_anim.play("idle")

	_restore_gameplay_controls()
	emit_signal("dialogue_finished")


func _on_skip_pressed() -> void:
	if not _dialogue_active:
		return
	end_dialogue()


func _hide_gameplay_controls() -> void:
	var canvas := get_parent()
	_movement_controls = canvas.get_node_or_null("Buttons") as Control
	_interaction_controls = canvas.get_node_or_null("Control") as Control
	if _movement_controls:
		_movement_was_visible = _movement_controls.visible
		_movement_controls.hide()
	if _interaction_controls:
		_interaction_was_visible = _interaction_controls.visible
		_interaction_controls.hide()


func _restore_gameplay_controls() -> void:
	if is_instance_valid(_movement_controls):
		_movement_controls.visible = _movement_was_visible
	if is_instance_valid(_interaction_controls):
		_interaction_controls.visible = _interaction_was_visible
