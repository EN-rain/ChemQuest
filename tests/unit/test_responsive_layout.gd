extends Node

const ResponsiveLayoutScript := preload("res://games/global/ResponsiveLayout.gd")
const FixedAspectSurfaceScript := preload("res://games/ui/FixedAspectSurface.gd")

var _failures: Array[String] = []


func _ready() -> void:
	_expect("landscape size is detected", ResponsiveLayoutScript.is_landscape_size(Vector2(1280, 720)))
	_expect("portrait size is detected", not ResponsiveLayoutScript.is_landscape_size(Vector2(720, 1280)))
	_expect("square size is treated as portrait guard", not ResponsiveLayoutScript.is_landscape_size(Vector2(720, 720)))
	_expect("wide scale uses the limiting axis", is_equal_approx(ResponsiveLayoutScript.uniform_scale(Vector2(2560, 1080), Vector2(1280, 720)), 1.5))
	_expect("tall scale uses the limiting axis", is_equal_approx(ResponsiveLayoutScript.uniform_scale(Vector2(1024, 768), Vector2(1280, 720)), 0.8))
	_expect("invalid design size returns zero scale", ResponsiveLayoutScript.uniform_scale(Vector2(1280, 720), Vector2.ZERO) == 0.0)
	_expect("invalid available size returns zero surface scale", FixedAspectSurfaceScript.calculate_scale(Vector2.ZERO) == 0.0)

	var safe_rect := ResponsiveLayoutScript.safe_rect_for(Vector2(1280, 720), Vector4(24, 16, 24, 16))
	_expect("safe rect preserves left inset", safe_rect.position.x == 24.0)
	_expect("safe rect preserves top inset", safe_rect.position.y == 16.0)
	_expect("safe rect subtracts horizontal insets", safe_rect.size.x == 1232.0)
	_expect("safe rect subtracts vertical insets", safe_rect.size.y == 688.0)

	var clamped := ResponsiveLayoutScript.safe_rect_for(Vector2(32, 32), Vector4(24, 24, 24, 24))
	_expect("safe rect clamps impossible insets", clamped.size == Vector2.ZERO)

	_expect("surface scale delegates to shared layout math", is_equal_approx(FixedAspectSurfaceScript.calculate_scale(Vector2(1920, 1080)), 1.5))

	if _failures.is_empty():
		print("RESPONSIVE_LAYOUT_RESULT PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("RESPONSIVE_LAYOUT_FAIL " + failure)
		get_tree().quit(1)


func _expect(label: String, condition: bool) -> void:
	if not condition:
		_failures.append(label)
