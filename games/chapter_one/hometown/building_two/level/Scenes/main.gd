extends Control

@onready var question_label = $Question
@onready var answer_container = $Answer
@onready var lives_label = $Lives

var questions = []
var current_question = {}
var q_index = 0
var lives = 3

# 🔹 1) PRELOAD YOUR CUSTOM FONT FILE HERE
# (make sure you created quiz_font.tres from a .ttf or .otf file)
var custom_font = preload("res://assets/LilitaOne-Regular.ttf")

func _ready():
	_load_questions()
	if questions.is_empty():
		question_label.text = "No questions available."
		_clear_answers()
		_update_lives()
		return
	_show_next_question()

func _load_questions():
	var path = "res://games/chapter_one/hometown/building_two/level/Data/questions.json"
	if FileAccess.file_exists(path):
		var text = FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_ARRAY:
			questions = parsed
			questions.shuffle()
		else:
			push_error("questions.json must be an array!")

func _show_next_question():
	if q_index >= questions.size():
		question_label.text = "🎉 You Win!"
		_clear_answers()
		return

	current_question = questions[q_index]
	q_index += 1

	question_label.text = current_question["question"]
	_update_lives()
	_spawn_answers()

func _spawn_answers():
	_clear_answers()
	for choice in current_question["choices"]:
		var btn = Button.new()
		btn.text = choice

		# 🔹 Apply custom font
		btn.add_theme_font_override("font", custom_font)
		btn.add_theme_font_size_override("font_size", 35)
		

		# 🔹 Force answer text color to black
		btn.add_theme_color_override("font_color", Color.BLACK)

		# 🔹 Base style (pink button with rounded corners)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.988, 0.800, 0.769) 
		btn.add_theme_stylebox_override("normal", stylebox)

		# Hover style
		var hover_style = stylebox.duplicate()
		hover_style.bg_color = Color(1.0, 0.85, 0.8) # lighter pink
		btn.add_theme_stylebox_override("hover", hover_style)

		# Pressed style
		var pressed_style = stylebox.duplicate()
		pressed_style.bg_color = Color(0.9, 0.7, 0.65) # darker pink
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.pressed.connect(_on_answer_pressed.bind(choice, btn))
		answer_container.add_child(btn)

func _clear_answers():
	for child in answer_container.get_children():
		child.queue_free()

# 🔹 Updated: Pass the button so we can recolor it
func _on_answer_pressed(choice, btn: Button):
	if choice == current_question["answer"]:
		# ✅ Correct → green button + white text
		var correct_style = StyleBoxFlat.new()
		correct_style.bg_color = Color(0, 0.8, 0) # green
		
		btn.add_theme_stylebox_override("normal", correct_style)
		btn.add_theme_color_override("font_color", Color.WHITE)

		question_label.text = "✅ Correct!"
		await get_tree().create_timer(1.0).timeout
		_show_next_question()
	else:
		# ❌ Wrong → red button + white text
		var wrong_style = StyleBoxFlat.new()
		wrong_style.bg_color = Color(0.8, 0, 0) # red
		btn.add_theme_stylebox_override("normal", wrong_style)
		btn.add_theme_color_override("font_color", Color.WHITE)

		lives -= 1
		_update_lives()
		if lives <= 0:
			question_label.text = "❌ Game Over"
			_clear_answers()

func _update_lives():
	var hearts = ""
	for i in range(lives):
		hearts += "❤️"
	lives_label.text = "Lives: " + hearts
