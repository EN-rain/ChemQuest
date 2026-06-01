extends Panel
@onready var label = $Label
@onready var grid: GridContainer = $CenterContainer/GridContainer
var mixture_scene: PackedScene = preload("res://games/chapter_one/hometown/building_one/Level1/Lesson3/mixtures.tscn")

func _ready() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 2.0)
	visible = false

# Displays all wrong mixture items in a grid
func show_mistakes(wrong_items: Array) -> void:
	for child in grid.get_children():
		child.queue_free()

	if wrong_items.is_empty():
		print("No mistakes to show.")
		return

	for item in wrong_items:
		if typeof(item) == TYPE_DICTIONARY:
			var wrapper = Control.new()
			wrapper.custom_minimum_size = Vector2(120, 120)
			wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var mixture: Mixture = mixture_scene.instantiate()
			mixture.set_data(item)
			mixture.stop_dragging()
			mixture.input_pickable = false
			mixture.monitoring = false
			mixture.monitorable = false
			mixture.scale = Vector2(0.9, 0.9)
			mixture.position = wrapper.custom_minimum_size / 2

			wrapper.add_child(mixture)
			grid.add_child(wrapper)

	print("Showing", wrong_items.size(), "mistakes.")
	visible = true


func _on_button_pressed() -> void:
	self.visible = false
