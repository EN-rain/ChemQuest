extends TextureRect

@export var circle_color: Color = Color.RED

func _ready() -> void:
	var color_rect: ColorRect = $ColorRect
	if color_rect:
		# Make sure it's a square so corner radius = circle
		var size = min(color_rect.size.x, color_rect.size.y)
		color_rect.custom_minimum_size = Vector2(size, size)

		# Apply stylebox
		var style := StyleBoxFlat.new()
		style.bg_color = circle_color
		style.corner_radius_top_left = size / 2
		style.corner_radius_top_right = size / 2
		style.corner_radius_bottom_left = size / 2
		style.corner_radius_bottom_right = size / 2

		color_rect.add_theme_stylebox_override("panel", style)
