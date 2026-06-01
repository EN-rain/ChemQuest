extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%AnimatedSprite2D.play("default")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://games/main.tscn")
