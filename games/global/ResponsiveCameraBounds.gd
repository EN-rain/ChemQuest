extends Camera2D

## Keeps a world camera inside its authored map rectangle. The rectangle is
## expressed in world/design coordinates, so changing the window size never
## changes player physics or object positions.

@export var authored_bounds := Rect2()
@export var extra_margin := 0.0


func _ready() -> void:
	_apply_bounds()
	_apply_saved_fov()
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)


func _apply_saved_fov() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	var fov_val: float = clampf(float(config.get_value("display", "fov", 50.0)), 0.0, 100.0)
	var target_zoom := lerpf(0.8, 0.4, fov_val / 100.0)
	zoom = Vector2(target_zoom, target_zoom)



func _exit_tree() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.disconnect(_on_layout_changed)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	# Limits are in world space, but reapplying keeps the camera's internal
	# bounds cache correct after a stretch/viewport transform change.
	_apply_bounds()


func _apply_bounds() -> void:
	if authored_bounds.size.x <= 0.0 or authored_bounds.size.y <= 0.0:
		return
	var bounds := authored_bounds.grow(maxf(0.0, extra_margin))
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	limit_smoothed = true
