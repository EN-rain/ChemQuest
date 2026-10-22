extends Node

## ReviewManager coordinates the Puzzle Review mode.
## Tracks return destination, spawn marker, and exact player position so
## returning from Review resumes the exact game state.

var is_in_review: bool = false
var return_scene_path: String = ""
var return_spawn_point: String = ""
var return_player_position: Vector2 = Vector2.ZERO

const REVIEW_SCENE_PATH := "res://games/review/review.tscn"

const PUZZLE_DEFINITIONS := [
	{
		"id": "book1",
		"name": "Book I: Elements",
		"category": "Building 1 • Lesson 1",
		"scene": "res://games/chapter_one/hometown/building_one/Level1/Lesson1/lesson_one.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/III (1).png",
		"hint": "Complete Book I with the Wizard in Building One"
	},
	{
		"id": "book2",
		"name": "Book II: Compounds",
		"category": "Building 1 • Lesson 2",
		"scene": "res://games/chapter_one/hometown/building_one/Level1/Lesson2/lesson_two.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/III.png",
		"hint": "Complete Book II with the Wizard in Building One"
	},
	{
		"id": "desk_quiz",
		"name": "Properties of Matter",
		"category": "Building 1 • Desk Quiz",
		"scene": "res://games/chapter_one/hometown/building_one/Level2/Level2.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/image 7.png",
		"hint": "Pass the Desk Quiz at the study desk in Building One"
	},
	{
		"id": "book3",
		"name": "Book III: Mixtures",
		"category": "Building 1 • Lesson 3",
		"scene": "res://games/chapter_one/hometown/building_one/Level1/Lesson3/Lesson3.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/III (3).png",
		"hint": "Complete Book III with the Wizard in Building One"
	},
	{
		"id": "separation",
		"name": "Separation Methods",
		"category": "Building 1 • Level 3",
		"scene": "res://games/chapter_one/hometown/building_one/Level3/level_3.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/lvl3guide.png",
		"hint": "Complete Separation Methods in Building One"
	},
	{
		"id": "accuracy",
		"name": "Accuracy vs Precision",
		"category": "Building 1 • Level 4",
		"scene": "res://games/chapter_one/hometown/building_one/Level4/PrecisionAccuracy/precision_accuracy.tscn",
		"preview": "res://games/chapter_one/hometown/building_one/imgs/Precisionguide.png",
		"hint": "Pass Accuracy vs Precision at the target range in Building One"
	},
	{
		"id": "density",
		"name": "Density Measurement",
		"category": "Building 2 • Arcade",
		"scene": "res://games/chapter_one/hometown/building_two/Level2-1/Level2-1/Scenes/level 1/level_1.tscn",
		"preview": "res://games/chapter_one/hometown/building_two/imgs/game.png",
		"hint": "Pass Density Measurement in Building Two"
	},
	{
		"id": "states",
		"name": "States of Matter",
		"category": "Building 2 • Matter Maze",
		"scene": "res://games/chapter_one/hometown/building_two/level2-2/mattermaze/Scenes/main.tscn",
		"preview": "res://games/chapter_one/hometown/building_two/imgs/b2.png",
		"hint": "Complete the Matter Maze in Building Two"
	}
]


func start_review() -> void:
	# Capture current state before opening review scene
	var cur_scene := get_tree().current_scene
	if cur_scene != null and not cur_scene.scene_file_path.is_empty():
		return_scene_path = cur_scene.scene_file_path
		var player := cur_scene.find_child("Player", true, false) as Node2D
		if player == null:
			player = cur_scene.find_child("player", true, false) as Node2D
		if player != null:
			return_player_position = player.global_position
			print("📸 [ReviewManager] Captured player position: ", return_player_position)
		else:
			return_player_position = Vector2.ZERO
	else:
		return_scene_path = SaveManager.current_scene_path if has_node("/root/SaveManager") else ""
		return_player_position = Vector2.ZERO

	if has_node("/root/SaveManager") and not SaveManager.last_spawn.is_empty():
		return_spawn_point = SaveManager.last_spawn
	elif has_node("/root/SpawnManager") and not SpawnManager.get_spawn().is_empty():
		return_spawn_point = SpawnManager.get_spawn()
	else:
		return_spawn_point = "default"

	print("📚 [ReviewManager] start_review -> return_scene: ", return_scene_path, " spawn: ", return_spawn_point)
	is_in_review = false

	if has_node("/root/FadeManager"):
		await FadeManager.fade_and_change(REVIEW_SCENE_PATH)
	else:
		get_tree().change_scene_to_file(REVIEW_SCENE_PATH)


