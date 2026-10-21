extends Control

## Virtual touch joystick for mobile character movement.
## Simulates "left", "right", "up", "down" input actions.

@export var clamp_radius: float = 55.0
@export var deadzone: float = 0.18

@onready var base: Panel = $Base
@onready var knob: Panel = $Base/Knob

var _touch_id: int = -1
var _is_dragging: bool = false
var _center: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_center = size * 0.5
	if base != null:
		base.position = _center - base.size * 0.5
	_reset_knob()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_PREDELETE:
		_release_all_actions()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _is_dragging:
			_touch_id = event.index
			_is_dragging = true
			_process_drag(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_id:
			_stop_drag()
			accept_event()

	elif event is InputEventScreenDrag:
		if _is_dragging and event.index == _touch_id:
			_process_drag(event.position)
			accept_event()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_touch_id = -1
				_process_drag(event.position)
				accept_event()
			else:
				_stop_drag()
				accept_event()

	elif event is InputEventMouseMotion and _is_dragging:
		_process_drag(event.position)
		accept_event()


func _process_drag(touch_pos: Vector2) -> void:
	_center = size * 0.5
	var diff := touch_pos - _center
	var dist := diff.length()
	var dir := diff.normalized() if dist > 0.0 else Vector2.ZERO

	var clamped_dist := minf(dist, clamp_radius)
	var knob_offset := dir * clamped_dist

	if knob != null and base != null:
		knob.position = (base.size * 0.5) + knob_offset - (knob.size * 0.5)

	var norm_vector := (dir * (clamped_dist / clamp_radius)) if clamp_radius > 0.0 else Vector2.ZERO
	_update_actions(norm_vector)


func _update_actions(vector: Vector2) -> void:
	# Horizontal
	if vector.x > deadzone:
		Input.action_press("right")
		Input.action_release("left")
	elif vector.x < -deadzone:
		Input.action_press("left")
		Input.action_release("right")
	else:
		Input.action_release("left")
		Input.action_release("right")

	# Vertical
	if vector.y > deadzone:
		Input.action_press("down")
		Input.action_release("up")
	elif vector.y < -deadzone:
		Input.action_press("up")
		Input.action_release("down")
	else:
		Input.action_release("up")
		Input.action_release("down")


func _stop_drag() -> void:
	_is_dragging = false
	_touch_id = -1
	_reset_knob()
	_release_all_actions()


func _reset_knob() -> void:
	if knob != null and base != null:
		knob.position = (base.size * 0.5) - (knob.size * 0.5)


func _release_all_actions() -> void:
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")
