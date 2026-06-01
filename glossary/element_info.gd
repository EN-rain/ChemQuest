extends Control

@onready var lbl_name = $Control/Name
@onready var lbl_symbol = $Control/Symbol
@onready var lbl_number = $Control/Number
@onready var lbl_mass = $Control/Mass
@onready var btn_back = %BackButton
@onready var img_element = $Control/ElementImage
@onready var lbl_compounds = $Control/CompoundsList  # RichTextLabel

var element_symbol = ""
var atomic_data = {}
var compounds = []

func set_element(symbol: String, atomic_info: Dictionary, compounds_info: Array):
	element_symbol = symbol
	atomic_data = atomic_info
	compounds = compounds_info

	# === Display atomic info ===
	lbl_name.text = "%s" % atomic_info.get("name", "Unknown")
	lbl_symbol.text = "%s" % symbol
	lbl_number.text = "%s" % str(atomic_info.get("atomic_number", "N/A"))
	lbl_mass.text = "%s" % str(atomic_info.get("atomic_mass", "N/A"))

	# === Display compounds ===
	if compounds_info.size() > 0:
		_display_compounds(compounds_info)
	else:
		lbl_compounds.text = "No known compounds."

	_load_element_image(symbol)

func _display_compounds(compounds_info: Array):
	var text := "Compounds that include %s:\n" % element_symbol
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
	else:
		img_element.texture = load("res://assets/elements/placeholder.png")

func _on_back_button_pressed() -> void:
	queue_free()  # remove this info panel from memory
	get_tree().change_scene_to_file("res://games/glossary/main.tscn")
