extends Node

var _config := ConfigFile.new()
var _save_path := "user://guides.cfg"
var _loaded := false

func _ready():
	_load_data()

# 🧩 Load or create config file
func _load_data():
	if _loaded:
		return
	if FileAccess.file_exists(_save_path):
		var file := FileAccess.open(_save_path, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			file.close()
			if not _is_config_text_valid(text):
				push_warning("GuideManager: resetting malformed guide data at %s" % _save_path)
				_config.clear()
				_config.save(_save_path)

	var err = _config.load(_save_path)
	if err != OK:
		push_warning("GuideManager: resetting unreadable guide data at %s" % _save_path)
		_config.clear()
		_config.save(_save_path)
	_loaded = true

func _is_config_text_valid(text: String) -> bool:
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line == "" or line.begins_with(";"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			continue
		var parts := line.split("=", false, 1)
		if parts.size() != 2:
			return false
		var value := parts[1].strip_edges()
		if value != "true" and value != "false":
			return false
	return true

#  Returns true if guide was already shown
func has_seen(guide_id: String) -> bool:
	_load_data()
	return _config.get_value("guides", guide_id, false)

# 💾 Marks guide as shown
func mark_seen(guide_id: String) -> void:
	_load_data()
	_config.set_value("guides", guide_id, true)
	_config.save(_save_path)

# 🔄 Optional: Reset all guides (for testing or debug)
func reset_all() -> void:
	_config.clear()
	_config.save(_save_path)
