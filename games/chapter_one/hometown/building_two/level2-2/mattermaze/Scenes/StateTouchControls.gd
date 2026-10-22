extends CanvasLayer

## Shared touch controls for the states-of-matter tutorial and levels.
## Buttons press/release the existing input actions so keyboard and touch use
## exactly the same player code path. Also provides a persistent top-left BACK button
## and exit confirmation dialog to return safely to Building Two.

const BACK_ICON_PATH := "res://assets/back.png"
const ATOM_LABEL_SETTINGS_PATH := "res://games/chapter_one/hometown/building_one/Level1/atom.tres"
const GRAY_BUTTON_PATH := "res://games/chapter_one/hometown/building_one/Level1/imgs/gray.png"
const FONT_PATH := "res://assets/LilitaOne-Regular.ttf"
const ROBOTO_FONT_PATH := "res://assets/Roboto-BoldCondensed.ttf"
const BUTTON_SIZE := Vector2(80.0, 72.0)
const GROUP_GAP := 10.0
const EDGE_MARGIN := 24.0

var _root: Control
var _movement: HBoxContainer
var _actions: HBoxContainer
var _back_button: Button
var _back_modal: Panel
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
	_back_button.name = "Back"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.flat = true
	_back_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_button.custom_minimum_size = Vector2(210.0, 55.0)
	_back_button.size = Vector2(210.0, 55.0)

	var icon_rect := TextureRect.new()
	icon_rect.name = "TextureRect"
	if ResourceLoader.exists(BACK_ICON_PATH):
		icon_rect.texture = load(BACK_ICON_PATH)
	icon_rect.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	icon_rect.anchor_top = 0.5
	icon_rect.anchor_bottom = 0.5
	icon_rect.offset_top = -32.0
	icon_rect.offset_right = 64.0
	icon_rect.offset_bottom = 32.0
	icon_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	icon_rect.scale = Vector2(0.9, 0.9)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(icon_rect)

	var label := Label.new()
	label.name = "Label"
	label.text = "BACK"
	if ResourceLoader.exists(ATOM_LABEL_SETTINGS_PATH):
		label.label_settings = load(ATOM_LABEL_SETTINGS_PATH)
	elif ResourceLoader.exists(FONT_PATH):
		var ls := LabelSettings.new()
		ls.font = load(FONT_PATH)
		ls.font_size = 50
		ls.outline_size = 5
		ls.outline_color = Color(0, 0, 0, 1)
		label.label_settings = ls
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -173.0
	label.offset_top = -33.0
	label.offset_bottom = 33.0
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(label)

	_back_button.pressed.connect(_on_back_pressed)
	_root.add_child(_back_button)


func _build_back_modal() -> void:
	_back_modal = Panel.new()
	_back_modal.name = "BackPanel"
	_back_modal.visible = false
	_back_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_back_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back_modal.anchor_right = 1.0
	_back_modal.anchor_bottom = 1.0
	_back_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_back_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_back_modal)

	var title_lbl := Label.new()
	title_lbl.name = "Label"
	title_lbl.text = "Are you sure?"
	if ResourceLoader.exists(ATOM_LABEL_SETTINGS_PATH):
		title_lbl.label_settings = load(ATOM_LABEL_SETTINGS_PATH)
	elif ResourceLoader.exists(FONT_PATH):
		var ls := LabelSettings.new()
		ls.font = load(FONT_PATH)
		ls.font_size = 50
		ls.outline_size = 5
		ls.outline_color = Color(0, 0, 0, 1)
		title_lbl.label_settings = ls
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.set_anchors_preset(Control.PRESET_CENTER)
	title_lbl.anchor_left = 0.5
	title_lbl.anchor_top = 0.5
	title_lbl.anchor_right = 0.5
	title_lbl.anchor_bottom = 0.5
	title_lbl.offset_left = -149.0
	title_lbl.offset_top = -121.0
	title_lbl.offset_right = 149.0
	title_lbl.offset_bottom = -63.0
	title_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	_back_modal.add_child(title_lbl)

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.anchor_left = 0.5
	hbox.anchor_top = 0.5
	hbox.anchor_right = 0.5
	hbox.anchor_bottom = 0.5
	hbox.offset_left = -182.0
	hbox.offset_top = -45.5
	hbox.offset_right = 182.0
	hbox.offset_bottom = 10.0
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	hbox.add_theme_constant_override("separation", 20)
	_back_modal.add_child(hbox)

	var btn_label_settings := LabelSettings.new()
	if ResourceLoader.exists(ROBOTO_FONT_PATH):
		btn_label_settings.font = load(ROBOTO_FONT_PATH)
	btn_label_settings.font_size = 30
	btn_label_settings.outline_color = Color(0, 0, 0, 1)

	var yes_btn := _create_modal_button("Yes", btn_label_settings)
	yes_btn.name = "Yes"
	yes_btn.pressed.connect(_on_yes_pressed)
	hbox.add_child(yes_btn)

	var no_btn := _create_modal_button("No", btn_label_settings)
	no_btn.name = "No"
	no_btn.pressed.connect(_on_no_pressed)
	hbox.add_child(no_btn)


func _create_modal_button(btn_text: String, lbl_settings: LabelSettings) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180.0, 0.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true

	var tex_rect := TextureRect.new()
	tex_rect.name = "TextureRect"
	if ResourceLoader.exists(GRAY_BUTTON_PATH):
		tex_rect.texture = load(GRAY_BUTTON_PATH)
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.anchor_right = 1.0
	tex_rect.anchor_bottom = 1.0
	tex_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tex_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex_rect)

	var lbl := Label.new()
	lbl.name = "Label"
	lbl.text = btn_text
	lbl.label_settings = lbl_settings
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.add_child(lbl)

	return btn


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
	if has_node("/root/ReviewManager") and ReviewManager.is_in_review:
		if has_node("/root/FadeManager"):
			var fm := get_node("/root/FadeManager")
			if fm != null and fm.has_method("fade_and_change"):
				await fm.fade_and_change("res://games/review/review.tscn")
				return
	if has_node("/root/SpawnManager"):
		var sm := get_node("/root/SpawnManager")
		if sm != null and sm.has_method("set_spawn"):
			sm.set_spawn("game_spawn")
	if has_node("/root/FadeManager"):
		var fm := get_node("/root/FadeManager")
		if fm != null and fm.has_method("fade_and_change"):
			await fm.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")


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
	if get_viewport() == null:
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
