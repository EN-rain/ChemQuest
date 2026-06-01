extends Panel

signal resume_timer  # ✅ Define once

@onready var back_panel = %BackPanel
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	FadeManager.setup(fade_sfx)

func _on_yes_pressed() -> void:
	SpawnManager.set_spawn("seperation_spawn")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_no_pressed() -> void:
	back_panel.visible = false
	emit_signal("resume_timer")  
