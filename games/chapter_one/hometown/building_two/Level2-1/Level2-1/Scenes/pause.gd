extends Panel

@onready var back_panel = %BackPanel
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)
	
func _on_yes_pressed() -> void:
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_two/building_two.tscn")

func _on_no_pressed() -> void:
	back_panel.visible = false

func _on_back_pressed() -> void:
	back_panel.show()
