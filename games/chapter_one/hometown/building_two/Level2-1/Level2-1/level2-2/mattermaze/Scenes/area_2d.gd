extends Area2D
@onready var tutorial: Panel = %tutorial

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.can_move = false
		tutorial.show()
		tutorial.set_meta("player_ref", body)
