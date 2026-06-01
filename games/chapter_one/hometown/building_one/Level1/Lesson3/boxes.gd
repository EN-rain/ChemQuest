extends Control

@onready var results_panel: Panel = %ResultsPanel
@onready var finalize_button: Button = %FinalizeButton
@onready var undo_button: Button = %UndoButton
@onready var spawner_panel: Control = %SpawnerPanel
@onready var sort_label: Label = %SortLabel 

var placed_count: int = 0
var correct_count: int = 0
const TARGET_COUNT: int = 15
var mistakes: Array = []
var finalized: bool = false
var lesson3: Node = null
var sorted_stack: Array = []


func _ready() -> void:
	lesson3 = get_tree().get_root().get_node("Lesson3")
	finalize_button.visible = false
	undo_button.visible = true
	_update_sort_label()  # ✅ Initialize display


# --- Triggered when a mixture enters the homogeneous box ---
func _on_homogeneous_area_entered(area: Area2D) -> void:
	if area is Mixture and not area.locked:
		_snap_to_marker(area, %Homogeneous, "homogeneous")


# --- Triggered when a mixture enters the heterogeneous box ---
func _on_heterogeneous_area_entered(area: Area2D) -> void:
	if area is Mixture and not area.locked:
		_snap_to_marker(area, %Heterogeneous, "heterogeneous")


# --- Moves the mixture to its target marker with animation ---
func _snap_to_marker(mixture: Mixture, target_area: Area2D, expected_type: String) -> void:
	var marker: Marker2D = target_area.get_node("Marker2D")
	if not marker:
		return

	mixture.stop_dragging()
	mixture.move_to_front()

	var tween := create_tween()
	tween.tween_property(mixture, "global_position", marker.global_position, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		_on_mixture_sorted(mixture, expected_type))


# --- Called after a mixture finishes snapping to box ---
func _on_mixture_sorted(mixture: Mixture, expected_type: String) -> void:
	if mixture.locked or placed_count >= TARGET_COUNT:
		return

	placed_count += 1
	print("Placed:", placed_count, "/", TARGET_COUNT)

	# Save previous state for Undo
	sorted_stack.append({
		"mixture": mixture,
		"original_pos": mixture.original_position
	})

	var is_correct: bool = mixture.mixture_data.get("type", "") == expected_type

	if is_correct:
		correct_count += 1
		if lesson3 and lesson3.has_method("record_correct_mixture"):
			lesson3.record_correct_mixture(mixture.mixture_data)
	else:
		if not mistakes.has(mixture.mixture_data):
			mistakes.append(mixture.mixture_data)

	# Lock mixture
	mixture.input_pickable = false
	mixture.monitoring = false
	mixture.monitorable = false
	mixture.locked = true

	# Spawn next mixture if under target
	if not finalized and lesson3 and lesson3.has_method("spawn_mixtures") and placed_count < TARGET_COUNT:
		lesson3.spawn_mixtures(1, false)

	_update_finalize_button()
	_update_sort_label()  # ✅ Update label each time


# --- Show finalize button when 15 are placed ---
func _update_finalize_button() -> void:
	finalize_button.visible = placed_count >= TARGET_COUNT


# --- ✅ Update the “Sorted X / 15” label ---
func _update_sort_label() -> void:
	if sort_label:
		sort_label.text = "%d / %d" % [placed_count, TARGET_COUNT]


# --- Called when player clicks Finalize ---
func _on_finalize_button_pressed() -> void:
	if lesson3 and lesson3.has_method("lock_all_mixtures"):
		lesson3.lock_all_mixtures()

	if results_panel.has_method("show_results"):
		results_panel.show_results(correct_count, mistakes)

	if lesson3 and lesson3.has_method("increment_run_count"):
		lesson3.increment_run_count()

	finalize_button.visible = false
	finalized = true


# --- Called when player clicks Undo ---
func _on_undo_button_pressed() -> void:
	if sorted_stack.is_empty():
		return

	var last_entry = sorted_stack.pop_back()
	var mixture: Mixture = last_entry["mixture"]
	var original_pos: Vector2 = last_entry["original_pos"]

	print("Undoing:", mixture.mixture_data.get("name", "Unknown"))

	if lesson3 and lesson3.has_method("remove_correct_mixture"):
		lesson3.remove_correct_mixture(mixture.mixture_data)

	# Disable during animation
	mixture.monitoring = false
	mixture.monitorable = false
	mixture.input_pickable = false
	mixture.locked = false

	var tween := create_tween()
	tween.tween_property(
		mixture,
		"global_position",
		spawner_panel.global_position + original_pos,
		0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		mixture.input_pickable = true
		mixture.monitoring = true
		mixture.monitorable = true
	)

	# Update counters
	if placed_count > 0:
		placed_count -= 1
	if mistakes.has(mixture.mixture_data):
		mistakes.erase(mixture.mixture_data)
	else:
		if correct_count > 0:
			correct_count -= 1

	_update_finalize_button()
	_update_sort_label()  # ✅ Also update label when undoing

	# Remove last spawned mixture visually
	if lesson3.current_mixtures.size() > 0:
		var last_spawned = lesson3.current_mixtures.pop_back()
		if is_instance_valid(last_spawned):
			last_spawned.queue_free()
