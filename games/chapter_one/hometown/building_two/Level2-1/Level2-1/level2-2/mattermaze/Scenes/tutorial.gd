extends Panel

@onready var close_button: Button = %CloseButton
@onready var tutorial_panel: Panel = %tutorial

const GUIDE_ID := "states_tutorial" # Unique name for this tutorial

func _ready() -> void:
	# Access GuideManager (autoloaded as a singleton)
	if not GuideManager.has_seen(GUIDE_ID):
		# Show tutorial only once
		tutorial_panel.show()
		close_button.show()

		# Mark as seen for next time
		GuideManager.mark_seen(GUIDE_ID)
	else:
		# Already seen → hide by default
		tutorial_panel.hide()
		close_button.hide()

func _on_close_button_pressed() -> void:
	tutorial_panel.hide()
	close_button.hide()


func _on_guide_button_pressed() -> void:
	show()
