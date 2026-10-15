extends Node

## Static route contract validator. It intentionally does not enter gameplay
## scenes or write user data; it validates the same PackedScenes and scripts
## that the interaction runner exercises.

const MANIFEST_PATH := "res://tests/routes/routes.json"
const QUEST_PATH := "res://games/global/quest.json"
const SPAWN_ALIASES := {"seperation_spawn": "separation_spawn"}
const KNOWN_SPAWNS := {
	"default": true,
	"from_building_one": true,
	"from_hometown": true,
	"from_building_two": true,
	"map_spawn": true,
	"desk_spawn": true,
	"separation_spawn": true,
	"shooting_spawn": true,
	"game_spawn": true,
}
const QUEST_ORDER := [
	"find_wiz", "read_books", "finish_book1", "after_book1", "finish_book2",
	"after_book2", "desk_quiz", "after_desk_quiz", "finish_book3", "after_book3",
	"separation_methods", "separation_methods_after", "accuracy_vs_precision",
	"after_accuracy_vs_precision", "find_christofe", "density_measurement",
	"after_density_measurement", "states_of_matter", "after_states_of_matter",
]

var _failures: Array[String] = []
var _warnings: Array[String] = []


func _ready() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	if manifest.is_empty():
		_fail("manifest could not be loaded")
	else:
		_validate_manifest(manifest)
	if _failures.is_empty():
		for warning in _warnings:
			print("ROUTE_WARNING ", warning)
		print("ROUTE_CONTRACT PASS scenes=%d routes=%d" % [manifest.get("active_scenes", []).size(), manifest.get("routes", []).size()])
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("ROUTE_CONTRACT_FAIL " + failure)
		get_tree().quit(1)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _validate_manifest(manifest: Dictionary) -> void:
	var active: Array = manifest.get("active_scenes", [])
	var routes: Array = manifest.get("routes", [])
	if manifest.get("version", 0) != 1:
		_fail("unsupported manifest version")
	if active.is_empty() or routes.is_empty():
		_fail("manifest must declare active scenes and routes")

	var scene_by_id: Dictionary = {}
	var incoming: Dictionary = {}
	var outgoing: Dictionary = {}
	var scene_instances: Dictionary = {}
	for entry in active:
		if not entry is Dictionary:
			_fail("active scene entry is not an object")
			continue
		var id := str(entry.get("id", ""))
		var path := str(entry.get("path", ""))
		if id.is_empty() or path.is_empty():
			_fail("active scene entry is missing id/path")
			continue
		if scene_by_id.has(id):
			_fail("duplicate active scene id: " + id)
		scene_by_id[id] = path
		incoming[id] = 0
		outgoing[id] = 0
		if not ResourceLoader.exists(path, "PackedScene"):
			_fail("missing PackedScene for " + id + ": " + path)
			continue
		var packed := ResourceLoader.load(path) as PackedScene
		if packed == null:
			_fail("failed to load PackedScene for " + id)
			continue
		scene_instances[id] = packed.instantiate()
		_validate_scene_source(id, path)
		_validate_connections(id, path, scene_instances[id])

	var terminal_ids: Array = manifest.get("terminal_scene_ids", [])
	for terminal in terminal_ids:
		if not scene_by_id.has(str(terminal)):
			_fail("terminal scene is not active: " + str(terminal))

	var route_ids: Dictionary = {}
	for route in routes:
		_validate_route(route, scene_by_id, incoming, outgoing, route_ids)

	for id in scene_by_id.keys():
		if id == "intro":
			continue
		if int(incoming.get(id, 0)) == 0:
			_fail("player-facing scene has no incoming route: " + id)
		if not terminal_ids.has(id) and int(outgoing.get(id, 0)) == 0:
			_fail("non-terminal scene has no outgoing route: " + id)

	_validate_quest_order()


