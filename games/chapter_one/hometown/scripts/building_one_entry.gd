extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("🚪 [BuildingOneEntry] Player entered transition area at ", body.global_position)
		body.can_move = false
		SpawnManager.set_spawn("default")
		print("🚪 [BuildingOneEntry] Spawn set to 'default', changing to building_one.tscn")
		var ok: bool = await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")
		if not ok and is_instance_valid(body):
			print("⚠️ [BuildingOneEntry] Transition cancelled or failed; restoring can_move to true")
			body.can_move = true
