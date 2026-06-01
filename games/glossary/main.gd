extends Control

# === Variables ===
var atomic_data: Dictionary = {}     # From elements.json
var compounds_data: Dictionary = {}  # From res://data/elements/*.json

@onready var table_image: TextureRect = $TableImage
@onready var buttons_container: Control = $ElementButtons
@onready var search_input: LineEdit = $SearchBar/SearchInput
@onready var suggestions_panel: PanelContainer = $SuggestionsPanel
@onready var suggestions_list: VBoxContainer = $SuggestionsPanel/VBoxContainer

# === Animation Settings ===
const ZOOM_SCALE := Vector2(3.0, 3.0)
const ZOOM_DURATION := 1.2
const ZOOM_OUT_DURATION := 1.0

var _original_position: Vector2
var _original_scale: Vector2

# === Initialization ===
func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	_original_position = table_image.position
	_original_scale = table_image.scale

	_load_atomic_data()
	_load_compound_files()
	_connect_buttons()
	_connect_search()

	# Defer setup so it happens after the scene finishes loading
	call_deferred("_setup_suggestions_layer")

func _setup_suggestions_layer() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SuggestionsLayer"
	get_tree().root.add_child(layer)

	layer.layer = 100  # top-most layer
	suggestions_panel.reparent(layer)
	suggestions_panel.z_index = 999

	# 🔧 Important: don't block mouse when hidden
	suggestions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suggestions_list.mouse_filter = Control.MOUSE_FILTER_STOP

	print("✅ SuggestionsPanel placed in CanvasLayer (z:", suggestions_panel.z_index, ")")


func _on_viewport_gui_input(event: InputEvent) -> void:
	# Detect click outside suggestions and search input
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if suggestions_panel.visible:
			var click_pos: Vector2 = event.position
			var panel_rect: Rect2 = suggestions_panel.get_global_rect()
			var input_rect: Rect2 = search_input.get_global_rect()

			# If click is outside both
			if not panel_rect.has_point(click_pos) and not input_rect.has_point(click_pos):
				
				_hide_suggestions()

func _hide_suggestions() -> void:
	if suggestions_panel.visible:
		suggestions_panel.hide()
	suggestions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enable_all_buttons(true)



func _on_gui_focus_changed(control: Control) -> void:
	# If focus left the search input and suggestions are open — hide it
	if suggestions_panel.visible and control != search_input:
		
		_hide_suggestions()

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
			atomic_data = parsed
		else:
			push_warning("⚠️ elements.json parsed but is not a Dictionary.")
	else:
		push_error("❌ Failed to open elements.json")

# === Load individual element compound files ===
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
				var element_name: String = atomic_data[s].get("name", "")
				if element_name == base_name or element_name.to_lower() == base_name.to_lower():
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
					compounds_data[symbol] = parsed
				else:
					push_warning("⚠️ Invalid JSON in " + file_name)
	dir.list_dir_end()
	print("✅ Loaded compound data for ", compounds_data.size(), " elements.")

# === Connect element buttons ===
# === Connect element buttons ===
func _connect_buttons() -> void:
	for child: Node in buttons_container.get_children():
		if child is Button:
			var btn: Button = child

			# ✅ Make sure button is active and clickable
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.disabled = false

			# ✅ Connect pressed signal if not already connected
			if not btn.pressed.is_connected(_on_element_pressed):
				btn.pressed.connect(_on_element_pressed.bind(btn))

			# Tooltip for hover info
			if atomic_data.has(btn.name):
				btn.set_tooltip_text(atomic_data[btn.name]["name"])


