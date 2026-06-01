extends Control

@onready var result_label: Label = %ResultsLabel
@onready var continue_button: Button = $Continue
@onready var accuracy_button_high: Button = %Accuracy
@onready var accuracy_button_low: Button = %Accuracy2
@onready var precision_button_high: Button = %Precision
@onready var precision_button_low: Button = %Precision2
@onready var vbox: HBoxContainer = %ResultsPanel/HBoxContainer 

var selected_accuracy: String = ""
var selected_precision: String = ""
var current_score: int = 0
var max_score: int = 10

func _ready() -> void:
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

# -------------------------
# Button Handlers
# -------------------------
func _on_accuracy_pressed() -> void:
	_select_accuracy("High Accuracy", accuracy_button_high, accuracy_button_low)

func _on_accuracy_2_pressed() -> void:
	_select_accuracy("Low Accuracy", accuracy_button_low, accuracy_button_high)

func _on_precision_pressed() -> void:
	_select_precision("High Precision", precision_button_high, precision_button_low)

func _on_precision_2_pressed() -> void:
	_select_precision("Low Precision", precision_button_low, precision_button_high)


# -------------------------
# Accuracy / Precision Selection
# -------------------------
func _select_accuracy(choice: String, chosen: Button, other: Button) -> void:
	selected_accuracy = choice
	chosen.disabled = true
	other.disabled = true
	other.modulate.a = 0.5
	_try_evaluate()

func _select_precision(choice: String, chosen: Button, other: Button) -> void:
	selected_precision = choice
	chosen.disabled = true
	other.disabled = true
	other.modulate.a = 0.5
	_try_evaluate()


# -------------------------
# Try Evaluate
# -------------------------
func _try_evaluate() -> void:
	if selected_accuracy != "" and selected_precision != "":
		_hide_all_buttons()
		evaluate_selection()


# -------------------------
# Hide/Show Buttons
# -------------------------
func _hide_all_buttons() -> void:
	for btn in [accuracy_button_high, accuracy_button_low, precision_button_high, precision_button_low]:
		btn.visible = false

func _show_all_buttons() -> void:
	for btn in [accuracy_button_high, accuracy_button_low, precision_button_high, precision_button_low]:
		btn.visible = true
		btn.disabled = false
		btn.modulate.a = 1.0
		btn.button_pressed = false


# -------------------------
# Calculate Accuracy & Precision
# -------------------------
func calculate_results() -> Dictionary:
	var hit_positions: Array[Vector2] = []
	var center := Vector2.ZERO
	var target_img: Sprite2D = null

	for child in vbox.get_children():
		if child.has_node("HitMark") and child.has_node("TargetImg"):
			var hit_mark: Sprite2D = child.get_node("HitMark")
			if hit_mark.visible:
				hit_positions.append(hit_mark.position)
				target_img = child.get_node("TargetImg")
				center = target_img.position

	if hit_positions.is_empty() or target_img == null:
		return {
			"accuracy": "Low Accuracy",
			"precision": "Low Precision"
		}

	var target_radius: float = target_img.texture.get_size().x * target_img.scale.x * 0.5

	# -----------------------
	# 1️⃣ Accuracy (distance to center)
	# -----------------------
	var distances: Array[float] = []
	var total_weighted := 0.0
	for pos in hit_positions:
		var d = pos.distance_to(center)
		distances.append(d)
		# Weight shots closer to center more heavily
		total_weighted += 1.0 - clamp(d / target_radius, 0.0, 1.0)

	var avg_dist = distances.reduce(func(a, b): return a + b) / hit_positions.size()
	var accuracy_ratio = avg_dist / target_radius

	# Weighted accuracy score in [0, 1]
	var accuracy_score = total_weighted / hit_positions.size()

	# Adaptive accuracy threshold
	var acc = "High Accuracy" if accuracy_score >= 0.7 or accuracy_ratio < 0.25 else "Low Accuracy"

	# -----------------------
	# 2️⃣ Precision (spread)
	# -----------------------
	var mean = Vector2.ZERO
	for pos in hit_positions:
		mean += pos
	mean /= hit_positions.size()

	var variance: float = 0.0
	for pos in hit_positions:
		variance += pos.distance_squared_to(mean)
	variance /= hit_positions.size()
	var std_dev = sqrt(variance)

	var precision_ratio = std_dev / target_radius

	# Adjust tolerance based on sample size (more shots → stricter)
	var dynamic_threshold = 0.25 - clamp((hit_positions.size() - 3) * 0.02, 0.0, 0.1)

	var prec = "High Precision" if precision_ratio < dynamic_threshold else "Low Precision"

	return {
		"accuracy": acc,
		"precision": prec
	}

