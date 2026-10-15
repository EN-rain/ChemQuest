extends Node

## Canonical transition spawn names. Older saves and scripts used the
## misspelled `seperation_spawn`; keep that value readable during migration.
const SPAWN_ALIASES := {
	"seperation_spawn": "separation_spawn",
}

var spawn_point: String = ""


func set_spawn(point_name: String) -> void:
	point_name = normalize_spawn_name(point_name)
	spawn_point = point_name
	print("SpawnManager.set_spawn ->", point_name)

	# Skip the auto-save when called with an empty name. Hometown consumes the
	# pending point this way and it does not represent a persistent state change.
	if point_name.is_empty():
		return

	# Auto-save only when the spawn actually changes to a non-empty value.
	if not Engine.is_editor_hint() and SaveManager.last_spawn != spawn_point:
		SaveManager.last_spawn = spawn_point
		SaveManager.save_game()
		print("Auto-saved after spawn change.")


func clear_pending() -> void:
	## Clear only the one-shot transition value. SaveManager.last_spawn remains
	## the resolved resume location for Continue.
	spawn_point = ""


func get_spawn() -> String:
	var point := normalize_spawn_name(spawn_point)
	spawn_point = point
	print("SpawnManager.get_spawn ->", point)
	return point


## Validate the pending spawn against a destination hub before it is saved.
## Gameplay scenes without a SpawnPoints node intentionally keep the pending
## value because their return scene consumes it later.
func validate_for_scene(scene_path: String) -> String:
	var requested := normalize_spawn_name(spawn_point)
	if requested.is_empty() or scene_path.is_empty():
		return requested
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_warning("SpawnManager: destination scene does not exist: %s" % scene_path)
		return requested

	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_warning("SpawnManager: unable to inspect destination scene: %s" % scene_path)
		return requested
	var instance := packed.instantiate()
	if instance == null:
		return requested
	var markers := instance.find_child("SpawnPoints", true, false)
	if markers == null:
		instance.free()
		return requested

	var resolved := requested
	if markers.get_node_or_null(requested) == null:
		var default_marker := markers.get_node_or_null("default")
		if default_marker != null:
			push_warning("SpawnManager: '%s' is not present in %s; using default." % [requested, scene_path])
			resolved = "default"
		else:
			push_warning("SpawnManager: '%s' is not present in %s and no default exists." % [requested, scene_path])
			resolved = ""
	instance.free()

	spawn_point = resolved
	if has_node("/root/SaveManager") and SaveManager.last_spawn != resolved:
		SaveManager.last_spawn = resolved
	return resolved


func normalize_spawn_name(point_name: String) -> String:
	return str(SPAWN_ALIASES.get(point_name, point_name))
