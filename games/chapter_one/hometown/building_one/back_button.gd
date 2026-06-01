extends Button
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
