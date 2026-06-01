extends Node2D

@onready var center := $Center
@onready var targets := $Targets
@export var radius: float = 200.0
@export var angular_speed: float = 1.0
@export var base_speed: float = 1.0   # 🔑 new: reference speed

var t: float = 0.0

func _ready() -> void:
	# Keep base speed value (in case angular_speed is changed later)
	base_speed = angular_speed

func _process(delta: float) -> void:
	t += angular_speed * delta
	var n := targets.get_child_count()
	for i in range(n):
		var a = t + i * TAU / n
		targets.get_child(i).global_position = center.global_position + Vector2(cos(a), sin(a)) * radius
