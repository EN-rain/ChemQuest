extends Node2D

var is_destroyed: bool = false

func on_target_hit(points: int, ring_name: String, hit_world: Vector2) -> void:
	if is_destroyed:
		return
	is_destroyed = true

	visible = false
	set_process(false)

	var manager = %PAManager
	if manager:
		manager.add_points(points)
		manager.on_target_destroyed()
		manager.update_target_result_dynamic(name, points, hit_world)  # pass world hit
