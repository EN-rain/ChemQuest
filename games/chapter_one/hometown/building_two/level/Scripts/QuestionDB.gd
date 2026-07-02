extends Node

var _questions: Array = []
var _index := 0

func _ready() -> void:
	_load_data()
	_shuffle()

func _load_data() -> void:
	var path := "res://games/chapter_one/hometown/building_two/level/Data/questions.json"
	if not FileAccess.file_exists(path):
		push_error("QuestionDB: questions.json not found at %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("QuestionDB: JSON root must be an array.")
		return
	_questions = parsed

func _shuffle() -> void:
	_questions.shuffle()
	_index = 0

func restart() -> void:
	_shuffle()

func has_next() -> bool:
	return _index < _questions.size()

func next_question() -> Dictionary:
	# Returns: {"question": String, "choices": Array[String], "answer": String, "explain": String}
	if not has_next():
		return {}
	var q: Dictionary = _questions[_index]
	_index += 1
	# Make a shallow copy and shuffle choices so the correct one isn’t always in same place
	var out := q.duplicate()
	out["choices"] = q["choices"].duplicate()
	out["choices"].shuffle()
	return out
