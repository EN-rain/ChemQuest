extends Control

const MAIN_SCENE := "res://games/main.tscn"

@onready var back_button: Button = $BackButton
@onready var disable_button: Button = $DisableButton
@onready var reset_button: Button = $ResetButton
@onready var unlock_all_button: Button = $UnlockAllButton
@onready var reset_pass_rates_button: Button = $ResetPassRatesButton
@onready var global_pass_spin: SpinBox = $GlobalPassContainer/GlobalPassSpin
@onready var apply_global_pass_button: Button = $GlobalPassContainer/ApplyGlobalPassButton
@onready var global_count_spin: SpinBox = $GlobalCountContainer/GlobalCountSpin
@onready var apply_global_count_button: Button = $GlobalCountContainer/ApplyGlobalCountButton
@onready var puzzle_list: VBoxContainer = $PuzzleScroll/PuzzleList
@onready var status_label: Label = $StatusLabel
@onready var reset_confirmation: ConfirmationDialog = $ResetConfirmation
@onready var lock_confirmation: ConfirmationDialog = $LockConfirmation
@onready var _dev_manager: Node = get_node_or_null("/root/DevModeManager")

var _checkboxes: Array[CheckBox] = []
var _count_spinboxes: Dictionary = {}
var _pass_spinboxes: Dictionary = {}
var _pass_labels: Dictionary = {}
var _goal_options: Dictionary = {}
var _pending_lock_index := -1


