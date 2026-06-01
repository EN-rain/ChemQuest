extends Node2D

@export var item_scene: PackedScene
@onready var spawn_panel: Panel = $bgml/SpawnPanel as Panel
@onready var item_holder: Node2D = $bgml/SpawnPanel/ItemHolder as Node2D

var items: Array[Area2D] = []
var placed_history: Array[Area2D] = []
var item_data: Array = []
var used_items: Array = []
var max_rounds: int = 5
var current_round: int = 1
var max_spawn_round: int = 3

func _ready() -> void:
	_load_item_data()
	spawn_items_vertically(3)

func _load_item_data() -> void:
	var json_path := "res://games/chapter_one/hometown/building_one/Level3/items.json"
	if not FileAccess.file_exists(json_path):
		return
	var file := FileAccess.open(json_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed and "items" in parsed:
		item_data = parsed["items"]

# --- Spawn initial vertical list
func spawn_items_vertically(count: int) -> void:
	if item_scene == null:
		item_scene = load("res://games/chapter_one/hometown/building_one/Level3/items.tscn")

	var panel_size: Vector2 = spawn_panel.size
	var spacing: float = 130.0
	var start_y: float = (panel_size.y - float(count - 1) * spacing) / 2.0
	var center_x: float = panel_size.x / 2.0

	for i in range(count):
		var item := item_scene.instantiate() as Area2D
		item_holder.add_child(item)
		item.position = Vector2(center_x, start_y + float(i) * spacing)
		item.original_index = i
		item.spawn_local_position = item.position
		item.spawner_ref = self
		items.append(item)

		if not item_data.is_empty():
			var random_item = _get_unique_random_item()
			if random_item and item.has_method("setup"):
				item.setup(random_item)
				item.item_id = random_item["id"]
		else:
			item.setup("Placeholder")

# --- NEW: spawn a single item after feedback
func spawn_single_item() -> void:
	if current_round > max_spawn_round:
		return

	if item_scene == null:
		item_scene = load("res://games/chapter_one/hometown/building_one/Level3/items.tscn")

	var panel_size: Vector2 = spawn_panel.size
	var spacing: float = 130.0
	var center_x: float = panel_size.x / 2.0
	var start_y: float = (panel_size.y - float(items.size()) * spacing) / 2.0

	#  Create new item
	var new_item := item_scene.instantiate() as Area2D
	item_holder.add_child(new_item)
	new_item.spawner_ref = self
	new_item.placed = false

	#  Place it visually at the next free slot
	var next_slot := 0
	for i in items:
		if i and is_instance_valid(i) and not i.placed:
			next_slot += 1

	var target_y: float = start_y + float(next_slot) * spacing
	new_item.position = Vector2(center_x, target_y)
	new_item.original_index = next_slot
	new_item.spawn_local_position = new_item.position

	#  Setup random data
	if not item_data.is_empty():
		var random_item = _get_unique_random_item()
		if random_item and new_item.has_method("setup"):
			new_item.setup(random_item)
			new_item.item_id = random_item["id"]
	else:
		new_item.setup("Placeholder")

	#  Add to tracking
	items.append(new_item)

	#  Smooth animation (spawn pop)
	var tween := create_tween()
	new_item.scale = Vector2(0.0, 0.0)
	tween.tween_property(new_item, "scale", Vector2(1, 1), 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	_realign_unplaced_items()


func _get_unique_random_item() -> Dictionary:
	if item_data.is_empty():
		return {}
	var available := item_data.filter(func(d): return not used_items.has(d["name"]))
	if available.is_empty():
		used_items.clear()
		available = item_data.duplicate(true)
	var random_item: Dictionary = available.pick_random()
	used_items.append(random_item["name"])
	return random_item

# --- Sorting & Undo as before ---
func auto_sort(placed_item: Area2D) -> void:
	if not placed_history.has(placed_item):
		placed_history.append(placed_item)

	var spacing: float = 130.0
	var panel_size: Vector2 = spawn_panel.size
	var center_x: float = panel_size.x / 2.0
	var start_y: float = (panel_size.y - float(items.size() - 1) * spacing) / 2.0

	# ✅ Filter out freed items before looping
	items = items.filter(func(i): return is_instance_valid(i))

	for i in range(items.size()):
		var item = items[i]

		# ✅ Skip invalid or freed items
		if not is_instance_valid(item):
			continue

		if item.placed:
			continue

		var new_index = i
		for j in range(i):
			if is_instance_valid(items[j]) and items[j].placed:
				new_index -= 1

		var new_y = start_y + new_index * spacing
		var tween := create_tween()
		tween.tween_property(item, "position", Vector2(center_x, new_y), 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		item.spawn_local_position = Vector2(center_x, new_y)


func undo_last_placement() -> void:
	if placed_history.is_empty():
		return

	var last_item: Area2D = placed_history.pop_back()
	last_item.placed = false
	last_item.set_drag_enabled(true)

	# ✅ Restore the Sprite2D size
	if last_item.has_node("Sprite2D"):
		var sprite: Sprite2D = last_item.get_node("Sprite2D")
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.25)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

	# --- Move the item back to its spawn slot ---
	var spacing: float = 130.0
	var panel_size: Vector2 = spawn_panel.size
	var center_x: float = panel_size.x / 2.0
	var start_y: float = (panel_size.y - float(items.size() - 1) * spacing) / 2.0
	var target_y := start_y + float(last_item.original_index) * spacing

	var tween := create_tween()
	tween.tween_property(last_item, "position", Vector2(center_x, target_y), 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	last_item.spawn_local_position = Vector2(center_x, target_y)

	# Re-align remaining items
	_realign_unplaced_items()


func _realign_unplaced_items() -> void:
	var spacing: float = 130.0
	var panel_size: Vector2 = spawn_panel.size
	var center_x: float = panel_size.x / 2.0
	var start_y: float = (panel_size.y - float(items.size() - 1) * spacing) / 2.0
	var next_slot := 0
	for item in items:
		if item.placed:
			continue
		var target_pos = Vector2(center_x, start_y + float(next_slot) * spacing)
		next_slot += 1
		var tween := create_tween()
		tween.tween_property(item, "position", target_pos, 0.3)
		item.spawn_local_position = target_pos
