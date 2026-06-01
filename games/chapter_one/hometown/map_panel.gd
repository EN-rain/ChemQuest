extends Panel

@onready var quest_indicator: Label = $Frame/QuestIndicator
@onready var quest_indicator_2: Label = $Frame/QuestIndicator2

var indicator_tweens: Dictionary = {}
var indicator_base_y: Dictionary = {}

func _ready() -> void:
	_register_indicator(quest_indicator)
	_register_indicator(quest_indicator_2)
	_update_quest_indicators()

	if not QuestManager.quest_added.is_connected(_on_quest_changed):
		QuestManager.quest_added.connect(_on_quest_changed)
	if not QuestManager.quest_completed.is_connected(_on_quest_changed):
		QuestManager.quest_completed.connect(_on_quest_changed)
	if not QuestManager.quest_updated.is_connected(_update_quest_indicators):
		QuestManager.quest_updated.connect(_update_quest_indicators)

func _register_indicator(indicator: Label) -> void:
	if indicator == null:
		return
	indicator_base_y[indicator.name] = indicator.position.y
	indicator.visible = false

func _on_quest_changed(_quest: Quest) -> void:
	_update_quest_indicators()

func _update_quest_indicators() -> void:
	var latest_quest := QuestManager.get_latest_incomplete_quest()
	var latest_id := ""
	if latest_quest != null:
		latest_id = latest_quest.id

	_update_indicator(quest_indicator, latest_id == "find_wiz")
	_update_indicator(quest_indicator_2, latest_id == "find_christofe")

func _update_indicator(indicator: Label, should_show: bool) -> void:
	if indicator == null:
		return

	if should_show:
		_start_indicator_pulse(indicator)
	else:
		_stop_indicator_pulse(indicator)

func _start_indicator_pulse(indicator: Label) -> void:
	var key := indicator.name
	if indicator_tweens.has(key):
		indicator_tweens[key].kill()

	var base_y: float = indicator_base_y.get(key, indicator.position.y)
	indicator.visible = true
	indicator.position.y = base_y

	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(indicator, "position:y", base_y - 10.0, 0.7)
	tween.tween_property(indicator, "position:y", base_y, 0.7)
	indicator_tweens[key] = tween

func _stop_indicator_pulse(indicator: Label) -> void:
	var key := indicator.name
	if indicator_tweens.has(key):
		indicator_tweens[key].kill()
		indicator_tweens.erase(key)

	indicator.visible = false
	indicator.position.y = indicator_base_y.get(key, indicator.position.y)
