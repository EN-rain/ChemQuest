class_name Atom
extends Area2D

@onready var shape: CollisionShape2D = $CollisionShape2D

var dragging: bool = false
static var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_enabled: bool = true
const SPRITE_PATH := "res://assets/atom_colors/"  # adjust to your folder

func _ready():
	input_pickable = true   # make sure the Area2D receives clicks/touches
	add_to_group("atoms") 

func set_element(element: Dictionary) -> void:
	var lbl: Label = $Label
	if lbl:
		var symbol: String = element.get("symbol", "?")
		lbl.text = symbol

	var color_name: String = element.get("color", "pink")
	_apply_color_sprite(color_name)

func _apply_color_sprite(color_name: String) -> void:
	var sprite: Sprite2D = $Sprite2D
	var c = color_name.strip_edges().to_lower()
	var file_path = SPRITE_PATH + c + ".png"
	if ResourceLoader.exists(file_path):
		sprite.texture = load(file_path)
	elif ResourceLoader.exists(SPRITE_PATH + "pink.png"):
		sprite.texture = load(SPRITE_PATH + "pink.png")

func set_drag_enabled(value: bool) -> void:
	drag_enabled = value
	input_pickable = value
	if not value:
		stop_dragging()

# Handle press on this atom
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and not Atom.is_dragging:
		dragging = true
		Atom.is_dragging = true
		drag_offset = global_position - get_global_mouse_position()

	elif event is InputEventScreenTouch and event.pressed and not Atom.is_dragging:
		dragging = true
		Atom.is_dragging = true
		drag_offset = global_position - event.position

# Handle motion + release
func _unhandled_input(event):
	if dragging:
		if event is InputEventMouseMotion:
			global_position = get_global_mouse_position() + drag_offset
		elif event is InputEventScreenDrag:
			global_position = event.position + drag_offset
		elif (event is InputEventMouseButton and not event.pressed) \
			or (event is InputEventScreenTouch and not event.pressed):
			stop_dragging()

func stop_dragging():
	if dragging:
		dragging = false
		Atom.is_dragging = false
