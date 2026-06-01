extends Node

const ELEMENTS_PATH := "res://games/global/elements.json"
var elements: Array = []
var element_by_name := {}
var element_by_symbol := {}

func _ready() -> void:
	_load_elements()

func _load_elements() -> void:
	var file := FileAccess.open(ELEMENTS_PATH, FileAccess.READ)
	if not file:
		push_error("❌ Cannot open elements.json")
		return
	elements = JSON.parse_string(file.get_as_text())
	file.close()

	for e in elements:
		if e.has("name"):
			element_by_name[e["name"]] = e
		if e.has("symbol"):
			element_by_symbol[e["symbol"]] = e

func get_color_for_symbol(symbol: String) -> Color:
	var e = element_by_symbol.get(symbol)
	if e and e.has("color"):
		return Color.from_string(e["color"], Color.WHITE)
	return Color.WHITE

func get_color_for_name(name: String) -> Color:
	var e = element_by_name.get(name)
	if e and e.has("color"):
		return Color.from_string(e["color"], Color.WHITE)
	return Color.WHITE
