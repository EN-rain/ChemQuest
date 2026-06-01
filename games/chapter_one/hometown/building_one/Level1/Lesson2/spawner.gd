extends Node2D

const ATOM_SCENE := preload("res://games/chapter_one/hometown/building_one/Level1/atom.tscn")

@onready var spawn_shape: CollisionShape2D = %Spawner/Node2D/Area2D/CollisionShape2D
@onready var pass_panel = %Pass
@onready var pass_label: Label = %Pass/Label

var rng := RandomNumberGenerator.new()
var row2plus_entries: Array[Dictionary] = []

func _ready():
	rng.randomize()
	call_deferred("_spawn_from_pass")

func _spawn_from_pass() -> void:
	var chosen: Dictionary = {}
	if pass_panel and pass_panel.has_method("get_current_compound"):
		chosen = pass_panel.get_current_compound()

	if chosen.is_empty():
		push_warning("⚠ PassPanel has no compound yet")
		return

	# ✅ Record this compound immediately (using its formula)
	if chosen.has("formula"):
		LessonManager.record_compound_spawned(chosen["formula"])

	_spawn_specific_compound(chosen)
	_spawn_distractors(chosen)


func _spawn_specific_compound(chosen: Dictionary) -> void:
	pass_label.text = str(chosen.get("name", "Unknown Compound"))
	print_debug("Row2+ Spawner set pass_label →", pass_label.text)

	for comp_entry in chosen.get("components", []):
		var count: int = int(comp_entry.get("count", 1))
		for i in range(count):
			_spawn_specific_atom(comp_entry)

func _spawn_distractors(chosen: Dictionary) -> void:
	if pass_panel and pass_panel.row2plus_entries.size() > 0:
		row2plus_entries = pass_panel.row2plus_entries

	if row2plus_entries.is_empty():
		push_warning("⚠ No row2+ entries available for distractors")
		return

	var chosen_symbols: Array[String] = []
	for comp_entry in chosen.get("components", []):
		chosen_symbols.append(str(comp_entry.get("symbol", "")))

	for i in range(3):  # spawn 3 distractors
		var attempts := 0
		var rand_entry: Dictionary
		while attempts < 10:
			rand_entry = row2plus_entries[rng.randi_range(0, row2plus_entries.size() - 1)]
			if rand_entry.has("components") and not rand_entry["components"].is_empty():
				var sym = str(rand_entry["components"][0].get("symbol", ""))
				if sym not in chosen_symbols:
					break
			attempts += 1

		if rand_entry and rand_entry.has("components") and not rand_entry["components"].is_empty():
			var distractor: Dictionary = rand_entry["components"][0]
			_spawn_specific_atom(distractor)
			print_debug("Row2+ Spawner added distractor →", distractor.get("symbol", "?"))


func _spawn_specific_atom(elem: Dictionary) -> void:
	var atom = ATOM_SCENE.instantiate()
	if not atom:
		return

	var local_pos := Vector2.ZERO
	if spawn_shape and spawn_shape.shape:
		local_pos = _random_point_in_shape(spawn_shape.shape, 0.0)
	atom.position = local_pos

	# ✅ Find color name from ElementColorDB
	if elem.has("symbol"):
		var sym = elem["symbol"]
		var element_info = ElementColorDB.element_by_symbol.get(sym)
		if element_info and element_info.has("color"):
			elem["color"] = element_info["color"]
		else:
			elem["color"] = "pink"  # fallback sprite

	# ✅ Send dictionary with "symbol" + "color" to atom
	if atom.has_method("set_element"):
		atom.set_element(elem)

	spawn_shape.get_parent().call_deferred("add_child", atom)
	print("Spawned atom:", elem.get("symbol", "?"), "color:", elem.get("color", "pink"))

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
