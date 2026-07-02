extends Control

@onready var label = $NextButton/Label

# Unique guide ID for this scene
@export var guide_id: String = "lesson_2_guide"

func _ready() -> void:
	# Animate the “Next” label blinking
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 2.0)

	# Show this guide only once
	if GuideManager.has_seen(guide_id):
		hide()
	else:
		show()
		if %GameTimer:
			%GameTimer.pause_timer()  # Pause the timer while guide is visible


func _on_next_button_pressed() -> void:
	# Hide the guide and resume/start timer
	hide()
	if not GuideManager.has_seen(guide_id):
		GuideManager.mark_seen(guide_id)
	if %GameTimer:
		if %GameTimer.running:
			%GameTimer.resume_timer()
		else:
			%GameTimer.start_timer()


func _on_guide_button_pressed() -> void:
	# Show guide and pause timer
	show()
	if %GameTimer:
		%GameTimer.pause_timer()
