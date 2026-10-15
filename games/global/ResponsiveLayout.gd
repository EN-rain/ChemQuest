extends Node

## Shared responsive-layout state for the landscape game shell.
##
## Scene UI should use anchors and containers. This service only owns the
## viewport facts that those scenes need to agree on: logical size, safe area,
## and portrait-guard state.

signal layout_changed(viewport_size: Vector2, safe_rect: Rect2)

const REFERENCE_SIZE := Vector2(1280.0, 720.0)
const MIN_DESKTOP_WINDOW_SIZE := Vector2i(854, 480)
const DEFAULT_SAFE_MARGIN := 24.0

var viewport_size := REFERENCE_SIZE
var safe_rect := Rect2(Vector2.ZERO, REFERENCE_SIZE)
var is_landscape := true

var _orientation_guard: Control
var _root_window: Window


func _ready() -> void:
	_root_window = get_tree().root
	if _root_window != null and not _root_window.size_changed.is_connected(_on_root_window_resized):
		_root_window.size_changed.connect(_on_root_window_resized)
	_apply_desktop_minimum_size()
	_create_orientation_guard()
	_refresh_layout()


static func is_landscape_size(size: Vector2) -> bool:
	return size.x > size.y


static func uniform_scale(available_size: Vector2, design_size: Vector2) -> float:
	if available_size.x <= 0.0 or available_size.y <= 0.0 or design_size.x <= 0.0 or design_size.y <= 0.0:
		return 0.0
	return minf(available_size.x / design_size.x, available_size.y / design_size.y)


static func safe_rect_for(size: Vector2, insets: Vector4) -> Rect2:
	var safe_size := Vector2(
		maxf(0.0, size.x - maxf(0.0, insets.x) - maxf(0.0, insets.z)),
		maxf(0.0, size.y - maxf(0.0, insets.y) - maxf(0.0, insets.w))
	)
	var safe_position := Vector2(maxf(0.0, insets.x), maxf(0.0, insets.y))
	if safe_position.x > size.x:
		safe_position.x = size.x
	if safe_position.y > size.y:
		safe_position.y = size.y
	return Rect2(safe_position, safe_size)


func _on_root_window_resized() -> void:
	_refresh_layout()


func _refresh_layout() -> void:
	var visible_size := get_viewport().get_visible_rect().size
	if visible_size.x <= 0.0 or visible_size.y <= 0.0:
		visible_size = REFERENCE_SIZE
	viewport_size = visible_size
	var insets := _safe_insets_for_viewport(visible_size)
	safe_rect = safe_rect_for(visible_size, insets)
	is_landscape = is_landscape_size(visible_size)
	if _orientation_guard != null:
		_orientation_guard.visible = not is_landscape
	layout_changed.emit(viewport_size, safe_rect)


func _safe_insets_for_viewport(visible_size: Vector2) -> Vector4:
	var fallback := Vector4(DEFAULT_SAFE_MARGIN, DEFAULT_SAFE_MARGIN, DEFAULT_SAFE_MARGIN, DEFAULT_SAFE_MARGIN)
	if DisplayServer.get_name() == "headless":
		return fallback
	var screen := DisplayServer.get_primary_screen()
	var screen_size_i := DisplayServer.screen_get_size(screen)
	var safe_area := DisplayServer.get_display_safe_area()
	if screen_size_i.x <= 0 or screen_size_i.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return fallback
	var screen_size := Vector2(screen_size_i)
	var scale := Vector2(visible_size.x / screen_size.x, visible_size.y / screen_size.y)
	var platform_insets := Vector4(
		maxf(0.0, float(safe_area.position.x) * scale.x),
		maxf(0.0, float(safe_area.position.y) * scale.y),
		maxf(0.0, float(screen_size_i.x - safe_area.end.x) * scale.x),
		maxf(0.0, float(screen_size_i.y - safe_area.end.y) * scale.y)
	)
	return Vector4(
		maxf(fallback.x, platform_insets.x),
		maxf(fallback.y, platform_insets.y),
		maxf(fallback.z, platform_insets.z),
		maxf(fallback.w, platform_insets.w)
	)


func _apply_desktop_minimum_size() -> void:
	if _root_window == null or DisplayServer.get_name() == "headless":
		return
	if OS.has_feature("pc"):
		_root_window.min_size = MIN_DESKTOP_WINDOW_SIZE


func _create_orientation_guard() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "ResponsiveOrientationGuard"
	add_child(canvas_layer)

	_orientation_guard = ColorRect.new()
	_orientation_guard.name = "RotateDeviceOverlay"
	_orientation_guard.color = Color("101018")
	_orientation_guard.mouse_filter = Control.MOUSE_FILTER_STOP
	_orientation_guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(_orientation_guard)

	var message := Label.new()
	message.name = "Message"
	message.text = "Please rotate your device to landscape"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 32)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message.custom_minimum_size = Vector2(480, 96)
	message.position = Vector2(-240, -48)
	message.size = Vector2(480, 96)
	_orientation_guard.add_child(message)
