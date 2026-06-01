extends Node2D

signal item_cleared(item: Area2D)
signal item_placed(item: Area2D) 

@onready var drop_area: Area2D = $Area2D
@onready var marker: Marker2D = $Area2D/Marker2D

func _ready() -> void:
	drop_area.area_entered.connect(_on_area_entered)
func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("items") or area.placed:
		return

	# Disable dragging and mark as placed
	area.set_drag_enabled(false)
	area.placed = true

	# Try to get the Sprite2D child
	var sprite: Sprite2D = null
	if area.has_node("Sprite2D"):
		sprite = area.get_node("Sprite2D")

	# Create the tween
	var tween := create_tween()

	# --- Move the item to the marker position ---
	tween.tween_property(area, "global_position", marker.global_position, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# --- Expand the sprite smoothly when placed ---
	if sprite:
		tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 2.5), 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

	# Wait for the tween to finish so the spawner receives a stable placed item
	await tween.finished

	# Emit placed signal so UI / feedback code can rely on this item being in placed_history
	emit_signal("item_placed", area)

	# Re-sort items in the spawner (if available)
	if area.spawner_ref and area.spawner_ref.has_method("auto_sort"):
		area.spawner_ref.auto_sort(area)

func clear_item_if_any() -> void:
	for child in drop_area.get_overlapping_areas():
		if child.is_in_group("items") and child.placed:
			print("🧹 Clearing timed-out item:", child.name)
			
			# Get spawner reference before freeing
			var spawner: Node = child.spawner_ref as Node
			
			# Remove the item safely
			if spawner and spawner.items.has(child):
				spawner.items.erase(child)
			if spawner and spawner.placed_history.has(child):
				spawner.placed_history.erase(child)
			
			child.queue_free()
			emit_signal("item_cleared", child)

			# ✅ After clearing, ask spawner to spawn a new one (if allowed)
			if spawner and spawner.has_method("spawn_single_item"):
				spawner.spawn_single_item()
			
			break
