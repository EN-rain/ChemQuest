extends Node

var spawn_point: String = ""

func set_spawn(point_name: String) -> void:
	spawn_point = point_name
	print("🔑 SpawnManager.set_spawn ->", point_name)

	# Fix (B4): Skip the auto-save when called with an empty spawn name.
	# This is the common case where hometown.gd calls `set_spawn("")` after
	# consuming the spawn point — it doesn't represent a state change and
	# must not trigger a save_game() write.
	if point_name == "":
		return

	# Auto-save only when the spawn actually changes to a non-empty value.
	if Engine.is_editor_hint() == false:
		if SaveManager.last_spawn != spawn_point:
			SaveManager.last_spawn = spawn_point
			SaveManager.save_game()
			print("💾 Auto-saved after spawn change.")

func get_spawn() -> String:
	var point := spawn_point
	print("📤 SpawnManager.get_spawn ->", point)
	return point
