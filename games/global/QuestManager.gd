extends Node

signal quest_updated
signal quest_added(quest: Quest)
signal quest_completed(quest: Quest)

var active_quests: Dictionary = {}  # id -> Quest
const DEFAULT_QUESTS_PATH := "res://games/global/quest.json"
const MAX_DENSITY_LEVEL: int = 3
const MAX_STATES_LEVEL: int = 3


# ---------------------------------------------------------
#  INITIALIZATION
# ---------------------------------------------------------
func _ready() -> void:
	# Fix (B1): Do NOT auto-load defaults here. The previous behavior
	# clobbered any state restored by SaveManager.restore_game(), and
	# depended on the fragile alphabetic autoload ordering that put
	# SaveManager after QuestManager.
	#
	# Defaults are now loaded explicitly by main.gd._on_new_game_pressed()
	# via load_default_quests(). On Continue, SaveManager.restore_game()
	# calls load_from_save_data() which sets active_quests directly.
	pass


# ---------------------------------------------------------
#  ADD / COMPLETE QUESTS
# ---------------------------------------------------------
func add_quest(quest: Quest) -> void:
	if quest.id in active_quests:
		print(" Quest already active:", quest.title)
	else:
		active_quests[quest.id] = quest
		print("Quest added:", quest.title)
		emit_signal("quest_added", quest)
		emit_signal("quest_updated")
		if has_node("/root/SaveManager"):
			SaveManager.save_game()

func complete_quest(id: String) -> void:
	if id in active_quests and not active_quests[id].is_completed:
		active_quests[id].is_completed = true
		print(" Quest completed:", active_quests[id].title)
		emit_signal("quest_completed", active_quests[id])
		emit_signal("quest_updated")
		if has_node("/root/SaveManager"):
			SaveManager.save_game()


# ---------------------------------------------------------
#  GETTERS
# ---------------------------------------------------------
func get_active_quests() -> Array:
	return active_quests.values()

func has_quest(id: String) -> bool:
	return id in active_quests

func is_quest_completed(id: String) -> bool:
	return id in active_quests and active_quests[id].is_completed


# ---------------------------------------------------------
#  LOAD DEFAULT QUESTS (used by New Game)
# ---------------------------------------------------------
func _load_default_quests() -> void:
	if FileAccess.file_exists(DEFAULT_QUESTS_PATH):
		var file := FileAccess.open(DEFAULT_QUESTS_PATH, FileAccess.READ)
		var text: String = file.get_as_text()
		file.close()
		var data: Variant = JSON.parse_string(text)
		if typeof(data) == TYPE_DICTIONARY and data.has("quests"):
			_load_from_data(data["quests"])


# ---------------------------------------------------------
#  Load quest data from array (used by defaults and saves)
# ---------------------------------------------------------
func _load_from_data(arr: Array) -> void:
	active_quests.clear()
	for entry in arr:
		var quest := Quest.new()
		quest.id = entry["id"]
		quest.title = entry["title"]
		quest.description = entry["description"]

		var raw_val: Variant = entry.get("is_completed", false)
		if typeof(raw_val) == TYPE_BOOL:
			quest.is_completed = raw_val
		elif typeof(raw_val) == TYPE_STRING:
			var s: String = raw_val.strip_edges().to_lower()
			quest.is_completed = s == "true"
		elif typeof(raw_val) == TYPE_INT:
			quest.is_completed = raw_val != 0
		else:
			quest.is_completed = false

		active_quests[quest.id] = quest
	print(" Loaded quests:", active_quests.size())


# ---------------------------------------------------------
#  Load from save.json (Continue game)
# ---------------------------------------------------------
func load_from_save_data(quests_array: Array) -> void:
	active_quests.clear()
	for entry in quests_array:
		var quest := Quest.new()
		quest.id = entry.get("id", "")
		quest.title = entry.get("title", "")
		quest.description = entry.get("description", "")

		# Fix (#27): Migrate old "seperation_*" quest IDs to the correct
		# "separation_*" spelling so existing saves don't break after the
		# rename in quest.json.
		if quest.id == "seperation_methods":
			quest.id = "separation_methods"
		elif quest.id == "seperation_methods_after":
			quest.id = "separation_methods_after"

		var raw_value: Variant = entry.get("is_completed", false)
		var parsed_value: bool = false

		if typeof(raw_value) == TYPE_BOOL:
			parsed_value = raw_value
		elif typeof(raw_value) == TYPE_STRING:
			var s: String = raw_value.strip_edges().to_lower()
			parsed_value = (s == "true")
		elif typeof(raw_value) == TYPE_INT:
			parsed_value = (raw_value != 0)
		else:
			parsed_value = false

		quest.is_completed = parsed_value
		active_quests[quest.id] = quest
		print(" Quest restored:", quest.id, "Completed:", quest.is_completed)

	print(" Quests restored from save:", active_quests.size())


