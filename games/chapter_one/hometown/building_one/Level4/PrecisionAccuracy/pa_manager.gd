extends Node2D

@onready var fire_button: Button = %FireButton
@onready var fire_zone: Area2D = %FireZone
@onready var fire_zone_boundary: ColorRect = %FireZoneBoundary
@onready var target_manager: Node2D = %TargetManager
@onready var score_display: Control = %ScoreDisplay

# FireZone movement
var fire_zone_speed: float = 300.0
var boundary_rect: Rect2
var moving_right: bool = true

# scoring
var max_score: int = 100
var target_radius: float = 65.0   # ≈ radius of Score1 ring

func _ready():
	Scoring.set_last_scene(get_tree().current_scene.scene_file_path)

	if fire_button:
		fire_button.pressed.connect(_on_fire_button_pressed)

	if fire_zone and fire_zone_boundary:
		var boundary_size = fire_zone_boundary.size
		var boundary_global_pos = fire_zone_boundary.global_position
		boundary_rect = Rect2(boundary_global_pos, boundary_size)

		# Ensure FireZone only collides with targets
		fire_zone.collision_layer = 4
		fire_zone.collision_mask = 2

func _physics_process(delta):
	if fire_zone and boundary_rect:
		var movement = fire_zone_speed * delta
		if moving_right:
			fire_zone.global_position.x += movement
			if fire_zone.global_position.x >= boundary_rect.end.x:
				fire_zone.global_position.x = boundary_rect.end.x
				moving_right = false
		else:
			fire_zone.global_position.x -= movement
			if fire_zone.global_position.x <= boundary_rect.position.x:
				fire_zone.global_position.x = boundary_rect.position.x
				moving_right = true

func _on_fire_button_pressed():
	# 🔊 Play shoot sound
	var sfx := AudioStreamPlayer.new()
	sfx.stream = MusicManager.music_library["shoot"]
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(func(): sfx.queue_free())

	var overlapping = fire_zone.get_overlapping_areas()
	var best_score := -1
	var hit_target: Node2D = null
	var hit_position := fire_zone.global_position

	for area in overlapping:
		if area.name.begins_with("Score"):
			var target: Node2D = area.get_parent()
			if target and target.name.begins_with("Target") and target.visible:
				if "has_been_hit" in target and target.has_been_hit:
					continue

				# get center
				var target_img: Sprite2D = target.get_node_or_null("TargetImg")
				var center_pos: Vector2 = target_img.global_position if target_img else target.global_position

				# score by distance
				var distance: float = center_pos.distance_to(fire_zone.global_position)
				var proximity: float = clamp(1.0 - (distance / target_radius), 0.0, 1.0)
				var score: int = int(round(proximity * max_score))

				if score > best_score:
					best_score = score
					hit_target = target
					hit_position = fire_zone.global_position

	if hit_target:
		on_target_hit(hit_target, hit_position, best_score)


func on_target_hit(target: Node2D, hit_pos: Vector2, score: int):
	if target_manager:
		target_manager.on_target_hit(target, hit_pos, score)

	if score_display and score_display.has_method("update_hit_display"):
		# ✅ pass the target node directly
		score_display.update_hit_display(target, hit_pos, score)

	increase_fire_zone_speed()

func increase_fire_zone_speed():
	fire_zone_speed += 20.0

func _on_home_pressed() -> void:
	Scoring.reset_precision_accuracy_score()
	get_tree().change_scene_to_file("res://scenes/levels/level_map/level_map.tscn")
