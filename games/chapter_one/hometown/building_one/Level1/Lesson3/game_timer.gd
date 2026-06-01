extends Node2D

@onready var time_label: Label = $TimeBar/TimeLabel
@onready var time_bar: ProgressBar = $TimeBar
@onready var logic_timer: Timer = $Timer

signal time_up

var round_time: float = 60.0
var remaining: float = 60.0
var running: bool = false

var fill_style: StyleBoxFlat
var bg_style: StyleBoxFlat


func _ready() -> void:
	# --- create and assign custom styles ---
	fill_style = StyleBoxFlat.new()
	bg_style = StyleBoxFlat.new()

	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	fill_style.bg_color = Color(0, 1, 0)

	for s in [bg_style, fill_style]:
		s.corner_radius_top_left = 12
		s.corner_radius_top_right = 12
		s.corner_radius_bottom_left = 12
		s.corner_radius_bottom_right = 12
		s.anti_aliasing = true

	time_bar.add_theme_stylebox_override("background", bg_style)
	time_bar.add_theme_stylebox_override("fill", fill_style)

	reset_timer_ui()
	logic_timer.wait_time = round_time
	logic_timer.one_shot = true
	logic_timer.timeout.connect(_on_time_up)
	start_timer()


func start_timer() -> void:
	remaining = round_time
	reset_timer_ui()
	_update_bar_color()
	logic_timer.start()
	running = true


func _process(delta: float) -> void:
	if not running:
		return

	remaining = max(0.0, remaining - delta)
	time_bar.value = remaining
	time_label.text = "%d" % int(remaining)
	_update_bar_color()

	if remaining <= 0.0:
		running = false
		logic_timer.stop()
		emit_signal("time_up")
		_handle_time_up_results()  # ✅ NEW


func reset_timer_ui() -> void:
	time_bar.max_value = round_time
	time_bar.value = round_time
	time_label.text = "%d" % int(round_time)


func _update_bar_color() -> void:
	var t := 1.0 - (remaining / round_time)
	var base_color := Color(0, 1, 0).lerp(Color(1, 0, 0), t)

	if remaining <= 10.0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
		base_color = base_color.lerp(Color(1, 0, 0), pulse)

	fill_style.bg_color = base_color
	time_bar.queue_redraw()


func stop_timer() -> void:
	running = false
	if logic_timer and not logic_timer.is_stopped():
		logic_timer.stop()


func _on_time_up() -> void:
	print("Time’s up!")
	emit_signal("time_up")
	_handle_time_up_results()  # ✅ Ensures trigger if connected only here


func reset_timer() -> void:
	stop_timer()
	start_timer()

func pause_timer() -> void:
	if not running:
		return
	running = false
	if logic_timer and logic_timer.is_stopped() == false:
		logic_timer.set_paused(true)
	print("⏸ Timer paused.")


func resume_timer() -> void:
	if running:
		return
	running = true
	if logic_timer:
		logic_timer.set_paused(false)
	print("▶ Timer resumed.")

# ✅ NEW — When timer runs out, show results even if unsorted
func _handle_time_up_results() -> void:
	# Find the Boxes node (where sorting happens)
	var boxes = get_tree().get_root().get_node_or_null("Lesson3/CanvasLayer/MarginContainer/Control/Boxes")
	if not boxes:
		print("⚠️ Couldn’t find Boxes node — skipping results display.")
		return

	# Find the ResultsPanel
	var results_panel = get_tree().get_root().get_node_or_null("Lesson3/CanvasLayer/MarginContainer/Control/ResultsPanel")
	if not results_panel:
		print("⚠️ Couldn’t find ResultsPanel node — skipping results display.")
		return

	if results_panel.visible:
		return  # already showing

	# Collect data
	var correct_count: int = boxes.correct_count if "correct_count" in boxes else 0
	var mistakes: Array = boxes.mistakes if "mistakes" in boxes else []

	print("⏰ Timer ended — showing results early. Correct:", correct_count, "Mistakes:", mistakes.size())

	# Stop everything else
	if "lesson3" in boxes and boxes.lesson3 and boxes.lesson3.has_method("lock_all_mixtures"):
		boxes.lesson3.lock_all_mixtures()

	# Show results panel
	results_panel.show_results(correct_count, mistakes)

	# Stop any additional spawns or logic
	if "lesson3" in boxes and boxes.lesson3 and boxes.lesson3.has_method("save_history"):
		boxes.lesson3.save_history()
