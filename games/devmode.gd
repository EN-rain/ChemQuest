extends Control

const MAIN_SCENE := "res://games/main.tscn"

@onready var back_button: Button = $BackButton
@onready var disable_button: Button = $DisableButton
@onready var reset_button: Button = $ResetButton
@onready var unlock_all_button: Button = $UnlockAllButton
@onready var puzzle_list: VBoxContainer = $PuzzleScroll/PuzzleList
@onready var status_label: Label = $StatusLabel
@onready var reset_confirmation: ConfirmationDialog = $ResetConfirmation
@onready var lock_confirmation: ConfirmationDialog = $LockConfirmation
@onready var _dev_manager: Node = get_node_or_null("/root/DevModeManager")

var _checkboxes: Array[CheckBox] = []
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
	reset_confirmation.confirmed.connect(_on_reset_confirmed)
	lock_confirmation.confirmed.connect(_on_lock_confirmed)
	var puzzle_names: Array = _dev_manager.call("get_puzzle_names")
	for index in range(puzzle_names.size()):
		var check := CheckBox.new()
		check.text = "%02d. %s" % [index + 1, puzzle_names[index]]
		check.toggled.connect(_on_puzzle_toggled.bind(index))
		puzzle_list.add_child(check)
		_checkboxes.append(check)
	_refresh_checkboxes()


func _refresh_checkboxes() -> void:
	var count: int = int(_dev_manager.call("get_unlocked_count"))
	for index in _checkboxes.size():
		_checkboxes[index].set_pressed_no_signal(index < count)
	status_label.text = "%d/%d puzzles unlocked. Checking a later puzzle completes all prerequisites; the selected puzzle remains unfinished." % [count, _checkboxes.size()]


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
		status_label.text = "Progress reset. Continue is disabled until the first gameplay checkpoint."
	else:
		status_label.text = "Reset cancelled: failed to preserve backup."


func _on_back_pressed() -> void:
	await FadeManager.fade_and_change(MAIN_SCENE)


func _on_disable_pressed() -> void:
	_dev_manager.call("disable")
	await FadeManager.fade_and_change(MAIN_SCENE)


func _return_to_main() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
