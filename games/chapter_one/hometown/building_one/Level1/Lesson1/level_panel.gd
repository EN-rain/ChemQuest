extends Panel
@onready var pass_panel = %Pass
@onready var checker = %Checker/Node2D

@onready var button1: Button = %Button1
@onready var button2: Button = %Button2
@onready var button3: Button = %Button3

@onready var lbg1: Sprite2D = %lbg1
@onready var lbg2: Sprite2D = %lbg2
@onready var lbg3: Sprite2D = %lbg3

var positions: Dictionary = {}
var active_button: Button = null
var is_focus_mode: bool = false
var is_expanded: bool = false

func _ready() -> void:
	positions[1] = button1.position
	positions[2] = button2.position
	positions[3] = button3.position

	_hide_buttons([button2, button3], true)

	button1.pressed.connect(func():
		# Always handle UI fade/show
		_on_focus_pressed(button1)

		# Difficulty logic
		if pass_panel and pass_panel.has_method("set_difficulty") and pass_panel.difficulty != 1:
			pass_panel.set_difficulty(1)
			if checker and checker.has_method("reset_game"):
				checker.reset_game()
	)


	button2.pressed.connect(func():
		_on_focus_pressed(button2)
		if pass_panel and pass_panel.has_method("set_difficulty"):
			pass_panel.set_difficulty(2)
		if checker and checker.has_method("reset_game"):
			checker.reset_game()
	)

	button3.pressed.connect(func():
		_on_focus_pressed(button3)
		if pass_panel and pass_panel.has_method("set_difficulty"):
			pass_panel.set_difficulty(3)
		if checker and checker.has_method("reset_game"):
			checker.reset_game()
	)


	# show lbg1 by default
	_update_lbg(button1)


func _on_focus_pressed(clicked: Button) -> void:
	if active_button == clicked and is_focus_mode:
		# collapse → reset order and show all
		_move_button(button1, positions[1])
		_move_button(button2, positions[2])
		_move_button(button3, positions[3])

		var others: Array = []
		for b in [button1, button2, button3]:
			if b != clicked:
				others.append(b)

		_show_buttons(others)
		is_focus_mode = false
		is_expanded = true
		_update_lbg(clicked)
	else:
		# focus mode: clicked goes top, others fade out
		_move_button(clicked, positions[1])

		var others: Array = []
		for b in [button1, button2, button3]:
			if b != clicked:
				others.append(b)

		_move_button(others[0], positions[2])
		_move_button(others[1], positions[3])
		_hide_buttons(others)

		active_button = clicked
		is_focus_mode = true
		_update_lbg(clicked)


func _move_button(btn: Button, target_pos: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "position", target_pos, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_buttons(buttons: Array, instant: bool = false) -> void:
	for b in buttons:
		if instant:
			b.visible = false
		else:
			var tween := create_tween()
			tween.tween_property(b, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)
			tween.finished.connect(func(): b.visible = false)


func _show_buttons(buttons: Array) -> void:
	for b in buttons:
		b.visible = true
		b.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(b, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_LINEAR)


func _update_lbg(active: Button) -> void:
	lbg1.visible = false
	lbg2.visible = false
	lbg3.visible = false

	if active == button1:
		lbg1.visible = true
	elif active == button2:
		lbg2.visible = true
	elif active == button3:
		lbg3.visible = true
