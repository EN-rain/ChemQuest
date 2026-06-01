extends Node

var dialogues: Dictionary = {}
const FILES := [
	"res://games/data/wiz.json",
	"res://games/data/cristofe.json"
]


func _ready() -> void:
	load_dialogues()

func load_dialogues() -> void:
	dialogues.clear()
	for path in FILES:
		if not FileAccess.file_exists(path):
			push_error("Dialogue file not found: " + path)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		var text := file.get_as_text()
		file.close()
		var data = JSON.parse_string(text)
		if typeof(data) == TYPE_DICTIONARY:
			for key in data.keys():
				dialogues[key] = data[key]

# Returns lines for dialogue key
func get_dialogue(key: String) -> Array:
	return dialogues.get(key, [])
