extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.can_move = false
		SpawnManager.set_spawn("default")
		var ok: bool = await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")
		if not ok and is_instance_valid(body):
			body.can_move = true
