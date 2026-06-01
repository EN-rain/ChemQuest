extends Node

var fade_rect: ColorRect

func setup(rect: ColorRect) -> void:
	fade_rect = rect


func fade_and_change(scene_path: String, duration: float = 1.0) -> void:
	if not fade_rect:
		push_error("FadeManager: fade_rect not set! Call setup() in _ready() of the scene.")
		return

	fade_rect.color = Color(0, 0, 0, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "color", Color.BLACK, duration)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)


# ✅ NEW FUNCTION: reload current scene with fade
func reload_current_scene(duration: float = 1.0) -> void:
	if not fade_rect:
		push_error("FadeManager: fade_rect not set! Call setup() in _ready() of the scene.")
		return

	var current_scene = get_tree().current_scene
	if not current_scene:
		push_error("FadeManager: No current scene to reload.")
		return

	fade_rect.color = Color(0, 0, 0, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(fade_rect, "color", Color.BLACK, duration)
	await tween.finished
	get_tree().reload_current_scene()
