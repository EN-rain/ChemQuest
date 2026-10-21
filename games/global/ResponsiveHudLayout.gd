extends CanvasLayer

## Shared layout adapter for authored HUDs.
##
## Existing scenes keep their node names and signal paths; this adapter only
## moves the shell controls into the current safe rectangle when the window
## changes. Gameplay nodes and their world coordinates are never touched.

@export var edge_margin := 24.0
@export var control_gap := 16.0
@export var bottom_panel_height := 236.0

var _service: Node


func _ready() -> void:
	_service = get_node_or_null("/root/ResponsiveLayout")
	if _service != null and not _service.layout_changed.is_connected(_on_layout_changed):
		_service.layout_changed.connect(_on_layout_changed)
	# TextureButton and themed Button sizes can settle one frame after scene
	# instantiation, so apply once now and once deferred.
	_apply_layout()
	call_deferred("_apply_layout")


func _exit_tree() -> void:
	if _service != null and _service.layout_changed.is_connected(_on_layout_changed):
		_service.layout_changed.disconnect(_on_layout_changed)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_layout()


func _apply_layout() -> void:
	if _service == null:
		_service = get_node_or_null("/root/ResponsiveLayout")
	if _service == null:
		return
	var viewport_size: Vector2 = _service.viewport_size
	var safe_rect: Rect2 = _service.safe_rect
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		safe_rect = Rect2(Vector2(edge_margin, edge_margin), viewport_size - Vector2(edge_margin * 2.0, edge_margin * 2.0))

	var content := get_node_or_null("MarginContainer/Control") as Control
	if content == null:
		content = get_node_or_null("Control") as Control

	var back := _find_control("BackButton", content)
	if back != null:
		_set_global_position(back, safe_rect.position)

	var menu_button := _find_control("MenuButton", content)
	if menu_button != null:
		_set_global_position(menu_button, safe_rect.position + Vector2(0.0, _visual_size(back).y + control_gap))

	var music := _find_control("MusicButton", content)
	var map := _find_control("MapButton", content)
	var settings_btn := _find_control("ingamesettings", content)

	var current_right := safe_rect.end.x
	if map != null and map.visible:
		_set_global_position(map, Vector2(current_right - _visual_size(map).x, safe_rect.position.y))
		current_right -= _visual_size(map).x + control_gap

	if settings_btn != null and settings_btn.visible:
		var btn_sz := _visual_size(settings_btn)
		var map_h := _visual_size(map).y if (map != null and map.visible) else btn_sz.y
		var btn_y := safe_rect.position.y + maxf(0.0, (map_h - btn_sz.y) * 0.5)
		_set_global_position(settings_btn, Vector2(current_right - btn_sz.x, btn_y))
		current_right -= btn_sz.x + control_gap

	if music != null:
		if music.visible:
			_set_global_position(music, Vector2(current_right - _visual_size(music).x, safe_rect.position.y))
		else:
			_set_global_position(music, safe_rect.position)

	# QuestPanel positioning belongs to each .tscn scene. Do not override
	# the editor-authored anchors, offsets, or position at runtime.

	var dialogue := _find_control("DialogueBox", content)
	if dialogue != null:
		_set_bottom_panel(dialogue, safe_rect)
	var feedback := _find_control("FeedbackPanel", content)
	if feedback != null:
		_set_bottom_panel(feedback, safe_rect)

	var fire_button := _find_control("FireButton", content)
	if fire_button != null:
		# Precision/Accuracy's authored button has a decorative child that
		# extends below the button's bottom anchor. Move the parent by the
		# overflow amount so both the artwork and hit target stay usable.
		var fire_art := fire_button.get_node_or_null("Sprite2D") as Control
		if fire_art != null:
			var overflow := fire_art.get_global_rect().end.y - safe_rect.end.y
			if overflow > 0.0:
				fire_button.global_position.y -= overflow

	# Cutscene/lesson controls live below the authored MarginContainer/Control.
	if content != null:
		var skip := content.get_node_or_null("Skip") as Control
		if skip != null:
			_set_global_position(skip, Vector2(safe_rect.end.x - _visual_size(skip).x, safe_rect.position.y))
		var next := content.get_node_or_null("Next") as Control
		if next != null:
			_set_global_position(next, Vector2(safe_rect.end.x - _visual_size(next).x, safe_rect.end.y - _visual_size(next).y))
		var prologue := content.get_node_or_null("PrologueLabel") as Control
		if prologue != null:
			var prologue_size := _visual_size(prologue)
			var max_width := maxf(0.0, safe_rect.size.x - 2.0 * edge_margin)
			if prologue.size.x > max_width:
				prologue.size.x = max_width
			_set_global_position(prologue, Vector2(safe_rect.position.x + (safe_rect.size.x - prologue_size.x) * 0.5, safe_rect.position.y + (safe_rect.size.y - prologue_size.y) * 0.5))

	var game_panel := _find_control("GamePanel", content)
	if game_panel != null:
		_center_panel(game_panel, safe_rect)

	var state_label := get_node_or_null("StateLabel") as Control
	if state_label != null:
		_set_global_position(state_label, safe_rect.position + Vector2(control_gap, control_gap))


func _top_stack_height() -> float:
	var total := 0.0
	var content := get_node_or_null("MarginContainer/Control") as Control
	if content == null:
		content = get_node_or_null("Control") as Control
	var back := _find_control("BackButton", content)
	if back != null and back.visible:
		total = maxf(total, _visual_size(back).y)
	var map := _find_control("MapButton", content)
	if map != null and map.visible:
		total = maxf(total, _visual_size(map).y)
	var settings_btn := _find_control("ingamesettings", content)
	if settings_btn != null and settings_btn.visible:
		total = maxf(total, _visual_size(settings_btn).y)
	var music := _find_control("MusicButton", content)
	if music != null and music.visible:
		total = maxf(total, _visual_size(music).y)
	return total


func _set_bottom_panel(control: Control, safe_rect: Rect2) -> void:
	var panel_size := _visual_size(control)
	var height := panel_size.y if panel_size.y > 0.0 else bottom_panel_height
	if control.scale.x == 1.0 and control.scale.y == 1.0:
		control.size.x = safe_rect.size.x
		panel_size.x = safe_rect.size.x
	_set_global_position(control, Vector2(safe_rect.position.x, safe_rect.end.y - height))


func _center_panel(control: Control, safe_rect: Rect2) -> void:
	var panel_size := _visual_size(control)
	_set_global_position(control, safe_rect.position + (safe_rect.size - panel_size) * 0.5)


func _set_global_position(control: Control, target: Vector2) -> void:
	control.global_position = target


func _visual_size(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO
	var value := control.size * control.scale.abs()
	if value.x <= 0.0 or value.y <= 0.0:
		if control is TextureButton:
			var texture_button := control as TextureButton
			if texture_button.texture_normal != null:
				value = texture_button.texture_normal.get_size() * texture_button.scale.abs()
	return value


func _find_control(node_name: String, content: Control = null) -> Control:
	var direct := get_node_or_null(node_name) as Control
	if direct != null:
		return direct
	if content != null:
		var nested := content.get_node_or_null(node_name) as Control
		if nested != null:
			return nested
	return null
