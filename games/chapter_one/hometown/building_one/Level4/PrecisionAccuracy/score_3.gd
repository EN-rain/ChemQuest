extends Area2D

@export var outer_radius: float = 39.0
@export var inner_radius: float = 26.0
@export var segments: int = 55   # renamed

func _ready() -> void:
	add_to_group("target_rings")
	var poly := CollisionPolygon2D.new()
	poly.polygon = make_ring(outer_radius, inner_radius, segments)
	add_child(poly)

func make_ring(outer_r: float, inner_r: float, segs: int) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in range(segs):
		var angle: float = TAU * i / segs
		pts.append(Vector2(cos(angle), sin(angle)) * outer_r)
	pts.append(Vector2(cos(0), sin(0)) * outer_r)
	for i in range(segs, -1, -1):
		var angle: float = TAU * i / segs
		pts.append(Vector2(cos(angle), sin(angle)) * inner_r)
	pts.append(Vector2(cos(0), sin(0)) * inner_r)
	return pts
