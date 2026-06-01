extends CanvasLayer

# ui.gd (on CanvasLayer or a UI manager script)
func _ready():
	%interact.pressed.connect(_on_interact_pressed)
	%interact.hide()

func _on_interact_pressed() -> void:
	if InteractionManager.current_interactable:
		InteractionManager.current_interactable.interact()
