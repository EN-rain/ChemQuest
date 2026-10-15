extends Node

## Regression for Start -> menu: the transition fades immediately, and taps
## on the loaded menu never trigger the carousel's background fade.
var _failures: Array[String] = []


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	await get_tree().process_frame

	var menu: Node = load("res://games/main.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var carousel: ScrollContainer = menu.get_node("CanvasLayer/Control/ScrollContainer")
	var background: TextureRect = menu.get_node("CanvasLayer2/TextureBg")
	var initial_texture: Texture2D = background.texture
	var fade_rect: ColorRect = carousel.get("fade_rect")
	_expect("menu carousel initialized to Hometown", carousel.get("current_display_name") == "Hometown")
	_expect("menu background overlay starts transparent", is_instance_valid(fade_rect) and is_zero_approx(fade_rect.modulate.a))

	for tap_position in [Vector2(1000, 130), Vector2(450, 200), Vector2(300, 350)]:
		var down := InputEventScreenTouch.new()
		down.position = tap_position
		down.pressed = true
		get_viewport().push_input(down, true)
		var up := InputEventScreenTouch.new()
		up.position = tap_position
		up.pressed = false
		get_viewport().push_input(up, true)
		await get_tree().process_frame
		_expect("tap does not start carousel snap", not bool(carousel.get("released")))
		_expect("tap does not change background selection", carousel.get("current_display_name") == "Hometown")
		_expect("tap does not change main background texture", background.texture == initial_texture)
		_expect("tap does not start menu background fade", is_zero_approx(fade_rect.modulate.a))

	menu.queue_free()
	await get_tree().process_frame
	var intro: Node = load("res://intro.tscn").instantiate()
	add_child(intro)
	await get_tree().process_frame
	var transitions: Array[String] = []
	FadeManager.transition_started.connect(func(path: String) -> void: transitions.append(path))
	intro.call("_on_button_pressed")
	_expect("Start triggers menu transition immediately", transitions == ["res://games/main.tscn"])
	_expect("Start prevents double click", (intro.get_node("CanvasLayer/Button") as Button).disabled)
	await get_tree().create_timer(0.23).timeout
	_expect("Start fades to black before switching scenes", FadeManager.fade_rect.color.a > 0.1 and FadeManager.fade_rect.color.a < 0.95)
	_expect("menu has not appeared before fade out completes", get_tree().current_scene == self)

	if _failures.is_empty():
		print("INTRO_MENU_FADE PASS: Start fade begins before scene swap; unrelated menu taps do not fade the background")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("INTRO_MENU_FADE FAIL ", failure)
		get_tree().quit(2)


func _expect(_label: String, condition: bool) -> void:
	if not condition:
		_failures.append(_label)
