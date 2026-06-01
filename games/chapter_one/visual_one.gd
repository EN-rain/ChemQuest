extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var prologue_label: Label = %PrologueLabel
@onready var skip_button: Button = %Skip
@onready var next_button: Button = %Next

var prologue_sentences: Array[String] = [
	"In the forest village of Elementara, science and nature once lived as one.",
	"Great minds left their mark here, shaping knowledge beneath the trees.",
	"But the greatest scientists disappeared… leaving only empty homes and fading memories.",
	"Some say they left because the village sought glory over truth.",
	"Others believe they dwell in a hidden mountain sanctuary, where pure knowledge thrives.",
	"The way forward lies beyond the forest, along a path walked only by legends.",
	"To restore balance between knowledge and wisdom… the path must be taken once more."
]

@export var typing_speed := 0.07
@export var auto_next_delay := 2.0

var _current_sentence := 0
var _is_typing := false
var _awaiting_auto_next := false
var _interrupt_typing := false
var _done := false

func _ready() -> void:
	MusicManager.play_music_by_id("prologue")
	FadeManager.setup(fade_sfx)
	prologue_label.text = ""
	await _start_next_sentence()


# ---------------------------------------------------------
# 🌿 Core Flow
# ---------------------------------------------------------
func _start_next_sentence() -> void:
	if _done:
		return
	if _is_typing or _awaiting_auto_next:
		return
	if _current_sentence >= prologue_sentences.size():
		_done = true
		return

	var sentence := prologue_sentences[_current_sentence]
	_current_sentence += 1

	await _type_sentence(sentence)
	if _done:
		return  # stop auto advance if skip was pressed mid-type

	_awaiting_auto_next = true
	await get_tree().create_timer(auto_next_delay).timeout
	_awaiting_auto_next = false

	if not _done:
		await _start_next_sentence()


# ---------------------------------------------------------
# ⌨️ Typewriter Effect
# ---------------------------------------------------------
func _type_sentence(sentence: String) -> void:
	if _done:
		return

	_is_typing = true
	_interrupt_typing = false
	prologue_label.text = ""

	for i in sentence.length():
		if _interrupt_typing or _done:
			prologue_label.text = sentence
			break

		prologue_label.text += sentence[i]
		await get_tree().create_timer(typing_speed).timeout

		if _done:
			return

	_is_typing = false
	_interrupt_typing = false


# ---------------------------------------------------------
# 🖱 NEXT Button
# ---------------------------------------------------------
func _on_next_pressed() -> void:
	if _done:
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/hometown.tscn")
		return

	if _is_typing:
		_interrupt_typing = true
		return

	if _awaiting_auto_next:
		return

	await _start_next_sentence()


# ---------------------------------------------------------
# ⏭ SKIP Button
# ---------------------------------------------------------
func _on_skip_pressed() -> void:
	if not _done:
		_done = true
		_interrupt_typing = true
		_is_typing = false
		_awaiting_auto_next = false

		# Show only the final sentence of the prologue
		var last_sentence: String = prologue_sentences.back()
		prologue_label.text = last_sentence

		# Optional: slight pause before scene transition
		await get_tree().create_timer(1.2).timeout

		await FadeManager.fade_and_change("res://games/chapter_one/hometown/hometown.tscn")
		return

	# If already done, just go to the next scene immediately
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/hometown.tscn")
