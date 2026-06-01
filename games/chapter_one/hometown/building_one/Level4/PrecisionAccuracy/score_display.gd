extends Control

# UI references
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var results_panel: Control = %ResultsPanel
@onready var results_vbox: HBoxContainer = results_panel.get_node("HBoxContainer")
@onready var score_label: Label = %ScoreLabel
@onready var round_label: Label = %RoundLabel
@onready var continue_button: Button = %Continue

# State
var score: int = 0
var hit_index: int = 0
var max_hits: int = 5
var results_shown: bool = false
var max_score: int = 5 # points needed to complete a run
var current_round: int = 1 # visible round counter

func _ready():
	for child in vbox.get_children():
		child.visible = false

	#  Restore score and round state
	score = Scoring.precision_accuracy_score if Scoring.precision_accuracy_score > 0 else 0

	# If a round number exists in Scoring, load it; otherwise start at 1
	if Scoring.has_meta("current_round"):
		current_round = Scoring.get_meta("current_round")
	else:
		current_round = 1
		Scoring.set_meta("current_round", current_round)

	_update_labels()


func update_hit_display(target: Node2D, hit_pos: Vector2, hit_score: int):
	hit_index += 1
	var ui_name = "HitTarget" + str(hit_index)
	var ui_entry: Node = vbox.get_node_or_null(ui_name)
	if not ui_entry:
		return
	ui_entry.visible = true

	var hit_mark: Sprite2D = ui_entry.get_node("HitMark")
	var ui_target_img: Sprite2D = ui_entry.get_node("TargetImg")
	var label: Label = ui_entry.get_node("Label")

	var offset: Vector2 = hit_pos - target.global_position
	var signed_offset_x: float = offset.x

	var world_radius := 128.0
	var normalized := offset / world_radius
	var ui_size := ui_target_img.texture.get_size() * ui_target_img.scale
	var ui_radius := ui_size.x
	var ui_hit_pos := normalized * ui_radius

	hit_mark.position = ui_target_img.position + ui_hit_pos
	hit_mark.scale = Vector2(0.2, 0.2)
	hit_mark.visible = true

	label.text = str(abs(hit_score))

	ui_entry.set_meta("signed_x", signed_offset_x)
	ui_entry.set_meta("raw_score", hit_score)

	_copy_to_results(ui_name, ui_hit_pos, hit_score, signed_offset_x)

	if hit_index >= max_hits and not results_shown:
		show_results()


func on_guess(player_guess: String, correct_answer: String):
	if not results_shown:
		show_results()

	if player_guess == correct_answer:
		score += 1

	_update_labels()
	Scoring.precision_accuracy_score = score
	_handle_post_guess()


func _copy_to_results(ui_name: String, ui_hit_pos: Vector2, hit_score: int, signed_offset_x: float):
	var result_entry: Node = results_vbox.get_node_or_null(ui_name)
	if not result_entry:
		return
	result_entry.visible = true

	var r_hit_mark: Sprite2D = result_entry.get_node("HitMark")
	var r_label: Label = result_entry.get_node("Label")
	var r_target_img: Sprite2D = result_entry.get_node("TargetImg")

	if r_hit_mark and r_target_img:
		r_hit_mark.position = r_target_img.position + ui_hit_pos
		r_hit_mark.visible = true
	if r_label:
		r_label.text = str(abs(hit_score))

	result_entry.set_meta("signed_x", signed_offset_x)
	result_entry.set_meta("raw_score", hit_score)


func show_results():
	results_shown = true
	self.visible = false
	results_panel.visible = true


func _handle_post_guess():
	if score >= max_score:
		# Show results and stop automatic restart
		results_shown = true
		results_panel.visible = true
		self.visible = false

		# Update Scoring state
		Scoring.precision_accuracy_score = score
		Scoring.set_meta("current_round", current_round)

		# Let ResultsPanel handle Continue button visibility
		if results_panel.has_method("show_results"):
			results_panel.show_results(score, max_score)

	else:
		# Retry same round if not full score
		var t = get_tree().create_timer(2.0)
		t.timeout.connect(_restart_game)

func _increment_round():
	current_round += 1
	Scoring.set_meta("current_round", current_round)


func _restart_game():
	#  If we're restarting after finishing targets, increase round
	if hit_index >= max_hits or score >= max_score:
		_increment_round()

	print("♻️ Restarting scene — Round:", current_round)
	get_tree().reload_current_scene()


func _update_labels():
	score_label.text = "Score: %d / %d" % [score, max_score]
	round_label.text = "Round: %d" % current_round
