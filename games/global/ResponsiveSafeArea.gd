extends MarginContainer
class_name ResponsiveSafeArea

## Full-rect container that keeps its children away from display cutouts and
## the game's minimum logical edge margin.

@export var minimum_margin := 24.0

var current_safe_rect := Rect2()


func _ready() -> void:
	_update_from_service()
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)


func _exit_tree() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.disconnect(_on_layout_changed)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_update_from_service()


func _update_from_service() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		return
	current_safe_rect = service.safe_rect
	var viewport_size: Vector2 = service.viewport_size
	var left := maxf(minimum_margin, current_safe_rect.position.x)
	var top := maxf(minimum_margin, current_safe_rect.position.y)
	var right := maxf(minimum_margin, viewport_size.x - current_safe_rect.end.x)
	var bottom := maxf(minimum_margin, viewport_size.y - current_safe_rect.end.y)
	add_theme_constant_override("margin_left", ceili(left))
	add_theme_constant_override("margin_top", ceili(top))
	add_theme_constant_override("margin_right", ceili(right))
	add_theme_constant_override("margin_bottom", ceili(bottom))
