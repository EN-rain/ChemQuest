extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = %FadeSfx

# 🧠 This will store the detected current level number
var level_number: int = 0

func _ready() -> void:
	
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Detect which level this is based on scene name
	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_path := current_scene.scene_file_path
		var scene_name := scene_path.get_file().get_basename() # e.g., "level_1"
		var regex := RegEx.new()
		regex.compile(r"\d+")
		var result := regex.search(scene_name)
		if result:
			level_number = int(result.get_string())
			print("📘 Detected Level:", level_number)
		else:
			level_number = 0

	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0) # Start transparent


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	print("Player reached the gate ✅ Level:", level_number)
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)


func _on_flag_animation_finished() -> void:
	if fade_rect:
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
		tween.finished.connect(_load_next_level, CONNECT_ONE_SHOT)
	else:
		_load_next_level()


func _load_next_level() -> void:
	var current_scene := get_tree().current_scene
	var current_name := current_scene.name
	var next_scene_path := ""
	var level_number := 0  # <-- new variable to store level as integer

	if current_name == "level_1":
		level_number = 1
		next_scene_path = "res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/Scenes/level_2.tscn"
	elif current_name == "level_2":
		level_number = 2
		next_scene_path = "res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/level2-2/mattermaze/Scenes/level_3.tscn"
	elif current_name == "level_3":
		level_number = 3
		# optional: return to hometown or reward scene after level 3
		next_scene_path = "res://games/chapter_one/hometown/building_two/building_two.tscn"

	if next_scene_path == "":
		print("⚠ No valid next level for:", current_name)
		return

	# ✅ Advance quest progress safely
	if QuestManager:
		QuestManager.advance_states_level(level_number)

	print("➡ Loading next scene:", next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)
