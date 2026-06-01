extends Area2D

@onready var talk_sound: AudioStreamPlayer = %DialogueBox/TalkSound
@onready var dialogue_box: Control = %DialogueBox
@onready var dialogue_label: Label = %DialogueBox/Label
@onready var player: Node = get_tree().get_first_node_in_group("Player") # assuming your Player is in "Player" group

# Customize your message
var dialogue_text := "It seems that there's no one here..."
var typing_speed := 0.04 # seconds per character

var is_typing := false

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	dialogue_box.visible = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and not is_typing:
		_show_dialogue()


func _show_dialogue() -> void:
	is_typing = true

	# Stop player movement (assuming Player script has a set_movement_enabled method)
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)

	dialogue_box.visible = true
	dialogue_label.text = ""

	await _typewriter_text(dialogue_text)

	# Wait briefly, stop sound, and hide box
	if talk_sound and talk_sound.playing:
		talk_sound.stop()

	await get_tree().create_timer(1).timeout

	dialogue_box.visible = false

	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)

	is_typing = false


# --- Typewriter Effect with normal talk speed ---
func _typewriter_text(text: String) -> void:
	for i in range(text.length()):
		dialogue_label.text = text.substr(0, i + 1)

		# 🗣️ Play sound every 3 characters, at normal pitch
		if i % 3 == 0 and talk_sound:
			if not talk_sound.playing:
				talk_sound.pitch_scale = 1.0  # normal speed
				talk_sound.play()

		await get_tree().create_timer(typing_speed).timeout

	# Stop talk sound after finishing
	if talk_sound and talk_sound.playing:
		talk_sound.stop()
