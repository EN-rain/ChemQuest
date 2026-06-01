extends CharacterBody2D

@export var speed := 200.0
@export var jump_force := -400.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var can_move: bool = true
var current_state: String = "Solid"   # "Solid", "Liquid", "Gas"
var target_state: String = ""         # used during phase transition
var in_transition: bool = false       # true while global_phasing animation plays

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	update_phase(current_state)


func _physics_process(delta: float) -> void:
	# Gravity
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += 1200 * delta

	# Jump (✅ allow during phasing)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# Movement input (✅ allow during phasing)
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * speed

	# Flip sprite
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	move_and_slide()

	# --- Phase switching (keys 1,2,3 or your mapping) ---
	if not in_transition:
		if Input.is_action_just_pressed("Solid") and current_state != "Solid":
			start_phase_transition("Solid")
		elif Input.is_action_just_pressed("Liquid") and current_state != "Liquid":
			start_phase_transition("Liquid")
		elif Input.is_action_just_pressed("Gas") and current_state != "Gas":
			start_phase_transition("Gas")

	# --- Animations ---
	if not in_transition:  # normal state animations
		match current_state:
			"Solid":
				if not is_on_floor():
					if velocity.y < 0:
						animated_sprite.play("solid_jump")
					else:
						animated_sprite.play("solid_fall")
				elif direction != 0:
					animated_sprite.play("solid_run")
				else:
					animated_sprite.play("solid_idle")

			"Liquid":
				if not is_on_floor():
					if velocity.y < 0:
						animated_sprite.play("liquid_jump")
					else:
						animated_sprite.play("liquid_fall")
				elif direction != 0:
					animated_sprite.play("liquid_run")
				else:
					animated_sprite.play("liquid_idle")

			"Gas":
				if not is_on_floor():
					if velocity.y < 0:
						animated_sprite.play("gas_jump")
					else:
						animated_sprite.play("gas_fall")
				elif direction != 0:
					animated_sprite.play("gas_run")
				else:
					animated_sprite.play("gas_idle")
	else:
		# ✅ While in transition, keep playing global phasing animation
		if animated_sprite.animation != "global_phasing":
			animated_sprite.play("global_phasing")


# --- Handle starting a phase transition ---
func start_phase_transition(new_state: String) -> void:
	in_transition = true
	target_state = new_state

	if animated_sprite.sprite_frames.has_animation("global_phasing"):
		animated_sprite.play("global_phasing")
	else:
		update_phase(new_state)
		in_transition = false


# --- Called when an animation finishes ---
func _on_animation_finished() -> void:
	if in_transition and animated_sprite.animation == "global_phasing":
		in_transition = false
		update_phase(target_state)


# --- Apply new phase ---
func update_phase(state: String) -> void:
	current_state = state

	match state:
		"Solid":
			animated_sprite.play("solid_idle")
		"Liquid":
			animated_sprite.play("liquid_idle")
		"Gas":
			animated_sprite.play("gas_idle")
