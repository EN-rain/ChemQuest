extends Node2D

const ATOM_SCENE := preload("res://games/chapter_one/hometown/building_one/Level1/atom.tscn")
const ELEMENTS_PATH: String = "res://games/global/elements.json"
const MAX_RUNS := 3

@onready var spawn_shape: CollisionShape2D = %Spawner/Node2D/Area2D/CollisionShape2D
@onready var pass_panel = %Pass
@onready var pass_label: Label = %Pass/Label

var rng := RandomNumberGenerator.new()
var row1_entries: Array[Dictionary] = []
var elements_data: Array[Dictionary] = []

func _ready() -> void:
	rng.randomize()
	_load_elements_json()
	call_deferred("_spawn_from_pass")

# Load all element data (symbol, color)
func _load_elements_json() -> void:
	var file := FileAccess.open(ELEMENTS_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_ARRAY:
			elements_data = []
			for entry in data:
				if typeof(entry) == TYPE_DICTIONARY:
					elements_data.append(entry)

# Spawn correct compound and distractors
func _spawn_from_pass() -> void:
	var chosen: Dictionary = {}
	if pass_panel and pass_panel.has_method("get_current_compound"):
		chosen = pass_panel.get_current_compound()
	if chosen.is_empty():
		push_warning("⚠ PassPanel has no compound yet")
		return

	# Skip used symbol
	if chosen.has("components") and chosen["components"].size() > 0:
		var first_symbol: String = str(chosen["components"][0].get("symbol", ""))
		if not LessonManager.can_spawn(first_symbol):
			pass_panel.next_compound()
			_spawn_from_pass()
			return

	pass_label.text = str(chosen.get("name", "Unknown Element"))
	_spawn_specific_compound(chosen)
	_spawn_distractors(chosen)

	# Mark as used
	if chosen.has("components") and chosen["components"].size() > 0:
		LessonManager.mark_element_used(chosen["components"][0].get("symbol", ""))

# Spawn all atoms for correct element
func _spawn_specific_compound(chosen: Dictionary) -> void:
	for comp_entry in chosen.get("components", []):
		var count: int = int(comp_entry.get("count", 1))
		for i in range(count):
			_spawn_specific_atom(comp_entry)

# Spawn distractor elements
func _spawn_distractors(chosen: Dictionary) -> void:
	if "row1_entries" in pass_panel:
		row1_entries = pass_panel.row1_entries
	if row1_entries.is_empty():
		push_warning("⚠ No row1 entries available for distractors")
		return

	var chosen_symbol: String = ""
	if chosen.has("components") and chosen["components"].size() > 0:
		chosen_symbol = str(chosen["components"][0].get("symbol", ""))

	for i in range(3):
		var attempts := 0
		var rand_entry: Dictionary
		while attempts < 10:
			rand_entry = row1_entries[rng.randi_range(0, row1_entries.size() - 1)]
			if rand_entry.has("components") and not rand_entry["components"].is_empty():
				var sym = str(rand_entry["components"][0].get("symbol", ""))
				if sym != chosen_symbol and LessonManager.can_spawn(sym):
					break
			attempts += 1

		if rand_entry and rand_entry.has("components") and not rand_entry["components"].is_empty():
			var distractor: Dictionary = rand_entry["components"][0]
			_spawn_specific_atom(distractor)

# Spawn a single atom in random position
func _spawn_specific_atom(elem: Dictionary) -> void:
	var atom = ATOM_SCENE.instantiate()
	if not atom:
		return

	# Find color info from elements.json
	var symbol := str(elem.get("symbol", ""))
	var color := "pink"
	for e in elements_data:
		if e.get("symbol", "") == symbol:
			color = e.get("color", "pink")
			break

	# Merge color into element dictionary
	elem["color"] = color

	var local_pos := Vector2.ZERO
	if spawn_shape and spawn_shape.shape:
		local_pos = _random_point_in_shape(spawn_shape.shape, 0.0)
	atom.position = local_pos

	if atom.has_method("set_element"):
		atom.set_element(elem)

	spawn_shape.get_parent().call_deferred("add_child", atom)


# Generate a random point in the spawn area
func _random_point_in_shape(shape: Shape2D, margin: float = 0.0) -> Vector2:
	if shape is RectangleShape2D:
		var ext: Vector2 = shape.extents - Vector2(margin, margin)
		return Vector2(rng.randf_range(-ext.x, ext.x), rng.randf_range(-ext.y, ext.y))
	elif shape is CircleShape2D:
		var r: float = max(shape.radius - margin, 0.0)
		var angle: float = rng.randf_range(0, TAU)
		var dist: float = sqrt(rng.randf()) * r
		return Vector2(cos(angle), sin(angle)) * dist
	return Vector2.ZERO
