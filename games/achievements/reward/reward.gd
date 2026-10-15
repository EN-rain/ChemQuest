extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%AnimatedSprite2D.play("default")

func _on_button_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
