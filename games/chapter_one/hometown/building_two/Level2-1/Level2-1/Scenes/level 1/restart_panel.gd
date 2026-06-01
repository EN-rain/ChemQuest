extends Panel

@onready var back_panel = %BackPanel
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)
	
func _on_yes_pressed() -> void:
	await FadeManager.reload_current_scene()

func _on_no_pressed() -> void:
	hide()

func _on_button_pressed() -> void:
	show()
