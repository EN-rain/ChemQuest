extends Node2D

@onready var time_label: Label = $TimeBar/TimeLabel
@onready var time_bar: ProgressBar = $TimeBar
@onready var logic_timer: Timer = $Timer

signal time_up

var round_time: float = 60.0
var remaining: float = 60.0
var running: bool = false
var paused: bool = false

var fill_style: StyleBoxFlat
var bg_style: StyleBoxFlat


func _ready() -> void:
	# --- create and assign custom styles ---
	fill_style = StyleBoxFlat.new()
	bg_style = StyleBoxFlat.new()

	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	fill_style.bg_color = Color(0, 1, 0)

	# 🟢 Rounded corners for both fill and background
	for s in [bg_style, fill_style]:
		s.corner_radius_top_left = 12
		s.corner_radius_top_right = 12
		s.corner_radius_bottom_left = 12
		s.corner_radius_bottom_right = 12
		s.anti_aliasing = true

	time_bar.add_theme_stylebox_override("background", bg_style)
	time_bar.add_theme_stylebox_override("fill", fill_style)

	reset_timer_ui()
	# IMPORTANT: don't hard-set logic_timer.wait_time to round_time here.
	# we'll set it when starting/resuming so it always matches `remaining`.
	logic_timer.one_shot = true
	logic_timer.timeout.connect(_on_time_up)
	# (optional) start automatically:
	# start_timer()


func start_timer() -> void:
	# start fresh from full round_time
	remaining = round_time
	paused = false
	running = true
	reset_timer_ui()
	_update_bar_color()
	# set timer to the remaining time and start it
	logic_timer.wait_time = remaining
	logic_timer.start()


func resume_timer() -> void:
	# resume from current remaining time (only if paused)
	if not running or not paused:
		return
	paused = false
	_update_bar_color()
	# ensure logic_timer waits only the remaining time
	logic_timer.wait_time = remaining
	logic_timer.start()


func pause_timer() -> void:
	# pause without resetting remaining
	if not running or paused:
		return
	paused = true
	# stop the Timer so it won't trigger while paused
	if logic_timer and not logic_timer.is_stopped():
		logic_timer.stop()


func toggle_pause() -> void:
	# convenient toggle (call from a button)
	if not running:
		return
	if paused:
		resume_timer()
	else:
		pause_timer()


func _process(delta: float) -> void:
	if not running or paused:
		return

	remaining = max(0.0, remaining - delta)
	time_bar.value = remaining
	time_label.text = "%d" % int(remaining)
	_update_bar_color()

	if remaining <= 0.0:
		running = false
		if logic_timer and not logic_timer.is_stopped():
			logic_timer.stop()
		emit_signal("time_up")


func reset_timer_ui() -> void:
	time_bar.max_value = round_time
	time_bar.value = round_time
	time_label.text = "%d" % int(round_time)


func _update_bar_color() -> void:
	var t := 1.0 - (remaining / round_time)

	# interpolate color smoothly green → red
	var base_color := Color(0, 1, 0).lerp(Color(1, 0, 0), t)

	# make it pulse red near the end
	if remaining <= 10.0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		base_color = base_color.lerp(Color(1, 0, 0), pulse)

	fill_style.bg_color = base_color
	time_bar.queue_redraw()   # ✅ forces the UI to repaint the new color


func stop_timer() -> void:
	# full stop (not pause) — stops and marks not running
	running = false
	paused = false
	if logic_timer and not logic_timer.is_stopped():
		logic_timer.stop()


func _on_time_up() -> void:
	# ensure internal state is consistent when Timer times out
	remaining = 0.0
	running = false
	paused = false
	time_bar.value = 0.0
	time_label.text = "0"
	print("Time’s up!")
	emit_signal("time_up")


func reset_timer() -> void:
	stop_timer()
	start_timer()
