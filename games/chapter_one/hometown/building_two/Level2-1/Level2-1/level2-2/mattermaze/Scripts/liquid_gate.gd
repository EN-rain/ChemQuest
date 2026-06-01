extends StaticBody2D

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.global_position.distance_to(global_position) < 40:
			if player.current_state == "Liquid":
				$CollisionShape2D.disabled = true
			else:
				$CollisionShape2D.disabled = false
