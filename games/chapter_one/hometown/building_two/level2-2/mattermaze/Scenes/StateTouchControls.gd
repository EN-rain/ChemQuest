extends CanvasLayer

## Shared touch controls for the states-of-matter tutorial and levels.
## Buttons press/release the existing input actions so keyboard and touch use
## exactly the same player code path.

const BUTTON_SIZE := Vector2(80.0, 72.0)
const GROUP_GAP := 10.0
const EDGE_MARGIN := 24.0

var _root: Control
var _movement: HBoxContainer
var _actions: HBoxContainer
var _pressed_actions: Dictionary = {}
var _service: Node


func _ready() -> void:
	layer = 20
	_build_controls()
	_service = get_node_or_null("/root/ResponsiveLayout")
	if _service != null and not _service.layout_changed.is_connected(_on_layout_changed):
		_service.layout_changed.connect(_on_layout_changed)
	_layout_controls()
	call_deferred("_layout_controls")


func _exit_tree() -> void:
	for action in _pressed_actions.keys():
		Input.action_release(action)
	_pressed_actions.clear()
	if _service != null and _service.layout_changed.is_connected(_on_layout_changed):
		_service.layout_changed.disconnect(_on_layout_changed)


func _build_controls() -> void:
	_root = Control.new()
	_root.name = "Control"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_movement = HBoxContainer.new()
	_movement.name = "Movement"
	_movement.add_theme_constant_override("separation", GROUP_GAP)
	_movement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_movement)
	_add_action_button(_movement, "◀", "left")
	_add_action_button(_movement, "▶", "right")

	_actions = HBoxContainer.new()
	_actions.name = "Actions"
	_actions.add_theme_constant_override("separation", GROUP_GAP)
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_actions)
	_add_action_button(_actions, "JUMP", "jump")
	_add_action_button(_actions, "SOLID", "Solid")
	_add_action_button(_actions, "LIQUID", "Liquid")
	_add_action_button(_actions, "GAS", "Gas")


func _add_action_button(parent: Container, label: String, action: String) -> void:
	var button := Button.new()
	button.name = action
	button.text = label
	button.custom_minimum_size = BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 18)
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	button.mouse_exited.connect(_release_action.bind(action))
	parent.add_child(button)


func _press_action(action: String) -> void:
	if _pressed_actions.has(action):
		return
	_pressed_actions[action] = true
	Input.action_press(action)


func _release_action(action: String) -> void:
	if not _pressed_actions.has(action):
		return
	_pressed_actions.erase(action)
	Input.action_release(action)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_layout_controls()


func _layout_controls() -> void:
	if _root == null or _movement == null or _actions == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var usable := Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN), viewport_size - Vector2(EDGE_MARGIN * 2.0, EDGE_MARGIN * 2.0))
	if _service != null and _service.safe_rect.size.x > 0.0 and _service.safe_rect.size.y > 0.0:
		usable = _service.safe_rect

	_movement.size = _movement.get_combined_minimum_size()
	_actions.size = _actions.get_combined_minimum_size()
	_movement.position = Vector2(usable.position.x, usable.end.y - _movement.size.y)
	_actions.position = Vector2(usable.end.x - _actions.size.x, usable.end.y - _actions.size.y)
