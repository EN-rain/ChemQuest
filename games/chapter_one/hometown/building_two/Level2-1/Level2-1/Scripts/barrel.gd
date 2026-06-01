extends RigidBody2D

@export var object_mass: float = 50.0
@export var volume: float = 10.0
var objmass:String = "50kg"
var objvol:String = "10 liters"
var is_picked_up: bool = false

func get_density() -> float:
	return object_mass / volume
	
func _ready():
	if has_node("Label"):
		$Label.visible = false  # Hide by default
		$Label.text = objmass + "\n" + objvol

func set_picked_up(picked_up: bool):
	is_picked_up = picked_up
	if has_node("Label"):
		$Label.visible = picked_up  # Show only when picked up

# Connect this to your pickup system
func _on_picked_up():
	set_picked_up(true)

# Connect this to your drop system
func _on_dropped():
	set_picked_up(false)
