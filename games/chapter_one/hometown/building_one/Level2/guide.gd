extends Control

@onready var label = $NextButton/Label

# Unique guide ID for this scene
@export var guide_id: String = "property_guide"

func _ready() -> void:
	# Recursively fade all labels
	_fade_all_labels(self)
	# Show this guide only once
	if GuideManager.has_seen(guide_id):
		hide()
	else:
		show()
		if %Timer:
			%Timer.set_paused(true)  # Pause the timer while guide is visible

func _fade_all_labels(node: Node) -> void:
	for lbl in node.get_children():  # changed from 'label' to 'lbl'
		if lbl is Label:
			_start_label_tween(lbl)
		_fade_all_labels(lbl) # recurse deeper

func _start_label_tween(lbl: Label) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tween.tween_property(lbl, "modulate:a", 1.0, 2.0)

func _on_next_button_pressed() -> void:
	hide()
	if not GuideManager.has_seen(guide_id):
		GuideManager.mark_seen(guide_id)
	if %Timer:
		if %Timer.is_stopped():
			%Timer.start()
		else:
			%Timer.set_paused(false)


func _on_guide_button_pressed() -> void:
	show()
	if %Timer:
		%Timer.set_paused(true)
