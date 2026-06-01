extends Control
class_name GameTime

@onready var label: Label = $Label as Label
@onready var timer: Timer = $Timer as Timer

signal tick(remaining_time: int)
signal time_up()

const ROUND_TIME: int = 30
var remaining_time: int = ROUND_TIME


func _ready() -> void:
	if has_node("Label"):
		label = $Label
	if has_node("Timer"):
		timer = $Timer

	timer.timeout.connect(_on_timer_tick)
	label.text = str(ROUND_TIME)
	_setup_timer()


func _setup_timer() -> void:
	if not timer:
		return
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.autostart = false


func start_round() -> void:
	remaining_time = ROUND_TIME

	if label:
		label.text = str(remaining_time)

	if timer:
		timer.start()


func stop_round() -> void:
	if timer:
		timer.stop()


func _on_timer_tick() -> void:
	remaining_time -= 1

	if label:
		label.text = str(remaining_time)

	emit_signal("tick", remaining_time)

	if remaining_time <= 0:
		if timer:
			timer.stop()
		if label:
			label.text = "0"
		emit_signal("time_up")