# === Zoom animation for element click ===
func _on_element_pressed(button: Button) -> void:
	var symbol: String = button.name
	if not atomic_data.has(symbol):
		push_warning("⚠️ No atomic data for element: " + symbol)
		return

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# --- Calculate where to zoom ---
	var button_center: Vector2 = button.get_global_rect().get_center()
	var viewport_center: Vector2 = get_viewport_rect().get_center()

	# Convert button center to table_image local coordinates
	var local_center: Vector2 = table_image.get_global_transform().affine_inverse().basis_xform(button_center)

	# Set pivot offset so scaling happens around the clicked element
	table_image.pivot_offset = local_center

	# --- Zoom in ---
	tween.tween_property(table_image, "scale", ZOOM_SCALE, ZOOM_DURATION)

	# Move so the clicked element appears at the center of the screen
	var global_to_local_offset: Vector2 = (viewport_center - button_center)
	var new_position: Vector2 = table_image.position + global_to_local_offset
	tween.tween_property(table_image, "position", new_position, ZOOM_DURATION)

	# --- After zoom, show info ---
	tween.tween_callback(Callable(self, "_show_element_info").bind(symbol))


# === Show element info scene ===
func _show_element_info(symbol: String) -> void:
	var scene_resource: PackedScene = load("res://games/glossary/element_info.tscn")
	var info_scene: CanvasLayer = scene_resource.instantiate() as CanvasLayer
	get_tree().root.add_child(info_scene)

	var atomic: Dictionary = atomic_data.get(symbol, {})
	var compounds: Array = compounds_data.get(symbol, [])

	info_scene.set_element(symbol, atomic, compounds)
	hide()

# === Smooth zoom-out when returning ===
func zoom_out() -> void:
	show()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	table_image.pivot_offset = Vector2.ZERO  # Reset pivot
	tween.tween_property(table_image, "scale", _original_scale, ZOOM_OUT_DURATION)
	tween.tween_property(table_image, "position", _original_position, ZOOM_OUT_DURATION)
	await tween.finished

# === Search System ===
func _connect_search() -> void:
	print("🔗 Connecting search input signals...")
	search_input.text_changed.connect(func(new_text):
		print("🔥 text_changed fired:", new_text)
		_on_search_text_changed(new_text)
	)
	search_input.text_submitted.connect(func(text):
		print("📗 text_submitted fired:", text)
		_on_search_pressed(text)
	)
	print("✅ Connected search signals to:", search_input)

# 🧠 Show live suggestions
func _on_search_text_changed(new_text: String) -> void:
	print("🔍 Search changed:", new_text)
	# Clear old suggestions
	for child in suggestions_list.get_children():
		child.queue_free()

	var query := new_text.strip_edges().to_lower()
	if query.is_empty():
		print("⚪ Empty query — hiding panel")
		_hide_suggestions()
		return

	var results: Array[Dictionary] = []
	var max_items := 8

	# --- Search elements (by name or symbol) ---
	for symbol: String in atomic_data.keys():
		if results.size() >= max_items:
			break
		var element_name := String(atomic_data[symbol].get("name", "")).to_lower()
		if element_name.begins_with(query) or symbol.to_lower().begins_with(query):
			results.append({"type": "element", "symbol": symbol})

	# --- Search compounds (by name or formula) ---
	for symbol: String in compounds_data.keys():
		if results.size() >= max_items:
			break
		for compound_variant in compounds_data[symbol]:
			var compound: Dictionary = compound_variant
			var comp_name := String(compound.get("name", "")).to_lower()
			var comp_formula := String(compound.get("formula", "")).to_lower()

			if comp_name.begins_with(query) or comp_formula.begins_with(query):
				results.append({
					"type": "compound",
					"symbol": symbol,
					"compound": comp_name.capitalize(),
					"formula": comp_formula
				})
				if results.size() >= max_items:
					break

	print("🧩 Found", results.size(), "results for query:", query)

	if results.is_empty():
		print("⚪ No matches — hiding panel")
		_hide_suggestions()
		return

	# --- Create clickable suggestion buttons ---
	for result in results:
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.visible = true
		btn.disabled = false
		btn.add_theme_font_size_override("font_size", 28)

		if result["type"] == "element":
			btn.text = "%s (%s)" % [
				atomic_data[result["symbol"]]["name"],
				result["symbol"]
			]
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			btn.text = "• %s (%s)" % [
				result["compound"],
				result["formula"]
			]
			btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))

		btn.connect("pressed", Callable(self, "_on_suggestion_clicked").bind(result))
		suggestions_list.add_child(btn)
		print("✅ Added suggestion:", btn.text)

	# --- Position and show panel ---
	var input_rect := search_input.get_global_rect()
	suggestions_panel.global_position = input_rect.position + Vector2(0, input_rect.size.y + 4)
	suggestions_panel.custom_minimum_size = Vector2(
		search_input.size.x,
		min(results.size(), max_items) * 36
	)
	suggestions_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	suggestions_panel.z_index = 999
	suggestions_panel.show()

	print("📦 Showing suggestions panel at:", suggestions_panel.global_position)
	_enable_all_buttons(false)
	suggestions_panel.show()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("🖱️ Mouse click at:", event.position)

		if suggestions_panel.visible:
			var click_pos: Vector2 = event.position
			var panel_rect: Rect2 = suggestions_panel.get_global_rect()
			var input_rect: Rect2 = search_input.get_global_rect()
			print("📐 Panel rect:", panel_rect, "Input rect:", input_rect)

			if panel_rect.has_point(click_pos):
				print("🟢 Click inside suggestions panel — allow click.")
				return
			if not input_rect.has_point(click_pos):
				print("🔴 Click outside panel — hiding.")
				_hide_suggestions()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("🟡 ESC pressed — hiding panel.")
		if suggestions_panel.visible:
			_hide_suggestions()



