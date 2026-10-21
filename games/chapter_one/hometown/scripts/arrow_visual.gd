extends Node2D

# Sleek, modern pointer arrow silhouette
var arrow_body := PackedVector2Array([
	Vector2(22, 0),       # Tip
	Vector2(5, -13),      # Upper arrowhead wing
	Vector2(7, -5),       # Upper inner neck
	Vector2(-14, -5),     # Upper shaft tail
	Vector2(-10, 0),      # Tail notch
	Vector2(-14, 5),      # Lower shaft tail
	Vector2(7, 5),        # Lower inner neck
	Vector2(5, 13)        # Lower arrowhead wing
])

const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.28)
const OUTLINE_COLOR := Color(0.15, 0.15, 0.18, 0.65)
const WHITE_CORE := Color(1.0, 1.0, 1.0, 1.0)
const GLOW_COLOR := Color(1.0, 1.0, 1.0)

var _shadow_polys: Array[PackedVector2Array] = []
var _outline_polys: Array[PackedVector2Array] = []
var _glow_layers: Array[Dictionary] = []
var _pulse: float = 0.0


func _ready() -> void:
	_generate_polygons()


func _generate_polygons() -> void:
	# Subtle drop shadow
	_shadow_polys = Geometry2D.offset_polygon(arrow_body, 1.6, Geometry2D.JOIN_ROUND)

	# Crisp contrast rim so white arrow remains readable on all bright/sand tiles
	_outline_polys = Geometry2D.offset_polygon(arrow_body, 0.9, Geometry2D.JOIN_ROUND)

	# Multi-stage soft white glow aura
	_glow_layers.clear()
	var glow_radii: Array[float] = [9.0, 6.0, 3.8, 2.0]
	var glow_alphas: Array[float] = [0.08, 0.16, 0.30, 0.52]

	for i in range(glow_radii.size()):
		var polys := Geometry2D.offset_polygon(arrow_body, glow_radii[i], Geometry2D.JOIN_ROUND)
		_glow_layers.append({
			"polys": polys,
			"base_alpha": glow_alphas[i]
		})


func _process(delta: float) -> void:
	_pulse += delta * 3.8
	queue_redraw()


func _draw() -> void:
	var pulse_factor := 0.78 + 0.22 * sin(_pulse)

	# 1. Ambient Drop Shadow (offset down-right for clean 3D separation)
	var shadow_offset := Vector2(0, 1.5)
	if _shadow_polys.size() > 0:
		for poly in _shadow_polys:
			var shifted := PackedVector2Array()
			shifted.resize(poly.size())
			for i in range(poly.size()):
				shifted[i] = poly[i] + shadow_offset
			draw_colored_polygon(shifted, SHADOW_COLOR)
	else:
		var shifted_body := PackedVector2Array()
		shifted_body.resize(arrow_body.size())
		for i in range(arrow_body.size()):
			shifted_body[i] = arrow_body[i] + shadow_offset
		draw_colored_polygon(shifted_body, SHADOW_COLOR)

	# 2. Outer Radiant Glowing Halo (Breathing white aura)
	for layer in _glow_layers:
		var alpha: float = layer["base_alpha"] * pulse_factor
		var c := Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha)
		var polys: Array = layer["polys"]
		for p in polys:
			draw_colored_polygon(p, c)

	# 3. Contrast Rim (Keeps arrow crisp on light surfaces)
	if _outline_polys.size() > 0:
		for p in _outline_polys:
			draw_colored_polygon(p, OUTLINE_COLOR)

	# 4. Pure Crisp White Body
	draw_colored_polygon(arrow_body, WHITE_CORE)

