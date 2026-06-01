extends Control

@onready var label = $NextButton/Label

# Unique guide ID for this scene
@export var guide_id: String = "precision_guide"

func _ready() -> void:
	# Recursively fade all labels
	_fade_all_labels(self)
	# Show this guide only once
	if GuideManager.has_seen(guide_id):
		hide()
	else:
		show()
		GuideManager.mark_seen(guide_id)


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

func _on_guide_button_pressed() -> void:
	show()
