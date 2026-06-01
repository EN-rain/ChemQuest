class_name Item
extends Area2D

var spawn_local_position: Vector2
var dragging := false
static var is_dragging := false
var drag_offset := Vector2.ZERO
var drag_enabled := true
var placed := false  #  NEW: becomes true when dropped into a holder
var spawner_ref: Node = null  # assigned from Spawner
var spawn_index: int = -1     # index in list
var original_index: int = -1        # permanent spawn slot
var item_id: String = ""
var feedback: Dictionary = {}
var separation: Array[String] = []

func _ready() -> void:
	input_pickable = true
	add_to_group("items")
	call_deferred("_store_spawn_position")

# --- Setup called by Spawner ---
func setup(item_data: Dictionary) -> void:
	item_id = item_data.get("id", "")
	var label: Label = $Label
	if label:
		label.text = item_data.get("name", "Unknown").capitalize()
	else:
		push_warning("⚠️ Label node not found in %s" % name)

	feedback = item_data.get("feedback", {})

	#  Safe conversion for typed Array[String]
	separation.clear()
	var sep_data = item_data.get("separation", [])
	for s in sep_data:
		if typeof(s) == TYPE_STRING:
			separation.append(s)

	print("🧱 Item setup:", item_data.get("name", "Unknown"))



func _store_spawn_position() -> void:
	spawn_local_position = position
	print(name, "stored spawn position:", spawn_local_position)


func set_drag_enabled(enabled: bool) -> void:
	drag_enabled = enabled
	if not enabled:
		stop_dragging()


func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if not drag_enabled or placed:
		return

	if event is InputEventMouseButton and event.pressed and not Item.is_dragging:
		dragging = true
		Item.is_dragging = true
		drag_offset = global_position - get_global_mouse_position()
		move_to_front()


func _unhandled_input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + drag_offset
	elif event is InputEventMouseButton and not event.pressed:
		stop_dragging()


func stop_dragging() -> void:
	if dragging:
		dragging = false
		Item.is_dragging = false

		#  Only return to original if not placed
		if not placed:
			return_to_spawn_position()


func return_to_spawn_position() -> void:
	print(name, "returning to", spawn_local_position)
	var tween := create_tween()
	tween.tween_property(self, "position", spawn_local_position, 0.25)
