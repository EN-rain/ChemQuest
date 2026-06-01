extends Panel

@onready var label: Label = $Label
@onready var continue_btn: Button = $Continue
@onready var go_back_btn: Button = $GoBack
@onready var retry_btn: Button = $Retry
@onready var fade_sfx: ColorRect = %FadeSfx
@onready var pass_label: Label = $PassLabel
func _ready() -> void:
	visible = false
	modulate.a = 0.0  # start fully transparent
	position.y += 80  # start slightly below (so it slides up)
	continue_btn.visible = false  # hidden by default
	FadeManager.setup(fade_sfx)
	
func _animate_panel_in() -> void:
	# Tween fade-in + slide-up
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - 80, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func show_results(score: int, passed: bool) -> void:
	MusicManager.play_music_by_id("showresults")
	visible = true
	label.text = "%d" % score

	if passed:
		pass_label.text = "You passed!"
		continue_btn.visible = true

		# ✅ Complete "separation_methods" quest if active
		if QuestManager.has_quest("separation_methods") and not QuestManager.is_quest_completed("separation_methods"):
			QuestManager.complete_quest("separation_methods")

		# ✅ Add "separation_methods_after" quest (from quest.json template)
		if not QuestManager.has_quest("separation_methods_after"):
			var next_quest = QuestManager.get_quest_template("separation_methods_after")
			if next_quest:
				QuestManager.add_quest(next_quest)
	else:
		pass_label.text = "\n12 is the passing score.\nTry again!"
		continue_btn.visible = false
		
	visible = true
	_animate_panel_in()
	
func _on_continue_pressed() -> void:
	print("👉 Setting spawn to separation_spawn in results panel before returning.")
	SpawnManager.set_spawn("separation_spawn")
	await FadeManager.fade_and_change("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_go_back_pressed() -> void:
	# Go back without marking as passed
	SpawnManager.set_spawn("separation_spawn")
	get_tree().change_scene_to_file("res://games/chapter_one/hometown/building_one/building_one.tscn")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
