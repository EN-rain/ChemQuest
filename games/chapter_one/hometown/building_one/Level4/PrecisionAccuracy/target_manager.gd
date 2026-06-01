# target_manager.gd - Robust center-repositioning for Targets
extends Node2D

signal sliding_finished

# Config
var target_spacing: float = 150.0   # spacing between targets (adjust if needed)

# Runtime
var targets: Array[Node2D] = []
var container_node: Node2D = null   # the node that actually contains the targets

@onready var game_manager: Node = %PAManager

func _ready() -> void:
	print("TargetManager ready!")
	await get_tree().process_frame
	initialize_targets()

# ---------------------------
# Utility: safe property check (works for script variables and exported properties)
# ---------------------------
func _has_property(obj: Object, prop_name: String) -> bool:
	if not obj:
		return false
	var plist := obj.get_property_list()
	for p in plist:
		if p is Dictionary and p.has("name") and p["name"] == prop_name:
			return true
	return false

# ---------------------------
# Initialization: collect target nodes and detect their container
# ---------------------------
func initialize_targets() -> void:
	targets.clear()

	# Prefer the obvious container: "../Targets"
	var possible_container := get_node_or_null("../Targets")
	if possible_container:
		container_node = possible_container
		for child in container_node.get_children():
			if child.name.begins_with("Target"):
				# ✅ keep scene order, no sorting
				targets.append(child)
	else:
		# Fallback: try numbered nodes
		for i in range(1, 11):
			var n := get_node_or_null("%Target" + str(i))
			if n:
				targets.append(n)
		if targets.size() > 0:
			container_node = targets[0].get_parent()

	if targets.is_empty():
		push_error("TargetManager: No targets found. Check scene structure.")
		return

	print("Found ", targets.size(), " targets under container: ", container_node)
	for t in targets:
		print(" - ", t.name, " local=", t.position, " global=", t.global_position)

func _cmp_local_x(a: Node, b: Node) -> int:
	if container_node == null:
		# fallback to comparing global x
		if a.global_position.x < b.global_position.x: return -1
		if a.global_position.x > b.global_position.x: return 1
		return 0
	var ax := container_node.to_local(a.global_position).x
	var bx := container_node.to_local(b.global_position).x
	if ax < bx: return -1
	if ax > bx: return 1
	return 0

# ---------------------------
# Called by PAManager when a target is hit
# ---------------------------
func on_target_hit(target: Node2D, hit_position: Vector2, score: int) -> void:
	if not targets.has(target):
		# already removed (double call) — ignore
		print("TargetManager: on_target_hit called but target not in list: ", target.name)
		return

	print("TargetManager: Target hit: ", target.name, " Score: ", score)

	# 1) Remove from active list and hide
	targets.erase(target)
	target.visible = false
	print("TargetManager: Hidden and erased ", target.name, " → remaining: ", targets.size())

	# 2) Slide remaining targets to new centered positions
	slide_targets_to_center()

	# 3) End condition
	if targets.is_empty():
		print("TargetManager: All targets destroyed! Game complete!")

# ---------------------------
# Reposition remaining targets evenly around x=0 (relative to container_node)
# ---------------------------
func slide_targets_to_center() -> void:
	if targets.is_empty():
		return

	if container_node == null:
		if targets.size() > 0:
			container_node = targets[0].get_parent()
			if container_node == null:
				push_error("TargetManager: container_node still null; cannot reposition")
				return

	print("Sliding ", targets.size(), " targets to new positions (centered)")

	# Pause shooting while sliding
	if game_manager and game_manager.has_method("pause_for_slide"):
		game_manager.pause_for_slide()

	var tween := create_tween()
	tween.set_parallel(true)

	var count := targets.size()
	# ✅ find the middle index
	var center_index := int(count / 2)

	for i in range(count):
		var t := targets[i]
		# offset from center
		var offset := (i - center_index) * target_spacing
		var current_local_y := container_node.to_local(t.global_position).y
		var new_local_pos := Vector2(offset, current_local_y)

		print("  -> ", t.name, " move to ", new_local_pos)
		tween.tween_property(t, "position", new_local_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		print("TargetManager: sliding finished, resuming shooting")
		if game_manager and game_manager.has_method("resume_after_slide"):
			game_manager.resume_after_slide()
		emit_signal("sliding_finished")
	)

# ---------------------------
# Convenience
# ---------------------------
func get_targets() -> Array[Node2D]:
	return targets.duplicate()

func get_target_count() -> int:
	return targets.size()
