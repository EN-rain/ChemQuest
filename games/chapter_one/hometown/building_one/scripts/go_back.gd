extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		print("🚪 [BuildingOne/GoBack] Player entered go_back at ", body.global_position)
		body.can_move = false

		# --- Define next scene and spawn point ---
		var next_scene := "res://games/chapter_one/hometown/hometown.tscn"
		var next_spawn := "from_building_one"

		print("🚪 [BuildingOne/GoBack] Setting spawn='", next_spawn, "', fading to ", next_scene)
		SpawnManager.set_spawn(next_spawn)
		SaveManager.change_scene_with_save(next_scene, next_spawn)
		var ok: bool = await FadeManager.fade_and_change(next_scene)
		if not ok and is_instance_valid(body):
			print("⚠️ [BuildingOne/GoBack] Transition cancelled or failed; restoring can_move to true")
			body.can_move = true
