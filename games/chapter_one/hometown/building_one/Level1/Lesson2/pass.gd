extends Panel

@onready var pass_label: Label = $Label   

const COMBO_PATH := "res://assets/periodic_table_combo/"
var rng := RandomNumberGenerator.new()
var current_compound: Dictionary = {}
var row2plus_entries: Array[Dictionary] = []

func _ready() -> void:
	rng.randomize()
	_load_row2plus_entries()
	next_compound()

func _load_row2plus_entries() -> void:
	row2plus_entries.clear()
	var dir := DirAccess.open(COMBO_PATH)
	if not dir:
		push_error("❌ Cannot open folder: " + COMBO_PATH)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var path = COMBO_PATH + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				file.close()

				# ✅ skip first row (index 0), collect others
				if typeof(parsed) == TYPE_ARRAY and parsed.size() > 1:
					for i in range(1, parsed.size()):
						if typeof(parsed[i]) == TYPE_DICTIONARY:
							row2plus_entries.append(parsed[i])
		file_name = dir.get_next()
	dir.list_dir_end()


func next_compound() -> void:
	if row2plus_entries.is_empty():
		push_error("⚠ No row2+ entries found")
		return
	
	current_compound = row2plus_entries[rng.randi_range(0, row2plus_entries.size() - 1)]
	pass_label.text = current_compound.get("name", "Unknown")
	print_debug("Row2Plus PassPanel set pass_label →", pass_label.text)

func get_current_compound() -> Dictionary:
	return current_compound
