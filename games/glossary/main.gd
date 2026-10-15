extends Control

const ReleaseLog = preload("res://games/global/ReleaseLog.gd")
const FixedAspectSurface = preload("res://games/ui/FixedAspectSurface.gd")

# === Variables ===
var atomic_data: Dictionary = {}     # From elements.json
var compounds_data: Dictionary = {}  # From res://games/glossary/data/elements/*.json

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
var _surface_position := Vector2.ZERO
var _surface_scale := 1.0
var _is_zoomed := false

# === Initialization ===
func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	_original_position = table_image.position
	_original_scale = table_image.scale
	_connect_responsive_layout()
	_apply_responsive_layout()

	_load_atomic_data()
	_load_compound_files()
	_connect_buttons()
	_connect_search()

	# Defer setup so it happens after the scene finishes loading
	call_deferred("_setup_suggestions_layer")
	call_deferred("_apply_responsive_layout")


func _connect_responsive_layout() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_responsive_layout_changed):
		service.layout_changed.connect(_on_responsive_layout_changed)


func _on_responsive_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null or table_image == null or buttons_container == null:
		return
	var viewport_size: Vector2 = service.viewport_size
	var safe_rect: Rect2 = service.safe_rect
	var design_size := Vector2(1280.0, 720.0)
	_surface_scale = FixedAspectSurface.calculate_scale(viewport_size, design_size)
	if _surface_scale <= 0.0:
		return
	var surface_size := design_size * _surface_scale
	_surface_position = (viewport_size - surface_size) * 0.5
	if not _is_zoomed:
		table_image.position = _surface_position
		table_image.size = design_size
		table_image.scale = Vector2.ONE * _surface_scale
		_original_position = _surface_position
		_original_scale = Vector2.ONE * _surface_scale
	buttons_container.position = _surface_position
	buttons_container.size = design_size
	buttons_container.scale = Vector2.ONE * _surface_scale

	var search_bar := get_node_or_null("SearchBar") as Control
	if search_bar != null:
		var search_width := minf(450.0, maxf(280.0, safe_rect.size.x - 48.0))
		var search_height := maxf(63.0, search_bar.size.y)
		# SearchBar is authored with a right anchor; update offsets so Godot's
		# layout pass cannot snap it back to the physical viewport edge.
		search_bar.anchor_left = 1.0
		search_bar.anchor_right = 1.0
		search_bar.anchor_top = 0.0
		search_bar.anchor_bottom = 0.0
		search_bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		search_bar.grow_vertical = Control.GROW_DIRECTION_END
		var right_margin := viewport_size.x - safe_rect.end.x
		search_bar.offset_left = -search_width - right_margin
		search_bar.offset_right = -right_margin
		search_bar.offset_top = safe_rect.position.y
		search_bar.offset_bottom = safe_rect.position.y + search_height
		search_input.custom_minimum_size.x = search_width
	var back_button := get_node_or_null("BackButton") as Control
	if back_button != null:
		back_button.global_position = safe_rect.position

func _setup_suggestions_layer() -> void:
	# Keep the panel under Main so the established SuggestionsPanel NodePath
	# remains valid for scripts, tests, and future scene tooling. Its high
	# z-index already keeps it above the authored table surface.
	suggestions_panel.z_index = 999

	# 🔧 Important: don't block mouse when hidden
	suggestions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	suggestions_list.mouse_filter = Control.MOUSE_FILTER_STOP

	ReleaseLog.info("SuggestionsPanel placed in CanvasLayer (z: %s)" % suggestions_panel.z_index)


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
	ReleaseLog.info("Loaded compound data for %s elements." % compounds_data.size())

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
	_is_zoomed = true
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
	var info_scene: Control = scene_resource.instantiate() as Control
	get_tree().root.add_child(info_scene)

	var atomic: Dictionary = atomic_data.get(symbol, {})
	var compounds: Array = compounds_data.get(symbol, [])

	# Call through the scene contract so the host remains a generic Control and
	# the implementation can evolve without a hard static type dependency.
	info_scene.call("set_element", symbol, atomic, compounds)
	hide()