# ---------------------------------------------------------
#  QUEST TEMPLATE (get by id from quest.json)
# ---------------------------------------------------------
func get_quest_template(id: String) -> Quest:
	if not FileAccess.file_exists(DEFAULT_QUESTS_PATH):
		return null
	var file := FileAccess.open(DEFAULT_QUESTS_PATH, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()

	var data: Variant = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY and data.has("quests"):
		for entry in data["quests"]:
			if entry["id"] == id:
				var quest := Quest.new()
				quest.id = entry["id"]
				quest.title = entry["title"]
				quest.description = entry["description"]

				var raw_val: Variant = entry.get("is_completed", false)
				if typeof(raw_val) == TYPE_BOOL:
					quest.is_completed = raw_val
				elif typeof(raw_val) == TYPE_STRING:
					var s: String = raw_val.strip_edges().to_lower()
					quest.is_completed = s == "true"
				elif typeof(raw_val) == TYPE_INT:
					quest.is_completed = raw_val != 0
				else:
					quest.is_completed = false

				return quest
	return null


# ---------------------------------------------------------
#  FIND LATEST INCOMPLETE QUEST
# ---------------------------------------------------------
func get_latest_incomplete_quest() -> Quest:
	for quest in active_quests.values():
		if not quest.is_completed:
			return quest
	return null


# ---------------------------------------------------------
#  DENSITY MEASUREMENT PROGRESSION
# ---------------------------------------------------------
var density_progress: int = 0
var density_completed_levels: Array[int] = []

func advance_density_level(level_num: int) -> void:
	if level_num <= 0 or level_num > MAX_DENSITY_LEVEL:
		push_warning("Invalid density level: %d" % level_num)
		return
	if level_num in density_completed_levels:
		print("Level %d already completed. Progress not increased." % level_num)
		return

	density_completed_levels.append(level_num)
	density_completed_levels.sort()
	density_progress = mini(MAX_DENSITY_LEVEL, density_completed_levels.size())
	print("Density progress now:", density_progress, "(Completed levels:", density_completed_levels, ")")

	match density_progress:
		1:
			print("Density Level 1 completed -> Unlocking Level 2")
		2:
			print("Density Level 2 completed -> Unlocking Level 3")
		3:
			print("Density Level 3 completed -> Finishing quest")
			if has_quest("density_measurement") and not is_quest_completed("density_measurement"):
				complete_quest("density_measurement")
				var next_quest := get_quest_template("after_density_measurement")
				if next_quest:
					add_quest(next_quest)

	if has_node("/root/SaveManager"):
		SaveManager.save_game()


# ---------------------------------------------------------
#  STATES OF MATTER PROGRESSION
# ---------------------------------------------------------
var states_progress: int = 0
## `completed_levels` is the canonical public collection used by the original
## States scenes. `cleared_states_levels` is retained as a compatibility alias
## for newer callers and is synchronized whenever progress is read or changed.
var cleared_states_levels: Array[int] = []
var completed_levels: Array[int] = []

func get_states_completed_levels() -> Array[int]:
	# Treat the established `completed_levels` field as authoritative when it
	# has been assigned directly by an older scene or a save migration. Only
	# fall back to the alias when the canonical collection is empty, which keeps
	# both public names usable without resurrecting stale entries.
	var source_levels: Array[int] = completed_levels
	if source_levels.is_empty() and not cleared_states_levels.is_empty():
		source_levels = cleared_states_levels
	var merged: Array[int] = []
	for level in source_levels:
		if level not in merged and level > 0 and level <= MAX_STATES_LEVEL:
			merged.append(level)
	merged.sort()
	cleared_states_levels = merged.duplicate()
	completed_levels = merged.duplicate()
	return merged

func advance_states_level(level_number: int) -> void:
	if level_number <= 0 or level_number > MAX_STATES_LEVEL:
		print("Invalid level number:", level_number)
		return

	if level_number in get_states_completed_levels():
		print("Level", level_number, "already completed. No progress added.")
		return

	completed_levels.append(level_number)
	completed_levels.sort()
	cleared_states_levels = completed_levels.duplicate()

	if level_number > states_progress:
		states_progress = level_number
		print("States progress advanced to level:", states_progress)

		match states_progress:
			1:
				print("States Level 1 completed -> Unlocking Level 2")
			2:
				print("States Level 2 completed -> Unlocking Level 3")
			3:
				print("States Level 3 completed -> Finishing quest")
				if has_quest("states_of_matter") and not is_quest_completed("states_of_matter"):
					complete_quest("states_of_matter")
					var next_quest := get_quest_template("after_states_of_matter")
					if next_quest:
						add_quest(next_quest)

	if has_node("/root/SaveManager"):
		SaveManager.save_game()


# ---------------------------------------------------------
#  LOAD DEFAULT QUESTS (external call for New Game)
# ---------------------------------------------------------
func load_default_quests() -> void:
	var path := "res://games/global/quest.json"
	if not FileAccess.file_exists(path):
		push_error("Default quest file missing at: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("QuestManager: failed to open default quest file.")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY or not data.has("quests"):
		push_error("QuestManager: invalid default quest data.")
		return

	active_quests.clear()
	for entry in data["quests"]:
		if not entry is Dictionary:
			continue
		var quest := Quest.new()
		quest.id = str(entry.get("id", ""))
		quest.title = str(entry.get("title", ""))
		quest.description = str(entry.get("description", ""))
		quest.is_completed = false
		active_quests[quest.id] = quest
	print("Default quests loaded: ", active_quests.size())


## Reset all gameplay progression and load a fresh copy of the quest templates.
## Guide/tutorial visibility is profile-level state and is intentionally not
## changed here.
func reset_for_new_game() -> void:
	active_quests.clear()
	density_progress = 0
	density_completed_levels.clear()
	states_progress = 0
	cleared_states_levels.clear()
	completed_levels.clear()
	load_default_quests()
