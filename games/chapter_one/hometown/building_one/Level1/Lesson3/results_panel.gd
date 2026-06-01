extends Panel

@onready var label: Label = $Label
@onready var continue_btn: Button = $Continue
@onready var pass_label: Label = $PassLabel
@onready var go_back_btn: Button = $GoBack
@onready var retry_btn: Button = $Retry
@onready var correction_btn: Button = $Correction
@onready var fade_sfx: ColorRect = %FadeSfx  # 🔊 for fade overlay (add in scene if missing)

func _ready() -> void:
	visible = false
	modulate.a = 0.0  # start fully transparent
	position.y += 80  # slide-up effect start position
	continue_btn.visible = false

	# initialize fade system
	FadeManager.setup(fade_sfx)


# 🪄 Reusable fade-in animation
func _animate_panel_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - 80, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# 🎯 Show the results with fade animation
func show_results(correct: int, _wrong_items: Array) -> void:
	MusicManager.play_music_by_id("showresults")
	var base_text = "%d" % [correct]

	if correct >= 12:
		label.text = base_text
		pass_label.text = "You passed!"
		continue_btn.visible = true

		if QuestManager.has_quest("after_book2") and not QuestManager.is_quest_completed("after_book2"):
			QuestManager.complete_quest("after_book2")

			var next_quest = QuestManager.get_quest_template("desk_quiz")
			if next_quest:
				QuestManager.add_quest(next_quest)

		%QuestPanel.show_latest_quest()
	else:
		pass_label.text = "\n12 is the passing score.\nTry again!"
		label.text = base_text
		continue_btn.visible = false

	visible = true
	_animate_panel_in()  


# --- Button handlers ---
func _on_continue_pressed() -> void:
	visible = false
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_go_back_pressed() -> void:
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_correction_pressed() -> void:
	print("Correction pressed")

	if %MistakesPanel and %MistakesPanel.has_method("show_mistakes"):
		var boxes = get_tree().get_root().get_node("Lesson3/CanvasLayer/MarginContainer/Control/Boxes")

		if boxes and "mistakes" in boxes:
			var wrong_list = boxes.mistakes
			if wrong_list.size() > 0:
				print("Showing", wrong_list.size(), "mistakes from Boxes.")
				%MistakesPanel.show_mistakes(wrong_list)
			else:
				print("No mistakes found to display.")
		else:
			print("Boxes node or 'mistakes' variable not found.")
