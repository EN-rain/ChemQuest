extends CollisionPolygon2D


func make_ring(inner_r: float, outer_r: float, edges: int = 32) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in range(edges):
		var angle = TAU * float(i) / float(edges)
		pts.append(Vector2(cos(angle), sin(angle)) * outer_r)
	for i in range(edges - 1, -1, -1):
		var angle = TAU * float(i) / float(edges)
		pts.append(Vector2(cos(angle), sin(angle)) * inner_r)
	return pts
