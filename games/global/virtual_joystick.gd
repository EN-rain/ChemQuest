class_name VirtualJoystick
extends Control

## Virtual touch joystick with dynamic touch area for mobile character movement.
## Simulates "left", "right", "up", "down" input actions.

static var is_active: bool = false
static var is_joystick_running: bool = false

@export var clamp_radius: float = 55.0
@export var deadzone: float = 0.18
@export var return_speed: float = 0.16

@onready var base: Panel = $Base
@onready var knob: Panel = $Base/Knob

var _touch_id: int = -1
var _is_dragging: bool = false
var _active_center: Vector2 = Vector2.ZERO
var _default_base_pos: Vector2 = Vector2.ZERO
var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_init_positions()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_PREDELETE:
		_stop_drag()


func _init_positions() -> void:
	# Area size is 340x320. Base size is 160x160.
	# Position base comfortably low and left: x=40, y=size.y - base.size.y - 25
	if base != null:
		var by := maxf(0.0, size.y - base.size.y - 25.0)
		_default_base_pos = Vector2(40.0, by)
		base.position = _default_base_pos
		_active_center = _default_base_pos + base.size * 0.5
	_reset_knob()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _is_dragging:
			_start_drag(event.index, event.position)
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
				_start_drag(-1, event.position)
				accept_event()
			else:
				_stop_drag()
				accept_event()

	elif event is InputEventMouseMotion and _is_dragging:
		_process_drag(event.position)
		accept_event()


func _start_drag(touch_id: int, touch_pos: Vector2) -> void:
	_is_dragging = true
	_touch_id = touch_id
	is_active = true

	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Move base to touch position, clamped so base circle stays inside the touch area
	if base != null:
		var half_base := base.size * 0.5
		var min_pos := Vector2.ZERO
		var max_pos := size - base.size
		var target_pos := touch_pos - half_base
		target_pos.x = clampf(target_pos.x, min_pos.x, max_pos.x)
		target_pos.y = clampf(target_pos.y, min_pos.y, max_pos.y)
		base.position = target_pos
		_active_center = base.position + half_base

	_reset_knob()
	_process_drag(touch_pos)


func _process_drag(touch_pos: Vector2) -> void:
	if base == null or knob == null:
		return

	var diff := touch_pos - _active_center
	var dist := diff.length()
	var dir := diff.normalized() if dist > 0.0 else Vector2.ZERO

	var clamped_dist := minf(dist, clamp_radius)
	var knob_offset := dir * clamped_dist

	knob.position = (base.size * 0.5) + knob_offset - (knob.size * 0.5)

	var norm_vector := (dir * (clamped_dist / clamp_radius)) if clamp_radius > 0.0 else Vector2.ZERO
	_update_actions(norm_vector)


func _update_actions(vector: Vector2) -> void:
	if vector.length() < deadzone:
		_release_all_actions()
		is_joystick_running = false
		return

	is_active = true
	is_joystick_running = (vector.length() >= 0.72)

	var angle_deg := rad_to_deg(vector.angle()) # -180 to 180
	var press_left := false
	var press_right := false
	var press_up := false
	var press_down := false

	# 8-directional sectors (45 degrees each):
	# Pure horizontal/vertical get a dedicated +/-22.5° cone so moving left never veers up.
	if angle_deg >= -22.5 and angle_deg < 22.5:
		press_right = true
	elif angle_deg >= 22.5 and angle_deg < 67.5:
		press_right = true
		press_down = true
	elif angle_deg >= 67.5 and angle_deg < 112.5:
		press_down = true
	elif angle_deg >= 112.5 and angle_deg < 157.5:
		press_down = true
		press_left = true
	elif angle_deg >= 157.5 or angle_deg < -157.5:
		press_left = true
	elif angle_deg >= -157.5 and angle_deg < -112.5:
		press_left = true
		press_up = true
	elif angle_deg >= -112.5 and angle_deg < -67.5:
		press_up = true
	elif angle_deg >= -67.5 and angle_deg < -22.5:
		press_up = true
		press_right = true

	_apply_action("left", press_left)
	_apply_action("right", press_right)
	_apply_action("up", press_up)
	_apply_action("down", press_down)


func _apply_action(action: String, pressed: bool) -> void:
	if pressed:
		if not Input.is_action_pressed(action):
			Input.action_press(action)
	else:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _stop_drag() -> void:
	_is_dragging = false
	_touch_id = -1
	is_active = false
	is_joystick_running = false
	_reset_knob()
	_release_all_actions()

	# Smoothly return base to default rest position
	if base != null:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_property(base, "position", _default_base_pos, return_speed)
		_tween.tween_callback(func():
			_active_center = _default_base_pos + base.size * 0.5
		)


func _reset_knob() -> void:
	if knob != null and base != null:
		knob.position = (base.size * 0.5) - (knob.size * 0.5)


func _release_all_actions() -> void:
	is_active = false
	is_joystick_running = false
	if Input.is_action_pressed("left"):
		Input.action_release("left")
	if Input.is_action_pressed("right"):
		Input.action_release("right")
	if Input.is_action_pressed("up"):
		Input.action_release("up")
	if Input.is_action_pressed("down"):
		Input.action_release("down")
