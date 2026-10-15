extends Node

## Reproduces first Wiz Skip -> Book I interaction prompt. In particular,
## finishing the conversation must recheck a puzzle Area2D the player is
## already overlapping, and leaving Wiz must not hide another area's prompt.
var _failures: Array[String] = []


func _ready() -> void:
	var tree := get_tree()
	QuestManager.reset_for_new_game()
	var building: Node2D = load("res://games/chapter_one/hometown/building_one/building_one.tscn").instantiate()
	add_child(building)
	await tree.physics_frame
	await tree.physics_frame
	var wiz: Node2D = building.get_node("World/NPC/Wiz")
	var book: Area2D = building.get_node("World/Furnitures/LevelOne")
	var player: CharacterBody2D = building.get_node("Player")
	var dialogue: Panel = building.get_node("CanvasLayer/DialogueBox")
	var interact_icon: TouchScreenButton = building.get_node("CanvasLayer/Control/interact")

	# Enter Book I's Area2D before Wiz is complete, while the gate is locked.
	player.global_position = book.global_position + Vector2(0, -50)
	await tree.physics_frame
	await tree.physics_frame
	book._on_body_entered(player)
	_expect("Book I is initially locked", not QuestManager.is_quest_completed("find_wiz") and not interact_icon.visible)

	# When first Wiz dialogue is skipped, Book I must become interactable even
	# if the player hasn't left/reentered its Area2D.
	wiz.interact()
	_expect("Wiz dialogue starts", dialogue.visible)
	dialogue._on_skip_pressed()
	await tree.physics_frame
	await tree.process_frame
	_expect("Skip completes first Wiz quest", QuestManager.is_quest_completed("find_wiz") and QuestManager.has_quest("read_books"))
	_expect("Book I shows interaction after Skip", interact_icon.visible and InteractionManager.current_interactable == book)

	# Wiz's delayed exit event cannot hide the icon owned by Book I.
	wiz._on_area_2d_body_exited(player)
	_expect("Wiz exit does not hide Book I", interact_icon.visible and InteractionManager.current_interactable == book)
	if _failures.is_empty():
		print("FIRST_WIZ_SKIP_INTERACT PASS")
		tree.quit(0)
	else:
		for failure in _failures:
			print("FIRST_WIZ_SKIP_INTERACT FAIL ", failure)
		tree.quit(2)


func _expect(label: String, condition: bool) -> void:
	if not condition:
		_failures.append(label)
