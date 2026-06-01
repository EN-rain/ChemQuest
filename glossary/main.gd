extends Control

# === Data ===
var atomic_data: Dictionary = {}      # From elements.json
var compounds_data: Dictionary = {}   # From res://games/glossary/data/elements/*.json

# === Scene references ===
@onready var table_image: TextureRect = $TableImage
@onready var buttons_container: Control = $ElementButtons
@onready var search_input: LineEdit = $SearchBar/SearchInput
@onready var suggestions_panel: Control = $SuggestionsPanel
@onready var suggestions_box: VBoxContainer = $SuggestionsPanel/VBoxContainer

# === Animation Settings ===
const ZOOM_SCALE: Vector2 = Vector2(3.0, 3.0)
const ZOOM_DURATION: float = 1.2
const ZOOM_OUT_DURATION: float = 1.0

var _original_position: Vector2
var _original_scale: Vector2


# === Initialization ===
func _ready() -> void:
	# existing init code.

	_original_position = table_image.position
	_original_scale = table_image.scale

	_load_atomic_data()
	_load_compound_files()
	_connect_buttons()
	_connect_search()
	
	connect("gui_input", Callable(self, "_on_click_outside"))

	# make panel pass mouse events to children
	if suggestions_panel:
		suggestions_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	if suggestions_box:
		suggestions_box.mouse_filter = Control.MOUSE_FILTER_PASS
	print("DEBUG: Scene ready; mouse filters set to PASS")

