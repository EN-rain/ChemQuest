extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)
	
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.can_move = false
		SpawnManager.set_spawn("from_building_two")
		await FadeManager.fade_and_change("res://games/chapter_one/hometown/hometown.tscn")
