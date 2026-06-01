extends Node2D

var has_been_hit: bool = false

func _ready():
	# ❌ removed scaling override
	# leave TargetImg scale as set in editor (0.5 for gameplay targets, 1.0 for ResultsPanel)

	# Set up colliders
	for score_area in get_children():
		if score_area is Area2D:
			score_area.collision_layer = 2
			score_area.collision_mask = 1
			score_area.monitoring = true
			score_area.monitorable = true

	print(name, " initialized with colliders")


func mark_as_hit() -> void:
	has_been_hit = true
	visible = false