func _on_click_outside(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = event.position
		var panel_rect: Rect2 = suggestions_panel.get_global_rect()
		var search_rect: Rect2 = search_input.get_global_rect()

		if not panel_rect.has_point(mouse_pos) and not search_rect.has_point(mouse_pos):
			print("DEBUG: Clicked outside — closing suggestions.")
			suggestions_panel.hide()
			search_input.release_focus()

# === Load elements.json ===
func _load_atomic_data() -> void:
	var path: String = "res://games/glossary/data/elements.json"
	if not FileAccess.file_exists(path):
		push_error("❌ elements.json not found.")
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			atomic_data = parsed as Dictionary
			print("DEBUG: Loaded atomic_data entries =", atomic_data.size())
		else:
			push_warning("⚠️ elements.json parsed but is not a Dictionary.")
	else:
		push_error("❌ Failed to open elements.json")


# === Load element compound files ===
func _load_compound_files() -> void:
	var dir: DirAccess = DirAccess.open("res://games/glossary/data/elements/")
	if not dir:
		push_error("❌ Could not open compound directory.")
		return

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break
		if file_name.ends_with(".json"):
			var base_name: String = file_name.get_basename()
			var symbol: String = ""

			for s: String in atomic_data.keys():
				var element_name_check: String = String(atomic_data[s].get("name", ""))
				if element_name_check == base_name or element_name_check.to_lower() == base_name.to_lower():
					symbol = s
					break

			if symbol == "":
				push_warning("⚠️ Could not find symbol for element file: " + base_name)
				continue

			var path: String = "res://games/glossary/data/elements/" + file_name
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file:
				var parsed: Variant = JSON.parse_string(file.get_as_text())
				file.close()
				if parsed is Array:
					compounds_data[symbol] = parsed as Array
					print("DEBUG: Loaded compounds for", symbol, "count =", (parsed as Array).size())
				else:
					push_warning("⚠️ Invalid JSON in " + file_name)
	dir.list_dir_end()
	print("✅ Loaded compound data for", compounds_data.size(), "elements.")


# === Connect element buttons ===
func _connect_buttons() -> void:
	for child: Node in buttons_container.get_children():
		if child is Button:
			var btn: Button = child
			btn.pressed.connect(_on_element_pressed.bind(btn))
			if atomic_data.has(btn.name):
				btn.set_tooltip_text(String(atomic_data[btn.name].get("name", "")))
	print("DEBUG: Connected element buttons:", buttons_container.get_child_count())


# === Element click zoom ===
func _on_element_pressed(button: Button) -> void:
	var symbol: String = button.name
	print("DEBUG: Element button pressed:", symbol)
	if not atomic_data.has(symbol):
		push_warning("⚠️ No atomic data for element: " + symbol)
		return

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var button_center: Vector2 = button.get_global_rect().get_center()
	var viewport_center: Vector2 = get_viewport_rect().get_center()
	var local_center: Vector2 = table_image.get_global_transform().affine_inverse().basis_xform(button_center)
	table_image.pivot_offset = local_center

	tween.tween_property(table_image, "scale", ZOOM_SCALE, ZOOM_DURATION)
	var new_position: Vector2 = table_image.position + (viewport_center - button_center)
	tween.tween_property(table_image, "position", new_position, ZOOM_DURATION)
	tween.tween_callback(Callable(self, "_show_element_info").bind(symbol))


# === Show element info ===
func _show_element_info(symbol: String) -> void:
	var scene_resource: PackedScene = load("res://games/glossary/element_info.tscn")
	if scene_resource == null:
		push_error("❌ element_info.tscn not found.")
		return
	var info_scene: Control = scene_resource.instantiate() as Control
	get_tree().root.add_child(info_scene)

	var atomic: Dictionary = atomic_data.get(symbol, {}) as Dictionary
	var compounds: Array = compounds_data.get(symbol, []) as Array
	if info_scene.has_method("set_element"):
		info_scene.set_element(symbol, atomic, compounds)
	else:
		push_warning("⚠️ element_info.tscn missing set_element method.")
	hide()


# === Smooth zoom-out ===
func zoom_out() -> void:
	show()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	table_image.pivot_offset = Vector2.ZERO
	tween.tween_property(table_image, "scale", _original_scale, ZOOM_OUT_DURATION)
	tween.tween_property(table_image, "position", _original_position, ZOOM_OUT_DURATION)
	await tween.finished


# === SEARCH SYSTEM ===
func _connect_search() -> void:
	search_input.text_changed.connect(_on_search_text_changed)
	search_input.text_submitted.connect(_on_search_pressed)
	suggestions_panel.show()
	print("DEBUG: Search connected; panel forced visible")


# === When pressing Enter ===
func _on_search_pressed(_text := "") -> void:
	print("DEBUG: Enter pressed in search bar, text:", search_input.text)
	_on_search_text_changed(search_input.text)


# === Live search (always visible, limited to 3) ===
func _on_search_text_changed(new_text: String) -> void:
	print("DEBUG: Search text changed:", new_text)
	for c: Node in suggestions_box.get_children():
		c.queue_free()
	print("DEBUG: Suggestions cleared")

	var query: String = String(new_text).strip_edges().to_lower()
	var shown_count: int = 0
	suggestions_panel.show()

	# Empty query = preview first 3
	if query.is_empty():
		for symbol: String in atomic_data.keys():
			if shown_count >= 3:
				break
			_add_element_group(symbol)
			shown_count += 1
		print("DEBUG: Empty query preview shown_count =", shown_count)
		return

	for symbol: String in atomic_data.keys():
		if shown_count >= 3:
			break

		var element_name: String = String(atomic_data[symbol].get("name", "")).to_lower()
		var compound_list: Array = compounds_data.get(symbol, []) as Array
		var element_matches: bool = element_name.contains(query)
		var compound_matches: bool = false

		for compound in compound_list:
			var cname: String = String(compound.get("name", "")).to_lower()
			if cname.contains(query):
				compound_matches = true
				break

		if element_matches or compound_matches:
			_add_element_group(symbol, query)
			shown_count += 1
			print("DEBUG: Added element group", symbol, "count", shown_count)

	if shown_count == 0:
		for symbol: String in atomic_data.keys():
			if shown_count >= 3:
				break
			_add_element_group(symbol)
			shown_count += 1
		print("DEBUG: No matches; fallback shown_count =", shown_count)

# === Helper: create clickable element + compound entries ===
func _add_element_group(symbol: String, query: String = "") -> void:
	if not atomic_data.has(symbol):
		print("DEBUG: Missing symbol", symbol)
		return

	# --- Element clickable button ---
	var element_name: String = String(atomic_data[symbol].get("name", ""))
	var element_button: Button = Button.new()
	element_button.text = "%s (%s)" % [element_name, symbol]
	element_button.focus_mode = Control.FOCUS_NONE
	element_button.mouse_filter = Control.MOUSE_FILTER_STOP
	element_button.flat = true  # removes background/border
	element_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	element_button.connect("pressed", Callable(self, "_on_element_selected").bind(symbol))
	suggestions_box.add_child(element_button)
	print("DEBUG: Added clickable element:", symbol)

	# --- Compound list buttons (indented, no alignment change) ---
	var compound_list: Array = compounds_data.get(symbol, []) as Array
	var shown_compounds: int = 0

	for compound in compound_list:
		if shown_compounds >= 3:
			break
		var cname: String = String(compound.get("name", ""))
		var formula: String = String(compound.get("formula", ""))
		if query == "" or cname.to_lower().contains(query):
			var btn: Button = Button.new()
			btn.text = "     - %s (%s)" % [cname, formula]  # 5 spaces before dash
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.flat = true
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.connect("pressed", Callable(self, "_on_suggestion_selected").bind(symbol, compound))
			suggestions_box.add_child(btn)
			print("DEBUG: Added compound button:", cname)
			shown_compounds += 1

	print("DEBUG: Added element +", shown_compounds, "compounds for", symbol)


# === Handle click on element name ===
func _on_element_selected(symbol: String) -> void:
	print("DEBUG: Element selected from popup:", symbol)

	if not atomic_data.has(symbol):
		push_warning("⚠️ No atomic data for element: " + symbol)
		return

	if buttons_container.has_node(symbol):
		var btn := buttons_container.get_node(symbol)
		if btn is Button:
			print("DEBUG: Triggering zoom into", symbol)
			_on_element_pressed(btn)
		else:
			push_warning("⚠️ Node found but not Button:", symbol)
	else:
		push_warning("⚠️ No button found for symbol:", symbol)

	suggestions_panel.hide()
	search_input.clear()
	search_input.release_focus()


# === Handle click on compound ===
func _on_suggestion_selected(symbol: String, compound: Dictionary) -> void:
	print("DEBUG: Compound selected -> symbol:", symbol, "compound:", compound)

	if not atomic_data.has(symbol):
		push_warning("⚠️ No atomic data for symbol: " + symbol)
		return

	# Highlight compound elements
	var components: Array = compound.get("components", []) as Array
	var elements: Array[String] = []
	for comp in components:
		if comp is Dictionary:
			var sym: String = String(comp.get("symbol", ""))
			if sym != "":
				elements.append(sym)
	print("DEBUG: Highlight elements:", elements)
	if elements.size() > 0:
		_highlight_elements(elements)

	# Trigger zoom into the parent element
	if buttons_container.has_node(symbol):
		var btn := buttons_container.get_node(symbol)
		if btn is Button:
			print("DEBUG: Triggering zoom into", symbol)
			_on_element_pressed(btn)
		else:
			push_warning("⚠️ Node found but not Button:", symbol)
	else:
		push_warning("⚠️ No button found for:", symbol)

	suggestions_panel.hide()
	search_input.clear()
	search_input.release_focus()


# === Highlight / reset ===
func _highlight_elements(symbols: Array[String]) -> void:
	print("DEBUG: Highlighting elements:", symbols)
	for child: Node in buttons_container.get_children():
		if child is Button:
			var btn: Button = child
			btn.modulate = Color.WHITE
			if symbols.has(btn.name):
				btn.modulate = Color(0.3, 1.0, 0.3)


func _reset_highlights() -> void:
	for child: Node in buttons_container.get_children():
		if child is Button:
			child.modulate = Color.WHITE
