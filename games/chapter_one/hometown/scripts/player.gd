extends CharacterBody2D

@export var walk_speed: float = 300
@export var run_speed: float = 600
var can_move: bool = true:
	set(value):
		if can_move != value:
			print("🔒 [Player] can_move changed: ", can_move, " -> ", value, " at pos=", global_position)
		can_move = value
var is_running: bool = false
var _logged_blocked: bool = false
var _logged_moving: bool = false

# Double-tap detection
var last_tap_time := 0.0
var last_tap_dir := ""
const DOUBLE_TAP_TIME := 0.3
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var footstep: AudioStreamPlayer = $AudioStreamPlayer  #  your footstep node
@onready var nav_arrow: Node2D = get_node_or_null("NavArrow")

var last_anim_dir := "down"
var first_pressed_dir := ""


func _ready() -> void:
	print("🎮 [Player] _ready() at global_position=", global_position, " can_move=", can_move)
	if nav_arrow == null:
		var arrow_scene: PackedScene = load("res://games/chapter_one/hometown/nav_arrow.tscn")
		if arrow_scene != null:
			nav_arrow = arrow_scene.instantiate() as Node2D
			add_child(nav_arrow)

func _physics_process(_delta: float) -> void:
	var raw_input := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)

	if not can_move:
		if raw_input != Vector2.ZERO:
			if not _logged_blocked:
				_logged_blocked = true
				print("⚠️ [Player] Movement input pressed (", raw_input, ") but can_move is FALSE! pos=", global_position)
		else:
			_logged_blocked = false
		velocity = Vector2.ZERO
		move_and_slide()
		_play_idle()
		_stop_footsteps()
		return

	if raw_input != Vector2.ZERO:
		if not _logged_moving:
			_logged_moving = true
			print("🏃 [Player] Started moving: raw_input=", raw_input, " at pos=", global_position)
	else:
		_logged_moving = false

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

	# If first_pressed_dir is no longer held or its axis is zero, clear it
	if first_pressed_dir != "":
		if not Input.is_action_pressed(first_pressed_dir):
			first_pressed_dir = ""
		elif (first_pressed_dir == "up" or first_pressed_dir == "down") and direction.y == 0:
			first_pressed_dir = ""
		elif (first_pressed_dir == "left" or first_pressed_dir == "right") and direction.x == 0:
			first_pressed_dir = ""

	# If all keys released, reset
	if direction == Vector2.ZERO:
		first_pressed_dir = ""
		_stop_footsteps()
	else:
		_play_footsteps()

	# === Running detection ===
	var current_dir := _get_input_direction_name(direction)
	if VirtualJoystick.is_active:
		is_running = VirtualJoystick.is_joystick_running
	else:
		# Double-tap detection for arrows / keyboard
		var now := Time.get_ticks_msec() / 1000.0
		if current_dir != "":
			if Input.is_action_just_pressed(current_dir):
				if current_dir == last_tap_dir and (now - last_tap_time) < DOUBLE_TAP_TIME:
					is_running = true
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
		var anim_target_dir := current_dir
		if first_pressed_dir != "" and Input.is_action_pressed(first_pressed_dir):
			if (first_pressed_dir in ["left", "right"] and direction.x != 0) or \
			   (first_pressed_dir in ["up", "down"] and direction.y != 0):
				anim_target_dir = first_pressed_dir
		_play_movement(anim_target_dir)

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
	elif abs(direction.y) > abs(direction.x):
		return "down" if direction.y > 0 else "up"
	elif direction != Vector2.ZERO:
		# Diagonal tie: preserve last anim direction if active on that axis
		if last_anim_dir == "left" and direction.x < 0:
			return "left"
		if last_anim_dir == "right" and direction.x > 0:
			return "right"
		if last_anim_dir == "up" and direction.y < 0:
			return "up"
		if last_anim_dir == "down" and direction.y > 0:
			return "down"
		# Default tie breaker: horizontal
		return "right" if direction.x > 0 else "left"
	return ""

# 🔇 Toggle footstep sounds on/off
func set_footsteps_muted(muted: bool) -> void:
	if footstep:
		footstep.volume_db = -80 if muted else 0

func set_movement_enabled(value: bool) -> void:
	can_move = value
