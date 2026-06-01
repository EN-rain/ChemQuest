extends Panel

@onready var pass_label: Label = $Label   

const COMBO_PATH := "res://assets/periodic_table_combo/"
var rng := RandomNumberGenerator.new()
var current_compound: Dictionary = {}
var row1_entries: Array[Dictionary] = []

func _ready() -> void:
	%Guide.show()
	rng.randomize()
	_load_row1_entries()
	next_compound()

func _load_row1_entries() -> void:
	row1_entries.clear()
	var dir := DirAccess.open(COMBO_PATH)
	if not dir:
		push_error(" Cannot open folder: " + COMBO_PATH)
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
				
				# ✅ Always take the first entry if array
				if typeof(parsed) == TYPE_ARRAY and parsed.size() > 0:
					var first_entry: Dictionary = parsed[0]
					if typeof(first_entry) == TYPE_DICTIONARY:
						row1_entries.append(first_entry)
		file_name = dir.get_next()
	dir.list_dir_end()

func next_compound() -> void:
	if row1_entries.is_empty():
		push_error(" No row1 entries found")
		return
	
	# Pick a random row1 entry
	current_compound = row1_entries[rng.randi_range(0, row1_entries.size() - 1)]
	pass_label.text = current_compound.get("name", "Unknown")
	print_debug("Row1Only PassPanel set pass_label →", pass_label.text)

func get_current_compound() -> Dictionary:
	return current_compound
