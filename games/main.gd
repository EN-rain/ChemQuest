extends Node2D

@onready var fade_sfx: ColorRect = %FadeSfx
@onready var playing_label: Label = %Playing
@onready var continue_button: Button = $CanvasLayer/VBoxContainer/Continue
@onready var dev_button: Button = $CanvasLayer2/DevButton
@onready var dev_label: Label = $CanvasLayer2/DevLabel
@onready var _dev_manager: Node = get_node_or_null("/root/DevModeManager")

const DEV_CLICKS_REQUIRED := 5
const DEV_CLICK_WINDOW_MS := 2000
const DEV_SCENE := "res://games/devmode.tscn"
var _dev_click_count := 0
var _dev_first_click_ms := 0


func _ready() -> void:
	_refresh_continue_button()
	if _dev_manager == null:
		# A Godot editor that was already running before the autoload was added
		# may still launch the scene with its old project settings. Recover the
		# manager in that case rather than silently ignoring developer clicks.
		var manager_script := load("res://games/global/DevModeManager.gd") as Script
		if manager_script != null:
			_dev_manager = manager_script.new() as Node
			_dev_manager.name = "DevModeManager"
			get_tree().root.add_child(_dev_manager)
	# Late-bound access keeps this scene parseable even when an already-open
	# Godot editor has not reloaded the newly registered autoload yet.
	dev_label.visible = _dev_manager != null and bool(_dev_manager.get("enabled"))
	# The indicator overlaps the button near the bottom edge; it must not
	# swallow the next click that opens the developer scene.
	dev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dev_button.pressed.connect(_on_dev_button_pressed)
	MusicManager.play_music_by_id("main")
	FadeManager.setup(fade_sfx)
	_connect_responsive_layout()
	_apply_responsive_layout()
	_start_blinking_playing_label()


## The Continue text is a separate Label child and the disabled Button uses
## StyleBoxEmpty, so Godot does not dim the text automatically. Modulate the
## whole Button (including its Label) to make an unavailable save obvious.
func _refresh_continue_button() -> void:
	var can_continue: bool = SaveManager.has_continue_checkpoint()
	continue_button.disabled = not can_continue
	continue_button.modulate = Color.WHITE if can_continue else Color(0.6, 0.6, 0.6, 0.5)


func _connect_responsive_layout() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service != null and not service.layout_changed.is_connected(_on_responsive_layout_changed):
		service.layout_changed.connect(_on_responsive_layout_changed)


func _on_responsive_layout_changed(_viewport_size: Vector2, _safe_rect: Rect2) -> void:
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var service := get_node_or_null("/root/ResponsiveLayout")
	if service == null:
		return
	var safe_rect: Rect2 = service.safe_rect
	var music_button := get_node_or_null("CanvasLayer/MusicButton") as Control
	if music_button != null:
		# The authored button is 64 design pixels and rendered at 1.5x.
		# Position the transformed 96px visual inside the safe rectangle.
		music_button.position = Vector2(safe_rect.end.x - 96.0, safe_rect.position.y)
	var achieve_button := get_node_or_null("CanvasLayer/AchieveButton") as Control
	if achieve_button != null:
		var achieve_size := achieve_button.size
		if achieve_size.x <= 0.0 or achieve_size.y <= 0.0:
			achieve_size = Vector2(112.0, 81.0)
		achieve_button.position = Vector2(
			safe_rect.end.x - achieve_size.x - 96.0,
			safe_rect.position.y
		)
	var menu := get_node_or_null("CanvasLayer/VBoxContainer") as Control
	if menu != null:
		var menu_size := menu.size
		if menu_size.x <= 0.0 or menu_size.y <= 0.0:
			menu_size = Vector2(317.0, 450.0)
		menu.position = Vector2(
			maxf(safe_rect.position.x + 24.0, safe_rect.end.x - menu_size.x - 24.0),
			safe_rect.position.y + maxf(0.0, (safe_rect.size.y - menu_size.y) * 0.5)
		)


func _start_blinking_playing_label() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(playing_label, "modulate:a", 0.2, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(playing_label, "modulate:a", 1.0, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_start_blinking_playing_label)


func _on_continue_pressed() -> void:
	if not SaveManager.has_continue_checkpoint():
		_refresh_continue_button()
		return
	MusicManager.play_sfx("button")

	var data: Dictionary = SaveManager.load_game()
	if data.is_empty() or not data.get("has_started_game", false) or not SaveManager.is_gameplay_scene(data.get("scene_path", "")):
		push_warning("Continue: no playable checkpoint exists.")
		_refresh_continue_button()
		return

	SaveManager.restore_game(data)
	var next_scene := SaveManager.current_scene_path
	var spawn_name := SaveManager.last_spawn if not SaveManager.last_spawn.is_empty() else "default"
	print("Continue pressed -> scene: ", next_scene, " spawn: ", spawn_name)
	SpawnManager.set_spawn(spawn_name)
	await FadeManager.fade_and_change(next_scene)


func _on_new_game_pressed() -> void:
	MusicManager.play_sfx("button")
	print("Starting a new game...")
	SaveManager.reset_for_new_game()
	_refresh_continue_button()
	await FadeManager.fade_and_change(SaveManager.NEW_GAME_SCENE_PATH)


func _on_chapter_1_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change(SaveManager.NEW_GAME_SCENE_PATH)


func _on_about_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/about.tscn")


func _on_glossary_pressed() -> void:
	MusicManager.play_sfx("button")
	await FadeManager.fade_and_change("res://games/glossary/main.tscn")


func _on_exit_pressed() -> void:
	MusicManager.play_sfx("button")
	SaveManager.flush_pending_save()
	MusicManager.stop_music()
	get_tree().quit()


func _on_dev_button_pressed() -> void:
	if _dev_manager == null:
		push_warning("DevModeManager autoload is unavailable. Reopen this project in Godot to refresh its autoloads.")
		return
	if bool(_dev_manager.get("enabled")):
		await FadeManager.fade_and_change(DEV_SCENE)
		return
	var now := Time.get_ticks_msec()
	if _dev_click_count == 0 or now - _dev_first_click_ms > DEV_CLICK_WINDOW_MS:
		_dev_first_click_ms = now
		_dev_click_count = 0
	_dev_click_count += 1
	if _dev_click_count >= DEV_CLICKS_REQUIRED:
		_dev_click_count = 0
		_dev_manager.call("enable")
		dev_label.visible = true
