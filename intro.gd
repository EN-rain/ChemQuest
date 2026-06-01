extends Node

@onready var label = $CanvasLayer/Button/Label

func _ready():
	var tween = create_tween()
	tween.set_loops() # loop forever
	tween.tween_property(label, "modulate:a", 0.0, 0.5) # fade out
	tween.tween_property(label, "modulate:a", 1.0, 2.0) # fade in

func _on_button_pressed() -> void:
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://games/main.tscn")
