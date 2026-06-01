extends Control

@export var radius: float = 32.0
@export var color: Color = Color.GREEN

func _ready():
	queue_redraw()

func _draw():
	draw_circle(Vector2(size.x / 2, size.y / 2), radius, color)