# === Smooth zoom-out when returning ===
func zoom_out() -> void:
	show()
	_is_zoomed = false
	_apply_responsive_layout()
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	table_image.pivot_offset = Vector2.ZERO  # Reset pivot
	tween.tween_property(table_image, "scale", _original_scale, ZOOM_OUT_DURATION)
	tween.tween_property(table_image, "position", _original_position, ZOOM_OUT_DURATION)
	await tween.finished

# === Search System ===
func _connect_search() -> void:
	ReleaseLog.info("Connecting search input signals...")
	search_input.text_changed.connect(func(new_text):
		ReleaseLog.info("text_changed fired: %s" % new_text)
		_on_search_text_changed(new_text)
	)
	search_input.text_submitted.connect(func(text):
		ReleaseLog.info("text_submitted fired: %s" % text)
		_on_search_pressed(text)
	)
	ReleaseLog.info("Connected search signals to: %s" % search_input)

# 🧠 Show live suggestions
func _on_search_text_changed(new_text: String) -> void:
	ReleaseLog.info("Search changed: %s" % new_text)
	# Clear old suggestions
	for child in suggestions_list.get_children():
		child.queue_free()

	var query := new_text.strip_edges().to_lower()
	if query.is_empty():
		ReleaseLog.info("Empty query — hiding panel")
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

	ReleaseLog.info("Found %s results for query: %s" % [results.size(), query])

	if results.is_empty():
		ReleaseLog.info("No matches — hiding panel")
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
		ReleaseLog.info("Added suggestion: %s" % btn.text)

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

	ReleaseLog.info("Showing suggestions panel at: %s" % suggestions_panel.global_position)
	_enable_all_buttons(false)
	suggestions_panel.show()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		ReleaseLog.info("Mouse click at: %s" % event.position)

		if suggestions_panel.visible:
			var click_pos: Vector2 = event.position
			var panel_rect: Rect2 = suggestions_panel.get_global_rect()
			var input_rect: Rect2 = search_input.get_global_rect()
			ReleaseLog.info("Panel rect: %s Input rect: %s" % [panel_rect, input_rect])

			if panel_rect.has_point(click_pos):
				ReleaseLog.info("Click inside suggestions panel — allow click.")
				return
			if not input_rect.has_point(click_pos):
				ReleaseLog.info("Click outside panel — hiding.")
				_hide_suggestions()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		ReleaseLog.info("ESC pressed — hiding panel.")
		if suggestions_panel.visible:
			_hide_suggestions()



func _enable_all_buttons(enable: bool) -> void:
	for child in buttons_container.get_children():
		if child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if enable else Control.MOUSE_FILTER_IGNORE

func _on_suggestion_clicked(data: Dictionary) -> void:
	ReleaseLog.info("CLICKED suggestion: %s" % data)
	_hide_suggestions()

	if data["type"] == "element":
		var symbol: String = data["symbol"]
		ReleaseLog.info("Element symbol clicked: %s" % symbol)
		if atomic_data.has(symbol) and buttons_container.has_node(symbol):
			var btn := buttons_container.get_node(symbol)
			if btn is Button:
				ReleaseLog.info("Triggering element zoom for %s" % symbol)
				_on_element_pressed(btn)

	elif data["type"] == "compound":
		var symbol: String = data["symbol"]
		var compound_name: String = data["compound"]
		ReleaseLog.info("Compound clicked: %s of element: %s" % [compound_name, symbol])
		if compounds_data.has(symbol):
			for compound_variant in compounds_data[symbol]:
				var compound: Dictionary = compound_variant
				if compound.get("name", "") == compound_name:
					if buttons_container.has_node(symbol):
						var btn := buttons_container.get_node(symbol)
						if btn is Button:
							ReleaseLog.info("Triggering compound zoom for %s" % compound_name)
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
		ReleaseLog.info("No compound found for query: %s" % query)
		

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
