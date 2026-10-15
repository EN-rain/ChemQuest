extends Node

@onready var label = $CanvasLayer/Button/Label
@onready var start_button: Button = $CanvasLayer/Button

var _starting := false

func _ready():
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	_apply_responsive_layout()
	var tween = create_tween()
	tween.set_loops() # loop forever
	tween.tween_property(label, "modulate:a", 0.0, 0.5) # fade out
	tween.tween_property(label, "modulate:a", 1.0, 2.0) # fade in


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if label == null:
		return
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		return
	var scale_factor: float = service.uniform_scale(service.viewport_size, Vector2(1280.0, 720.0))
	if scale_factor <= 0.0:
		return
	# Keep the authored pixel-art title legible without allowing it to grow
	# beyond the compact start surface on tall desktop windows.
	label.add_theme_font_size_override("font_size", roundi(clampf(250.0 * scale_factor, 180.0, 300.0)))

func _on_button_pressed() -> void:
	if _starting:
		return
	_starting = true
	start_button.disabled = true
	var success: bool = await FadeManager.fade_and_change("res://games/main.tscn", 0.5)
	if not success and is_inside_tree():
		_starting = false
		start_button.disabled = false
