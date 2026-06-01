extends RigidBody2D

@export var object_mass: float = 130.0
@export var volume: float = 10.0
var objmass: String = "125kg"
var objvol: String = "10 liters"
var is_picked_up: bool = false

func get_density() -> float:
	return object_mass / volume

func _ready() -> void:
	if has_node("Label"):
		$Label.visible = false  # Hide by default
		$Label.text = objmass + "\n" + objvol

func set_picked_up(picked_up: bool) -> void:
	is_picked_up = picked_up
	if has_node("Label"):
		$Label.visible = picked_up  # Show only when picked up

# ✅ These make your player’s pickup/drop calls valid
func _on_picked_up() -> void:
	set_picked_up(true)

func _on_dropped() -> void:
	set_picked_up(false)

# ✅ Keep label upright (doesn’t rotate when object rolls)
func _process(_delta: float) -> void:
	if has_node("Label"):
		$Label.rotation = 0  # cancel out rotation
