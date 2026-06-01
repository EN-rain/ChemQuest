extends ScrollContainer

@export var snap_speed: float = 8.0
@export var fade_time: float = 0.3

@onready var texture_bg: TextureRect = %TextureBg
@onready var marker: Control = %Marker
@onready var playing_label: Label = %Playing
@onready var title_label: Label = %TitleLabel
@onready var vbox: VBoxContainer = $VBoxContainer

var target_scroll: float = 0.0
var snapping: bool = false
var released: bool = false
var fade_rect: ColorRect
var current_display_name: String = ""


func _ready() -> void:
	target_scroll = float(scroll_vertical)

	# 🔹 Create a black overlay behind the background (for clean fades)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchor_left = 0.0
	fade_rect.anchor_top = 0.0
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.modulate.a = 0.0
	texture_bg.get_parent().add_child(fade_rect)
	fade_rect.z_index = texture_bg.z_index + 1

	var buttons := vbox.get_children()
	if buttons.size() >= 3:
		(buttons[0] as Button).set_meta("display_name", "Hometown")
		(buttons[1] as Button).set_meta("display_name", "University")
		(buttons[2] as Button).set_meta("display_name", "Laboratory")


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			snapping = false
		else:
			released = true


func _process(delta: float) -> void:
	if released:
		released = false
		_snap_to_nearest()

	if snapping:
		scroll_vertical = int(lerp(float(scroll_vertical), target_scroll, snap_speed * delta))
		if abs(float(scroll_vertical) - target_scroll) < 1.0:
			scroll_vertical = int(target_scroll)
			snapping = false

func _snap_to_nearest() -> void:
	if vbox == null or vbox.get_child_count() == 0:
		return

	var closest: Button = null
	var closest_dist: float = INF
	var marker_y: float = marker.global_position.y + marker.size.y * 0.5

	for child in vbox.get_children():
		var btn := child as Button
		if btn:
			var btn_center_y: float = btn.global_position.y + btn.size.y * 0.5
			var dist: float = abs(btn_center_y - marker_y)
			if dist < closest_dist:
				closest = btn
				closest_dist = dist

	if closest:
		var btn_center_y: float = closest.global_position.y + closest.size.y * 0.5
		var offset: float = btn_center_y - marker_y
		target_scroll = clamp(float(scroll_vertical) + offset, 0.0, float(get_v_scroll_bar().max_value))
		snapping = true

		var display_name := str(closest.get_meta("display_name")) if closest.has_meta("display_name") else closest.text

		#  Only update if the section actually changed
		if display_name != current_display_name:
			current_display_name = display_name

			match display_name:
				"Hometown":
					title_label.text = "Hometown"
					playing_label.text = "Playing"
					_change_bg_texture(preload("res://assets/mainbg.png"))
				"University":
					title_label.text = "University"
					playing_label.text = "Available Soon"
					_change_bg_texture(preload("res://assets/unix.png"))
				"Laboratory":
					title_label.text = "Laboratory"
					playing_label.text = "Available Soon"
					_change_bg_texture(preload("res://assets/chemlabx.png"))

# 🔹 Fade to black, change texture, fade back in
func _change_bg_texture(new_texture: Texture2D) -> void:
	if texture_bg.texture == new_texture:
		return

	var tween := get_tree().create_tween()

	# Fade to black
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Change texture when black
	tween.tween_callback(func ():
		texture_bg.texture = new_texture)

	# Fade back to visible
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
