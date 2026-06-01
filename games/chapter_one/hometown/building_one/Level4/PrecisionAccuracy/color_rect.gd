extends ColorRect   # use ColorRect directly instead of TextureRect

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.RED
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999

	add_theme_stylebox_override("panel", style)
