extends CharacterBody2D

@export var base_speed := 200.0
@export var base_jump_force := 400.0
@onready var animated_sprite := $AnimatedSprite2D
@onready var hand_position: Marker2D = $HandPosition
@onready var collision_shape := $bodycollision   # ✅ make sure you have one in Player scene

var is_in_range: bool = false
var target: RigidBody2D
var held_object: RigidBody2D = null
var current_speed: float
var current_jump_force: float
var took_damage: bool = false   # ✅ track death state

func respawn():
	get_tree().reload_current_scene()

func _ready():
	current_speed = base_speed
	current_jump_force = base_jump_force

func _physics_process(delta: float) -> void:
	pickup_object()
	drop_object()
	
	# Spikes Effect (Mario-style death)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Spikes" and not took_damage:
			took_damage = true
			velocity = Vector2(0, -200)   # little bounce
			animated_sprite.play("fall")
			collision_shape.disabled = true   # fall through the map
			await get_tree().create_timer(1.0).timeout
			respawn()
			return

	# Movement with weight effects
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
	velocity.x = direction * current_speed

	# Jumping with weight effects
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = -current_jump_force
	else:
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

	move_and_slide()

	# Update animation
	if is_on_floor():
		if direction != 0:
			animated_sprite.play("run")
			animated_sprite.flip_h = direction < 0
		else:
			animated_sprite.play("idle")
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")  
		else:
			animated_sprite.play("fall") 

# ✅ Pickup Code
func pickup_object() -> void:
	if is_in_range and Input.is_action_just_pressed("pickup") and not held_object:
		held_object = target
		held_object._on_picked_up()
		held_object.reparent(hand_position)
		held_object.position = hand_position.position
		held_object.linear_velocity = Vector2.ZERO
		held_object.freeze = true

		# Apply weight effects based on density
		var density = held_object.get_density()
		var speed_modifier = 1.0 + (density * 0.05)
		var jump_modifier = 1.0 - (density * 0.03)

		current_speed = base_speed / speed_modifier
		current_jump_force = base_jump_force * clamp(jump_modifier, 0.5, 1.0)

		# Visual feedback
		animated_sprite.modulate = Color(1, 0.95, 0.9)

# ✅ Updated Drop Code with Arc
func drop_object() -> void:
	if Input.is_action_just_pressed("drop") and held_object:
		# Reparent back to world
		held_object.reparent(get_parent())
		held_object._on_dropped()

		# Position slightly in front of player
		var drop_offset = Vector2.RIGHT * 20 if not animated_sprite.flip_h else Vector2.LEFT * 20
		held_object.position = position + drop_offset

		# Enable physics and throw with an arc
		held_object.freeze = false
		var throw_force := Vector2(
			150 if not animated_sprite.flip_h else -150,  # forward push
			-300                                         # upward push
		)
		held_object.linear_velocity = throw_force

		# Clear held object
		held_object = null

		# Reset player stats
		current_speed = base_speed
		current_jump_force = base_jump_force
		animated_sprite.modulate = Color.WHITE

func _on_range_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.get_collision_layer_value(1):
		is_in_range = true
		target = body

func _on_range_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and body.get_collision_layer_value(1):
		is_in_range = false
		target = null
