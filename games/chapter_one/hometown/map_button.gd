extends Button

@onready var label = %MapPanel/Label
@onready var close_overlay: Button = $"../Button"
func _ready() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 2.0)
	
func _on_pressed() -> void:
	%MapPanel.show()
	close_overlay.show()

func _on_button_pressed() -> void:
	%MapPanel.hide()
	close_overlay.hide()
