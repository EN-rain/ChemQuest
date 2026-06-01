extends Node2D

@onready var sprite: Sprite2D = $StaticBody2D/Sprite2D
@onready var interact_button: TouchScreenButton = %interact

var player_in_area := false

func _ready() -> void:
	interact_button.pressed.connect(_on_interact_pressed)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): 
		player_in_area = true
		interact_button.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_area = false

func _on_interact_pressed() -> void:
	if player_in_area:
		# swap to another texture
		sprite.texture = preload("res://games/chapter_one/hometown/building_one/imgs/FurnaceOn.png")

		interact_button.hide()
