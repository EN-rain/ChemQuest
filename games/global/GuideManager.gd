extends Node

var _config := ConfigFile.new()
var _save_path := "user://guides.cfg"
var _loaded := false

func _ready():
	_load_data()

# 🧩 Load or create config file
func _load_data():
	if _loaded: return
	var err = _config.load(_save_path)
	if err != OK:
		_config.save(_save_path)
	_loaded = true

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
