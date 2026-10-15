extends Node

## The QuestPanel is editor-positioned. Responsive HUD recalculation must not
## replace its authored anchors or offsets with a hardcoded screen position.
func _ready() -> void:
	var tree := get_tree()
	get_window().size = Vector2i(1280, 720)
	await tree.process_frame
	var hud := CanvasLayer.new()
	hud.set_script(load("res://games/global/ResponsiveHudLayout.gd"))
	var quest := Panel.new()
	quest.name = "QuestPanel"
	quest.anchor_top = 0.5
	quest.anchor_bottom = 0.5
	quest.offset_left = 2.0
	quest.offset_top = -208.0
	quest.offset_right = 420.0
	quest.offset_bottom = -130.0
	hud.add_child(quest)
	add_child(hud)
	await tree.process_frame
	var first_position := quest.position
	hud.call("_apply_layout")
	await tree.process_frame
	var same_at_start := quest.position.is_equal_approx(first_position)
	get_window().size = Vector2i(1024, 640)
	await tree.process_frame
	var before_refresh := quest.position
	hud.call("_apply_layout")
	await tree.process_frame
	var same_after_resize := quest.position.is_equal_approx(before_refresh)
	var horizontal_preserved := is_equal_approx(quest.position.x, 2.0)
	hud.queue_free()
	if same_at_start and same_after_resize and horizontal_preserved:
		print("QUEST_PANEL_POSITION PASS: authored layout preserved at startup and after resize")
		tree.quit(0)
	else:
		print("QUEST_PANEL_POSITION FAIL start=", same_at_start, " resize=", same_after_resize, " horizontal=", horizontal_preserved)
		tree.quit(1)
