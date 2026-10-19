extends Node2D

const OUTLINE_COLOR := Color(0.02, 0.08, 0.22, 0.95)
const FILL_COLOR := Color(0.0, 0.75, 1.0, 1.0)
const HIGHLIGHT_COLOR := Color(0.8, 0.96, 1.0, 0.95)
const CHEVRON_OUTLINE := Color(0.02, 0.08, 0.22, 0.85)
const CHEVRON_FILL := Color(0.12, 0.58, 0.95, 0.85)


func _draw() -> void:
	# 1. Trailing Chevron Outline (Bigger scale)
	var chevron_outline := PackedVector2Array([
		Vector2(-18, 0),
		Vector2(-30, -12),
		Vector2(-26.5, -15.5),
		Vector2(-12.5, 0),
		Vector2(-26.5, 15.5),
		Vector2(-30, 12)
	])
	draw_colored_polygon(chevron_outline, CHEVRON_OUTLINE)

	# 2. Trailing Chevron Fill (Electric Blue)
	var chevron_fill := PackedVector2Array([
		Vector2(-19.5, 0),
		Vector2(-28.5, -10.5),
		Vector2(-25.5, -13),
		Vector2(-15, 0),
		Vector2(-25.5, 13),
		Vector2(-28.5, 10.5)
	])
	draw_colored_polygon(chevron_fill, CHEVRON_FILL)

	# 3. Main Arrow Dark Outline (Bigger scale: ~65px length, 42px width)
	var outline := PackedVector2Array([
		Vector2(35, 0),
		Vector2(5, -21),
		Vector2(9, -9),
		Vector2(-21, -9),
		Vector2(-12, 0),
		Vector2(-21, 9),
		Vector2(9, 9),
		Vector2(5, 21)
	])
	draw_colored_polygon(outline, OUTLINE_COLOR)

	# 4. Main Arrow Body (Vibrant Blue)
	var body := PackedVector2Array([
		Vector2(32, 0),
		Vector2(7, -18),
		Vector2(10.5, -6.5),
		Vector2(-18, -6.5),
		Vector2(-10.5, 0),
		Vector2(-18, 6.5),
		Vector2(10.5, 6.5),
		Vector2(7, 18)
	])
	draw_colored_polygon(body, FILL_COLOR)

	# 5. Inner Core Highlight (Glow cyan-white)
	var highlight := PackedVector2Array([
		Vector2(25, 0),
		Vector2(9, -8),
		Vector2(12, -3),
		Vector2(-5, -3),
		Vector2(-2, 0),
		Vector2(-5, 3),
		Vector2(12, 3),
		Vector2(9, 8)
	])
	draw_colored_polygon(highlight, HIGHLIGHT_COLOR)
