extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	MusicManager.current_music.volume_db = -10  
	FadeManager.setup(fade_sfx)
	
func _on_back_button_pressed() -> void:
	await FadeManager.fade_and_change("res://games/main.tscn")
