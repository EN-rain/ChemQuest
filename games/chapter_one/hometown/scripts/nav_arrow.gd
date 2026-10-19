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

	# Requirement:
	# - arrow will show only on find_wiz and find_christofe
	# - find_wiz arrow will point into the BuildingOneEntry
	# - find_christofe to GoBack after going outside it will point to BuildingTwoEntry
	var is_find_wiz: bool = quest_mgr.has_quest("find_wiz") and not quest_mgr.is_quest_completed("find_wiz")
	var is_find_christofe: bool = quest_mgr.has_quest("find_christofe") and not quest_mgr.is_quest_completed("find_christofe")

	var new_target: Node2D = null

	if is_find_wiz:
		new_target = _find_node_by_name(current_scene, "BuildingOneEntry")
	elif is_find_christofe:
		# In building_one, point to GoBack doorway
		var go_back := _find_node_by_name(current_scene, "GoBack")
		if go_back != null:
			new_target = go_back
		else:
			# Outside in hometown, point to BuildingTwoEntry
			new_target = _find_node_by_name(current_scene, "BuildingTwoEntry")
	else:
		new_target = null

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
