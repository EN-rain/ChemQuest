extends StaticBody2D

var player: Node = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	if player.global_position.distance_to(global_position) < 40:
		$CollisionShape2D.disabled = player.current_state == "Solid"
