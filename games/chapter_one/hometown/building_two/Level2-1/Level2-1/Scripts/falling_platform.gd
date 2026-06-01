extends StaticBody2D

@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var original_position: Vector2

func _ready() -> void:
	# Store the original position of the collision shape
	original_position = collision_shape_2d.position
	timer.one_shot = true
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player":
		timer.start(0.15)  # wait 1.5 sec before disappearing

func _on_timer_timeout() -> void:
	# Step 1: Disappear
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	collision_shape_2d.disabled = true
	collision_shape_2d.position = Vector2(-10000, 20000)

	# Step 2: Start a delayed call to reappear
	await get_tree().create_timer(4.0).timeout
	reappear()

func reappear() -> void:
	# Restore visibility
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

	# Re-enable collision
	collision_shape_2d.disabled = false
	collision_shape_2d.position = original_position
