extends Node2D

@onready var area: Area2D = $Area2D
@onready var checker_label: Label = %CheckerPanel/Label
@onready var confirm_button: Button = %ConfirmButton
@onready var pass_panel = %Pass
@onready var score_label: Label = %ScorePanel/Label
@onready var spawner = %Spawner/Node2D
@onready var marker: Marker2D = %Marker2D
@onready var game_timer = %GameTimer

var atom_counts: Dictionary = {}
var score: int = 0
var current_round: int = 1
const MAX_ROUNDS := 15

var elements_order: Array = []
var placed_atoms: Array = [] #


func _ready() -> void:
	var file = FileAccess.open("res://games/global/elements_order.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY and data.has("elements_order"):
			elements_order = data["elements_order"]

	# Connect signals
	area.area_entered.connect(_on_area_2d_area_entered)
	area.area_exited.connect(_on_area_2d_area_exited)

	_update_checker_label()
	if game_timer:
		game_timer.time_up.connect(_on_time_up)
	
func _on_time_up() -> void:
	# Show feedback
	var target = pass_panel.get_current_compound()
	var compound_name = target.get("name", "Unknown")
	checker_label.text = "Time’s up! The correct compound was %s" % compound_name
	confirm_button.disabled = true
	await get_tree().create_timer(1.0).timeout
	_delayed_next_round()

# ------------------- AUTO ARRANGE -------------------
func _on_area_2d_area_entered(other_area: Area2D) -> void:
	if other_area is Atom:
		var lbl: Label = other_area.get_node_or_null("Label")
		if not lbl: return
		var sym: String = lbl.text

		# Add to placed list
		placed_atoms.append({"sym": sym, "node": other_area})

		# Auto arrange them
		_auto_arrange_atoms()

		# Count this atom
		atom_counts[sym] = atom_counts.get(sym, 0) + 1
		_update_checker_label()


func _on_area_2d_area_exited(other_area: Area2D) -> void:
	if other_area is Atom:
		var lbl: Label = other_area.get_node_or_null("Label")
		if lbl:
			var sym: String = lbl.text
			if atom_counts.has(sym):
				atom_counts[sym] -= 1
				if atom_counts[sym] <= 0:
					atom_counts.erase(sym)
				_update_checker_label()

	# Remove from placed_atoms
	placed_atoms = placed_atoms.filter(func(p): return p["node"].is_inside_tree() and area.get_overlapping_areas().has(p["node"]))
	_auto_arrange_atoms()

# ------------------- ARRANGE LOGIC -------------------
func _auto_arrange_atoms() -> void:
	if elements_order.is_empty(): return
	if placed_atoms.is_empty(): return

	# Sort placed_atoms by order in JSON
	placed_atoms.sort_custom(func(a, b):
		return elements_order.find(a["sym"]) < elements_order.find(b["sym"])
	)

	# Now reposition them like cards
	for i in range(placed_atoms.size()):
		var atom = placed_atoms[i]["node"]
		var target_pos = marker.global_position
		target_pos.x += i * 10 # shift right per index

		var tween = get_tree().create_tween()
		tween.tween_property(
			atom, "global_position", target_pos, 0.3
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# Layering: smaller index = higher z_index (covers others)
		atom.z_index = placed_atoms.size() - i


# ------------------- UI / GAME -------------------
func _update_checker_label() -> void:
	if checker_label == null:
		return
	
	if atom_counts.is_empty():
		checker_label.text = ""
		if confirm_button:
			confirm_button.visible = false
		return

	#  Sort keys according to elements_order.json
	var keys := atom_counts.keys()
	keys.sort_custom(func(a, b):
		return elements_order.find(a) < elements_order.find(b)
	)

	var parts: Array[String] = []
	for sym in keys:
		var count: int = atom_counts[sym]
		var part: String = sym + (str(count) if count > 1 else "")
		parts.append(part)

	checker_label.text = " + ".join(parts)

	if confirm_button:
		confirm_button.visible = true

		confirm_button.visible = true

func _update_score_label() -> void:
	if score_label:
		score_label.text = "%d\n%d/%d" % [score, current_round, MAX_ROUNDS]

# --- Helper: enable/disable all atom input & dragging ---
func _set_atoms_interaction(enabled: bool) -> void:
	for atom in get_tree().get_nodes_in_group("atoms"):
		if not atom:
			continue

		# Use the atom's internal method if it exists (your Atom.gd supports this)
		if atom.has_method("set_drag_enabled"):
			atom.set_drag_enabled(enabled)

		# Prevent touch/mouse input but keep overlap detection active
		if atom is Area2D:
			atom.input_pickable = enabled

		# For Control-based atoms (rare, but safe):
		if atom is Control:
			atom.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE


func _on_confirm_button_pressed() -> void:
	# 🔒 Disable atom dragging and confirm button immediately
	_set_atoms_interaction(false)
	confirm_button.disabled = true
	confirm_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if %GameTimer:
		%GameTimer.stop_timer()

	var target_compound: Dictionary = {}
	if pass_panel and pass_panel.has_method("get_current_compound"):
		target_compound = pass_panel.get_current_compound()
	if target_compound.is_empty() or not target_compound.has("components"):
		return

	var target_counts: Dictionary = {}
	for comp in target_compound["components"]:
		var sym: String = comp.get("symbol", "")
		var count: int = int(comp.get("count", 1))
		target_counts[sym] = count

	var correct := _compare_counts(atom_counts, target_counts)

	# 🎵 Pause BG
	MusicManager.pause_music()

	# Choose sound
	var sfx_id := "correct" if correct else "wrong"
	var sfx := AudioStreamPlayer.new()
	sfx.stream = MusicManager.music_library[sfx_id]
	sfx.bus = "SFX"
	add_child(sfx)
	sfx.play()

	# 🧩 Feedback text
	if correct:
		score += 1
		checker_label.text = "Correct!"
	else:
		var parts: Array[String] = []
		for comp in target_compound["components"]:
			var sym: String = comp.get("symbol", "")
			var count: int = int(comp.get("count", 1))
			parts.append(sym + (str(count) if count > 1 else ""))
		var correct_formula := "".join(parts)
		checker_label.text = "Wrong! Correct Element: %s" % correct_formula

	# 🕒 Wait a fixed amount of time (same for all sounds)
	await get_tree().create_timer(1.0).timeout

	sfx.stop()
	sfx.queue_free()

	# 🔊 Resume background
	MusicManager.resume_music()

	current_round += 1
	if current_round > MAX_ROUNDS:
		_end_game()
		return

	_delayed_next_round()



# --- Clear all atoms from the scene ---
func _clear_all_atoms(update_label: bool = true):
	for atom in get_tree().get_nodes_in_group("atoms"):
		if atom:
			atom.queue_free()
	atom_counts.clear()
	placed_atoms.clear()
	if update_label:
		_update_checker_label()

func _delayed_next_round() -> void:
	_clear_all_atoms()

	if pass_panel and pass_panel.has_method("next_compound"):
		pass_panel.next_compound()

	if spawner and spawner.has_method("_spawn_from_pass"):
		await spawner._spawn_from_pass()

	# ✅ Re-enable atom input & confirm button
	_set_atoms_interaction(true)
	confirm_button.disabled = false
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP

	_update_score_label()

	# Reset timer
	if %GameTimer:
		%GameTimer.reset_timer()


func _compare_counts(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in b.keys():
		if not a.has(key): return false
		if int(a[key]) != int(b[key]): return false
	return true
	
func _end_game() -> void:
	if %ResultsPanel:
		%ResultsPanel.show_results(score, [])

	if %GameTimer:
		%GameTimer.stop_timer()

	for atom in get_tree().get_nodes_in_group("atoms"):
		if atom.has_method("set_drag_enabled"):
			atom.set_drag_enabled(false)
		atom.visible = false

	# 🧩 Lesson 1 counter
	LessonManager.increment_run_and_check_reset()

func _recount_atoms_from_area():
	atom_counts.clear()
	placed_atoms.clear()
	var overlapping := area.get_overlapping_areas()
	for a in overlapping:
		if a is Atom:
			var lbl: Label = a.get_node_or_null("Label")
			if lbl:
				var sym: String = lbl.text
				atom_counts[sym] = atom_counts.get(sym, 0) + 1
				placed_atoms.append({"sym": sym, "node": a})
	_update_checker_label()
	_auto_arrange_atoms()

func reset_game():
	score = 0
	current_round = 1
	_update_score_label()
	_clear_all_atoms()
	if pass_panel and pass_panel.has_method("next_compound"):
		pass_panel.next_compound()
	if spawner and spawner.has_method("spawn_round_atoms"):
		spawner.spawn_round_atoms()
