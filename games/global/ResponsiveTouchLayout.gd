extends CanvasLayer

## Repositions embedded TouchScreenButtons against the current logical
## viewport. The gameplay scenes keep their existing input actions and button
## textures; only the CanvasLayer layout changes.

@export var control_path: NodePath = NodePath("Control")
@export var edge_margin := 24.0
@export var button_gap := 24.0
@export var vertical_gap := 24.0

var _control: Control


func _ready() -> void:
	_control = get_node_or_null(control_path) as Control
	if _control == null:
		return
	_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	_apply_layout()


func _exit_tree() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.disconnect(_on_layout_changed)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_layout()


func _apply_layout() -> void:
	if _control == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var usable_rect := Rect2(
		Vector2(edge_margin, edge_margin),
		Vector2(maxf(0.0, viewport_size.x - edge_margin * 2.0), maxf(0.0, viewport_size.y - edge_margin * 2.0))
	)
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and service.safe_rect.size.x > 0.0 and service.safe_rect.size.y > 0.0:
		usable_rect = service.safe_rect
	var buttons := {
		"Left": _find_touch_button("Left"),
		"Right": _find_touch_button("Right"),
		"Jump": _find_touch_button("Jump"),
		"Pick": _find_touch_button("Pick"),
		"Drop": _find_touch_button("Drop"),
	}
	var left := buttons["Left"] as TouchScreenButton
	var right := buttons["Right"] as TouchScreenButton
	var jump := buttons["Jump"] as TouchScreenButton
	var pick := buttons["Pick"] as TouchScreenButton
	var drop := buttons["Drop"] as TouchScreenButton
	var left_size := _button_size(left)
	var right_size := _button_size(right)
	var jump_size := _button_size(jump)
	var pick_size := _button_size(pick)
	var drop_size := _button_size(drop)
	var movement_bottom := usable_rect.end.y
	if left != null:
		_set_global_position(left, Vector2(usable_rect.position.x, movement_bottom - left_size.y))
	if right != null:
		_set_global_position(right, Vector2(usable_rect.position.x + left_size.x + button_gap, movement_bottom - right_size.y))
	var action_right := usable_rect.end.x
	if jump != null:
		_set_global_position(jump, Vector2(action_right - jump_size.x, movement_bottom - jump_size.y))
	if pick != null:
		_set_global_position(pick, Vector2(action_right - jump_size.x - button_gap - pick_size.x, movement_bottom - pick_size.y))
	if drop != null:
		_set_global_position(drop, Vector2(action_right - jump_size.x - button_gap - drop_size.x, movement_bottom - pick_size.y - vertical_gap - drop_size.y))


func _button_size(button: TouchScreenButton) -> Vector2:
	if button == null or button.texture_normal == null:
		return Vector2.ZERO
	return button.texture_normal.get_size() * button.scale.abs()


func _find_touch_button(button_name: String) -> TouchScreenButton:
	if _control == null:
		return null
	return _control.find_child(button_name, true, false) as TouchScreenButton


func _set_global_position(button: TouchScreenButton, target: Vector2) -> void:
	button.global_position = target