func _ready() -> void:
	# Both the scene and the progression service check the activation flag.
	# Opening devmode.tscn directly without the five clicks grants nothing.
	if _dev_manager == null or not bool(_dev_manager.get("enabled")):
		call_deferred("_return_to_main")
		return
	back_button.pressed.connect(_on_back_pressed)
	disable_button.pressed.connect(_on_disable_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	unlock_all_button.pressed.connect(_on_unlock_all_pressed)
	reset_pass_rates_button.pressed.connect(_on_reset_pass_rates_pressed)
	apply_global_pass_button.pressed.connect(_on_apply_global_pass_pressed)
	apply_global_count_button.pressed.connect(_on_apply_global_count_pressed)
	reset_confirmation.confirmed.connect(_on_reset_confirmed)
	lock_confirmation.confirmed.connect(_on_lock_confirmed)

	var puzzle_names: Array = _dev_manager.call("get_puzzle_names")
	for index in range(puzzle_names.size()):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var check := CheckBox.new()
		check.text = "%02d. %s" % [index + 1, puzzle_names[index]]
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.toggled.connect(_on_puzzle_toggled.bind(index))
		row.add_child(check)
		_checkboxes.append(check)

		var cfg: Dictionary = _dev_manager.call("get_puzzle_config_by_index", index)
		if not cfg.is_empty():
			var p_type: String = str(cfg.get("type", "score"))
			var cur_count: int = int(cfg.get("current_count", cfg.get("max", 15)))
			var cur_pass: int = int(cfg.get("current_pass", cfg.get("default", 12)))

			if p_type == "score":
				var count_lbl := Label.new()
				count_lbl.text = "Questions:"
				count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				row.add_child(count_lbl)

				var count_spin := SpinBox.new()
				count_spin.min_value = 1
				count_spin.max_value = 50
				count_spin.step = 1
				count_spin.value = cur_count
				count_spin.custom_minimum_size = Vector2(70, 0)
				row.add_child(count_spin)
				_count_spinboxes[index] = count_spin

				var pass_lbl := Label.new()
				pass_lbl.text = "Pass Score:"
				pass_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				row.add_child(pass_lbl)

				var pass_spin := SpinBox.new()
				pass_spin.min_value = 1
				pass_spin.max_value = cur_count
				pass_spin.step = 1
				pass_spin.value = cur_pass
				pass_spin.custom_minimum_size = Vector2(70, 0)
				row.add_child(pass_spin)
				_pass_spinboxes[index] = pass_spin

				var rate_lbl := Label.new()
				rate_lbl.custom_minimum_size = Vector2(90, 0)
				rate_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				_update_rate_label(rate_lbl, cur_pass, cur_count)
				row.add_child(rate_lbl)
				_pass_labels[index] = rate_lbl

				count_spin.value_changed.connect(func(new_count: float):
					var c_val: int = int(new_count)
					_dev_manager.call("set_quiz_count_by_index", index, c_val)
					pass_spin.max_value = c_val
					if pass_spin.value > c_val:
						pass_spin.value = c_val
					_update_rate_label(rate_lbl, int(pass_spin.value), c_val)
				)

				pass_spin.value_changed.connect(func(new_pass: float):
					var p_val: int = int(new_pass)
					_dev_manager.call("set_pass_rate_by_index", index, p_val)
					_update_rate_label(rate_lbl, p_val, int(count_spin.value))
				)

				var default_btn := Button.new()
				default_btn.text = "Default"
				var def_count: int = 15 if index < 5 else 5
				var def_pass: int = int(cfg.get("default", 12))
				default_btn.pressed.connect(func():
					count_spin.value = def_count
					pass_spin.max_value = def_count
					pass_spin.value = def_pass
				)
				row.add_child(default_btn)

			elif p_type == "goal":
				var goal_lbl := Label.new()
				goal_lbl.text = "Pass Mode:"
				goal_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				row.add_child(goal_lbl)

				var opt := OptionButton.new()
				opt.add_item("Require Goal (100%)", 1)
				opt.add_item("Auto-Pass (0%)", 0)
				opt.select(0 if cur_pass > 0 else 1)
				opt.custom_minimum_size = Vector2(180, 0)
				row.add_child(opt)
				_goal_options[index] = opt

				opt.item_selected.connect(func(sel_idx: int):
					var pass_val: int = opt.get_item_id(sel_idx)
					_dev_manager.call("set_pass_rate_by_index", index, pass_val)
				)

		puzzle_list.add_child(row)

	_refresh_checkboxes()


func _update_rate_label(lbl: Label, cur_val: int, max_val: int) -> void:
	var pct := int(round((float(cur_val) / float(max_val)) * 100.0)) if max_val > 0 else 100
	lbl.text = "/ %d (%d%%)" % [max_val, pct]


func _refresh_checkboxes() -> void:
	var count: int = int(_dev_manager.call("get_unlocked_count"))
	for index in _checkboxes.size():
		_checkboxes[index].set_pressed_no_signal(index < count)
	status_label.text = "%d/%d puzzles unlocked. Checking a later puzzle completes all prerequisites; the selected puzzle remains unfinished." % [count, _checkboxes.size()]


func _refresh_pass_rate_controls() -> void:
	for index in _count_spinboxes:
		var cfg: Dictionary = _dev_manager.call("get_puzzle_config_by_index", index)
		var c_spin: SpinBox = _count_spinboxes[index]
		var cur_count: int = int(cfg.get("current_count", c_spin.value))
		c_spin.set_value_no_signal(cur_count)

		if _pass_spinboxes.has(index):
			var p_spin: SpinBox = _pass_spinboxes[index]
			p_spin.max_value = cur_count
			var cur_pass: int = int(cfg.get("current_pass", p_spin.value))
			p_spin.set_value_no_signal(cur_pass)
			if _pass_labels.has(index):
				_update_rate_label(_pass_labels[index], cur_pass, cur_count)

	for index in _goal_options:
		var cfg: Dictionary = _dev_manager.call("get_puzzle_config_by_index", index)
		var opt: OptionButton = _goal_options[index]
		var cur: int = int(cfg.get("current_pass", 1))
		opt.select(0 if cur > 0 else 1)


func _on_puzzle_toggled(checked: bool, index: int) -> void:
	if _dev_manager == null or not bool(_dev_manager.get("enabled")):
		_refresh_checkboxes()
		return
	if not checked:
		_pending_lock_index = index
		_refresh_checkboxes()
		lock_confirmation.popup_centered()
		return
	if not bool(_dev_manager.call("set_puzzle_unlocked", index, true)):
		status_label.text = "Could not update progress. Check Godot's output log."
		_refresh_checkboxes()
		return
	_refresh_checkboxes()


func _on_lock_confirmed() -> void:
	if _pending_lock_index < 0:
		return
	var target := _pending_lock_index
	_pending_lock_index = -1
	if not bool(_dev_manager.call("set_puzzle_unlocked", target, false)):
		status_label.text = "Could not lock puzzle. Check Godot's output log."
		return
	_refresh_checkboxes()


func _on_unlock_all_pressed() -> void:
	if bool(_dev_manager.call("unlock_all")):
		_refresh_checkboxes()
	else:
		status_label.text = "Could not unlock puzzles. Check Godot's output log."


func _on_reset_pressed() -> void:
	reset_confirmation.popup_centered()


func _on_reset_confirmed() -> void:
	if bool(_dev_manager.call("reset_progress")):
		_refresh_checkboxes()
		_refresh_pass_rate_controls()
		status_label.text = "Progress, quiz counts, and pass rates reset to defaults. Continue is disabled until next checkpoint."
	else:
		status_label.text = "Reset cancelled: failed to preserve backup."


func _on_reset_pass_rates_pressed() -> void:
	if _dev_manager == null or not bool(_dev_manager.get("enabled")):
		return
	_dev_manager.call("reset_all_pass_rates")
	_dev_manager.call("reset_all_quiz_counts")
	_refresh_pass_rate_controls()
	status_label.text = "All puzzle question counts and pass rates have been reset to default values."


func _on_apply_global_pass_pressed() -> void:
	if _dev_manager == null or not bool(_dev_manager.get("enabled")):
		return
	var pct: float = global_pass_spin.value
	_dev_manager.call("apply_global_pass_percentage", pct)
	_refresh_pass_rate_controls()
	status_label.text = "Applied %d%% pass rate across all puzzles." % int(pct)


func _on_apply_global_count_pressed() -> void:
	if _dev_manager == null or not bool(_dev_manager.get("enabled")):
		return
	var count: int = int(global_count_spin.value)
	_dev_manager.call("apply_global_quiz_count", count)
	_refresh_pass_rate_controls()
	status_label.text = "Set %d questions across all quiz puzzles." % count


func _on_back_pressed() -> void:
	await FadeManager.fade_and_change(MAIN_SCENE)


func _on_disable_pressed() -> void:
	_dev_manager.call("disable")
	await FadeManager.fade_and_change(MAIN_SCENE)


func _return_to_main() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
