extends Area2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.can_move = false

		# --- Define next scene and spawn point ---
		var next_scene := "res://games/chapter_one/hometown/hometown.tscn"
		var next_spawn := "from_building_one"

		SpawnManager.set_spawn(next_spawn)
		SaveManager.change_scene_with_save(next_scene, next_spawn)
		await FadeManager.fade_and_change(next_scene)
