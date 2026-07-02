extends Node

var spawn_point: String = ""
var last_player_position: Vector2 = Vector2.ZERO

func set_spawn(point_name: String) -> void:
	spawn_point = point_name
	print("🔑 SpawnManager.set_spawn ->", point_name)

	# Auto-save when spawn changes
	if Engine.is_editor_hint() == false:
		SaveManager.last_spawn = spawn_point
		SaveManager.save_game()
		print("💾 Auto-saved after spawn change.")

func get_spawn() -> String:
	var point := spawn_point
	print("📤 SpawnManager.get_spawn ->", point)
	return point
