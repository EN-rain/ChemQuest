extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var controls_modal: Control = %ControlsModal


func _ready() -> void:
	if fade_sfx != null:
		FadeManager.setup(fade_sfx)
	if controls_modal != null:
		controls_modal.visible = false


func _on_back_button_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/main.tscn")


func _on_controls_pressed() -> void:
	MusicManager.play_sfx("button")
	if controls_modal != null:
		controls_modal.visible = true


func _on_close_controls_pressed() -> void:
	MusicManager.play_sfx("button")
	if controls_modal != null:
		controls_modal.visible = false


func _on_achievements_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/achievements/achievements.tscn")


func _on_about_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/about.tscn")
