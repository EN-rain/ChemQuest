extends Control

signal screen_pressed

const GUIDE_ID := "hometown_controls_tutorial"
const TUTORIAL_ANIMATION := "tutorial_anim"
const FIRST_STOP := 1.0
const SECOND_STOP := 2.0
const FIRST_TEXT := "Use these controls to move, and double tap any direction to run."
const SECOND_TEXT := "Follow this quest to progress"

@onready var animation_player: AnimationPlayer = $Panel/AnimationPlayer
@onready var label: Label = $Panel/Label

func _ready() -> void:
	visible = false

	if has_node("/root/GuideManager") and GuideManager.has_seen(GUIDE_ID):
		return

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if has_node("/root/GuideManager"):
		GuideManager.mark_seen(GUIDE_ID)

	if not animation_player.has_animation(TUTORIAL_ANIMATION):
		visible = false
		return

	var animation := animation_player.get_animation(TUTORIAL_ANIMATION)
	await _show_step(FIRST_STOP, FIRST_TEXT)
	await _play_until(SECOND_STOP)
	await _show_step(SECOND_STOP, SECOND_TEXT)
	await _play_until(animation.length)

	visible = false

func _show_step(time: float, text: String) -> void:
	animation_player.play(TUTORIAL_ANIMATION)
	animation_player.seek(time, true)
	animation_player.pause()
	label.text = text
	await _wait_for_screen_press()

func _play_until(time: float) -> void:
	var start_time := animation_player.current_animation_position
	animation_player.play(TUTORIAL_ANIMATION)
	animation_player.seek(start_time, true)
	while animation_player.current_animation_position < time:
		await get_tree().process_frame
	animation_player.seek(time, true)
	animation_player.pause()

func _wait_for_screen_press() -> void:
	await screen_pressed

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		screen_pressed.emit()
	elif event is InputEventScreenTouch and event.pressed:
		screen_pressed.emit()
