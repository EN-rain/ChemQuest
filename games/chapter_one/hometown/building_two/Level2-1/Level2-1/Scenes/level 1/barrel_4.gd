extends RigidBody2D

@export var barrel_id: int = 4
var object_mass: float
var volume: float
var density: float
var is_picked_up := false


func _ready():
	randomize()
	object_mass = randi_range(10, 100)
	volume = randi_range(5, 50)
	density = object_mass / max(volume, 1.0)
	add_to_group("BarrelGroup")

	print("🧱 Barrel %s → M:%.1f | V:%.1f | ρ:%.2f" % [barrel_id, object_mass, volume, density])

	if has_node("Label"):
		$Label.visible = false
		$Label.text = "Mass: %.1f kg\nVol: %.1f L\nρ: %.2f" % [object_mass, volume, density]


func _on_picked_up():
	is_picked_up = true
	_update_data_label()
	if has_node("Label"): $Label.visible = true


func _on_dropped():
	is_picked_up = false
	_clear_data_label()
	if has_node("Label"): $Label.visible = false


func _update_data_label():
	var data_label = get_tree().get_first_node_in_group("Data")
	if data_label == null:
		print("⚠️ No %Data label found.")
		return

	if not ChallengeManager.initialized:
		print("⚠️ ChallengeManager not ready yet.")
		return

	var type = ChallengeManager.challenge_type
	var text := ""

	match type:
		"density": text = "Mass: %.1f kg\nVolume: %.1f L" % [object_mass, volume]
		"mass": text = "Density: %.2f\nVolume: %.1f L" % [density, volume]
		"volume": text = "Mass: %.1f kg\nDensity: %.2f" % [object_mass, density]
		_: text = "Mass: %.1f\nVol: %.1f\nρ: %.2f" % [object_mass, volume, density]

	data_label.text = text
	print("🧾 %Data updated →", text)


func _clear_data_label():
	var data_label = get_tree().get_first_node_in_group("Data")
	if data_label:
		data_label.text = ""
		print("🧹 Cleared %Data label")


func get_density() -> float:
	return density
