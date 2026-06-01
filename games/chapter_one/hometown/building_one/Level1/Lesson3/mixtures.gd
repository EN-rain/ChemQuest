class_name Mixture
extends Area2D

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

var mixture_data: Dictionary = {}
var dragging: bool = false
static var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO 
var locked: bool = false

func _ready() -> void:
	input_pickable = true
	add_to_group("mixtures")

func set_data(data: Dictionary) -> void:
	mixture_data = data
	var lbl: Label = $Label   # get it fresh
	if lbl:
		lbl.text = data.get("name", "Unknown Mixture")
	else:
		print("Label missing in scene!")



# Called when the Area2D receives a direct input event (mouse/touch press)
func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	# mouse press
	if event is InputEventMouseButton and event.pressed and not Mixture.is_dragging:
		dragging = true
		Mixture.is_dragging = true
		drag_offset = global_position - get_global_mouse_position()
		move_to_front()  # 👈 bring this mixture on top immediately
	# touch press
	elif event is InputEventScreenTouch and event.pressed and not Mixture.is_dragging:
		dragging = true
		Mixture.is_dragging = true
		drag_offset = global_position - event.position
		move_to_front()  # 👈 same for touch


# Handle motion + release events (mouse motion, screen drag, or release)
func _unhandled_input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + drag_offset
	elif event is InputEventScreenDrag:
		global_position = event.position + drag_offset
	# release by mouse or release by touch
	elif (event is InputEventMouseButton and not event.pressed) \
		or (event is InputEventScreenTouch and not event.pressed):
		stop_dragging()

func stop_dragging() -> void:
	if dragging:
		dragging = false
		Mixture.is_dragging = false
