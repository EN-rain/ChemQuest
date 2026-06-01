extends Area2D

@export var value := 1   # points or molecules gained

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Scoring.precision_accuracy_score += value   # add to global score
		queue_free()
