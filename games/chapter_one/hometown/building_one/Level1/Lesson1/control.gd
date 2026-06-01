extends Control

@onready var back_panel = %BackPanel

func _ready() -> void:
	if GuideManager.has_seen("lesson_1_guide"):
		%GameTimer.start_timer()
	else:
		# First time seen → mark it and start timer
		GuideManager.mark_seen("lesson_1_guide")
		%GameTimer.stop_timer()


func _on_back_button_pressed() -> void:
	back_panel.visible = true
	if %GameTimer:
		%GameTimer.stop_timer()
