extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = $CanvasLayer/ColorRect

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0) # Start fully transparent

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	print("Player reached the gate ✅")
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(
		Callable(self, "_on_flag_animation_finished"),
		CONNECT_ONE_SHOT
	)

func _on_flag_animation_finished() -> void:
	if not fade_rect:
		_close_game()
		return

	# Fade to black before closing the game
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 2.0) # Fade out over 2 seconds
	tween.finished.connect(Callable(self, "_close_game"), CONNECT_ONE_SHOT)

func _close_game() -> void:
	print("🎮 Game Over – Closing the game...")
	get_tree().quit()
