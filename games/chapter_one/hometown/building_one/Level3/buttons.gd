extends Control

@onready var feedback_label: Label = %FeedBackLabel as Label
@onready var feedback_text: Label = %FeedBackPanel/Label as Label
@onready var score_label: Label = %ScoreLabel as Label
@onready var round_label: Label = %RoundLabel as Label
@onready var spawner: Node = %Spawner as Node
@onready var game_time: GameTime = %GameTimer as GameTime
@onready var result_panel: Panel = %ResultsPanel as Panel
@onready var undo_button: Button = %UndoButton

var current_item: Area2D = null
var score: int = 0
var round_number: int = 1
var feedback_active: bool = false

@export var feedback_delay: float = 1.0
@export var max_rounds: int = 15
@export var passing_score: int = 12

func _ready() -> void:
	await get_tree().process_frame
	game_time.tick.connect(_on_timer_tick)
	game_time.time_up.connect(_on_time_up)

	round_label.text = "%d" % round_number
	score_label.text = "%d" % score

	if spawner:
		spawner.max_rounds = max_rounds
		spawner.max_spawn_round = max_rounds - 3
		spawner.current_round = round_number

	game_time.start_round()


func _on_timer_tick(remaining_time: int) -> void:
	if remaining_time <= 5:
		%GameTimer/Label.add_theme_color_override("font_color", Color.RED)
	else:
		%GameTimer/Label.add_theme_color_override("font_color", Color.WHITE)

func _on_time_up() -> void:
	feedback_label.text = "Time's up!"
	feedback_text.text = "Moving to the next item..."

	for holder in get_tree().get_nodes_in_group("holders"):
		if holder.has_method("clear_item_if_any"):
			holder.clear_item_if_any()

	await get_tree().create_timer(0.5).timeout
	_skip_current_item()


# ---------------------------
# 🔊 FEEDBACK + AUDIO LOGIC
# ---------------------------
func show_feedback(method_name: String) -> void:
	if feedback_active:
		return
	feedback_active = true

	# 🔒 Disable undo immediately after a method is clicked
	if undo_button:
		undo_button.disabled = true

	current_item = await _get_active_item()
	if current_item == null:
		feedback_label.text = "No item selected."
		feedback_text.text = ""
		feedback_active = false
		return

	var feedback_data: Dictionary = current_item.feedback
	if not feedback_data.has(method_name):
		feedback_label.text = " No feedback for " + method_name
		feedback_text.text = ""
		return

	var is_correct: bool = method_name in current_item.separation
	var feedback_msg: String = str(feedback_data[method_name])

	game_time.stop_round()

	# 🎵 Fade out background music
	MusicManager.pause_music()

	# 🔊 Play correct/wrong SFX
	var sfx_id: String = "correct" if is_correct else "wrong"
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx.stream = MusicManager.music_library[sfx_id]
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.play()

	# 🧩 Feedback text
	if is_correct:
		feedback_label.text = "Correct!"
		score += 1
	else:
		var correct_methods: Array[String] = current_item.separation
		var correct_text: String = correct_methods.reduce(
			func(accum, val):
				return (accum + ", " + val) if accum != "" else val,
			""
		)
		if correct_text == "":
			correct_text = "Unknown"

		feedback_label.text = "Wrong! The correct answer was: %s" % correct_text

	score_label.text = "%d" % score

	# ✍️ Typewriter effect runs simultaneously with sound
	await _typewriter_effect(feedback_msg)

	# Wait a bit to let the sound finish
	await get_tree().create_timer(0.5).timeout

	# Clean up sound + resume music
	sfx.stop()
	sfx.queue_free()
	MusicManager.resume_music()

	# 🕓 Delay before next item
	await get_tree().create_timer(1.0).timeout

	_remove_current_item()
	feedback_label.text = ""
	feedback_text.text = ""

	# 🧩 Spawn next
	if spawner and spawner.has_method("spawn_single_item"):
		spawner.spawn_single_item()

	_next_round()
	feedback_active = false


# ---------------------------
# 🔧 UTILITY HELPERS
# ---------------------------
func _get_active_item() -> Area2D:
	# Primary source: spawner's placed_history
	if spawner and spawner.placed_history.size() > 0:
		var candidate := spawner.placed_history.back() as Area2D
		if candidate and is_instance_valid(candidate):
			return candidate

	# Small race window: briefly wait and re-check once
	await get_tree().create_timer(0.05).timeout
	if spawner and spawner.placed_history.size() > 0:
		var candidate2 := spawner.placed_history.back() as Area2D
		if candidate2 and is_instance_valid(candidate2):
			return candidate2

	# Fallback: look for any item nodes that are marked placed
	var placed_candidates := []
	for node in get_tree().get_nodes_in_group("items"):
		if node is Area2D and node.placed and is_instance_valid(node):
			placed_candidates.append(node)

	if placed_candidates.size() > 0:
		# return the last one (closest to being most recently placed)
		return placed_candidates.back() as Area2D

	return null


func _typewriter_effect(text: String) -> void:
	feedback_text.text = ""
	for ch in text:
		feedback_text.text += ch
		await get_tree().create_timer(0.03).timeout

func _remove_current_item() -> void:
	if current_item and current_item.placed:
		if Level3Manager and current_item.item_id != "":
			Level3Manager.mark_item_cleared(current_item.item_id)

		if spawner:
			if spawner.items.has(current_item):
				spawner.items.erase(current_item)
			if spawner.placed_history.has(current_item):
				spawner.placed_history.erase(current_item)
			current_item.queue_free()
			if spawner.has_method("_realign_unplaced_items"):
				spawner._realign_unplaced_items()


func _skip_current_item() -> void:
	_remove_current_item()
	feedback_label.text = ""
	feedback_text.text = ""
	_next_round()


func _next_round() -> void:
	round_number += 1

	if spawner:
		spawner.current_round = round_number

	if round_number > max_rounds:
		_end_game()
		return

	round_label.text = "%d" % round_number
	game_time.start_round()

	# 🔓 Re-enable Undo for the next round
	if undo_button:
		undo_button.disabled = false



func _end_game() -> void:
	game_time.stop_round()
	await get_tree().create_timer(0.5).timeout

	var passed: bool = score >= passing_score
	if result_panel and result_panel.has_method("show_results"):
		# ✅ pass boolean, not array
		result_panel.show_results(score, passed)

	if Level3Manager:
		Level3Manager.increment_run_and_check_reset()

	visible = false

# --- Button handlers -
func _on_filtration_pressed() -> void: show_feedback("filtration")
func _on_magnetism_pressed() -> void: show_feedback("magnetism")
func _on_evaporation_pressed() -> void: show_feedback("evaporation")
func _on_decantation_pressed() -> void: show_feedback("decantation")
func _on_sieving_pressed() -> void: show_feedback("sieving")