func launch_puzzle(puzzle_scene: String) -> void:
	print("🚀 [ReviewManager] Launching puzzle in review mode: ", puzzle_scene)
	is_in_review = true
	if has_node("/root/FadeManager"):
		await FadeManager.fade_and_change(puzzle_scene)
	else:
		get_tree().change_scene_to_file(puzzle_scene)


func exit_review_to_game() -> void:
	print("🏠 [ReviewManager] Exiting review back to game: ", return_scene_path, " spawn: ", return_spawn_point, " pos: ", return_player_position)
	var scene_to_load := return_scene_path
	if scene_to_load.is_empty() or not ResourceLoader.exists(scene_to_load, "PackedScene"):
		if has_node("/root/SaveManager") and not SaveManager.current_scene_path.is_empty():
			scene_to_load = SaveManager.current_scene_path
		else:
			scene_to_load = "res://games/chapter_one/hometown/hometown.tscn"

	if has_node("/root/SpawnManager") and not return_spawn_point.is_empty():
		SpawnManager.set_spawn(return_spawn_point)

	var pos_to_restore := return_player_position
	is_in_review = false

	if has_node("/root/FadeManager"):
		await FadeManager.fade_and_change(scene_to_load)
	else:
		get_tree().change_scene_to_file(scene_to_load)
		await get_tree().process_frame

	if pos_to_restore != Vector2.ZERO:
		_apply_restored_player_position(pos_to_restore)
		call_deferred("_apply_restored_player_position", pos_to_restore)


func _apply_restored_player_position(pos: Vector2) -> void:
	var cur := get_tree().current_scene
	if cur == null:
		return
	var player := cur.find_child("Player", true, false) as Node2D
	if player == null:
		player = cur.find_child("player", true, false) as Node2D
	if player != null:
		player.global_position = pos
		print("🎯 [ReviewManager] Restored exact player position: ", pos)


func is_puzzle_unlocked(puzzle_id: String) -> bool:
	if not has_node("/root/QuestManager"):
		return false

	match puzzle_id:
		"book1":
			return QuestManager.is_quest_completed("finish_book1") \
				or QuestManager.is_quest_completed("after_book1") \
				or (has_node("/root/LessonManager") and LessonManager.is_lesson_completed(1))
		"book2":
			return QuestManager.is_quest_completed("finish_book2") \
				or QuestManager.is_quest_completed("after_book2") \
				or (has_node("/root/LessonManager") and LessonManager.is_lesson_completed(2))
		"desk_quiz":
			return QuestManager.is_quest_completed("desk_quiz") \
				or QuestManager.is_quest_completed("after_desk_quiz")
		"book3":
			return QuestManager.is_quest_completed("finish_book3") \
				or QuestManager.is_quest_completed("after_book3") \
				or (has_node("/root/LessonManager") and LessonManager.is_lesson_completed(3))
		"separation":
			return QuestManager.is_quest_completed("separation_methods") \
				or QuestManager.is_quest_completed("separation_methods_after") \
				or (has_node("/root/Level3Manager") and Level3Manager.is_completed)
		"accuracy":
			return QuestManager.is_quest_completed("accuracy_vs_precision") \
				or QuestManager.is_quest_completed("after_accuracy_vs_precision")
		"density":
			return QuestManager.is_quest_completed("density_measurement") \
				or QuestManager.is_quest_completed("after_density_measurement") \
				or QuestManager.density_progress > 0 \
				or QuestManager.density_completed_levels.size() > 0
		"states":
			var states_levels: Array = []
			if QuestManager.has_method("get_states_completed_levels"):
				states_levels = QuestManager.get_states_completed_levels()
			elif "completed_levels" in QuestManager:
				states_levels = QuestManager.completed_levels
			return QuestManager.is_quest_completed("states_of_matter") \
				or QuestManager.is_quest_completed("after_states") \
				or QuestManager.states_progress > 0 \
				or states_levels.size() > 0
		_:
			return false
