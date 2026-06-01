extends Panel

@onready var label: Label = $Label
@onready var pass_label: Label = $PassLabel
@onready var continue_btn: Button = $Continue
@onready var go_back_btn: Button = $GoBack
@onready var retry_btn: Button = $Retry
@onready var correction_btn: Button = $Correction
@onready var back_panel: Panel = %BackPanel
@onready var fade_sfx: ColorRect = %FadeSfx

func _ready() -> void:
	visible = false
	modulate.a = 0.0  # start fully transparent
	position.y += 80  # start slightly below (so it slides up)
	continue_btn.visible = false
	FadeManager.setup(fade_sfx)

# Called when the game ends
func show_results(correct: int, _wrong_items: Array) -> void:
	MusicManager.play_music_by_id("showresults")
	var base_text = "%d" % [correct]

	if correct >= 12: # Passing score
		label.text = base_text
		pass_label.text = "You passed!"
		continue_btn.visible = true

		#  Quest progression
		if QuestManager.has_quest("finish_book1") and not QuestManager.is_quest_completed("finish_book1"):
			QuestManager.complete_quest("finish_book1")

			var next_quest = QuestManager.get_quest_template("after_book1")
			if next_quest:
				QuestManager.add_quest(next_quest)
	else:
		pass_label.text = "\n12 is the passing score.\nTry again!"
		label.text = base_text
		continue_btn.visible = false

	visible = true
	_animate_panel_in()
func end_run_check_reset() -> void:
	LessonManager.increment_run_and_check_reset()

func _animate_panel_in() -> void:
	# Tween fade-in + slide-up
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - 80, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Button handlers ---
func _on_continue_pressed() -> void:
	visible = false
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_go_back_pressed() -> void:
	back_panel.show()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()

func _on_correction_pressed() -> void:
	await FadeManager.fade_and_change("res://games/glossary/main.tscn")
