extends Node2D

@export var base_orbit_distance: float = 78.0
@export var idle_threshold_seconds: float = 2.0

@onready var visual: Node2D = $Visual

var target_node: Node2D = null
var is_visible_state: bool = false
var current_distance: float = 48.0
var idle_time: float = 0.0
var bob_time: float = 0.0
var fade_tween: Tween = null
var player: CharacterBody2D = null
var _initialized_on_spawn: bool = false


func _ready() -> void:
	z_index = 10
	player = get_parent() as CharacterBody2D
	if visual != null:
		visual.modulate.a = 0.0
		current_distance = base_orbit_distance - 30.0
		visual.position = Vector2(current_distance, 0)

	var quest_mgr := get_node_or_null("/root/QuestManager")
	if quest_mgr != null:
		if not quest_mgr.quest_updated.is_connected(_on_quest_changed):
			quest_mgr.quest_updated.connect(_on_quest_changed)
		if not quest_mgr.quest_added.is_connected(_on_quest_changed):
			quest_mgr.quest_added.connect(_on_quest_changed)
		if not quest_mgr.quest_completed.is_connected(_on_quest_changed):
			quest_mgr.quest_completed.connect(_on_quest_changed)

	call_deferred("_setup_on_spawn")


func _setup_on_spawn() -> void:
	_refresh_target()
	_initialized_on_spawn = true
	# Requirement: Arrow shows immediately after spawn if a valid quest target exists
	if target_node != null:
		_animate_in()


func _physics_process(delta: float) -> void:
	if not _initialized_on_spawn:
		return

	if target_node == null or not is_instance_valid(target_node):
		if is_visible_state:
			_animate_out()
		return

	# Detect if the player is actively moving
	var is_moving := false
	if player != null:
		is_moving = player.velocity.length() > 5.0
	else:
		is_moving = (
			Input.is_action_pressed("left")
			or Input.is_action_pressed("right")
			or Input.is_action_pressed("up")
			or Input.is_action_pressed("down")
		)

	if is_moving:
		idle_time = 0.0
		if is_visible_state:
			# Requirement: Hide after moving
			_animate_out()
	else:
		idle_time += delta
		if idle_time >= idle_threshold_seconds and not is_visible_state:
			# Requirement: Show after 2 seconds idle
			_animate_in()

	# If visible or transitioning, keep updating rotation and gliding motion
	if visual != null and visual.modulate.a > 0.01:
		_update_direction_and_motion(delta)


func _update_direction_and_motion(delta: float) -> void:
	var target_pos := get_target_global_position()
	var to_target := target_pos - global_position
	var target_dist := to_target.length()

	# Hide smoothly if standing directly on the target to avoid spinning
	if target_dist < 55.0:
		if is_visible_state:
			_animate_out()
		return

	# Smooth rotation tracking towards the target
	var desired_angle := to_target.angle()
	rotation = lerp_angle(rotation, desired_angle, delta * 12.0)

	# Fluid propelled bobbing animation along pointer vector
	bob_time += delta * 4.5
	var bob_offset := sin(bob_time) * 8.0
	visual.position.x = current_distance + bob_offset
	visual.scale = Vector2.ONE * (1.0 + sin(bob_time) * 0.05)


func get_target_global_position() -> Vector2:
	if not is_instance_valid(target_node):
		return Vector2.ZERO

	# Use child CollisionShape2D center if present for exact doorway target
	var col_shape := target_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col_shape != null:
		return col_shape.global_position
	return target_node.global_position


func _animate_in() -> void:
	if is_visible_state or visual == null:
		return
	is_visible_state = true

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	# Smoothly glides outward into orbit while fading in
	fade_tween = create_tween().set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(self, "current_distance", base_orbit_distance, 0.4)
	fade_tween.tween_property(visual, "modulate:a", 1.0, 0.35)


func _animate_out() -> void:
	if not is_visible_state or visual == null:
		return
	is_visible_state = false

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	# Smoothly glides inward towards the player while fading out
	fade_tween = create_tween().set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(self, "current_distance", base_orbit_distance - 30.0, 0.25)
	fade_tween.tween_property(visual, "modulate:a", 0.0, 0.25)


func _on_quest_changed(_quest: Variant = null) -> void:
	_refresh_target()
	if target_node != null and idle_time >= idle_threshold_seconds and not is_visible_state:
		_animate_in()


func _refresh_target() -> void:
	var quest_mgr := get_node_or_null("/root/QuestManager")
	if quest_mgr == null:
		target_node = null
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		target_node = null
		return

	var latest_quest: Quest = quest_mgr.get_latest_incomplete_quest()
	if latest_quest == null:
		target_node = null
		if is_visible_state:
			_animate_out()
		return

	var quest_id := latest_quest.id
	var new_target: Node2D = null

	# Scene context identification
	var b1_entry := _find_node_by_name(current_scene, "BuildingOneEntry")
	var b2_entry := _find_node_by_name(current_scene, "BuildingTwoEntry")
	var is_in_hometown := (b1_entry != null or b2_entry != null)
	var is_in_building_one := _find_node_by_name(current_scene, "Wiz") != null
	var is_in_building_two := _find_node_by_name(current_scene, "Christofe") != null
	var go_back := _find_node_by_name(current_scene, "GoBack")

	# Group 1: Building One quests (Wiz, Books, Desk, Separation, Accuracy)
	const B1_QUESTS := [
		"find_wiz",
		"read_books",
		"finish_book1",
		"after_book1",
		"finish_book2",
		"after_book2",
		"desk_quiz",
		"after_desk_quiz",
		"finish_book3",
		"after_book3",
		"separation_methods",
		"separation_methods_after",
		"accuracy_vs_precision",
		"after_accuracy_vs_precision"
	]

	# Group 2: Building Two quests (Christofe, Density, States)
	const B2_QUESTS := [
		"find_christofe",
		"density_measurement",
		"after_density_measurement",
		"states_of_matter",
		"after_states_of_matter"
	]

	if quest_id in B1_QUESTS:
		if is_in_hometown:
			new_target = b1_entry
		elif is_in_building_two:
			new_target = go_back
		elif is_in_building_one:
			match quest_id:
				"find_wiz", "after_book1", "after_book2", "after_desk_quiz", "after_book3", "separation_methods_after", "after_accuracy_vs_precision":
					new_target = _find_node_by_name(current_scene, "Wiz")
				"read_books", "finish_book1", "finish_book2", "finish_book3":
					new_target = _find_node_by_name(current_scene, "LevelOne")
				"desk_quiz":
					new_target = _find_node_by_name(current_scene, "LevelTwo")
				"separation_methods":
					new_target = _find_node_by_name(current_scene, "LevelThree")
				"accuracy_vs_precision":
					new_target = _find_node_by_name(current_scene, "LevelFour")

	elif quest_id in B2_QUESTS:
		if is_in_hometown:
			new_target = b2_entry
		elif is_in_building_one:
			new_target = go_back
		elif is_in_building_two:
			match quest_id:
				"find_christofe", "after_density_measurement", "after_states_of_matter":
					new_target = _find_node_by_name(current_scene, "Christofe")
				"density_measurement", "states_of_matter":
					new_target = _find_node_by_name(current_scene, "Game")

	target_node = new_target

	if target_node == null and is_visible_state:
		_animate_out()


func _find_node_by_name(root: Node, node_name: String) -> Node2D:
	if root == null:
		return null
	if root.name == node_name and root is Node2D:
		return root as Node2D
	for child in root.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null
