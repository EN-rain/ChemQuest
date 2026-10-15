extends Control

@onready var lbl_name = $Control/Name
@onready var lbl_symbol = $Control/Symbol
@onready var lbl_number = $Control/Number
@onready var lbl_mass = $Control/Mass
@onready var btn_back = $Control/BackButton
@onready var img_element = $Control/ElementImage
@onready var lbl_compounds = $Control/CompoundsList  # RichTextLabel

var element_symbol = ""
var atomic_data = {}
var compounds = []

const FALLBACK_ELEMENT_IMAGE := "res://games/glossary/assets/elements/placeholder.svg"

func _ready():
	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.connect(_on_layout_changed)
	_apply_responsive_layout()
	call_deferred("_apply_responsive_layout")


func _exit_tree() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and service.layout_changed.is_connected(_on_layout_changed):
		service.layout_changed.disconnect(_on_layout_changed)


func _on_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		return
	var safe_rect: Rect2 = service.safe_rect
	btn_back.global_position = safe_rect.position
	var image_size: Vector2 = img_element.size * img_element.scale.abs()
	if image_size.x > 0.0 and image_size.y > 0.0:
		var image_scale := minf(1.0, minf((safe_rect.size.x * 0.52) / image_size.x, (safe_rect.size.y - 120.0) / image_size.y))
		image_scale = maxf(0.55, image_scale)
		img_element.scale = Vector2.ONE * image_scale
		image_size = img_element.size * img_element.scale.abs()
		img_element.global_position = Vector2(
			safe_rect.position.x + maxf(0.0, safe_rect.size.x * 0.48 - image_size.x * 0.5),
			safe_rect.position.y + maxf(72.0, (safe_rect.size.y - image_size.y) * 0.5)
		)
	var list := lbl_compounds as Control
	if list != null:
		var list_width := minf(360.0, maxf(280.0, safe_rect.size.x * 0.32))
		list.global_position = Vector2(safe_rect.end.x - list_width, safe_rect.position.y + 160.0)
		list.size = Vector2(list_width, maxf(180.0, safe_rect.size.y - 190.0))

func set_element(symbol: String, atomic_info: Dictionary, compounds_info: Array):
	element_symbol = symbol
	atomic_data = atomic_info
	compounds = compounds_info

	# === Display atomic info ===
	lbl_name.text = "%s" % atomic_info.get("name", "Unknown")
	lbl_symbol.text = "Symbol : %s" % symbol
	lbl_number.text = "Atomic Number : %s" % str(atomic_info.get("atomic_number", "N/A"))
	lbl_mass.text = "Atomic Mass : %s" % str(atomic_info.get("atomic_mass", "N/A"))

	# === Display compounds ===
	if compounds_info.size() > 0:
		_display_compounds(compounds_info)
	else:
		lbl_compounds.text = "No known compounds."

	_load_element_image(symbol)

func _display_compounds(compounds_info: Array):
	var text := "Example Compounds of %s:\n" % element_symbol
	for compound in compounds_info:
		text += "\n• %s (%s)\n" % [compound.get("name", ""), compound.get("formula", "")]
		text += "  Components: "
		for comp in compound.get("components", []):
			text += "%s%s " % [comp.get("symbol", ""), str(comp.get("count", ""))]
		text += "\n"
	lbl_compounds.text = text.strip_edges()

func _load_element_image(symbol: String):
	var path = "res://games/glossary/assets/elements/%s.png" % symbol
	if ResourceLoader.exists(path):
		img_element.texture = load(path)
	elif ResourceLoader.exists(FALLBACK_ELEMENT_IMAGE):
		img_element.texture = load(FALLBACK_ELEMENT_IMAGE)

func _on_back_pressed():
	var main_scene = get_tree().root.get_node("Main")
	if not main_scene:
		queue_free()
		return

	var fade_tween = create_tween()
	fade_tween.tween_property($Control, "modulate:a", 0.0, 0.6)
	main_scene.zoom_out()
	await get_tree().create_timer(0.6).timeout
	queue_free()


# Kept as a compatibility alias for the signal saved in older scene files.
# The canonical scene connects the same button to _on_back_pressed in code,
# while this name preserves any serialized NodePath connections.
func _on_back_button_pressed() -> void:
	_on_back_pressed()
