extends Panel

@onready var close_button: Button = %CloseButton
@onready var tutorial_panel: Panel = %tutorial

const GUIDE_ID := "states_tutorial"


func _ready() -> void:
	if not GuideManager.has_seen(GUIDE_ID):
		tutorial_panel.show()
		close_button.show()
	else:
		tutorial_panel.hide()
		close_button.hide()


func _on_close_button_pressed() -> void:
	if not GuideManager.has_seen(GUIDE_ID):
		GuideManager.mark_seen(GUIDE_ID)
	tutorial_panel.hide()
	close_button.hide()


func _on_guide_button_pressed() -> void:
	show()
