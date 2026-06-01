extends Panel

@onready var label: Label = $Label
@onready var continue_btn: Button = $Continue
@onready var go_back_btn: Button = $GoBack
@onready var pass_label: Label = $PassLabel
@onready var retry_btn: Button = $Retry
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	continue_btn.visible = false
	FadeManager.setup(fade_sfx)

func _animate_panel_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - 10, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
func show_results(correct: int, _wrong_items: Array) -> void:
	MusicManager.play_music_by_id("showresults")
	var base_text = "%d" % [correct]

	if correct >= 12:
		label.text = base_text
		pass_label.text = "You passed!"
		continue_btn.visible = true

		# ✅ Complete desk_quiz
		if QuestManager.has_quest("desk_quiz") and not QuestManager.is_quest_completed("desk_quiz"):
			QuestManager.complete_quest("desk_quiz")

		# ✅ Unlock next quest (after_desk_quiz) if defined
		var next_quest = QuestManager.get_quest_template("after_desk_quiz")
		if next_quest and not QuestManager.has_quest("after_desk_quiz"):
			QuestManager.add_quest(next_quest)

	else:
		pass_label.text = "\n12 is the passing score.\nTry again!"
		label.text = base_text
		continue_btn.visible = false

	visible = true
	_animate_panel_in()  

func _on_continue_pressed() -> void:
	visible = false
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_go_back_pressed() -> void:
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
