extends RigidBody2D

var object_mass: float
var volume: float
var is_picked_up: bool = false

@onready var label := $Label

func _ready():
	if Engine.has_singleton("BarrelDataManager"):
		var bdm = Engine.get_singleton("BarrelDataManager")
		var config = bdm.get_random_barrel_config()
		object_mass = config["mass"]
		volume = config["volume"]
	else:
		object_mass = 10.0
		volume = 5.0

	if label:
		label.visible = false
		label.text = "%0.1f kg\n%0.1f L\nDensity: %0.2f" % [object_mass, volume, get_density()]

func get_density() -> float:
	return object_mass / volume

func set_picked_up(picked_up: bool):
	is_picked_up = picked_up
	if label:
		label.visible = picked_up

func _on_picked_up():
	set_picked_up(true)

func _on_dropped():
	set_picked_up(false)
