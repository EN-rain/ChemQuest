extends Panel

@onready var back_panel = %BackPanel


func _on_back_button_pressed() -> void:
	back_panel.show() 
	
func _on_yes_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")

func _on_no_pressed() -> void:
	back_panel.visible = false
