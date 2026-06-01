extends RigidBody2D

@export var item_id: int = 1
var object_mass: float
var volume: float
var density: float
var is_picked_up: bool = false

func _ready() -> void:
	randomize()
	object_mass = randi_range(1, 100)
	volume = randi_range(1, 100)
	density = object_mass / max(volume, 1.0)
	add_to_group("ItemGroup")

	print("🧱 Item %s → M:%.1f | V:%.1f | ρ:%.2f" % [item_id, object_mass, volume, density])

	if has_node("Label"):
		$Label.visible = false
		$Label.text = "Mass: %.2fkg\nVol: %.2fL\nρ: %.2f" % [object_mass, volume, density]

func get_density() -> float:
	return density

func _on_picked_up() -> void:
	is_picked_up = true
	_update_data_label()
	if has_node("Label"): $Label.visible = true

func _on_dropped() -> void:
	is_picked_up = false
	_clear_data_label()
	if has_node("Label"): $Label.visible = false

func _update_data_label():
	var data_label = get_tree().get_first_node_in_group("Data")
	if data_label == null:
		return
	data_label.text = "Mass: %.2f kg\nVolume: %.2f L" % [object_mass, volume]

func _clear_data_label():
	var data_label = get_tree().get_first_node_in_group("Data")
	if data_label:
		data_label.text = ""

func _process(_delta: float) -> void:
	if has_node("Label"):
		$Label.rotation = 0
