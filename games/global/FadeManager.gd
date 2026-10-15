extends Node

## Persistent scene-transition service.
##
## Older scenes still call setup() with a scene-local ColorRect. That method is
## intentionally retained as a compatibility no-op: a transition must never
## depend on a node that is about to be freed by the scene change.

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String, success: bool)

const FADE_LAYER := 90

var fade_rect: ColorRect
var _fade_layer: CanvasLayer
var _transition_in_progress := false
var _test_mode := false


func _ready() -> void:
	_test_mode = "--route-test" in OS.get_cmdline_user_args()
	_ensure_overlay()


func _ensure_overlay() -> void:
	if is_instance_valid(fade_rect):
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "PersistentFadeLayer"
	_fade_layer.layer = FADE_LAYER
	add_child(_fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.name = "PersistentFadeRect"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(fade_rect)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_test_mode(enabled: bool) -> void:
	## Test runners may opt into instant transitions without changing gameplay.
	_test_mode = enabled


func setup(_legacy_rect: ColorRect) -> void:
	## Compatibility shim for scene scripts written before the persistent overlay.
	_ensure_overlay()


func fade_and_change(scene_path: String, duration: float = 1.0) -> bool:
	_ensure_overlay()
	if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path, "PackedScene"):
		var invalid_message := "FadeManager: refusing to change to missing scene: " + scene_path
		# The route contract deliberately probes an invalid path. Keep that
		# expected rejection out of the engine-error stream in test mode while
		# retaining a hard error for a production caller that supplied a bad path.
		if _test_mode:
			push_warning(invalid_message)
		else:
			push_error(invalid_message)
		return false
	if _transition_in_progress:
		push_warning("FadeManager: ignoring concurrent transition to " + scene_path)
		return false

	_transition_in_progress = true
	transition_started.emit(scene_path)
	if has_node("/root/SpawnManager") and SpawnManager.has_method("validate_for_scene"):
		SpawnManager.validate_for_scene(scene_path)
	if has_node("/root/SaveManager") and SaveManager.has_method("save_before_transition"):
		SaveManager.save_before_transition(scene_path)
	var actual_duration := 0.0 if _test_mode else maxf(0.0, duration)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.color = Color(0, 0, 0, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(fade_rect, "color", Color.BLACK, actual_duration)
	await tween.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("FadeManager: scene change failed for %s (error %d)." % [scene_path, error])
	else:
		await get_tree().process_frame

	# Fade into the new scene instead of revealing it in one frame. The
	# persistent overlay remains black while the new scene is initialized.
	var fade_in := get_tree().create_tween()
	fade_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), actual_duration)
	await fade_in.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_in_progress = false
	transition_finished.emit(scene_path, error == OK)
	return error == OK


func reload_current_scene(duration: float = 1.0) -> void:
	if _transition_in_progress:
		return
	_transition_in_progress = true
	_ensure_overlay()
	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_error("FadeManager: No current scene to reload.")
		_transition_in_progress = false
		return
	var actual_duration := 0.0 if _test_mode else maxf(0.0, duration)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.color = Color(0, 0, 0, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(fade_rect, "color", Color.BLACK, actual_duration)
	await tween.finished
	get_tree().reload_current_scene()
	await get_tree().process_frame
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_in_progress = false
