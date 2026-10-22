extends Node

@onready var label = $CanvasLayer/Button/Label
@onready var start_button: Button = $CanvasLayer/Button
@onready var game_icon: TextureRect = $CanvasLayer/GameIcon

var _starting := false
var _intro_tween: Tween = null
var _pulse_tween: Tween = null

func _ready():
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	_apply_responsive_layout()

	# Start with label hidden while game icon plays fade in / fade out
	if label != null:
		label.modulate.a = 0.0

	if game_icon != null:
		game_icon.modulate.a = 0.0
		_intro_tween = create_tween()
		# Fade in game icon
		_intro_tween.tween_property(game_icon, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Hold
		_intro_tween.tween_interval(0.6)
		# Fade out game icon
		_intro_tween.tween_property(game_icon, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# When icon fade out completes, show and pulse the START label
		_intro_tween.tween_callback(_start_label_pulse)
	else:
		_start_label_pulse()


func _start_label_pulse() -> void:
	if label == null:
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		return
	label.modulate.a = 1.0
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(label, "modulate:a", 0.0, 0.5)
	_pulse_tween.tween_property(label, "modulate:a", 1.0, 2.0)


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
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if game_icon != null:
		game_icon.modulate.a = 0.0
	start_button.disabled = true
	var success: bool = await FadeManager.fade_and_change("res://games/main.tscn", 0.5)
	if not success and is_inside_tree():
		_starting = false
		start_button.disabled = false
