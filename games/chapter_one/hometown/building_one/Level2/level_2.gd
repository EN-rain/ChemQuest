extends Node2D

var questions: Array[Dictionary] = []
var current_question: Dictionary = {}
var total_questions: int = 15
var passing_score: int = 12
var correct_count: int = 0
var wrong_count: int = 0
var asked_count: int = 0

@onready var situation_label: Label = %Control/Situation
@onready var input_line: LineEdit = %Control/InputLine
@onready var back_button: Button = %Control/BackButton
@onready var score_label: Label = %Control/ScoreLabel
@onready var round_label: Label = %Control/RoundLabel
@onready var timer_label: Label = %Control/TimerLabel
@onready var results_panel: Panel = %Control/ResultsPanel
@onready var ok_button: Button = %Ok
@onready var quiz_timer: Timer = %Timer
@onready var back_panel: Panel = %BackPanel

var shortcuts: Dictionary = {
	"e": "extensive",
	"i": "intensive",
	"c": "chemical",
	"p": "physical"
}


# -------------------- READY --------------------
func _ready() -> void:
	randomize()
	load_questions()
	show_new_question()

	ok_button.pressed.connect(_on_ok_pressed)
	input_line.text_submitted.connect(_on_answer_submitted)
	back_panel.resume_timer.connect(_on_resume_from_back_panel)
	quiz_timer.timeout.connect(_on_timer_timeout)

	results_panel.visible = false
	update_labels()


# -------------------- MAIN GAME LOGIC --------------------
func _on_ok_pressed() -> void:
	var text: String = input_line.text
	input_line.clear()
	await _on_answer_submitted(text)


func load_questions() -> void:
	var file: FileAccess = FileAccess.open("res://games/chapter_one/hometown/building_one/Level2/data.json", FileAccess.READ)
	if file:
		var data: Variant = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_ARRAY:
			var parsed_questions: Array[Dictionary] = []
			for q in data:
				if typeof(q) == TYPE_DICTIONARY:
					parsed_questions.append(q)
			questions = parsed_questions


func show_new_question() -> void:
	if asked_count >= total_questions:
		end_quiz()
		return
	
	current_question = questions.pick_random()
	situation_label.text = str(current_question["situation"])
	input_line.clear()

	# 🔹 Increment the round
	asked_count += 1
	update_labels()

	quiz_timer.wait_time = 30
	quiz_timer.start()
	update_timer_label()


func _process(_delta: float) -> void:
	if quiz_timer.is_stopped():
		return
	timer_label.text = str(int(quiz_timer.time_left))


func _on_timer_timeout() -> void:
	wrong_count += 1
	await show_feedback("Time's up!", false)
	await get_tree().create_timer(1.0).timeout
	show_new_question()


func _on_answer_submitted(text: String) -> void:
	if quiz_timer.is_stopped():
		return

	quiz_timer.stop()
	var player_answer: String = text.strip_edges().to_lower()

	if shortcuts.has(player_answer):
		player_answer = shortcuts[player_answer]

	if player_answer in ["extensive", "intensive", "chemical", "physical"]:
		var feedback: String = str(current_question["feedback"].get(player_answer, "No feedback available."))
		var correct: bool = (player_answer == current_question["answer"])

		if correct:
			correct_count += 1
		else:
			wrong_count += 1

		await show_feedback(feedback, correct)
		await get_tree().create_timer(1.0).timeout
		show_new_question()
	else:
		await show_feedback("Invalid input. Please type Extensive, Intensive, Chemical, Physical or E/I/C/P.", false)
		wrong_count += 1
		await get_tree().create_timer(1.0).timeout
		show_new_question()


# -------------------- LABEL UPDATES --------------------
func update_labels() -> void:
	score_label.text = "%d" % correct_count
	round_label.text = "%d" % asked_count


func update_timer_label() -> void:
	timer_label.text = str(int(quiz_timer.time_left))


# -------------------- FEEDBACK + SOUND --------------------
func show_feedback(text: String, correct: bool) -> void:
	MusicManager.pause_music()  # fade out music

	var sfx_id: String = "correct" if correct else "wrong"
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx.stream = MusicManager.music_library[sfx_id]
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.play()

	# Typewriter feedback while SFX plays
	situation_label.text = ""
	for i in text.length():
		situation_label.text += text[i]
		await get_tree().create_timer(0.03).timeout

	await get_tree().create_timer(0.5).timeout
	sfx.stop()
	sfx.queue_free()

	MusicManager.resume_music()  # fade back in


# -------------------- ENDING --------------------
func end_quiz() -> void:
	quiz_timer.stop()
	results_panel.show_results(correct_count, [])
	
# -------------------- BACK PANEL --------------------
func _on_back_button_pressed() -> void:
	quiz_timer.paused = true
	back_panel.show()


func _on_resume_from_back_panel() -> void:
	quiz_timer.paused = false
