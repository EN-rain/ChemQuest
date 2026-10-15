extends Control
class_name FixedAspectSurface

## Keeps one authored child at a fixed design size and scales it uniformly to
## the available rectangle. This is for dense art-directed UI, not ordinary
## menus that should use anchors and containers.

@export var design_size := Vector2(1280.0, 720.0)


static func calculate_scale(available_size: Vector2, authored_size := Vector2(1280.0, 720.0)) -> float:
	if available_size.x <= 0.0 or available_size.y <= 0.0 or authored_size.x <= 0.0 or authored_size.y <= 0.0:
		return 0.0
	return minf(
		available_size.x / authored_size.x,
		available_size.y / authored_size.y
	)


func _ready() -> void:
	_layout_child()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_child()


func _layout_child() -> void:
	if get_child_count() == 0:
		return
	var child := get_child(0) as Control
	if child == null or design_size.x <= 0.0 or design_size.y <= 0.0:
		return
	var scale_factor := calculate_scale(size, design_size)
	child.position = (size - design_size * scale_factor) * 0.5
	child.size = design_size
	child.scale = Vector2.ONE * scale_factor
