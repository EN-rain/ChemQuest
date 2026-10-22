extends Node

func _ready() -> void:
	var tex = load("res://games/review/assets/states_level_one.png")
	print("STATES_TEX: ", tex)
	
	if has_node("/root/QuestManager"):
		QuestManager.active_quests["finish_book1"] = {"is_completed": true}
		QuestManager.active_quests["finish_book2"] = {"is_completed": true}
		QuestManager.active_quests["desk_quiz"] = {"is_completed": true}
		QuestManager.active_quests["finish_book3"] = {"is_completed": true}
		QuestManager.active_quests["separation_methods"] = {"is_completed": true}
		QuestManager.active_quests["accuracy_vs_precision"] = {"is_completed": true}
		QuestManager.active_quests["density_measurement"] = {"is_completed": true}
		QuestManager.active_quests["states_of_matter"] = {"is_completed": true}
	
	var packed := load("res://games/review/review.tscn") as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	
	for i in range(25):
		await get_tree().process_frame
	
	var vp := get_viewport()
	var img := vp.get_texture().get_image()
	if img != null and not img.is_empty():
		var img_path := "C:/Users/LENOVO/.gemini/antigravity-ide/brain/09c4ab9d-f57d-4709-aa18-2cf8215b6c20/scratch/review_all_unlocked2.png"
		img.save_png(img_path)
		print("SCREENSHOT_SAVED: " + img_path)
	
	get_tree().quit(0)
