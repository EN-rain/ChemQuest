extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_rect: ColorRect = get_node_or_null("%FadeSfx") as ColorRect

# 🧠 This will store the detected current level number
var level_number: int = 0
var _gate_triggered := false
var _transition_started := false

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
	if _gate_triggered or _transition_started or body.name != "Player":
		return
	_gate_triggered = true

	print("Player reached the gate ✅ Level:", level_number)
	animated_sprite.play("finish")
	animated_sprite.animation_finished.connect(_on_flag_animation_finished, CONNECT_ONE_SHOT)


func _on_flag_animation_finished() -> void:
	_load_next_level()


func _load_next_level() -> void:
	if _transition_started:
		return
	var current_scene := get_tree().current_scene
	var current_name := current_scene.name
	var next_scene_path := ""
	var completed_level_number := 0

	if current_name == "level_1":
		completed_level_number = 1
		next_scene_path = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_2.tscn"
	elif current_name == "level_2":
		completed_level_number = 2
		next_scene_path = "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/level_3.tscn"
	elif current_name == "level_3":
		completed_level_number = 3
		# optional: return to hometown or reward scene after level 3
		next_scene_path = "res://games/chapter_one/hometown/building_two/building_two.tscn"

	if next_scene_path == "":
		print("⚠ No valid next level for:", current_name)
		return

	# ✅ Advance quest progress safely
	if QuestManager:
		QuestManager.advance_states_level(completed_level_number)

	print("➡ Loading next scene:", next_scene_path)
	_transition_started = true
	await FadeManager.fade_and_change(next_scene_path)