# -------------------------
# Evaluation + Explanation
# -------------------------
func evaluate_selection():
	var result = calculate_results()
	var correct_accuracy = result["accuracy"]
	var correct_precision = result["precision"]

	var selected_str = "%s, %s" % [selected_accuracy, selected_precision]
	var correct_str = "%s, %s" % [correct_accuracy, correct_precision]

	var acc_text = "Your shots were centered well" if correct_accuracy == "High Accuracy" else "Your shots strayed from the center"
	var prec_text = "and they were grouped consistently." if correct_precision == "High Precision" else "and they were scattered widely."
	var explanation = "%s %s" % [acc_text, prec_text]

	var correct: bool = (selected_accuracy == correct_accuracy and selected_precision == correct_precision)

	# 🔊 Play correct or wrong sound
	var sfx_id: String = "correct" if correct else "wrong"
	var sfx := AudioStreamPlayer.new()
	sfx.stream = MusicManager.music_library[sfx_id]
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(func(): sfx.queue_free())

	if correct:
		result_label.text = "Correct!\nYou chose: %s\nExplanation: %s" % [selected_str, explanation]
		_send_result_to_scoredisplay(true, correct_str)
	else:
		result_label.text = "Wrong!\nYou chose: %s\nCorrect answer: %s\nExplanation: %s" % [
			selected_str, correct_str, explanation
		]
		_send_result_to_scoredisplay(false, correct_str)

# Send Result to ScoreDisplay
# -------------------------
func _send_result_to_scoredisplay(is_correct: bool, correct_str: String) -> void:
	var score_display = get_tree().get_root().find_child("ScoreDisplay", true, false)
	if score_display:
		if is_correct:
			score_display.on_guess(correct_str, correct_str)
		else:
			score_display.on_guess("wrong", correct_str)

# -------------------------
# Results + Continue logic
# -------------------------
func show_results(score: int, new_max: int) -> void:
	current_score = score
	max_score = new_max
	visible = true

	if current_score >= max_score:
		MusicManager.play_music_by_id("showresults")
		continue_button.visible = true
		result_label.text += "\n Perfect! %d/%d" % [current_score, max_score]
	else:
		continue_button.visible = false
		result_label.text += "\nYou scored %d/%d" % [current_score, max_score]

# -------------------------
# Continue button pressed
# -------------------------
func _on_continue_pressed() -> void:
	Scoring.update_best_score("game5", current_score)
	if current_score >= 8:
		Scoring.unlock_level("game6")

	var acc_id := "accuracy_vs_precision"
	if QuestManager.has_quest(acc_id) and not QuestManager.is_quest_completed(acc_id):
		QuestManager.complete_quest(acc_id)

	var after_id := "after_accuracy_vs_precision"
	if not QuestManager.has_quest(after_id) and QuestManager.active_quests.has(after_id):
		QuestManager.add_quest(QuestManager.active_quests[after_id])

	Scoring.reset_precision_accuracy_score()
	SpawnManager.set_spawn("shooting_spawn")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

# -------------------------
# Reset for Next Round
# -------------------------
func _reset_selection() -> void:
	selected_accuracy = ""
	selected_precision = ""
	_show_all_buttons()
	result_label.text = ""
