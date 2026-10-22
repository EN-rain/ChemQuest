extends CanvasLayer

## Shared touch controls for the states-of-matter tutorial and levels.
## Buttons press/release the existing input actions so keyboard and touch use
## exactly the same player code path. Also provides a persistent top-left BACK button
## and exit confirmation dialog to return safely to Building Two.

const BACK_ICON_PATH := "res://assets/back.png"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"
const ROBOTO_FONT_PATH := "res://assets/Roboto-BoldCondensed.ttf"
const BUTTON_SIZE := Vector2(80.0, 72.0)
const GROUP_GAP := 10.0
const EDGE_MARGIN := 24.0

var _root: Control
var _movement: HBoxContainer
var _actions: HBoxContainer
var _back_button: Button
var _back_modal: Control
var _pressed_actions: Dictionary = {}
var _service: Node


func _ready() -> void:
	layer = 20
	_build_controls()
	_build_back_modal()
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

	_build_back_button()


func _build_back_button() -> void:
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.flat = true
	_back_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_button.custom_minimum_size = Vector2(170.0, 52.0)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 10)
	_back_button.add_child(hbox)

	var icon_rect := TextureRect.new()
	if ResourceLoader.exists(BACK_ICON_PATH):
		icon_rect.texture = load(BACK_ICON_PATH)
	icon_rect.custom_minimum_size = Vector2(40.0, 40.0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_rect)

	var label := Label.new()
	label.text = "BACK"
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)

	_back_button.pressed.connect(_on_back_pressed)
	_root.add_child(_back_button)


func _build_back_modal() -> void:
	_back_modal = Control.new()
	_back_modal.name = "BackModal"
	_back_modal.visible = false
	_back_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_back_modal)

	var dim := ColorRect.new()
	dim.name = "DimBackdrop"
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back_modal.add_child(dim)

	var card := PanelContainer.new()
	card.name = "ModalCard"
	card.custom_minimum_size = Vector2(420.0, 200.0)
	card.anchors_preset = Control.PRESET_CENTER
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -210.0
	card.offset_top = -100.0
	card.offset_right = 210.0
	card.offset_bottom = 100.0

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.1, 0.12, 0.96)
	card_style.set_corner_radius_all(14)
	card_style.border_color = Color(0.32, 0.35, 0.42, 0.85)
	card_style.set_border_width_all(2)
	card_style.content_margin_left = 28
	card_style.content_margin_right = 28
	card_style.content_margin_top = 22
	card_style.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", card_style)
	_back_modal.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "EXIT PUZZLE?"
	if ResourceLoader.exists(FONT_PATH):
		title_lbl.add_theme_font_override("font", load(FONT_PATH))
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Return to Building Two?\nYour progress in this room will be reset."
	if ResourceLoader.exists(ROBOTO_FONT_PATH):
		desc_lbl.add_theme_font_override("font", load(ROBOTO_FONT_PATH))
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	vbox.add_child(spacer)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var no_btn := Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(130.0, 44.0)
	no_btn.focus_mode = Control.FOCUS_NONE
	if ResourceLoader.exists(FONT_PATH):
		no_btn.add_theme_font_override("font", load(FONT_PATH))
	no_btn.add_theme_font_size_override("font_size", 18)
	var no_style := StyleBoxFlat.new()
	no_style.bg_color = Color(0.24, 0.25, 0.3, 0.95)
	no_style.set_corner_radius_all(8)
	no_btn.add_theme_stylebox_override("normal", no_style)
	var no_hover := StyleBoxFlat.new()
	no_hover.bg_color = Color(0.32, 0.34, 0.4, 1.0)
	no_hover.set_corner_radius_all(8)
	no_btn.add_theme_stylebox_override("hover", no_hover)
	no_btn.pressed.connect(_on_no_pressed)
	btn_hbox.add_child(no_btn)

	var yes_btn := Button.new()
	yes_btn.text = "YES"
	yes_btn.custom_minimum_size = Vector2(130.0, 44.0)
	yes_btn.focus_mode = Control.FOCUS_NONE
	if ResourceLoader.exists(FONT_PATH):
		yes_btn.add_theme_font_override("font", load(FONT_PATH))
	yes_btn.add_theme_font_size_override("font_size", 18)
	var yes_style := StyleBoxFlat.new()
	yes_style.bg_color = Color(0.78, 0.22, 0.22, 0.95)
	yes_style.set_corner_radius_all(8)
	yes_btn.add_theme_stylebox_override("normal", yes_style)
	var yes_hover := StyleBoxFlat.new()
	yes_hover.bg_color = Color(0.92, 0.28, 0.28, 1.0)
	yes_hover.set_corner_radius_all(8)
	yes_btn.add_theme_stylebox_override("hover", yes_hover)
	yes_btn.pressed.connect(_on_yes_pressed)
	btn_hbox.add_child(yes_btn)


func _on_back_pressed() -> void:
	_play_sfx("button")
	if _back_modal != null:
		_back_modal.visible = true
	_pause_player(true)


func _on_no_pressed() -> void:
	_play_sfx("button")
	if _back_modal != null:
		_back_modal.visible = false
	_pause_player(false)


func _on_yes_pressed() -> void:
	_play_sfx("button")
	for action in _pressed_actions.keys():
		Input.action_release(action)
	_pressed_actions.clear()
	if has_node("/root/MusicManager"):
		var mm := get_node("/root/MusicManager")
		if mm != null and mm.has_method("stop_music"):
			mm.stop_music()
	SpawnManager.set_spawn("game_spawn")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")


func _pause_player(paused: bool) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var player := get_tree().current_scene.find_child("Player", true, false) as CharacterBody2D
	if player == null:
		player = get_tree().current_scene.find_child("player", true, false) as CharacterBody2D
	if player != null:
		player.set_physics_process(not paused)


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/MusicManager"):
		var mm := get_node("/root/MusicManager")
		if mm != null and mm.has_method("play_sfx"):
			mm.play_sfx(sfx_name)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if _back_modal != null and _back_modal.visible:
			_on_no_pressed()
			get_viewport().set_input_as_handled()
		elif _back_modal != null and not _back_modal.visible:
			_on_back_pressed()
			get_viewport().set_input_as_handled()


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

	if _back_button != null:
		_back_button.size = _back_button.get_combined_minimum_size()
		_back_button.position = usable.position