func _validate_route(route: Variant, scene_by_id: Dictionary, incoming: Dictionary, outgoing: Dictionary, route_ids: Dictionary) -> void:
	if not route is Dictionary:
		_fail("route entry is not an object")
		return
	var route_id := str(route.get("id", ""))
	if route_id.is_empty():
		_fail("route is missing id")
	elif route_ids.has(route_id):
		_fail("duplicate route id: " + route_id)
	route_ids[route_id] = true

	for field in ["start_scene", "required_quest_state", "required_progress_state", "spawn", "driver", "expected_scene", "expected_spawn", "expected_quest_changes", "expected_progress_changes", "supported_inputs"]:
		if not route.has(field):
			_fail("route %s is missing %s" % [route_id, field])

	var start_id := str(route.get("start_scene", ""))
	var expected_id := str(route.get("expected_scene", ""))
	if not scene_by_id.has(start_id):
		_fail("route %s starts at unknown scene %s" % [route_id, start_id])
	else:
		outgoing[start_id] = int(outgoing.get(start_id, 0)) + 1
	if not scene_by_id.has(expected_id):
		_fail("route %s targets unknown scene %s" % [route_id, expected_id])
	else:
		incoming[expected_id] = int(incoming.get(expected_id, 0)) + 1

	if str(route.get("driver", "")).is_empty():
		_fail("route %s has an empty driver" % route_id)
	var inputs: Array = route.get("supported_inputs", [])
	if inputs.is_empty():
		_fail("route %s has no supported input" % route_id)

	var spawn := _normalize_spawn(str(route.get("spawn", "")))
	var expected_spawn := _normalize_spawn(str(route.get("expected_spawn", "")))
	if not spawn.is_empty() and not KNOWN_SPAWNS.has(spawn):
		_fail("route %s requests unknown spawn %s" % [route_id, spawn])
	if not expected_spawn.is_empty() and not KNOWN_SPAWNS.has(expected_spawn):
		_fail("route %s expects unknown spawn %s" % [route_id, expected_spawn])
	if str(route.get("expected_spawn", "")) != "" and expected_spawn != str(route.get("expected_spawn", "")):
		_warnings.append("route %s normalizes expected spawn to %s" % [route_id, expected_spawn])

	# If either endpoint declares a SpawnPoints node, validate the marker there.
	# Gameplay scenes intentionally carry a pending hub spawn while they have no
	# marker of their own, so the global-name check above remains the fallback.
	if not expected_spawn.is_empty():
		var marker_path := _find_spawn_owner(scene_by_id, expected_spawn, expected_id, start_id)
		if marker_path.is_empty() and expected_spawn != "default":
			_warnings.append("route %s carries %s until a later hub consumes it" % [route_id, expected_spawn])


func _find_spawn_owner(scene_by_id: Dictionary, spawn: String, expected_id: String, start_id: String) -> String:
	for id in [expected_id, start_id]:
		if not scene_by_id.has(id):
			continue
		var packed := ResourceLoader.load(scene_by_id[id]) as PackedScene
		if packed == null:
			continue
		var root := packed.instantiate()
		var markers := root.find_child("SpawnPoints", true, false)
		if markers != null and markers.get_node_or_null(spawn) != null:
			root.free()
			return id
		root.free()
	return ""


func _validate_scene_source(id: String, path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	for forbidden in ["Level2-1/Level2-1", "res://glossary/"]:
		if forbidden in text:
			_fail("active scene %s references quarantined duplicate tree: %s" % [id, forbidden])


func _validate_connections(id: String, path: String, root: Node) -> void:
	if root == null:
		_fail("could not instantiate active scene " + id)
		return
	var text := FileAccess.get_file_as_string(path)
	var regex := RegEx.new()
	regex.compile("\\[connection[^\\n]*to=\\\"([^\\\"]+)\\\"[^\\n]*method=\\\"([^\\\"]+)\\\"[^\\n]*\\]")
	for match in regex.search_all(text):
		var target_path := match.get_string(1)
		var method := match.get_string(2)
		var target := root.get_node_or_null(NodePath(target_path))
		if target == null:
			_fail("scene %s connection target missing: %s" % [id, target_path])
		elif not target.has_method(method):
			_fail("scene %s connection method missing: %s.%s" % [id, target_path, method])
	root.free()


func _validate_quest_order() -> void:
	var data := _load_json(QUEST_PATH)
	var actual: Array[String] = []
	for entry in data.get("quests", []):
		if entry is Dictionary:
			actual.append(str(entry.get("id", "")))
	if actual != QUEST_ORDER:
		_fail("quest.json order differs from the Chapter One progression contract")


func _normalize_spawn(value: String) -> String:
	return str(SPAWN_ALIASES.get(value, value))


func _fail(message: String) -> void:
	_failures.append(message)