func _enable_all_buttons(enable: bool) -> void:
	for child in buttons_container.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if enable else Control.MOUSE_FILTER_IGNORE

func _on_suggestion_clicked(data: Dictionary) -> void:
	print("✅ CLICKED suggestion:", data)
	_hide_suggestions()

	if data["type"] == "element":
		var symbol: String = data["symbol"]
		print("🔸 Element symbol clicked:", symbol)
		if atomic_data.has(symbol) and buttons_container.has_node(symbol):
			var btn := buttons_container.get_node(symbol)
			if btn is Button:
				print("🔹 Triggering element zoom for", symbol)
				_on_element_pressed(btn)

	elif data["type"] == "compound":
		var symbol: String = data["symbol"]
		var compound_name: String = data["compound"]
		print("🔸 Compound clicked:", compound_name, "of element:", symbol)
		if compounds_data.has(symbol):
			for compound_variant in compounds_data[symbol]:
				var compound: Dictionary = compound_variant
				if compound.get("name", "") == compound_name:
					if buttons_container.has_node(symbol):
						var btn := buttons_container.get_node(symbol)
						if btn is Button:
							print("🔹 Triggering compound zoom for", compound_name)
							_on_element_pressed(btn)
					break

func _on_search_pressed(_text := "") -> void:
	var query: String = search_input.text.strip_edges().to_lower()
	if query.is_empty():
		_reset_highlights()
		
		return

	var found_elements: Array[String] = []
	for symbol: String in compounds_data.keys():
		for compound: Dictionary in compounds_data[symbol]:
			if compound.get("name", "").to_lower() == query:
				for comp: Dictionary in compound.get("components", []):
					var sym: String = comp["symbol"]
					if not found_elements.has(sym):
						found_elements.append(sym)

	if found_elements.size() > 0:
		_highlight_elements(found_elements)
		
	else:
		print("⚠️ No compound found for query: ", query)
		

# === Highlight Elements ===
func _highlight_elements(symbols: Array[String]) -> void:
	for child: Node in buttons_container.get_children():
		if child is Button:
			var btn: Button = child
			btn.modulate = Color.WHITE
			if symbols.has(btn.name):
				btn.modulate = Color(0.3, 1.0, 0.3)


# === Reset Highlights ===
func _reset_highlights() -> void:
	for child: Node in buttons_container.get_children():
		if child is Button:
			var btn: Button = child
			btn.modulate = Color.WHITE
