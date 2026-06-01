extends Control

@onready var overlay: ColorRect = $ColorRect
@onready var anim: AnimationPlayer = $Node2D/AnimationPlayer

var closed_pos: Vector2
var open_pos: Vector2
var _tween: Tween

func _ready() -> void:

	overlay.hide()

func _on_menu_button_pressed() -> void:
	anim.play("slide_in")
	%Player.can_move = false
	overlay.show()
	_slide_to(open_pos)

func _on_back_pressed() -> void:
	_slide_to(closed_pos)
	anim.play_backwards("slide_in")
	
func _slide_to(target: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)

	# when fully closed again
	if target == closed_pos:
		_tween.finished.connect(func():
			overlay.hide()
			%Player.can_move = true
		)
