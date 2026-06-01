extends Control

@onready var spawner := %Spawner 
@onready var back_panel := %BackPanel
func _on_undo_button_pressed() -> void:
	if spawner and spawner.has_method("undo_last_placement"):
		spawner.undo_last_placement()

func _on_back_button_pressed() -> void:
	back_panel.show()
