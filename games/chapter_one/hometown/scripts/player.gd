extends CharacterBody2D

@export var walk_speed: float = 300
@export var run_speed: float = 600
var can_move: bool = true
var is_running: bool = false

# Double-tap detection
var last_tap_time := 0.0
var last_tap_dir := ""
const DOUBLE_TAP_TIME := 0.3
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep: AudioStreamPlayer = $AudioStreamPlayer  #  your footstep node

var last_anim_dir := "down"
var first_pressed_dir := ""

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle()
		_stop_footsteps()
		return

	var direction := Vector2.ZERO

	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1

	# Detect first pressed direction
	if Input.is_action_just_pressed("up"):
		first_pressed_dir = "up"
	elif Input.is_action_just_pressed("down"):
		first_pressed_dir = "down"
	elif Input.is_action_just_pressed("left"):
		first_pressed_dir = "left"
	elif Input.is_action_just_pressed("right"):
		first_pressed_dir = "right"

	# If all keys released, reset
	if direction == Vector2.ZERO:
		first_pressed_dir = ""
		_stop_footsteps()
	else:
		_play_footsteps()

	# === Double-tap detection ===
	var current_dir := _get_input_direction_name(direction)
	var now := Time.get_ticks_msec() / 1000.0

	if current_dir != "":
		if Input.is_action_just_pressed(current_dir):
			if current_dir == last_tap_dir and (now - last_tap_time) < DOUBLE_TAP_TIME:
				is_running = true
				print("🏃 Running:", current_dir)
			else:
				is_running = false
			last_tap_dir = current_dir
			last_tap_time = now
		elif Input.is_action_pressed(current_dir) and is_running:
			is_running = true
	else:
		is_running = false

	# === Apply movement (supports diagonals) ===
	var speed = run_speed if is_running else walk_speed
	velocity = direction.normalized() * speed
	move_and_slide()

	# === Animation ===
	if direction == Vector2.ZERO:
		_play_idle()
	else:
		_play_movement(first_pressed_dir if first_pressed_dir != "" else current_dir)

# === Animation Functions ===
func _play_idle() -> void:
	var anim_name := "idle_" + last_anim_dir
	if anim.animation != anim_name:
		anim.play(anim_name)

func _play_movement(dir_name: String) -> void:
	if dir_name == "":
		return

	last_anim_dir = dir_name
	var state := "run" if is_running else "walk"
	var anim_name := state + "_" + dir_name
	if anim.animation != anim_name:
		anim.play(anim_name)

# === Audio Handling ===
func _play_footsteps() -> void:
	if not footstep.playing:
		footstep.play()

	# Slower when walking, faster when running
	if is_running:
		footstep.pitch_scale = 0.8   # normal speed for running
	else:
		footstep.pitch_scale = 0.5  # slower, deeper sound for walking


func _stop_footsteps() -> void:
	if footstep.playing:
		footstep.stop()

# === Utility for double-tap logic ===
func _get_input_direction_name(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	elif abs(direction.y) > 0:
		return "down" if direction.y > 0 else "up"
	return ""

# 🔇 Toggle footstep sounds on/off
func set_footsteps_muted(muted: bool) -> void:
	if footstep:
		footstep.volume_db = -80 if muted else 0

func set_movement_enabled(value: bool) -> void:
	can_move = value
